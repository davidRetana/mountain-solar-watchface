using Toybox.Graphics;

class SolarBar {
    // Prefer the daylight interval containing now; at night show the next one.
    static function selectInterval(rises, sets, now) {
        var next = null;
        for (var i = 0; i < rises.size(); i += 1) {
            var start = rises[i];
            var end = null;
            for (var j = 0; j < sets.size(); j += 1) {
                if (sets[j] > start && (end == null || sets[j] < end)) { end = sets[j]; }
            }
            if (end == null) { continue; }
            if (start <= now && now <= end) { return [start, end]; }
            if (start > now && (next == null || start < next[0])) { next = [start, end]; }
        }
        return next;
    }

    // At night keep the track muted.
    static function draw(dc, font, data, now) {
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        dc.drawText(38, 54, font, Formatters.solarTime(data.sunrise), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(222, 54, font, Formatters.solarTime(data.sunset), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.fillRectangle(80, 53, 100, 2);
        if (data.sunrise == null || data.sunset == null) { return; }
        var start = data.sunrise.value();
        var end = data.sunset.value();
        if (end <= start || now < start || now > end) { return; }
        dc.setColor(Theme.AMBER, Graphics.COLOR_BLACK);
        dc.fillRectangle(90, 53, 80, 2);
        var x = 90 + ((now - start).toFloat() * 80 / (end - start)).toNumber();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillCircle(x, 54, 9);
        drawSun(dc, x, 54, Theme.AMBER, 4);
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
