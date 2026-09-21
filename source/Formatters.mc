module Formatters {
    const DAYS = ["DOM", "LUN", "MAR", "MIÉ", "JUE", "VIE", "SÁB"];
    const MONTHS = ["ENE", "FEB", "MAR", "ABR", "MAY", "JUN", "JUL", "AGO", "SEP", "OCT", "NOV", "DIC"];

    function date(info) {
        return DAYS[info.day_of_week - 1] + " " + info.day.toString() + " " + MONTHS[info.month - 1];
    }

    function count(value) {
        if (value == null) { return "--"; }
        var digits = value.toNumber().toString();
        var result = "";
        while (digits.length() > 3) {
            var split = digits.length() - 3;
            result = "." + digits.substring(split, digits.length()) + result;
            digits = digits.substring(0, split);
        }
        return digits + result;
    }

    function progress(steps, goal, width) {
        if (steps == null || goal == null || goal <= 0 || steps <= 0) { return 0; }
        if (steps >= goal) { return width; }
        return (width * steps.toFloat() / goal).toNumber();
    }

    function batteryText(data) {
        if (data.batteryDays != null) {
            if (data.batteryDays < 1) { return "<1 d"; }
            return data.batteryDays.toNumber().toString() + " d";
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
