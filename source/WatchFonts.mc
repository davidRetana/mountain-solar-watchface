using Toybox.Graphics;

// Font availability varies even between MIP models (8 Solar uses SemiBold).
class WatchFonts {
    const TEXT_FACES = ["RobotoCondensedBold", "RobotoCondensedRegular"];
    const TIME_FACES = ["BionicBold", "BionicSemiBold", "RobotoCondensedBold"];

    function initialize() {}

    function readVector(faces, size) {
        return Graphics.getVectorFont({:face => faces, :size => size});
    }

    function radial(size) { return readVector(TEXT_FACES, size); }

    function text(size, fallback) {
        var font = readVector(TEXT_FACES, size);
        return font == null ? fallback : font;
    }

    function time(dc, layout as WatchLayout) {
        // Preserve the original search at 260px; allow smaller sizes if needed.
        var step = layout.size(2);
        for (var size = layout.size(138); size >= layout.size(40); size -= step) {
            var font = readVector(TIME_FACES, size);
            if (font == null) { break; }
            if (dc.getTextWidthInPixels("00:00", font) <= layout.timeWidth) { return font; }
        }
        // Never measure or draw a null font, including on an unknown profile.
        var fallbacks = [Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD];
        for (var i = 0; i < fallbacks.size(); i += 1) {
            if (dc.getTextWidthInPixels("00:00", fallbacks[i]) <= layout.timeWidth) { return fallbacks[i]; }
        }
        return Graphics.FONT_XTINY;
    }
}
