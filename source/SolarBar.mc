using Toybox.Graphics;
using Toybox.Lang;

class SolarBar {
    // Pair real adjacent events. The end is exclusive so sunset switches to
    // the moon immediately and sunrise switches back to the sun.
    static function selectInterval(rises as Lang.Array<Lang.Number>, sets as Lang.Array<Lang.Number>, now as Lang.Number) as Lang.Array or Null {
        var day = containingInterval(rises, sets, now);
        if (day != null) { return [day[0], day[1], true]; }
        var night = containingInterval(sets, rises, now);
        if (night != null) { return [night[0], night[1], false]; }
        return null;
    }

    static function containingInterval(starts as Lang.Array<Lang.Number>, ends as Lang.Array<Lang.Number>, now as Lang.Number) as Lang.Array<Lang.Number> or Null {
        for (var i = 0; i < starts.size(); i += 1) {
            var start = starts[i];
            var end = null;
            for (var j = 0; j < ends.size(); j += 1) {
                if (ends[j] > start && (end == null || ends[j] < end)) { end = ends[j]; }
            }
            if (end != null && start <= now && now < end) { return [start, end]; }
        }
        return null;
    }

    static function draw(dc, font, data as WatchData, now) {
        var interval = data.solarInterval;
        var start = null;
        var end = null;
        if (interval != null) {
            start = new Toybox.Time.Moment(interval[0]);
            end = new Toybox.Time.Moment(interval[1]);
        }
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        dc.drawText(38, 54, font, Formatters.solarTime(start), Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(222, 54, font, Formatters.solarTime(end), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.fillRectangle(80, 53, 100, 2);
        if (interval == null || now < interval[0] || now >= interval[1]) { return; }
        var color = interval[2] ? Theme.AMBER : Theme.TEXT;
        dc.setColor(color, Graphics.COLOR_BLACK);
        dc.fillRectangle(90, 53, 80, 2);
        var x = 90 + ((now - interval[0]).toFloat() * 80 / (interval[1] - interval[0])).toNumber();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillCircle(x, 54, 9);
        if (interval[2]) {
            drawSun(dc, x, 54, color, 4);
        } else {
            dc.setColor(color, Graphics.COLOR_BLACK);
            dc.fillCircle(x, 54, 6);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.fillCircle(x + 3, 52, 5);
        }
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
