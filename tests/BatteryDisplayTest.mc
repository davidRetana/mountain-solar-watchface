using Toybox.Test;
using Toybox.Time;
using Toybox.Application;

(:test)
function batteryDisplayFormatsSelectedModeAndMissingReadings(logger) {
    var data = new WatchData();
    data.batteryDays = 12.8;
    data.battery = 50.9;
    Test.assert(Formatters.batteryText(data).equals("12 d"));
    data.batteryDays = 0.5;
    Test.assert(Formatters.batteryText(data).equals("<1 d"));
    data.batteryAsPercentage = true;
    Test.assert(Formatters.batteryText(data).equals("50%"));
    data.battery = 100;
    Test.assert(Formatters.batteryText(data).equals("100%"));
    data.battery = 0;
    Test.assert(Formatters.batteryText(data).equals("0%"));
    data.battery = null;
    Test.assert(Formatters.batteryText(data).equals("--"));
    data.batteryAsPercentage = false;
    Test.assert(Formatters.batteryText(data).equals("<1 d"));
    data.batteryDays = null;
    data.battery = 50;
    Test.assert(Formatters.batteryText(data).equals("50%"));
    data.battery = null;
    Test.assert(Formatters.batteryText(data).equals("--"));
    return true;
}

(:test)
function batteryDisplayPreferenceLoadsAtStartupAndIsCached(logger) {
    var provider = new EfficiencyProvider();
    provider.batteryPreference = 1;
    provider.refresh();
    Test.assert(provider.data.batteryAsPercentage && provider.batteryPreferenceReads == 1);
    for (var i = 0; i < 10; i += 1) {
        provider.clock += 60;
        provider.refresh();
    }
    Test.assert(provider.batteryPreferenceReads == 1);
    provider.batteryPreference = 0;
    provider.invalidateSettings();
    provider.refresh();
    Test.assert(!provider.data.batteryAsPercentage && provider.batteryPreferenceReads == 2);
    return true;
}

(:test)
function batteryDisplayChangesRefreshPresentationWithinSameMinute(logger) {
    var provider = new EfficiencyProvider();
    provider.refresh();
    var cache = new WatchPresentation(7, 5, 10);
    var dc = new EfficiencyDc();
    cache.prepare(dc, provider.data, provider.revision);
    Test.assert(cache.batteryText.equals("12 d"));
    var revision = provider.revision;
    provider.batteryPreference = 1;
    provider.invalidateSettings();
    provider.refresh();
    cache.prepare(dc, provider.data, provider.revision);
    Test.assert(cache.batteryText.equals("50%") && provider.revision == revision + 1);
    provider.batteryPreference = 0;
    provider.invalidateSettings();
    provider.refresh();
    cache.prepare(dc, provider.data, provider.revision);
    Test.assert(cache.batteryText.equals("12 d") && provider.revision == revision + 2);
    // Re-saving an unchanged setting must not create a new snapshot.
    provider.invalidateSettings();
    provider.refresh();
    Test.assert(provider.revision == revision + 2);
    Test.assert(provider.activityReads == 1 && provider.batteryReads == 1 && provider.weatherReads == 1);
    return true;
}

(:test)
function batteryDisplayInvalidOrMissingPreferencesKeepDaysDefault(logger) {
    var provider = new EfficiencyProvider();
    var invalid = [null, 99, -1, "1"];
    for (var i = 0; i < invalid.size(); i += 1) {
        provider.batteryPreference = 1;
        provider.invalidateSettings();
        provider.refresh();
        Test.assert(provider.data.batteryAsPercentage);
        provider.batteryPreference = invalid[i];
        provider.invalidateSettings();
        provider.refresh();
        Test.assert(!provider.data.batteryAsPercentage);
    }
    provider.batteryPreference = 1;
    provider.invalidateSettings();
    provider.refresh();
    provider.missingBatteryPreference = true;
    provider.invalidateSettings();
    provider.refresh();
    Test.assert(!provider.data.batteryAsPercentage);
    Test.assert(provider.batteryReads == 1);
    return true;
}

(:test)
class DeviceSettingsProvider extends EfficiencyProvider {
    function initialize() {
        EfficiencyProvider.initialize();
        data.units = new WatchUnits();
    }
    function readBatteryPreference() { return Application.Properties.getValue("BatteryDisplay"); }
}

(:test)
class DeviceSettingsObserver {
    var provider;
    var calls = 0;
    function initialize() {
        provider = new DeviceSettingsProvider();
        provider.refresh();
    }
    function changed() {
        calls += 1;
        provider.invalidateSettings();
    }
}

(:test)
class TestWatchPreferenceDelegate extends WatchPreferenceDelegate {
    var closes = 0;
    function initialize(key, callback) { WatchPreferenceDelegate.initialize(key, callback); }
    // The test runner does not open the system settings view stack.
    function closeMenu() { closes += 1; }
}

(:test)
function onWatchBatteryMenuSavesPreferenceAndRefreshesCachedData(logger) {
    var original = Application.Properties.getValue("BatteryDisplay");
    try {
        Application.Properties.setValue("BatteryDisplay", 0);
        var menu = new WatchPreferenceMenu("BatteryDisplay");
        var observer = new DeviceSettingsObserver();
        var delegate = new TestWatchPreferenceDelegate("BatteryDisplay", observer.method(:changed));
        var provider = observer.provider;
        var cache = new WatchPresentation(7, 5, 10);
        var dc = new EfficiencyDc();
        for (var i = 1; i >= 0; i -= 1) {
            delegate.onSelect(menu.getItem(i));
            Test.assert(Application.Properties.getValue("BatteryDisplay") == i);
            provider.refresh();
            cache.prepare(dc, provider.data, provider.revision);
            Test.assert(provider.data.batteryAsPercentage == (i == 1));
            Test.assert(cache.batteryText.equals(i == 1 ? "50%" : "12 " + provider.data.locale.dayUnit));
            // A new provider must read the persisted on-watch choice too.
            var restarted = new DeviceSettingsProvider();
            restarted.refresh();
            Test.assert(restarted.data.batteryAsPercentage == (i == 1));
        }
        Test.assert(observer.calls == 2 && delegate.closes == 2);
        Test.assert(provider.activityReads == 1 && provider.batteryReads == 1 && provider.weatherReads == 1);
    } finally {
        Application.Properties.setValue("BatteryDisplay", original);
        Application.getApp().onSettingsChanged();
    }
    return true;
}

(:test)
function onWatchBatteryMenuBackKeepsPreference(logger) {
    var original = Application.Properties.getValue("BatteryDisplay");
    try {
        Application.Properties.setValue("BatteryDisplay", 1);
        var observer = new DeviceSettingsObserver();
        var delegate = new TestWatchPreferenceDelegate("BatteryDisplay", observer.method(:changed));
        delegate.onBack();
        Test.assert(Application.Properties.getValue("BatteryDisplay") == 1);
        Test.assert(observer.calls == 0 && delegate.closes == 1);
    } finally {
        Application.Properties.setValue("BatteryDisplay", original);
        Application.getApp().onSettingsChanged();
    }
    return true;
}
