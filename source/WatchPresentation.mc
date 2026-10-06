using Toybox.Time;

// Small text/measurement cache, shared by all redraws of a minute snapshot.
// Keep source values only for expensive text measurements, not a second copy
// of WatchData or a full-screen bitmap.
class WatchPresentation {
    var revision = -1;
    var labelFont;
    var smallFont;
    var valueFont;
    var layout as WatchLayout;
    var citySource = null;
    var stepsSource = null;
    var goalSource = null;
    var elevationSource = null;
    var solarStart = null;
    var solarEnd = null;
    var utcOffset = null;
    var cityText = "--";
    var temperatureText = "--°C";
    var stepsText = "--";
    var goalText = " / --";
    var stepsFont;
    var stepsX = 60;
    var goalX = 60;
    var stepsProgress = 0;
    var elevationText = "-- m";
    var elevationFont;
    var heartText = "--";
    var heartAgeText = "--";
    var batteryText = "--";
    var solarStartText = "--:--";
    var solarEndText = "--:--";

    function initialize(label, small, value) {
        layout = new WatchLayout(260, 260);
        configure(layout, label, small, value);
    }

    function configure(geometry as WatchLayout, label, small, value) {
        layout = geometry;
        labelFont = label;
        smallFont = small;
        valueFont = value;
        revision = -1;
    }

    function prepare(dc, data as WatchData, nextRevision) {
        if (revision == nextRevision) { return; }
        var first = revision == -1;
        if (first || !sameText(citySource, data.city)) {
            citySource = data.city;
            cityText = Formatters.city(data.city, dc, labelFont, layout.cityWidth);
        }
        if (first || stepsSource != data.steps || goalSource != data.stepGoal) {
            stepsSource = data.steps;
            goalSource = data.stepGoal;
            stepsText = Formatters.count(data.steps);
            goalText = " / " + Formatters.count(data.stepGoal);
            var counter = stepsText + goalText;
            stepsFont = labelFont;
            var width = dc.getTextWidthInPixels(counter, stepsFont);
            if (width > layout.stepsTextWidth) {
                stepsFont = smallFont;
                width = dc.getTextWidthInPixels(counter, stepsFont);
            }
            stepsX = layout.stepsX + ((layout.stepsBar[2] - width) / 2).toNumber();
            goalX = stepsX + dc.getTextWidthInPixels(stepsText, stepsFont);
            stepsProgress = Formatters.progress(data.steps, data.stepGoal, layout.stepsBar[2]);
        }
        if (first || elevationSource != data.elevation) {
            elevationSource = data.elevation;
            elevationText = Formatters.elevation(data.elevation);
            elevationFont = valueFont;
            if (dc.getTextWidthInPixels(elevationText, elevationFont) > layout.elevationWidth) { elevationFont = labelFont; }
        }
        var interval = data.solarInterval;
        var start = interval == null ? null : interval[0];
        var end = interval == null ? null : interval[1];
        if (first || start != solarStart || end != solarEnd || utcOffset != data.utcOffset) {
            solarStart = start;
            solarEnd = end;
            utcOffset = data.utcOffset;
            solarStartText = start == null ? "--:--" : Formatters.solarTime(new Time.Moment(start));
            solarEndText = end == null ? "--:--" : Formatters.solarTime(new Time.Moment(end));
        }
        temperatureText = Formatters.temperature(data.temperature);
        heartText = Formatters.count(data.heartRate);
        heartAgeText = Formatters.heartAge(data.heartRateWhen, data.updatedAt);
        batteryText = Formatters.batteryText(data);
        revision = nextRevision;
    }

    function sameText(a, b) {
        if (a == null || b == null) { return a == null && b == null; }
        return a.equals(b);
    }
}
