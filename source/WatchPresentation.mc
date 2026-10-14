using Toybox.Time;
using Toybox.System;

// Small text/measurement cache, shared by all redraws of a minute snapshot.
// Keep source values only for expensive text measurements, not a second copy
// of WatchData or a full-screen bitmap.
class WatchPresentation {
    var revision = -1;
    var localeRevision = -1;
    var unitsRevision = -1;
    var labelFont;
    var smallFont;
    var valueFont;
    var layout as WatchLayout;
    var citySource = null;
    var stepsSource = null;
    var goalSource = null;
    var elevationSource = null;
    var elevationUnitSource = null;
    var temperatureSource = null;
    var temperatureUnitSource = null;
    var solarStart = null;
    var solarEnd = null;
    var utcOffset = null;
    var cityText = "--";
    var temperatureText = "--°C";
    var temperatureFont;
    var stepsText = "--";
    var goalText = " / --";
    var stepsFont;
    var stepsX = 60;
    var goalX = 60;
    var stepsProgress = 0;
    var elevationText = "-- m";
    var elevationUnitText = null;
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
        if (revision == nextRevision && localeRevision == data.locale.revision &&
            unitsRevision == data.units.revision) { return; }
        var first = revision == -1 || localeRevision != data.locale.revision;
        if (first || !sameText(citySource, data.city)) {
            citySource = data.city;
            cityText = Formatters.city(data.city, dc, labelFont, layout.cityWidth);
        }
        if (first || stepsSource != data.steps || goalSource != data.stepGoal) {
            stepsSource = data.steps;
            goalSource = data.stepGoal;
            stepsText = Formatters.count(data.steps, data.locale);
            goalText = " / " + Formatters.count(data.stepGoal, data.locale);
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
        if (first || elevationSource != data.elevation || elevationUnitSource != data.units.elevation) {
            elevationSource = data.elevation;
            elevationUnitSource = data.units.elevation;
            elevationText = Formatters.elevation(data.elevation, data.units.elevation);
            elevationUnitText = null;
            elevationFont = valueFont;
            if (dc.getTextWidthInPixels(elevationText, elevationFont) > layout.elevationWidth) { elevationFont = labelFont; }
            if (dc.getTextWidthInPixels(elevationText, elevationFont) > layout.elevationWidth) { elevationFont = smallFont; }
            if (dc.getTextWidthInPixels(elevationText, elevationFont) > layout.elevationWidth) {
                // Some native fallback fonts cannot fit five digits plus ft.
                elevationUnitText = data.units.elevation == System.UNIT_STATUTE ? "ft" : "m";
                elevationText = elevationText.substring(0, elevationText.length() - elevationUnitText.length() - 1);
            }
        }
        if (first || temperatureSource != data.temperature || temperatureUnitSource != data.units.temperature) {
            temperatureSource = data.temperature;
            temperatureUnitSource = data.units.temperature;
            temperatureText = Formatters.temperature(data.temperature, data.units.temperature);
            temperatureFont = labelFont;
            if (dc.getTextWidthInPixels(temperatureText, temperatureFont) > layout.temperatureWidth) { temperatureFont = smallFont; }
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
        heartText = Formatters.count(data.heartRate, data.locale);
        heartAgeText = Formatters.heartAge(data.heartRateWhen, data.updatedAt, data.locale);
        batteryText = Formatters.batteryText(data);
        revision = nextRevision;
        localeRevision = data.locale.revision;
        unitsRevision = data.units.revision;
    }

    function sameText(a, b) {
        if (a == null || b == null) { return a == null && b == null; }
        return a.equals(b);
    }
}
