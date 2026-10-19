using Toybox.Application;
using Toybox.System;
using Toybox.Test;

(:test)
class TestWatchSettingsDelegate extends WatchSettingsDelegate {
    var openedMenu;
    var openedDelegate;
    function initialize(callback) { WatchSettingsDelegate.initialize(callback); }
    function openMenu(menu, delegate) {
        openedMenu = menu;
        openedDelegate = delegate;
    }
}

(:test)
function onWatchSettingsRoutesEachPreferenceAndCancelsWithoutChanges(logger) {
    var keys = ["BatteryDisplay", "TemperatureUnits", "ElevationUnits"];
    var originals = [];
    for (var i = 0; i < keys.size(); i += 1) {
        originals.add(Application.Properties.getValue(keys[i]));
    }
    try {
        var app = Application.getApp() as MountainWatchApp;
        var settings = app.getSettingsView() as Toybox.Lang.Array;
        Test.assert(settings[0] instanceof WatchSettingsMenu);
        Test.assert(settings[1] instanceof WatchSettingsDelegate);
        var menu = settings[0] as WatchSettingsMenu;
        var observer = new DeviceSettingsObserver();
        var delegate = new TestWatchSettingsDelegate(observer.method(:changed));
        for (var i = 0; i < keys.size(); i += 1) {
            var key = keys[i];
            Application.Properties.setValue(key, 1);
            var item = menu.getItem(i);
            Test.assert(item.getId().equals(key));
            delegate.onSelect(item);
            Test.assert(delegate.openedMenu instanceof WatchPreferenceMenu);
            Test.assert(delegate.openedDelegate.propertyKey.equals(key));
            var options = delegate.openedMenu as WatchPreferenceMenu;
            var last = key.equals("BatteryDisplay") ? 1 : 2;
            Test.assert(options.getItem(0).getId() == 0 && options.getItem(last).getId() == last);
            Test.assert(WatchSettings.selection(key) == 1);
            var cancel = new TestWatchPreferenceDelegate(key, observer.method(:changed));
            cancel.onBack();
            Test.assert(Application.Properties.getValue(key) == 1 && cancel.closes == 1);
            // Invalid saved values use the default in the local menu too.
            Application.Properties.setValue(key, 99);
            Test.assert(WatchSettings.selection(key) == 0);
        }
        Test.assert(observer.calls == 0);
    } finally {
        for (var i = 0; i < keys.size(); i += 1) {
            Application.Properties.setValue(keys[i], originals[i]);
        }
        Application.getApp().onSettingsChanged();
    }
    return true;
}

(:test)
function onWatchUnitMenusSaveIndependentOverridesAndRestoreWatchUnits(logger) {
    var keys = ["BatteryDisplay", "TemperatureUnits", "ElevationUnits"];
    var originals = [];
    for (var i = 0; i < keys.size(); i += 1) {
        originals.add(Application.Properties.getValue(keys[i]));
    }
    try {
        Application.Properties.setValue("BatteryDisplay", 1);
        Application.Properties.setValue("TemperatureUnits", 0);
        Application.Properties.setValue("ElevationUnits", 0);
        var observer = new DeviceSettingsObserver();
        var provider = observer.provider;
        provider.data.temperature = 15;
        provider.data.elevation = 1371;
        var cache = new WatchPresentation(7, 5, 10);
        var dc = new EfficiencyDc();
        var root = new WatchSettingsMenu();
        var temperature = new WatchPreferenceMenu("TemperatureUnits");
        var elevation = new WatchPreferenceMenu("ElevationUnits");
        var tempDelegate = new TestWatchPreferenceDelegate("TemperatureUnits", observer.method(:changed));
        var elevDelegate = new TestWatchPreferenceDelegate("ElevationUnits", observer.method(:changed));
        cache.prepare(dc, provider.data, provider.revision);
        Test.assert(cache.temperatureText.equals("15°C") && cache.elevationText.equals("1371 m"));
        tempDelegate.onSelect(temperature.getItem(2));
        elevDelegate.onSelect(elevation.getItem(2));
        provider.refresh();
        cache.prepare(dc, provider.data, provider.revision);
        Test.assert(cache.temperatureText.equals("59°F") && cache.elevationText.equals("4498 ft"));
        Test.assert(Application.Properties.getValue("TemperatureUnits") == 2);
        Test.assert(Application.Properties.getValue("ElevationUnits") == 2);
        var restarted = new DeviceSettingsProvider();
        restarted.refresh();
        Test.assert(restarted.data.units.temperature == System.UNIT_STATUTE);
        Test.assert(restarted.data.units.elevation == System.UNIT_STATUTE);
        tempDelegate.onSelect(temperature.getItem(1));
        provider.refresh();
        cache.prepare(dc, provider.data, provider.revision);
        Test.assert(cache.temperatureText.equals("15°C") && cache.elevationText.equals("4498 ft"));
        elevDelegate.onSelect(elevation.getItem(1));
        provider.refresh();
        cache.prepare(dc, provider.data, provider.revision);
        Test.assert(cache.elevationText.equals("1371 m"));
        provider.deviceSettings.temperatureUnits = System.UNIT_STATUTE;
        tempDelegate.onSelect(temperature.getItem(0));
        provider.refresh();
        cache.prepare(dc, provider.data, provider.revision);
        Test.assert(cache.temperatureText.equals("59°F") && cache.elevationText.equals("1371 m"));
        provider.deviceSettings.elevationUnits = System.UNIT_STATUTE;
        elevDelegate.onSelect(elevation.getItem(0));
        provider.refresh();
        cache.prepare(dc, provider.data, provider.revision);
        Test.assert(cache.elevationText.equals("4498 ft"));
        Test.assert(provider.data.units.temperatureMode == 0 && provider.data.units.elevationMode == 0);
        Test.assert(Application.Properties.getValue("TemperatureUnits") == 0);
        Test.assert(Application.Properties.getValue("ElevationUnits") == 0);
        Test.assert(Application.Properties.getValue("BatteryDisplay") == 1 && cache.batteryText.equals("50%"));
        root.refreshLabels();
        Test.assert(root.getItem(1).getSubLabel().equals(Application.loadResource(Rez.Strings.UseWatchUnits)));
        Test.assert(root.getItem(2).getSubLabel().equals(Application.loadResource(Rez.Strings.UseWatchUnits)));
        Test.assert(observer.calls == 6 && tempDelegate.closes == 3 && elevDelegate.closes == 3);
        Test.assert(provider.activityReads == 1 && provider.batteryReads == 1 && provider.weatherReads == 1);
    } finally {
        for (var i = 0; i < keys.size(); i += 1) {
            Application.Properties.setValue(keys[i], originals[i]);
        }
        Application.getApp().onSettingsChanged();
    }
    return true;
}
