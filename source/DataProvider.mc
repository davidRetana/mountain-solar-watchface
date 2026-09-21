using Toybox.ActivityMonitor;
using Toybox.System;
using Toybox.SensorHistory;
using Toybox.Time;
using Toybox.Time.Gregorian;

class DataProvider {
    var data;
    var lastHistoryUpdate = null;
    const HEART_MAX_AGE = 900;
    const ELEVATION_MAX_AGE = 1800;
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
        refreshHistory(now.value());
        return data;
    }

    function refreshHistory(now) {
        if (lastHistoryUpdate == null || now < lastHistoryUpdate || now - lastHistoryUpdate >= 300) {
            lastHistoryUpdate = now;
            data.heartRate = null;
            data.heartRateWhen = null;
            data.elevation = null;
            data.elevationWhen = null;
            // Read existing history only; never start optical sensing or GPS.
            try {
                var heart = newestValid(SensorHistory.getHeartRateHistory({
                    :period => new Time.Duration(HEART_MAX_AGE),
                    :order => SensorHistory.ORDER_NEWEST_FIRST
                }), now, HEART_MAX_AGE, true);
                if (heart != null) {
                    data.heartRate = heart.data;
                    data.heartRateWhen = heart.when.value();
                }
            } catch (e) {
                // Permission denied or history unavailable: keep null.
            }
            try {
                var elevation = newestValid(SensorHistory.getElevationHistory({
                    :period => new Time.Duration(ELEVATION_MAX_AGE),
                    :order => SensorHistory.ORDER_NEWEST_FIRST
                }), now, ELEVATION_MAX_AGE, false);
                if (elevation != null) {
                    data.elevation = elevation.data;
                    data.elevationWhen = elevation.when.value();
                }
            } catch (e) {
                // Elevation history can be absent independently of heart rate.
            }
        }
        // Expire cached readings each minute, even between history queries.
        if (data.heartRateWhen != null && (now < data.heartRateWhen || now - data.heartRateWhen > HEART_MAX_AGE)) {
            data.heartRate = null;
            data.heartRateWhen = null;
        }
        if (data.elevationWhen != null && (now < data.elevationWhen || now - data.elevationWhen > ELEVATION_MAX_AGE)) {
            data.elevation = null;
            data.elevationWhen = null;
        }
    }

    function newestValid(history, now, maxAge, positiveOnly) {
        // Bound work even if a device supplies unusually dense history.
        for (var i = 0; i < 30; i += 1) {
            var sample = history.next();
            if (sample == null) { return null; }
            var age = now - sample.when.value();
            if (age > maxAge) { return null; }
            if (age >= 0 && sample.data != null && (!positiveOnly || sample.data > 0)) {
                return sample;
            }
        }
        return null;
    }
}
