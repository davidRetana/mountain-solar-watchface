using Toybox.ActivityMonitor;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

class DataProvider {
    var data;
    var lastMinute = null;

    function initialize() {
        data = new WatchData();
    }

    function refresh() {
        var now = Time.now();
        var minute = (now.value() / 60).toNumber();
        if (minute == lastMinute) { return data; }
        lastMinute = minute;
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        data.timeText = info.hour.format("%02d") + ":" + info.min.format("%02d");
        data.dateText = Formatters.date(info);
        // Clear previous readings so failures cannot leave stale values on screen.
        data.steps = null;
        data.stepGoal = null;
        data.battery = null;
        data.batteryDays = null;
        try {
            var activity = ActivityMonitor.getInfo();
            if (activity != null) {
                if (activity.steps != null && activity.steps >= 0) { data.steps = activity.steps; }
                if (activity.stepGoal != null && activity.stepGoal > 0) { data.stepGoal = activity.stepGoal; }
            }
        } catch (e) {
            // Activity tracking may be unavailable.
        }
        try {
            var stats = System.getSystemStats();
            if (stats.battery != null && stats.battery >= 0 && stats.battery <= 100) {
                data.battery = stats.battery;
            }
            if (stats has :batteryInDays) {
                if (stats.batteryInDays != null && stats.batteryInDays >= 0) {
                    data.batteryDays = stats.batteryInDays;
                }
            }
        } catch (e) {
            // Keep the missing-data presentation if system stats are unavailable.
        }
        return data;
    }
}
