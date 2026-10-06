using Toybox.Graphics;
using Toybox.Lang;
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
    var locationIcon;
    var thermometerIcon;
    var layout as WatchLayout or Null;
    var fonts;

    function initialize() {
        WatchFace.initialize();
        provider = new DataProvider();
        // Load once; preserve native pixels at 260px and scale only these glyphs
        // on other sizes, using destination rectangles cached in the layout.
        locationIcon = WatchUi.loadResource(Rez.Drawables.LocationIcon);
        thermometerIcon = WatchUi.loadResource(Rez.Drawables.ThermometerIcon);
        fonts = new WatchFonts();
        timeFont = null;
        layout = null;
        presentation = null;
    }

    function onLayout(dc) {
        if (layout == null || layout.width != dc.getWidth() || layout.height != dc.getHeight()) {
            layout = new WatchLayout(dc.getWidth(), dc.getHeight());
            dateFont = fonts.radial(layout.size(18));
            dayFont = fonts.text(layout.size(30), Graphics.FONT_MEDIUM);
            labelFont = fonts.text(layout.size(15), Graphics.FONT_XTINY);
            valueFont = fonts.text(layout.size(21), Graphics.FONT_SMALL);
            smallFont = fonts.text(layout.size(11), Graphics.FONT_XTINY);
            timeFont = fonts.time(dc, layout);
            if (presentation == null) {
                presentation = new WatchPresentation(labelFont, smallFont, valueFont);
            }
            presentation.configure(layout, labelFont, smallFont, valueFont);
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
        drawCentered(dc, layout.centerX, layout.timeY, timeFont, data.timeText, Theme.TEXT);

        drawCentered(dc, layout.centerX, layout.dayY, dayFont, data.dayText, Theme.TEXT);
        dc.setColor(Theme.TEXT, Graphics.COLOR_BLACK);
        if (dateFont != null) {
            dc.drawRadialText(layout.centerX, layout.centerY, dateFont, data.weekdayText,
                Graphics.TEXT_JUSTIFY_CENTER, 112, layout.dateRadius,
                Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE);
            dc.drawRadialText(layout.centerX, layout.centerY, dateFont, data.monthText,
                Graphics.TEXT_JUSTIFY_CENTER, 68, layout.dateRadius,
                Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE);
        } else {
            // Radial text requires a vector font. Use straight text if absent.
            drawCentered(dc, layout.dateLeftX, layout.dateY, labelFont, data.weekdayText, Theme.TEXT);
            drawCentered(dc, layout.dateRightX, layout.dateY, labelFont, data.monthText, Theme.TEXT);
        }

        SolarBar.draw(dc, labelFont, data, data.updatedAt,
            presentation.solarStartText, presentation.solarEndText, layout);

        drawPin(dc);
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        dc.drawText(layout.cityX, layout.cityY, labelFont, presentation.cityText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        drawIcon(dc, layout.thermometer, thermometerIcon);
        drawCentered(dc, layout.temperatureX, layout.cityY, labelFont, presentation.temperatureText, Theme.TEXT);

        drawStepsIcon(dc);
        dc.setColor(Theme.TEXT, Graphics.COLOR_BLACK);
        dc.drawText(presentation.stepsX, layout.stepsY, presentation.stepsFont, presentation.stepsText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        dc.drawText(presentation.goalX, layout.stepsY, presentation.stepsFont, presentation.goalText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.DIVIDER, Graphics.COLOR_BLACK);
        var bar = layout.stepsBar;
        dc.fillRoundedRectangle(bar[0], bar[1], bar[2], bar[3], bar[3]);
        dc.setColor(Theme.AMBER, Graphics.COLOR_BLACK);
        var progress = presentation.stepsProgress;
        if (progress >= bar[3]) {
            dc.fillRoundedRectangle(bar[0], bar[1], progress, bar[3], bar[3]);
        } else if (progress > 0) {
            dc.fillRectangle(bar[0], bar[1], progress, bar[3]);
        }

        dc.setColor(Theme.DIVIDER, Graphics.COLOR_BLACK);
        for (var i = 0; i < layout.dividers.size(); i += 1) {
            var line = layout.dividers[i];
            dc.drawLine(line[0], line[1], line[2], line[3]);
        }
        drawHeart(dc);
        drawCentered(dc, layout.heartX, layout.heartY, valueFont, presentation.heartText, Theme.RED);
        drawCentered(dc, layout.heartX, layout.heartAgeY, smallFont, presentation.heartAgeText, Theme.MUTED);
        drawMountain(dc);
        drawCentered(dc, layout.centerX, layout.valueY, presentation.elevationFont, presentation.elevationText, Theme.TEXT);
        drawBattery(dc, data.battery);
        drawCentered(dc, layout.batteryX, layout.valueY, valueFont, presentation.batteryText, Formatters.batteryColor(data.battery));
    }

    function drawCentered(dc, x, y, font, label, color) {
        dc.setColor(color, Graphics.COLOR_BLACK);
        dc.drawText(x, y, font, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawIcon(dc, rectangle as Lang.Array<Lang.Number>, bitmap) {
        if (rectangle[2] == bitmap.getWidth() && rectangle[3] == bitmap.getHeight()) {
            dc.drawBitmap(rectangle[0], rectangle[1], bitmap);
        } else {
            dc.drawScaledBitmap(rectangle[0], rectangle[1], rectangle[2], rectangle[3], bitmap);
        }
    }

    function drawPin(dc) {
        drawIcon(dc, layout.pin, locationIcon);
    }

    function drawStepsIcon(dc) {
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        dc.fillPolygon(layout.leftSole);
        var heel = layout.leftHeel;
        dc.fillRoundedRectangle(heel[0], heel[1], heel[2], heel[3], layout.marker2);
        dc.fillPolygon(layout.rightSole);
        heel = layout.rightHeel;
        dc.fillRoundedRectangle(heel[0], heel[1], heel[2], heel[3], layout.marker2);
    }

    function drawHeart(dc) {
        dc.setColor(Theme.RED, Graphics.COLOR_BLACK);
        var circle = layout.heartLeft;
        dc.fillCircle(circle[0], circle[1], circle[2]);
        circle = layout.heartRight;
        dc.fillCircle(circle[0], circle[1], circle[2]);
        dc.fillPolygon(layout.heart);
    }

    function drawMountain(dc) {
        dc.setColor(Theme.BROWN, Graphics.COLOR_BLACK);
        dc.fillPolygon(layout.mountain);
    }

    function drawBattery(dc, percent) {
        dc.setColor(Formatters.batteryColor(percent), Graphics.COLOR_BLACK);
        var rect = layout.battery;
        dc.drawRectangle(rect[0], rect[1], rect[2], rect[3]);
        rect = layout.batteryCap;
        dc.fillRectangle(rect[0], rect[1], rect[2], rect[3]);
        rect = layout.batteryFill;
        var fill = Formatters.progress(percent, 100, rect[2]);
        if (fill > 0) { dc.fillRectangle(rect[0], rect[1], fill, rect[3]); }
    }
}
