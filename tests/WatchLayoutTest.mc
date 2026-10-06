using Toybox.Graphics;
using Toybox.Test;

(:test)
class CountingWatchFonts extends WatchFonts {
    var calls = 0;
    function initialize() { WatchFonts.initialize(); }
    function readVector(faces, size) {
        calls += 1;
        return WatchFonts.readVector(faces, size);
    }
}

(:test)
class MissingWatchFonts extends WatchFonts {
    function initialize() { WatchFonts.initialize(); }
    function readVector(faces, size) { return null; }
}

(:test)
function resizedViewRebuildsLayoutAndCachesFonts(logger) {
    var view = new MountainWatchView();
    var provider = new EfficiencyProvider();
    var fonts = new CountingWatchFonts();
    view.provider = provider;
    view.fonts = fonts;
    var sizes = [260, 240, 280, 416, 454];
    for (var i = 0; i < sizes.size(); i += 1) {
        var size = sizes[i];
        var bitmap = Graphics.createBufferedBitmap({
            :width => size, :height => size
        });
        var dc = bitmap.get().getDc();
        view.onLayout(dc);
        var calls = fonts.calls;
        var geometry = view.layout;
        var timeFont = view.timeFont;
        Test.assert(geometry.width == size && geometry.centerX == size / 2);
        Test.assert(timeFont != null && dc.getTextWidthInPixels("00:00", timeFont) <= geometry.timeWidth);
        Test.assert(geometry.stepsBar[0] + geometry.stepsBar[2] < size);
        Test.assert(geometry.heartAgeY < size && geometry.dateRadius < size / 2);
        // Draw both moving markers and fallbacks with the real Garmin API.
        provider.refresh();
        provider.data.city = "A LONG CITY NAME";
        provider.data.steps = 12345;
        provider.data.stepGoal = 10000;
        provider.data.solarInterval = [provider.clock - 60, provider.clock + 60, true];
        provider.revision += 1;
        view.onUpdate(dc);
        Test.assert(view.presentation.stepsProgress == geometry.stepsBar[2]);
        provider.data.solarInterval[2] = false;
        provider.revision += 1;
        view.onUpdate(dc);
        view.onLayout(dc);
        view.onUpdate(dc);
        Test.assert(fonts.calls == calls && view.layout == geometry && view.timeFont == timeFont);
        Test.assert(view.presentation.layout == geometry && provider.activityReads == 1);
    }
    return true;
}

(:test)
function missingVectorFontsStillRender(logger) {
    var view = new MountainWatchView();
    view.provider = new EfficiencyProvider();
    view.fonts = new MissingWatchFonts();
    var bitmap = Graphics.createBufferedBitmap({
        :width => 260, :height => 260
    });
    var dc = bitmap.get().getDc();
    view.onLayout(dc);
    Test.assert(view.dateFont == null && view.timeFont != null);
    Test.assert(view.labelFont != null && view.valueFont != null);
    view.onUpdate(dc);
    return true;
}

(:test)
function presentationRemeasuresAfterResize(logger) {
    var dc = new EfficiencyDc();
    var cache = new WatchPresentation(7, 5, 10);
    var data = new WatchData();
    data.city = "LONG CITY NAME";
    data.steps = 5000;
    data.stepGoal = 10000;
    cache.prepare(dc, data, 1);
    var smallCity = cache.cityText;
    var measurements = dc.measurements;
    var layout = new WatchLayout(454, 454);
    cache.configure(layout, 7, 5, 10);
    cache.prepare(dc, data, 1); // Same data revision, different geometry.
    Test.assert(dc.measurements > measurements && !cache.cityText.equals(smallCity));
    Test.assert(cache.stepsProgress == (layout.stepsBar[2] / 2).toNumber());
    Test.assert(cache.stepsX >= layout.stepsX);
    return true;
}
