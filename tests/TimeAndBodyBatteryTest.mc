using Toybox.Application;
using Toybox.Test;
using Toybox.Time;
using Toybox.Time.Gregorian;

(:test)
class HealthSample {
    var data;
    var when;
    function initialize(value, seconds) { data = value; when = new Time.Moment(seconds); }
}

(:test)
class HealthHistory {
    var samples as Toybox.Lang.Array;
    var index = 0;
    function initialize(values) { samples = values; }
    function next() {
        if (index >= samples.size()) { return null; }
        var result = samples[index];
        index += 1;
        return result;
    }
}

(:test)
class HealthProvider extends EfficiencyProvider {
    var twelveHour = 0;
    var bodyBattery = 0;
    var preferenceReads = 0;
    var missingPreferences = false;
    var bodyReads = 0;
    var heartReads = 0;
    var samples = [];
    var unsupported = false;
    var denied = false;
    function initialize() { EfficiencyProvider.initialize(); }
    function readDisplayPreference(key) {
        preferenceReads += 1;
        if (missingPreferences) { throw new Toybox.Lang.InvalidValueException("Missing preference"); }
        return key.equals("TimeFormat") ? twelveHour : bodyBattery;
    }
    function readBodyBatteryHistory() {
        bodyReads += 1;
        if (denied) { throw new Toybox.Lang.InvalidValueException("Unavailable history"); }
        return unsupported ? null : new HealthHistory(samples);
    }
    function readHeartHistory() {
        heartReads += 1;
        return new HealthHistory([new HealthSample(65, clock)]);
    }
}

(:test)
function twelveHourFormattingHandlesMidnightNoonAndDayBoundaries(logger) {
    var hours = [0, 1, 11, 12, 13, 23];
    var expected = ["12:07", "01:07", "11:07", "12:07", "01:07", "11:07"];
    for (var i = 0; i < hours.size(); i += 1) {
        Test.assert(Formatters.clockTime(hours[i], 7, true).equals(expected[i]));
        Test.assert(Formatters.timePeriod(hours[i], true).equals(hours[i] < 12 ? "AM" : "PM"));
        Test.assert(Formatters.clockTime(hours[i], 7, false).equals(hours[i].format("%02d") + ":07"));
        Test.assert(Formatters.timePeriod(hours[i], false).equals(""));
    }
    Test.assert(Formatters.clockTime(23, 59, true).equals("11:59"));
    Test.assert(Formatters.solarTime(null, true).equals("--:--"));
    return true;
}

(:test)
function timePreferenceRefreshesClockAndSolarCacheInSameMinute(logger) {
    var provider = new HealthProvider();
    provider.refresh();
    provider.data.solarInterval = [provider.clock, provider.clock + 3600, true];
    var cache = new WatchPresentation(7, 5, 10);
    var dc = new EfficiencyDc();
    cache.prepare(dc, provider.data, provider.revision);
    var revision = provider.revision;
    var info = Gregorian.info(new Time.Moment(provider.clock), Time.FORMAT_SHORT);
    provider.twelveHour = 1;
    provider.invalidateSettings();
    provider.refresh();
    // Ensure changing format regenerates solar labels with unchanged events.
    cache.solarStartText = "stale";
    cache.prepare(dc, provider.data, provider.revision);
    Test.assert(provider.revision == revision + 1 && provider.data.twelveHourTime);
    Test.assert(provider.data.timeText.equals(Formatters.clockTime(info.hour, info.min, true)));
    Test.assert(provider.data.timePeriod.equals(info.hour < 12 ? "AM" : "PM"));
    Test.assert(cache.solarStartText.equals(Formatters.solarTime(new Time.Moment(provider.clock), true)));
    Test.assert(provider.heartReads == 1 && provider.bodyReads == 0);
    Test.assert(provider.activityReads == 1 && provider.batteryReads == 1 && provider.weatherReads == 1);
    provider.twelveHour = 0;
    provider.invalidateSettings();
    provider.refresh();
    Test.assert(provider.data.timePeriod.equals(""));
    Test.assert(provider.data.timeText.equals(Formatters.clockTime(info.hour, info.min, false)));
    revision = provider.revision;
    provider.invalidateSettings();
    provider.refresh();
    Test.assert(provider.revision == revision);
    return true;
}

(:test)
function healthSelectionReadsOnlySelectedHistoryAndPreservesRefreshCadence(logger) {
    var provider = new HealthProvider();
    provider.samples = [new HealthSample(73, provider.clock)];
    provider.refresh();
    Test.assert(provider.data.heartRate == 65 && provider.bodyReads == 0);
    provider.bodyBattery = 1;
    provider.invalidateSettings();
    provider.refresh();
    Test.assert(provider.data.bodyBattery == 73 && provider.bodyReads == 1 && provider.heartReads == 1);
    var elevationRead = provider.lastHistoryUpdate;
    for (var i = 0; i < 4; i += 1) {
        provider.clock += 60;
        provider.refresh();
    }
    Test.assert(provider.bodyReads == 1 && provider.heartReads == 1);
    Test.assert(provider.preferenceReads == 4);
    provider.clock += 60;
    provider.refresh();
    Test.assert(provider.bodyReads == 2 && provider.heartReads == 1);
    provider.bodyBattery = 0;
    provider.invalidateSettings();
    provider.refresh();
    Test.assert(provider.data.heartRate == 65 && provider.heartReads == 2 && provider.bodyReads == 2);
    Test.assert(provider.activityReads == 6 && provider.batteryReads == 2 && provider.weatherReads == 2);
    Test.assert(provider.lastHistoryUpdate == elevationRead + 300);
    return true;
}

(:test)
function bodyBatteryAcceptsZeroAndHundredSkipsInvalidSamplesAndBoundsWork(logger) {
    var provider = new HealthProvider();
    var now = provider.clock;
    var history = new HealthHistory([
        new HealthSample(90, now + 60), new HealthSample(null, now),
        new HealthSample(-1, now), new HealthSample(101, now), new HealthSample(0, now)
    ]);
    Test.assert(provider.newestValidBodyBattery(history, now).data == 0);
    history = new HealthHistory([new HealthSample(100, now - 900)]);
    Test.assert(provider.newestValidBodyBattery(history, now).data == 100);
    history = new HealthHistory([new HealthSample(50, now - 901)]);
    Test.assert(provider.newestValidBodyBattery(history, now) == null);
    var samples = [];
    for (var i = 0; i < 31; i += 1) { samples.add(new HealthSample(-1, now)); }
    samples.add(new HealthSample(80, now));
    history = new HealthHistory(samples);
    Test.assert(provider.newestValidBodyBattery(history, now) == null && history.index == 30);
    return true;
}

(:test)
function bodyBatteryExpiresAndHandlesUnavailableHistoryWithoutStaleValues(logger) {
    var provider = new HealthProvider();
    provider.bodyBattery = 1;
    provider.samples = [new HealthSample(45, provider.clock - 900)];
    provider.refresh();
    Test.assert(provider.data.bodyBattery == 45);
    provider.clock += 60;
    provider.refresh();
    Test.assert(provider.data.bodyBattery == null && provider.data.bodyBatteryWhen == null);
    Test.assert(provider.bodyReads == 1);
    provider.clock += 240;
    provider.samples = [new HealthSample(0, provider.clock)];
    provider.refresh();
    Test.assert(provider.data.bodyBattery == 0);
    provider.clock += 300;
    provider.unsupported = true;
    provider.refresh();
    Test.assert(provider.data.bodyBattery == null);
    provider.unsupported = false;
    provider.clock += 300;
    provider.denied = true;
    provider.refresh();
    Test.assert(provider.data.bodyBattery == null);
    provider.denied = false;
    provider.clock -= 60;
    provider.samples = [new HealthSample(100, provider.clock)];
    provider.refresh();
    Test.assert(provider.data.bodyBattery == 100);
    provider.clock += 3600;
    provider.samples = [];
    provider.refresh();
    Test.assert(provider.data.bodyBattery == null);
    return true;
}

(:test)
function invalidOrMissingDisplayPreferencesKeepExistingDefaults(logger) {
    var provider = new HealthProvider();
    var invalid = [null, 99, -1, "1", 2];
    for (var i = 0; i < invalid.size(); i += 1) {
        provider.twelveHour = 1;
        provider.bodyBattery = 1;
        provider.invalidateSettings();
        provider.refresh();
        Test.assert(provider.data.twelveHourTime && provider.data.bodyBatterySelected);
        provider.twelveHour = invalid[i];
        provider.bodyBattery = invalid[i];
        provider.invalidateSettings();
        provider.refresh();
        Test.assert(!provider.data.twelveHourTime && !provider.data.bodyBatterySelected);
    }
    provider.missingPreferences = true;
    provider.invalidateSettings();
    provider.refresh();
    Test.assert(!provider.data.twelveHourTime && !provider.data.bodyBatterySelected);
    return true;
}

(:test)
function newOnWatchPreferencesPersistAndUpdateImmediately(logger) {
    var keys = ["TimeFormat", "HealthDisplay"];
    var originals = [Application.Properties.getValue(keys[0]), Application.Properties.getValue(keys[1])];
    try {
        Application.Properties.setValue(keys[0], 0);
        Application.Properties.setValue(keys[1], 0);
        var observer = new DeviceSettingsObserver();
        var root = new WatchSettingsMenu();
        for (var i = 0; i < keys.size(); i += 1) {
            var menu = new WatchPreferenceMenu(keys[i]);
            var delegate = new TestWatchPreferenceDelegate(keys[i], observer.method(:changed));
            delegate.onSelect(menu.getItem(1));
            observer.provider.refresh();
            Test.assert(Application.Properties.getValue(keys[i]) == 1);
            Test.assert(i == 0 ? observer.provider.data.twelveHourTime : observer.provider.data.bodyBatterySelected);
            var restarted = new DeviceSettingsProvider();
            restarted.refresh();
            Test.assert(i == 0 ? restarted.data.twelveHourTime : restarted.data.bodyBatterySelected);
            root.refreshLabels();
            Test.assert(root.getItem(i + 3).getSubLabel().equals(Application.loadResource(WatchSettings.options(keys[i])[1])));
            delegate.onBack();
            Test.assert(Application.Properties.getValue(keys[i]) == 1 && delegate.closes == 2);
            delegate.onSelect(menu.getItem(0));
            observer.provider.refresh();
            Test.assert(i == 0 ? !observer.provider.data.twelveHourTime : !observer.provider.data.bodyBatterySelected);
        }
        Test.assert(observer.calls == 4);
        Test.assert(observer.provider.activityReads == 1 && observer.provider.batteryReads == 1 && observer.provider.weatherReads == 1);
    } finally {
        for (var i = 0; i < keys.size(); i += 1) { Application.Properties.setValue(keys[i], originals[i]); }
        Application.getApp().onSettingsChanged();
    }
    return true;
}

(:test)
function bodyBatteryPresentationUsesPercentageAndRestoresHeartRate(logger) {
    var data = new WatchData();
    var cache = new WatchPresentation(7, 5, 10);
    var dc = new EfficiencyDc();
    data.bodyBatterySelected = true;
    data.bodyBattery = 100;
    data.bodyBatteryWhen = 1000;
    data.updatedAt = 1060;
    cache.prepare(dc, data, 1);
    Test.assert(cache.heartText.equals("100%") && cache.heartAgeText.equals("1 MIN"));
    data.bodyBattery = 0;
    cache.prepare(dc, data, 2);
    Test.assert(cache.heartText.equals("0%"));
    data.bodyBattery = null;
    data.bodyBatteryWhen = null;
    cache.prepare(dc, data, 3);
    Test.assert(cache.heartText.equals("--%") && cache.heartAgeText.equals("--"));
    data.bodyBatterySelected = false;
    data.heartRate = 65;
    data.heartRateWhen = 1000;
    cache.prepare(dc, data, 4);
    Test.assert(cache.heartText.equals("65") && cache.heartAgeText.equals("1 MIN"));
    return true;
}

(:test)
function newDisplayModesRenderAcrossSizesAndNativeFontFallbacks(logger) {
    var view = new MountainWatchView();
    var provider = new HealthProvider();
    provider.twelveHour = 1;
    provider.bodyBattery = 1;
    provider.samples = [new HealthSample(100, provider.clock)];
    view.provider = provider;
    var sizes = [240, 260, 280, 416, 454];
    for (var fallback = 0; fallback < 2; fallback += 1) {
        if (fallback == 1) {
            view.fonts = new MissingWatchFonts();
            view.layout = null;
            sizes = [Toybox.System.getDeviceSettings().screenWidth];
        }
        for (var i = 0; i < sizes.size(); i += 1) {
            var bitmap = Toybox.Graphics.createBufferedBitmap({:width => sizes[i], :height => sizes[i]});
            var dc = bitmap.get().getDc();
            view.onLayout(dc);
            view.onUpdate(dc);
            Test.assert(view.presentation.heartText.equals("100%"));
            Test.assert(dc.getTextWidthInPixels(view.presentation.heartText, view.valueFont) <= view.layout.elevationWidth);
            Test.assert(dc.getTextWidthInPixels(provider.data.timeText, view.timeFont) <= view.layout.timeWidth);
            Test.assert(dc.getTextWidthInPixels(provider.data.timePeriod, view.smallFont) <= view.layout.timeWidth);
            provider.bodyBattery = 0;
            provider.twelveHour = 0;
            provider.invalidateSettings();
            view.onUpdate(dc);
            Test.assert(view.presentation.heartText.equals("65") && provider.data.timePeriod.equals(""));
            provider.bodyBattery = 1;
            provider.twelveHour = 1;
            provider.invalidateSettings();
        }
    }
    return true;
}
