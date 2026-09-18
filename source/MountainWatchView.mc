using Toybox.Graphics;
using Toybox.WatchUi;

class MountainWatchView extends WatchUi.WatchFace {
    var dateFont;
    var timeFont;
    var labelFont;
    var valueFont;
    var smallFont;

    function initialize() {
        WatchFace.initialize();
        // Cache fonts once; the static stage performs no sensor or network work.
        dateFont = Graphics.getVectorFont({:face=>"RobotoCondensedBold", :size=>18});
        timeFont = Graphics.getVectorFont({:face=>"BionicBold", :size=>86});
        labelFont = Graphics.getVectorFont({:face=>"RobotoCondensedBold", :size=>15});
        valueFont = Graphics.getVectorFont({:face=>"RobotoCondensedBold", :size=>21});
        smallFont = Graphics.getVectorFont({:face=>"RobotoCondensedBold", :size=>11});
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        // Layout coordinates target the fenix7's 260 x 260 display.
        dc.setColor(Theme.TEXT, Graphics.COLOR_BLACK);
        dc.drawRadialText(130, 130, dateFont, "MIÉ 16 SEP",
            Graphics.TEXT_JUSTIFY_CENTER, 90, 109,
            Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE);

        drawPin(dc, 54, 54);
        drawCentered(dc, 89, 54, labelFont, "MADRID", Theme.MUTED);
        SolarBar.drawSun(dc, 169, 54, Theme.MUTED, 4);
        drawCentered(dc, 202, 54, labelFont, "23°C", Theme.TEXT);

        drawCentered(dc, 130, 106, timeFont, "14:37", Theme.TEXT);

        drawStepsIcon(dc, 72, 151);
        // Separate colors for current steps and target, as in the reference.
        dc.setColor(Theme.TEXT, Graphics.COLOR_BLACK);
        dc.drawText(94, 153, labelFont, "8.426", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        dc.drawText(133, 153, labelFont, "/ 10.000", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.DIVIDER, Graphics.COLOR_BLACK);
        dc.fillRoundedRectangle(58, 166, 144, 5, 5);
        dc.setColor(Theme.AMBER, Graphics.COLOR_BLACK);
        dc.fillRoundedRectangle(58, 166, 121, 5, 5);

        SolarBar.drawStatic(dc, labelFont);

        dc.setColor(Theme.DIVIDER, Graphics.COLOR_BLACK);
        dc.drawLine(100, 201, 100, 233);
        dc.drawLine(160, 201, 160, 233);
        drawHeart(dc, 74, 204);
        drawCentered(dc, 74, 221, valueFont, "68", Theme.RED);
        drawCentered(dc, 74, 236, smallFont, "5 MIN", Theme.MUTED);
        drawMountain(dc, 130, 207);
        drawCentered(dc, 130, 224, valueFont, "667 m", Theme.TEXT);
        drawBattery(dc, 179, 202);
        drawCentered(dc, 186, 224, valueFont, "12 d", Theme.GREEN);
    }

    function drawCentered(dc, x, y, font, label, color) {
        dc.setColor(color, Graphics.COLOR_BLACK);
        dc.drawText(x, y, font, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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

    function drawBattery(dc, x, y) {
        dc.setColor(Theme.GREEN, Graphics.COLOR_BLACK);
        dc.drawRectangle(x, y, 16, 10);
        dc.fillRectangle(x + 16, y + 3, 2, 4);
        dc.fillRectangle(x + 2, y + 2, 12, 6);
    }
}
