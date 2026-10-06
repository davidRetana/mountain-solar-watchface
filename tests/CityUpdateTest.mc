using Toybox.Test;
using Toybox.Application.Storage;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Position;

(:test)
module TestCityState {
    function restore(key, value) {
        if (value == null) { Storage.deleteValue(key); }
        else { Storage.setValue(key, value); }
    }
}

(:test)
function cityCacheKeepsRecentVisits(logger) {
    var previous = Storage.getValue("cityCache");
    Storage.setValue("cityCache", ["0", "0", "Legacy city"]);
    for (var i = 1; i < 8; i += 1) {
        CityLookup.remember([i.toString(), "0"], "City " + i.toString());
    }
    var migrated = CityLookup.cachedName(["0", "0"]);
    // Visiting an old location makes it recent; the next insert evicts city 1.
    CityLookup.remember(["0", "0"], "Legacy city");
    CityLookup.remember(["8", "0"], "New city");
    var retained = CityLookup.cachedName(["0", "0"]);
    var evicted = CityLookup.cachedName(["1", "0"]);
    CityLookup.remember(["8", "0"], "Renamed city");
    var renamed = CityLookup.cachedName(["8", "0"]);
    var count = CityLookup.cacheEntries().size();
    TestCityState.restore("cityCache", previous);
    Test.assert(migrated.equals("Legacy city") && retained.equals("Legacy city"));
    Test.assert(evicted == null && renamed.equals("Renamed city") && count == 8);
    return true;
}

(:test)
function cityRetryBackoffAndRecovery(logger) {
    var previous = Storage.getValue("cityRetry");
    var oldAttempt = Storage.getValue("cityAttempt");
    Storage.deleteValue("cityRetry");
    // The legacy one-hour timestamp must not block the new implementation.
    Storage.setValue("cityAttempt", 1000);
    var immediate = CityRetry.nextAttempt(1000) == 1000;
    var delays = [300, 900, 1800, 3600, 3600];
    var now = 1000;
    var correct = true;
    for (var i = 0; i < delays.size(); i += 1) {
        CityRetry.beginAttempt(now);
        // A lost callback also preserves a retry deadline across restarts.
        if (CityRetry.nextAttempt(now + 1) != now + delays[i]) { correct = false; }
        CityRetry.failed(now + 2);
        if (CityRetry.nextAttempt(now + 2) != now + 2 + delays[i]) { correct = false; }
        now += 2 + delays[i];
    }
    var clockCorrected = CityRetry.nextAttempt(500) == 500;
    CityRetry.succeeded();
    var recovered = CityRetry.nextAttempt(now) == now;
    CityRetry.beginAttempt(now);
    var reset = CityRetry.nextAttempt(now) == now + 300;
    TestCityState.restore("cityRetry", previous);
    TestCityState.restore("cityAttempt", oldAttempt);
    Test.assert(immediate && correct && recovered && reset && clockCorrected);
    return true;
}

(:test)
class TestCityScheduler extends CityScheduler {
    var pending = null;
    var last = null;
    var registrations = 0;
    var cancellations = 0;
    function initialize() { CityScheduler.initialize(); }
    function registeredTime() { return pending; }
    function lastEventTime() { return last; }
    function register(when) { pending = when; registrations += 1; }
    function cancel() { pending = null; cancellations += 1; }
}

(:test)
function citySchedulingOnlyWhenNeeded(logger) {
    var previous = Storage.getValue("cityRetry");
    Storage.deleteValue("cityRetry");
    var scheduler = new TestCityScheduler();
    scheduler.update(false, 1000);
    var idle = scheduler.registrations == 0 && scheduler.cancellations == 0;
    scheduler.update(true, 1000);
    scheduler.update(true, 1060);
    var noDuplicate = scheduler.registrations == 1 && scheduler.pending.value() == 1000;
    scheduler.last = new Time.Moment(1060);
    CityRetry.beginAttempt(1060);
    CityRetry.failed(1062);
    scheduler.update(true, 1062);
    scheduler.update(true, 1120);
    var retry = scheduler.registrations == 2 && scheduler.pending.value() == 1362;
    // Returning to a known location cancels even a pending failure retry.
    scheduler.update(false, 1121);
    var cancelled = scheduler.pending == null && scheduler.cancellations == 1;
    CityRetry.succeeded();
    scheduler.update(true, 1122);
    var minimum = scheduler.pending.value() == 1360;
    scheduler.pending = new Time.Duration(900);
    scheduler.update(true, 1420);
    var migrated = scheduler.pending instanceof Time.Moment && scheduler.pending.value() == 1420;
    TestCityState.restore("cityRetry", previous);
    Test.assert(idle && noDuplicate && retry && cancelled && minimum && migrated);
    return true;
}

(:test)
class TestCityWeather {
    var observationTime;
    var observationLocationPosition;
    var temperature;
    function initialize(seconds, lat, lon, temp) {
        observationTime = new Time.Moment(seconds);
        observationLocationPosition = new Position.Location({:latitude=>lat, :longitude=>lon, :format=>:degrees});
        temperature = temp;
    }
}

(:test)
class TestWeatherProvider extends DataProvider {
    var solarCalls = 0;
    function initialize() { DataProvider.initialize(); }
    function refreshSolar(location, now) {
        solarCalls += 1;
        solarRises = [now.value()];
        solarSets = [now.value() + 1000];
    }
}

(:test)
function weatherUpdatesWithoutRepeatedSolarWork(logger) {
    var previous = Storage.getValue("cityCache");
    Storage.setValue("cityCache", ["40.42", "-3.70", "Madrid"]);
    var provider = new TestWeatherProvider();
    var now = new Time.Moment(1750000000);
    var info = Gregorian.info(now, Time.FORMAT_SHORT);
    var weather = new TestCityWeather(now.value(), 40.42, -3.70, 20);
    provider.applyWeather(weather, now, info);
    var first = provider.data.city.equals("Madrid") && provider.solarCalls == 1;
    weather.temperature = 21;
    provider.applyWeather(weather, new Time.Moment(now.value() + 60), info);
    var temperature = provider.data.temperature == 21 && provider.solarCalls == 1;
    var moved = new TestCityWeather(now.value(), 42.57, -0.55, 10);
    provider.applyWeather(moved, new Time.Moment(now.value() + 120), info);
    var noWrongCity = provider.data.city == null && provider.solarCalls == 2;
    CityLookup.remember(["42.57", "-0.55"], "Jaca");
    provider.applyWeather(moved, new Time.Moment(now.value() + 121), info);
    var resolved = provider.data.city.equals("Jaca") && provider.solarCalls == 2;
    provider.applyWeather(weather, new Time.Moment(now.value() + 180), info);
    var returned = provider.data.city.equals("Madrid") && provider.solarCalls == 3;
    var tomorrow = new Time.Moment(now.value() + 86400);
    weather.observationTime = tomorrow;
    provider.applyWeather(weather, tomorrow, Gregorian.info(tomorrow, Time.FORMAT_SHORT));
    var nextDay = provider.solarCalls == 4;
    provider.applyWeather(weather, new Time.Moment(tomorrow.value() + 7201), info);
    var expired = provider.data.city == null && provider.data.temperature == null && provider.cityKey == null;
    weather.observationTime = now;
    weather.observationLocationPosition = null;
    provider.applyWeather(weather, now, info);
    var noPosition = provider.data.temperature == 21 && provider.data.city == null && provider.solarRises.size() == 0;
    TestCityState.restore("cityCache", previous);
    Test.assert(first && temperature && noWrongCity && resolved && returned && nextDay && expired && noPosition);
    return true;
}
