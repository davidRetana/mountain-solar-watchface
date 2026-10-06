using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Math;

module Formatters {
    function count(value, locale as WatchLocale) {
        if (value == null) { return "--"; }
        var digits = value.toNumber().toString();
        var result = "";
        while (digits.length() > 3) {
            var split = digits.length() - 3;
            result = locale.groupSeparator + digits.substring(split, digits.length()) + result;
            digits = digits.substring(0, split);
        }
        return digits + result;
    }

    function progress(steps, goal, width) {
        if (steps == null || goal == null || goal <= 0 || steps <= 0) { return 0; }
        if (steps >= goal) { return width; }
        return (width * steps.toFloat() / goal).toNumber();
    }

    function solarTime(moment) {
        if (moment == null) { return "--:--"; }
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        return info.hour.format("%02d") + ":" + info.min.format("%02d");
    }

    function temperature(value) {
        if (value == null) { return "--°C"; }
        return Math.round(value).toNumber().toString() + "°C";
    }

    function city(value, dc, font, width) {
        if (value == null || value.length() == 0) { return "--"; }
        var label = value.toUpper();
        if (dc.getTextWidthInPixels(label, font) <= width) { return label; }
        while (label.length() > 0 && dc.getTextWidthInPixels(label + "...", font) > width) {
            label = label.substring(0, label.length() - 1);
        }
        return label + "...";
    }

    function heartAge(when, now, locale as WatchLocale) {
        if (when == null || now < when) { return "--"; }
        var minutes = ((now - when) / 60).toNumber();
        if (minutes == 0) { return "<1 " + locale.minuteUnit; }
        return minutes.toString() + " " + locale.minuteUnit;
    }

    function elevation(value) {
        if (value == null) { return "-- m"; }
        return value.toNumber().toString() + " m";
    }

    function batteryText(data) {
        if (data.batteryDays != null) {
            if (data.batteryDays < 1) { return "<1 " + data.locale.dayUnit; }
            return data.batteryDays.toNumber().toString() + " " + data.locale.dayUnit;
        }
        if (data.battery != null) { return data.battery.toNumber().toString() + "%"; }
        return "--";
    }

    function batteryColor(percent) {
        if (percent == null) { return Theme.MUTED; }
        if (percent >= 30) { return Theme.GREEN; }
        if (percent >= 10) { return Theme.AMBER; }
        return Theme.RED;
    }
}
