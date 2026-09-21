using Toybox.Graphics;

class SolarBar {
    // Weather and sunrise/sunset are connected in a later stage.
    static function drawUnavailable(dc, font) {
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        dc.drawText(38, 54, font, "--:--", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(222, 54, font, "--:--", Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.fillRectangle(80, 53, 100, 2);
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
