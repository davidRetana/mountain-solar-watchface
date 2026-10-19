using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;

// Both the native watch menu and Connect IQ use the same property values.
module WatchSettings {
    function title(key) {
        if (key.equals("BatteryDisplay")) { return Rez.Strings.BatteryDisplayTitle; }
        if (key.equals("TemperatureUnits")) { return Rez.Strings.TemperatureUnitsTitle; }
        return Rez.Strings.ElevationUnitsTitle;
    }

    function options(key) as Lang.Array<Lang.ResourceId> {
        if (key.equals("BatteryDisplay")) { return [Rez.Strings.BatteryDays, Rez.Strings.BatteryPercentage]; }
        if (key.equals("TemperatureUnits")) { return [Rez.Strings.UseWatchUnits, Rez.Strings.Celsius, Rez.Strings.Fahrenheit]; }
        return [Rez.Strings.UseWatchUnits, Rez.Strings.Meters, Rez.Strings.Feet];
    }

    function selection(key) as Lang.Number {
        try {
            var value = Application.Properties.getValue(key);
            if (value == 1) { return 1; }
            if (value == 2 && !key.equals("BatteryDisplay")) { return 2; }
        } catch (e) {
            // Missing preferences keep days remaining or the watch's units.
        }
        return 0;
    }
}

// Garmin opens this menu from the watch face's on-device settings.
class WatchSettingsMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({:title => Rez.Strings.AppName});
        var keys = ["BatteryDisplay", "TemperatureUnits", "ElevationUnits"];
        for (var i = 0; i < keys.size(); i += 1) {
            addItem(new WatchUi.MenuItem(WatchSettings.title(keys[i]), null, keys[i], null));
        }
        refreshLabels();
    }

    function onShow() {
        Menu2.onShow();
        refreshLabels();
    }

    function refreshLabels() {
        for (var i = 0; i < 3; i += 1) {
            var item = getItem(i);
            var key = item.getId();
            var labels = WatchSettings.options(key);
            item.setSubLabel(labels[WatchSettings.selection(key)]);
        }
    }
}

class WatchSettingsDelegate extends WatchUi.Menu2InputDelegate {
    var onChanged;

    function initialize(callback) {
        Menu2InputDelegate.initialize();
        onChanged = callback;
    }

    function onSelect(item) {
        var key = item.getId();
        openMenu(new WatchPreferenceMenu(key), new WatchPreferenceDelegate(key, onChanged));
    }

    function openMenu(menu, delegate) { WatchUi.pushView(menu, delegate, WatchUi.SLIDE_LEFT); }
}

class WatchPreferenceMenu extends WatchUi.Menu2 {
    function initialize(key) {
        Menu2.initialize({:title => WatchSettings.title(key), :focus => WatchSettings.selection(key)});
        var labels = WatchSettings.options(key);
        for (var i = 0; i < labels.size(); i += 1) {
            addItem(new WatchUi.MenuItem(labels[i], null, i, null));
        }
    }
}

class WatchPreferenceDelegate extends WatchUi.Menu2InputDelegate {
    var propertyKey;
    var onChanged;

    function initialize(key, callback) {
        Menu2InputDelegate.initialize();
        propertyKey = key;
        onChanged = callback;
    }

    function onSelect(item) {
        Application.Properties.setValue(propertyKey, item.getId());
        // Local property writes do not trigger the mobile settings callback.
        onChanged.invoke();
        closeMenu();
    }

    function onBack() { closeMenu(); }

    function closeMenu() { WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); }
}
