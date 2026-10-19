using Toybox.Graphics;
using Toybox.System;
using Toybox.Test;

(:test)
class TestUnitDeviceSettings {
    var systemLanguage = System.getDeviceSettings().systemLanguage;
    var elevationUnits = System.UNIT_METRIC;
    var temperatureUnits = System.UNIT_METRIC;
}

(:test)
class TestWatchUnits extends WatchUnits {
    var altitudePreference = AUTO;
    var temperaturePreference = AUTO;
    var reads = 0;
    var missing = false;
    function initialize() { WatchUnits.initialize(); }
    function readPreference(key) {
        reads += 1;
        if (missing) { throw new Toybox.Lang.InvalidValueException("Missing test preference"); }
        return key.equals("ElevationUnits") ? altitudePreference : temperaturePreference;
    }
}

(:test)
function unitConversionsRoundAfterConversionAndHandleMissingData(logger) {
    var metric = System.UNIT_METRIC;
    var statute = System.UNIT_STATUTE;
    Test.assert(Formatters.temperature(15, metric).equals("15°C"));
    Test.assert(Formatters.temperature(15, statute).equals("59°F"));
    Test.assert(Formatters.temperature(0, statute).equals("32°F"));
    Test.assert(Formatters.temperature(-40, statute).equals("-40°F"));
    Test.assert(Formatters.temperature(-10.4, statute).equals("13°F"));
    Test.assert(Formatters.temperature(null, metric).equals("--°C"));
    Test.assert(Formatters.temperature(null, statute).equals("--°F"));
    Test.assert(Formatters.elevation(1371, metric).equals("1371 m"));
    Test.assert(Formatters.elevation(1371, statute).equals("4498 ft"));
    Test.assert(Formatters.elevation(-10, statute).equals("-33 ft"));
    Test.assert(Formatters.elevation(0, statute).equals("0 ft"));
    Test.assert(Formatters.elevation(1.6, metric).equals("2 m"));
    Test.assert(Formatters.elevation(1.6, statute).equals("5 ft"));
    Test.assert(Formatters.elevation(null, metric).equals("-- m"));
    Test.assert(Formatters.elevation(null, statute).equals("-- ft"));
    return true;
}

(:test)
function unitsFollowIndependentWatchPreferencesAndCacheProperties(logger) {
    var settings = new TestUnitDeviceSettings();
    var units = new TestWatchUnits();
    units.refresh(settings);
    Test.assert(units.reads == 2);
    settings.elevationUnits = System.UNIT_STATUTE;
    Test.assert(units.refresh(settings));
    Test.assert(units.elevation == System.UNIT_STATUTE && units.temperature == System.UNIT_METRIC);
    var revision = units.revision;
    Test.assert(!units.refresh(settings) && units.revision == revision && units.reads == 2);
    settings.temperatureUnits = System.UNIT_STATUTE;
    Test.assert(units.refresh(settings) && units.temperature == System.UNIT_STATUTE);
    settings.elevationUnits = System.UNIT_METRIC;
    Test.assert(units.refresh(settings) && units.elevation == System.UNIT_METRIC);
    return true;
}

(:test)
function explicitUnitsOverrideWatchAndInvalidPreferencesUseAuto(logger) {
    var settings = new TestUnitDeviceSettings();
    settings.elevationUnits = System.UNIT_STATUTE;
    var units = new TestWatchUnits();
    units.altitudePreference = units.METRIC;
    units.temperaturePreference = units.STATUTE;
    units.refresh(settings);
    Test.assert(units.elevation == System.UNIT_METRIC && units.temperature == System.UNIT_STATUTE);
    settings.elevationUnits = System.UNIT_METRIC;
    settings.temperatureUnits = System.UNIT_STATUTE;
    Test.assert(!units.refresh(settings));
    units.altitudePreference = 99;
    units.temperaturePreference = null;
    units.invalidateSettings();
    units.refresh(settings);
    Test.assert(units.elevationMode == units.AUTO && units.temperatureMode == units.AUTO);
    settings.elevationUnits = System.UNIT_STATUTE;
    settings.temperatureUnits = System.UNIT_METRIC;
    Test.assert(units.refresh(settings));
    units.missing = true;
    units.invalidateSettings();
    units.refresh(settings);
    Test.assert(units.elevation == System.UNIT_STATUTE && units.temperature == System.UNIT_METRIC);
    return true;
}

(:test)
function unitChangesRefreshCachedReadingsWithoutExtraDataReads(logger) {
    var provider = new EfficiencyProvider();
    provider.refresh();
    provider.data.elevation = 1371;
    provider.data.temperature = 15;
    var dc = new EfficiencyDc();
    var cache = new WatchPresentation(7, 5, 10);
    cache.prepare(dc, provider.data, provider.revision);
    for (var i = 0; i < 20; i += 1) { provider.refresh(); }
    Test.assert(provider.settingsReads == 1);
    provider.deviceSettings.elevationUnits = System.UNIT_STATUTE;
    provider.clock += 60;
    provider.refresh();
    cache.prepare(dc, provider.data, provider.revision);
    Test.assert(cache.elevationText.equals("4498 ft") && cache.temperatureText.equals("15°C"));
    Test.assert(provider.settingsReads == 2 && provider.weatherReads == 1 && provider.batteryReads == 1);
    var activity = provider.activityReads;
    var revision = provider.revision;
    provider.data.units.temperaturePreference = provider.data.units.STATUTE;
    provider.invalidateSettings();
    provider.refresh(); // Settings event within the same minute.
    cache.prepare(dc, provider.data, provider.revision);
    Test.assert(cache.temperatureText.equals("59°F") && provider.revision == revision + 1);
    Test.assert(provider.activityReads == activity && provider.weatherReads == 1 && provider.batteryReads == 1);
    Test.assert(provider.data.temperature == 15 && provider.data.elevation == 1371);
    return true;
}

(:test)
function presentationInvalidatesUnitsWithSameDataRevision(logger) {
    var dc = new EfficiencyDc();
    var cache = new WatchPresentation(8, 5, 10);
    var data = new WatchData();
    data.units = new TestWatchUnits();
    var settings = new TestUnitDeviceSettings();
    data.units.refresh(settings);
    data.elevation = 8848.86;
    data.temperature = -40;
    cache.prepare(dc, data, 1);
    settings.elevationUnits = System.UNIT_STATUTE;
    settings.temperatureUnits = System.UNIT_STATUTE;
    data.units.refresh(settings);
    cache.prepare(dc, data, 1);
    Test.assert(cache.elevationText.equals("29032 ft") && cache.elevationFont == 5);
    Test.assert(cache.temperatureText.equals("-40°F"));
    var measurements = dc.measurements;
    cache.prepare(dc, data, 1);
    Test.assert(dc.measurements == measurements);
    // Exercise fixed-size fonts that cannot fit the inline unit.
    cache.configure(new WatchLayout(240, 240), 8, 8, 10);
    cache.prepare(dc, data, 1);
    Test.assert(cache.elevationText.equals("29032") && cache.elevationUnitText.equals("ft"));
    settings.elevationUnits = System.UNIT_METRIC;
    data.units.refresh(settings);
    cache.prepare(dc, data, 1);
    Test.assert(cache.elevationText.equals("8849 m") && cache.elevationUnitText == null);
    return true;
}

(:test)
function unitTextFitsAcrossLayoutsAndFontFallbacks(logger) {
    var view = new MountainWatchView();
    var provider = new EfficiencyProvider();
    view.provider = provider;
    provider.deviceSettings.elevationUnits = System.UNIT_STATUTE;
    provider.deviceSettings.temperatureUnits = System.UNIT_STATUTE;
    var sizes = [240, 260, 280, 454];
    for (var fallback = 0; fallback < 2; fallback += 1) {
        if (fallback == 1) {
            view.fonts = new MissingWatchFonts();
            // Native bitmap fonts have the current device's fixed pixel size.
            sizes = [System.getDeviceSettings().screenWidth];
        }
        for (var i = 0; i < sizes.size(); i += 1) {
            var size = sizes[i];
            var bitmap = Graphics.createBufferedBitmap({:width => size, :height => size});
            var dc = bitmap.get().getDc();
            view.onLayout(dc);
            provider.data.elevation = 8848.86;
            provider.data.temperature = -40;
            provider.revision += 1;
            view.onUpdate(dc);
            Test.assert(dc.getTextWidthInPixels(view.presentation.elevationText,
                view.presentation.elevationFont) <= view.layout.elevationWidth);
            Test.assert(dc.getTextWidthInPixels(view.presentation.temperatureText,
                view.presentation.temperatureFont) <= view.layout.temperatureWidth);
            if (view.presentation.elevationUnitText != null) {
                Test.assert(view.presentation.elevationText.equals("29032"));
                Test.assert(view.presentation.elevationUnitText.equals("ft"));
                Test.assert(dc.getTextWidthInPixels(view.presentation.elevationUnitText,
                    view.smallFont) <= view.layout.elevationWidth);
            } else {
                Test.assert(view.presentation.elevationText.equals("29032 ft"));
            }
            provider.data.elevation = null;
            provider.data.temperature = null;
            provider.revision += 1;
            view.onUpdate(dc);
            Test.assert(view.presentation.elevationText.equals("-- ft"));
            Test.assert(view.presentation.elevationUnitText == null);
            Test.assert(view.presentation.temperatureText.equals("--°F"));
        }
    }
    return true;
}
