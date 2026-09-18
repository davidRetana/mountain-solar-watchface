using Toybox.Graphics;

class SolarBar {
    static function drawStatic(dc, font) {
        dc.setColor(Theme.TEXT, Graphics.COLOR_BLACK);
        dc.drawText(29, 188, font, "07:52", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(231, 188, font, "20:17", Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        dc.fillRectangle(72, 187, 116, 2);
        dc.setColor(Theme.AMBER, Graphics.COLOR_BLACK);
        dc.fillRectangle(85, 187, 81, 2);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillCircle(145, 188, 9);
        drawSun(dc, 145, 188, Theme.AMBER, 4);
    }

    static function drawSun(dc, x, y, color, radius) {
        dc.setColor(color, Graphics.COLOR_BLACK);
        dc.fillCircle(x, y, radius);
        dc.drawLine(x, y - 8, x, y - 6);
        dc.drawLine(x, y + 6, x, y + 8);
        dc.drawLine(x - 8, y, x - 6, y);
        dc.drawLine(x + 6, y, x + 8, y);
        dc.drawLine(x - 6, y - 6, x - 5, y - 5);
        dc.drawLine(x + 5, y - 5, x + 6, y - 6);
        dc.drawLine(x - 6, y + 6, x - 5, y + 5);
        dc.drawLine(x + 5, y + 5, x + 6, y + 6);
    }
}
