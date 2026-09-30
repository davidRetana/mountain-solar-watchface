using Toybox.Test;
using Toybox.Time;
using Toybox.Time.Gregorian;

(:test)
class EfficiencyScheduler {
    var calls = 0;
    var needed = false;
    function update(value, now) { calls += 1; needed = value; }
}

(:test)
class EfficiencyBattery {
    var battery = 50;
    var batteryInDays = 12;
}

(:test)
class EfficiencyProvider extends DataProvider {
    var activityReads = 0;
    var batteryReads = 0;
    var weatherReads = 0;
    var cityReads = 0;
    var solarCalls = 0;
    var weather = null;
    var battery = null;
    var clock = 1750000020;
    function initialize() {
        DataProvider.initialize();
        cityScheduler = new EfficiencyScheduler();
        battery = new EfficiencyBattery();
    }
    function readActivity() { activityReads += 1; return null; }
    function refresh() { return refreshAt(new Time.Moment(clock)); }
    function readBattery() { batteryReads += 1; return battery; }
    function readWeather() { weatherReads += 1; return weather; }
    function readCity(key) { cityReads += 1; return null; }
    function refreshSolar(location, now) {
        solarCalls += 1;
        solarRises = [now.value() - 60, now.value() + 86400];
        solarSets = [now.value() + 120];
    }
}

(:test)
function batteryEfficiencyCadenceAndBackground(logger) {
    var provider = new EfficiencyProvider();
    var start = 1750000020; // An exact minute boundary.
    provider.refreshAt(new Time.Moment(start));
    for (var second = 1; second < 300; second += 1) {
        provider.refreshAt(new Time.Moment(start + second));
    }
    Test.assert(provider.activityReads == 5 && provider.batteryReads == 1 && provider.weatherReads == 1);
    Test.assert(provider.cityScheduler.calls == 1 && provider.revision == 5);
    provider.refreshAt(new Time.Moment(start + 300));
    Test.assert(provider.activityReads == 6 && provider.batteryReads == 2 && provider.weatherReads == 2);
    provider.invalidateWeather();
    provider.refreshAt(new Time.Moment(start + 301));
    Test.assert(provider.activityReads == 6 && provider.batteryReads == 2 && provider.weatherReads == 3);
    // Deadlines must recover from clock corrections and time spent hidden.
    provider.refreshAt(new Time.Moment(start - 60));
    Test.assert(provider.batteryReads == 3 && provider.weatherReads == 4);
    provider.refreshAt(new Time.Moment(start + 3600));
    Test.assert(provider.batteryReads == 4 && provider.weatherReads == 5);
    // A failed read after the TTL must replace the old value with a fallback.
    provider.battery = null;
    provider.refreshAt(new Time.Moment(start + 3900));
    Test.assert(provider.data.battery == null && provider.data.batteryDays == null);
    return true;
}

(:test)
function cachedWeatherExpiresBetweenReads(logger) {
    var provider = new EfficiencyProvider();
    var start = 1750000020;
    provider.weather = new TestCityWeather(start - 7140, 40.42, -3.70, 20);
    provider.refreshAt(new Time.Moment(start));
    Test.assert(provider.data.temperature == 20 && provider.cityScheduler.needed);
    provider.refreshAt(new Time.Moment(start + 60));
    Test.assert(provider.data.temperature == 20); // Exactly two hours is valid.
    provider.refreshAt(new Time.Moment(start + 120));
    Test.assert(provider.weatherReads == 1 && provider.data.temperature == null);
    Test.assert(provider.weatherLocation == null && provider.data.solarInterval == null);
    Test.assert(!provider.cityScheduler.needed && provider.cityScheduler.calls == 2);
    return true;
}

(:test)
function cachedSolarTransitionsAndCityInvalidation(logger) {
    var provider = new EfficiencyProvider();
    var start = 1750000020;
    provider.weather = new TestCityWeather(start, 40.42, -3.70, 20);
    provider.refreshAt(new Time.Moment(start));
    var firstInterval = provider.data.solarInterval;
    provider.refreshAt(new Time.Moment(start + 60));
    Test.assert(provider.data.solarInterval == firstInterval && firstInterval[2]);
    provider.refreshAt(new Time.Moment(start + 120));
    Test.assert(!provider.data.solarInterval[2]);
    Test.assert(provider.solarCalls == 1 && provider.weatherReads == 1);
    provider.refreshAt(new Time.Moment(start + 300));
    Test.assert(provider.cityReads == 1 && provider.weatherReads == 2);
    provider.invalidateWeather();
    provider.refreshAt(new Time.Moment(start + 301));
    Test.assert(provider.cityReads == 2 && provider.solarCalls == 1);
    provider.weather = new TestCityWeather(start, 42.57, -0.55, 10);
    provider.refreshAt(new Time.Moment(start + 660));
    Test.assert(provider.cityReads == 3 && provider.solarCalls == 2);
    return true;
}

(:test)
function cachedSolarRefreshesAtMidnight(logger) {
    var provider = new EfficiencyProvider();
    // Locate a local midnight without assuming the simulator's time zone.
    var midnight = 1750000020;
    for (var i = 0; i < 1440; i += 1) {
        var info = Gregorian.info(new Time.Moment(midnight), Time.FORMAT_SHORT);
        if (info.hour == 0 && info.min == 0) { break; }
        midnight += 60;
    }
    provider.weather = new TestCityWeather(midnight - 60, 40.42, -3.70, 20);
    provider.refreshAt(new Time.Moment(midnight - 60));
    var date = provider.data.dayText;
    provider.refreshAt(new Time.Moment(midnight));
    Test.assert(provider.solarCalls == 2 && provider.weatherReads == 1);
    Test.assert(!provider.data.dayText.equals(date));
    return true;
}

(:test)
function cachedHistoryStillExpiresEachMinute(logger) {
    var provider = new EfficiencyProvider();
    var start = 1750000020;
    provider.refreshAt(new Time.Moment(start));
    provider.data.heartRate = 65;
    provider.data.heartRateWhen = start - 900;
    provider.data.elevation = -10;
    provider.data.elevationWhen = start - 1800;
    provider.refreshAt(new Time.Moment(start + 60));
    Test.assert(provider.lastHistoryUpdate == start);
    Test.assert(provider.data.heartRate == null && provider.data.elevation == null);
    return true;
}

(:test)
class EfficiencyDc {
    var measurements = 0;
    function getTextWidthInPixels(text, font) {
        measurements += 1;
        return text.length() * font;
    }
}

(:test)
function presentationReusesMeasurementsAndUpdatesFallbacks(logger) {
    var dc = new EfficiencyDc();
    var cache = new WatchPresentation(7, 5, 10);
    var data = new WatchData();
    data.city = "A very long city name";
    data.steps = 123456789;
    data.stepGoal = 150000000;
    data.elevation = -1234;
    data.heartRate = 65;
    data.heartRateWhen = 1000;
    data.updatedAt = 1000;
    data.solarInterval = [1000, 2000, true];
    cache.prepare(dc, data, 1);
    var measurements = dc.measurements;
    Test.assert(cache.stepsFont == 5 && cache.elevationFont == 7);
    for (var i = 0; i < 60; i += 1) { cache.prepare(dc, data, 1); }
    data.updatedAt = 1060;
    cache.prepare(dc, data, 2);
    Test.assert(dc.measurements == measurements && cache.heartAgeText.equals("1 MIN"));
    // Force solar text regeneration on a time-zone change even with unchanged events.
    cache.solarStartText = "invalidated by test";
    data.utcOffset = 3600;
    cache.prepare(dc, data, 3);
    Test.assert(!cache.solarStartText.equals("invalidated by test"));
    data.city = null;
    data.steps = null;
    data.stepGoal = null;
    data.elevation = null;
    data.heartRate = null;
    data.heartRateWhen = null;
    data.solarInterval = null;
    cache.prepare(dc, data, 4);
    Test.assert(cache.cityText.equals("--") && cache.stepsProgress == 0);
    Test.assert(cache.elevationText.equals("-- m") && cache.heartText.equals("--"));
    Test.assert(cache.heartAgeText.equals("--") && cache.solarStartText.equals("--:--"));
    // Layout invalidation must remeasure even when the values are unchanged.
    measurements = dc.measurements;
    cache.revision = -1;
    cache.prepare(dc, data, 4);
    Test.assert(dc.measurements > measurements);
    return true;
}

(:test)
function repeatedViewUpdatesUsePreparedSnapshot(logger) {
    var view = new MountainWatchView();
    var provider = new EfficiencyProvider();
    view.provider = provider;
    // Exercise the actual Garmin drawing API. This bitmap exists only in tests.
    var bitmap = Toybox.Graphics.createBufferedBitmap({
        :width => 260, :height => 260,
        :palette => [Toybox.Graphics.COLOR_BLACK, Theme.TEXT, Theme.MUTED,
            Theme.DIVIDER, Theme.AMBER, Theme.RED, Theme.GREEN, Theme.BROWN]
    });
    var dc = bitmap.get().getDc();
    view.onLayout(dc);
    view.onUpdate(dc);
    Test.assert(view.timeFont != null && view.presentation.revision == 1);
    view.onUpdate(dc);
    Test.assert(view.presentation.revision == 1 && provider.activityReads == 1);
    // Minute updates and layout restoration must still work with absent data.
    provider.clock += 60;
    view.onUpdate(dc);
    Test.assert(view.presentation.revision == 2 && provider.activityReads == 2);
    view.onLayout(dc);
    Test.assert(view.presentation.revision == -1);
    view.onUpdate(dc);
    Test.assert(view.presentation.revision == 2 && provider.activityReads == 2);
    return true;
}
