using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Time;

class MountainWatchView extends WatchUi.WatchFace {
    var provider;
    var dateFont;
    var timeFont;
    var labelFont;
    var valueFont;
    var smallFont;

    function initialize() {
        WatchFace.initialize();
        provider = new DataProvider();
        // Cache fonts once; data queries are cached separately by the provider.
        dateFont = Graphics.getVectorFont({:face=>"RobotoCondensedBold", :size=>18});
        timeFont = Graphics.getVectorFont({:face=>"BionicBold", :size=>86});
        labelFont = Graphics.getVectorFont({:face=>"RobotoCondensedBold", :size=>15});
        valueFont = Graphics.getVectorFont({:face=>"RobotoCondensedBold", :size=>21});
        smallFont = Graphics.getVectorFont({:face=>"RobotoCondensedBold", :size=>11});
    }

    function onUpdate(dc) {
        var data = provider.refresh();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        // Layout coordinates target the fenix7's 260 x 260 display.
        dc.setColor(Theme.TEXT, Graphics.COLOR_BLACK);
        dc.drawRadialText(130, 130, dateFont, data.dateText,
            Graphics.TEXT_JUSTIFY_CENTER, 90, 109,
            Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE);

        SolarBar.draw(dc, labelFont, data, Time.now().value());

        drawPin(dc, 54, 74);
        drawCentered(dc, 89, 74, labelFont, Formatters.city(data.city, dc, labelFont, 66), Theme.MUTED);
        drawThermometer(dc, 169, 74);
        drawCentered(dc, 202, 74, labelFont, Formatters.temperature(data.temperature), Theme.TEXT);

        drawCentered(dc, 130, 126, timeFont, data.timeText, Theme.TEXT);

        drawStepsIcon(dc, 72, 171);
        var stepsText = Formatters.count(data.steps);
        var goalText = " / " + Formatters.count(data.stepGoal);
        var stepsFont = labelFont;
        if (dc.getTextWidthInPixels(stepsText + goalText, stepsFont) > 116) {
            stepsFont = smallFont;
        }
        dc.setColor(Theme.TEXT, Graphics.COLOR_BLACK);
        dc.drawText(90, 173, stepsFont, stepsText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        dc.drawText(90 + dc.getTextWidthInPixels(stepsText, stepsFont), 173, stepsFont, goalText,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.DIVIDER, Graphics.COLOR_BLACK);
        dc.fillRoundedRectangle(58, 186, 144, 5, 5);
        dc.setColor(Theme.AMBER, Graphics.COLOR_BLACK);
        var progress = Formatters.progress(data.steps, data.stepGoal, 144);
        if (progress >= 5) {
            dc.fillRoundedRectangle(58, 186, progress, 5, 5);
        } else if (progress > 0) {
            dc.fillRectangle(58, 186, progress, 5);
        }

        dc.setColor(Theme.DIVIDER, Graphics.COLOR_BLACK);
        dc.drawLine(100, 201, 100, 233);
        dc.drawLine(160, 201, 160, 233);
        drawHeart(dc, 74, 204);
        drawCentered(dc, 74, 221, valueFont, Formatters.count(data.heartRate), Theme.RED);
        drawCentered(dc, 74, 236, smallFont, Formatters.heartAge(data.heartRateWhen, Time.now().value()), Theme.MUTED);
        drawMountain(dc, 130, 207);
        var elevationText = Formatters.elevation(data.elevation);
        var elevationFont = valueFont;
        if (dc.getTextWidthInPixels(elevationText, elevationFont) > 56) { elevationFont = labelFont; }
        drawCentered(dc, 130, 224, elevationFont, elevationText, Theme.TEXT);
        drawBattery(dc, 179, 202, data.battery);
        drawCentered(dc, 186, 224, valueFont, Formatters.batteryText(data), Formatters.batteryColor(data.battery));
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

    function drawPin(dc, x, y) {
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        dc.fillCircle(x, y - 2, 4);
        dc.fillPolygon([[x - 4, y], [x + 4, y], [x, y + 7]]);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillCircle(x, y - 2, 1);
    }

    function drawStepsIcon(dc, x, y) {
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        dc.fillEllipse(x - 4, y - 3, 5, 9);
        dc.fillEllipse(x + 4, y - 7, 5, 9);
        dc.fillEllipse(x - 4, y + 7, 4, 4);
        dc.fillEllipse(x + 3, y + 3, 4, 4);
    }

    function drawHeart(dc, x, y) {
        dc.setColor(Theme.RED, Graphics.COLOR_BLACK);
        dc.fillCircle(x - 3, y, 3);
        dc.fillCircle(x + 3, y, 3);
        dc.fillPolygon([[x - 6, y], [x + 6, y], [x, y + 8]]);
    }

    function drawMountain(dc, x, y) {
        dc.setColor(Theme.BROWN, Graphics.COLOR_BLACK);
        dc.fillPolygon([[x - 10, y + 6], [x - 6, y], [x - 4, y + 2],
            [x, y - 6], [x + 4, y + 1], [x + 6, y - 1], [x + 10, y + 6]]);
    }

    function drawBattery(dc, x, y, percent) {
        dc.setColor(Formatters.batteryColor(percent), Graphics.COLOR_BLACK);
        dc.drawRectangle(x, y, 16, 10);
        dc.fillRectangle(x + 16, y + 3, 2, 4);
        var fill = Formatters.progress(percent, 100, 12);
        if (fill > 0) { dc.fillRectangle(x + 2, y + 2, fill, 6); }
    }
}
