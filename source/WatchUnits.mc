using Toybox.Application;
using Toybox.System;

// Store sensor/weather values in metric units; resolve display units separately.
class WatchUnits {
    const AUTO = 0;
    const METRIC = 1;
    const STATUTE = 2;
    var elevationMode = AUTO;
    var temperatureMode = AUTO;
    var elevation = System.UNIT_METRIC;
    var temperature = System.UNIT_METRIC;
    var revision = 0;
    var settingsDirty = true;

    function initialize() {}

    function invalidateSettings() { settingsDirty = true; }

    function readPreference(key) { return Application.Properties.getValue(key); }

    function preference(key) {
        try {
            var value = readPreference(key);
            if (value == METRIC || value == STATUTE) { return value; }
        } catch (e) {
            // Missing/invalid settings on an upgrade use the watch preference.
        }
        return AUTO;
    }

    function resolve(mode, deviceUnit) {
        if (mode == METRIC) { return System.UNIT_METRIC; }
        if (mode == STATUTE) { return System.UNIT_STATUTE; }
        return deviceUnit == System.UNIT_STATUTE ? System.UNIT_STATUTE : System.UNIT_METRIC;
    }

    function refresh(settings) {
        if (settingsDirty) {
            elevationMode = preference("ElevationUnits");
            temperatureMode = preference("TemperatureUnits");
            settingsDirty = false;
        }
        var nextElevation = resolve(elevationMode, settings.elevationUnits);
        var nextTemperature = resolve(temperatureMode, settings.temperatureUnits);
        if (elevation == nextElevation && temperature == nextTemperature) { return false; }
        elevation = nextElevation;
        temperature = nextTemperature;
        revision += 1;
        return true;
    }
}
