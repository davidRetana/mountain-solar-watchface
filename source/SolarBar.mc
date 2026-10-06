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

    static function draw(dc, font, data as WatchData, now, startText, endText, layout as WatchLayout) {
        var interval = data.solarInterval;
        dc.setColor(Theme.MUTED, Graphics.COLOR_BLACK);
        dc.drawText(layout.solarStartX, layout.solarY, font, startText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(layout.solarEndX, layout.solarY, font, endText, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        var line = layout.solarLine;
        dc.fillRectangle(line[0], line[1], line[2], line[3]);
        if (interval == null || now < interval[0] || now >= interval[1]) { return; }
        var color = interval[2] ? Theme.AMBER : Theme.TEXT;
        dc.setColor(color, Graphics.COLOR_BLACK);
        var track = layout.solarTrack;
        dc.fillRectangle(track[0], track[1], track[2], track[3]);
        var x = track[0] + ((now - interval[0]).toFloat() * track[2] / (interval[1] - interval[0])).toNumber();
        var y = layout.solarY;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillCircle(x, y, layout.marker9);
        if (interval[2]) {
            drawSun(dc, x, y, color, layout);
        } else {
            dc.setColor(color, Graphics.COLOR_BLACK);
            dc.fillCircle(x, y, layout.marker6);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.fillCircle(x + layout.marker3, y - layout.marker2, layout.marker5);
        }
    }

    static function drawSun(dc, x, y, color, layout as WatchLayout) {
        dc.setColor(color, Graphics.COLOR_BLACK);
        dc.fillCircle(x, y, layout.marker4);
        dc.drawLine(x, y - layout.marker8, x, y - layout.marker6);
        dc.drawLine(x, y + layout.marker6, x, y + layout.marker8);
        dc.drawLine(x - layout.marker8, y, x - layout.marker6, y);
        dc.drawLine(x + layout.marker6, y, x + layout.marker8, y);
        dc.drawLine(x - layout.marker6, y - layout.marker6, x - layout.marker5, y - layout.marker5);
        dc.drawLine(x + layout.marker5, y - layout.marker5, x + layout.marker6, y - layout.marker6);
        dc.drawLine(x - layout.marker6, y + layout.marker6, x - layout.marker5, y + layout.marker5);
        dc.drawLine(x + layout.marker5, y + layout.marker5, x + layout.marker6, y + layout.marker6);
    }
}
