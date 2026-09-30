using Toybox.Graphics;
using Toybox.WatchUi;

class MountainWatchView extends WatchUi.WatchFace {
    var provider;
    var dateFont;
    var dayFont;
    var timeFont;
    var labelFont;
    var valueFont;
    var smallFont;
    var presentation;
    // Fixed fenix7 geometry: reuse these arrays on every full redraw.
    const PIN = [[50, 74], [58, 74], [54, 81]];
    const LEFT_SOLE = [[36, 182], [37, 179], [40, 179], [41, 182], [40, 187], [37, 187]];
    const RIGHT_SOLE = [[44, 178], [45, 175], [48, 175], [49, 178], [48, 183], [45, 183]];
    const HEART = [[68, 204], [80, 204], [74, 212]];
    const MOUNTAIN = [[120, 213], [124, 207], [126, 209], [130, 201], [134, 208], [136, 206], [140, 213]];

    function initialize() {
        WatchFace.initialize();
        provider = new DataProvider();
        // Cache fonts once; data queries are cached separately by the provider.
        dateFont = Graphics.getVectorFont({:face=>"RobotoCondensedBold", :size=>18});
        dayFont = Graphics.getVectorFont({:face=>"RobotoCondensedBold", :size=>30});
        timeFont = null;
        labelFont = Graphics.getVectorFont({:face=>"RobotoCondensedBold", :size=>15});
        valueFont = Graphics.getVectorFont({:face=>"RobotoCondensedBold", :size=>21});
        smallFont = Graphics.getVectorFont({:face=>"RobotoCondensedBold", :size=>11});
        presentation = new WatchPresentation(labelFont, smallFont, valueFont);
    }

    function onLayout(dc) {
        if (timeFont == null) {
            // Scale both axes equally and size against the widest time once.
            for (var size = 138; size >= 86; size -= 2) {
                timeFont = Graphics.getVectorFont({:face=>"BionicBold", :size=>size});
                if (dc.getTextWidthInPixels("00:00", timeFont) <= 232) { break; }
            }
        }
        presentation.revision = -1;
    }

    function onUpdate(dc) {
        var data = provider.refresh();
        presentation.prepare(dc, data, provider.revision);
        // Garmin may need to restore the whole screen after an overlay or
        // transition. Repaint it, but reuse the prepared minute snapshot.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        // Paint the padded time font first to preserve the adjacent rows.
        drawCentered(dc, 130, 124, timeFont, data.timeText, Theme.TEXT);

        // Layout coordinates target the fenix7's 260 x 260 display.
        drawCentered(dc, 130, 25, dayFont, data.dayText, Theme.TEXT);
        dc.setColor(Theme.TEXT, Graphics.COLOR_BLACK);
        dc.drawRadialText(130, 130, dateFont, data.weekdayText,
            Graphics.TEXT_JUSTIFY_CENTER, 112, 109,
            Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE);
        dc.drawRadialText(130, 130, dateFont, data.monthText,
            Graphics.TEXT_JUSTIFY_CENTER, 68, 109,
            Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE);

        SolarBar.draw(dc, labelFont, data, data.updatedAt,
            presentation.solarStartText, presentation.solarEndText);

        drawPin(dc);
        // The pin ends at x=58; keep a 6px gap and room before the thermometer.
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        dc.drawText(64, 74, labelFont, presentation.cityText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        drawThermometer(dc, 169, 74);
        drawCentered(dc, 202, 74, labelFont, presentation.temperatureText, Theme.TEXT);

        drawStepsIcon(dc);
        dc.setColor(Theme.TEXT, Graphics.COLOR_BLACK);
        dc.drawText(presentation.stepsX, 174, presentation.stepsFont, presentation.stepsText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        dc.drawText(presentation.goalX, 174, presentation.stepsFont, presentation.goalText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.DIVIDER, Graphics.COLOR_BLACK);
        dc.fillRoundedRectangle(60, 184, 156, 7, 7);
        dc.setColor(Theme.AMBER, Graphics.COLOR_BLACK);
        var progress = presentation.stepsProgress;
        if (progress >= 7) {
            dc.fillRoundedRectangle(60, 184, progress, 7, 7);
        } else if (progress > 0) {
            dc.fillRectangle(60, 184, progress, 7);
        }

        dc.setColor(Theme.DIVIDER, Graphics.COLOR_BLACK);
        dc.drawLine(100, 201, 100, 233);
        dc.drawLine(160, 201, 160, 233);
        drawHeart(dc);
        drawCentered(dc, 74, 221, valueFont, presentation.heartText, Theme.RED);
        drawCentered(dc, 74, 236, smallFont, presentation.heartAgeText, Theme.MUTED);
        drawMountain(dc);
        drawCentered(dc, 130, 224, presentation.elevationFont, presentation.elevationText, Theme.TEXT);
        drawBattery(dc, 179, 202, data.battery);
        drawCentered(dc, 186, 224, valueFont, presentation.batteryText, Formatters.batteryColor(data.battery));
    }

    function drawCentered(dc, x, y, font, label, color) {
        dc.setColor(color, Graphics.COLOR_BLACK);
        dc.drawText(x, y, font, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawThermometer(dc, x, y) {
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        dc.drawRoundedRectangle(x - 2, y - 7, 5, 12, 3);
        dc.fillCircle(x, y + 5, 3);
        dc.drawLine(x, y - 3, x, y + 5);
    }

    function drawPin(dc) {
        var x = 54;
        var y = 74;
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        dc.fillCircle(x, y - 2, 4);
        dc.fillPolygon(PIN);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillCircle(x, y - 2, 1);
    }

    function drawStepsIcon(dc) {
        var x = 43;
        var y = 185;
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        // Separate soles and heels, aligned to whole pixels for the MIP display.
        dc.fillPolygon(LEFT_SOLE);
        dc.fillRoundedRectangle(x - 6, y + 4, 4, 4, 2);
        dc.fillPolygon(RIGHT_SOLE);
        dc.fillRoundedRectangle(x + 2, y, 4, 4, 2);
    }

    function drawHeart(dc) {
        var x = 74;
        var y = 204;
        dc.setColor(Theme.RED, Graphics.COLOR_BLACK);
        dc.fillCircle(x - 3, y, 3);
        dc.fillCircle(x + 3, y, 3);
        dc.fillPolygon(HEART);
    }

    function drawMountain(dc) {
        dc.setColor(Theme.BROWN, Graphics.COLOR_BLACK);
        dc.fillPolygon(MOUNTAIN);
    }

    function drawBattery(dc, x, y, percent) {
        dc.setColor(Formatters.batteryColor(percent), Graphics.COLOR_BLACK);
        dc.drawRectangle(x, y, 16, 10);
        dc.fillRectangle(x + 16, y + 3, 2, 4);
        var fill = Formatters.progress(percent, 100, 12);
        if (fill > 0) { dc.fillRectangle(x + 2, y + 2, fill, 6); }
    }
}
