using Toybox.ActivityMonitor;
using Toybox.System;
using Toybox.Weather;
using Toybox.SensorHistory;
using Toybox.Time;
using Toybox.Time.Gregorian;

class DataProvider {
    var data;
    var lastHistoryUpdate = null;
    const HEART_MAX_AGE = 900;
    const ELEVATION_MAX_AGE = 1800;
    var lastWeatherUpdate = null;
    var weatherDay = null;
    const WEATHER_MAX_AGE = 7200;
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
        refreshWeather(now, info);
        return data;
    }

    function clearWeather() {
        data.city = null;
        data.temperature = null;
        data.weatherWhen = null;
        data.sunrise = null;
        data.sunset = null;
    }

    function refreshWeather(now, info) {
        var seconds = now.value();
        var day = info.year * 10000 + info.month * 100 + info.day;
        if (lastWeatherUpdate == null || seconds < lastWeatherUpdate ||
            seconds - lastWeatherUpdate >= 900 || day != weatherDay) {
            lastWeatherUpdate = seconds;
            weatherDay = day;
            clearWeather();
            try {
                var weather = Weather.getCurrentConditions();
                if (weather != null && weather.observationTime != null) {
                    var age = seconds - weather.observationTime.value();
                    if (age >= 0 && age <= WEATHER_MAX_AGE) {
                        data.weatherWhen = weather.observationTime.value();
                        data.temperature = weather.temperature;
                        data.city = weather.observationLocationName;
                        // Use the weather station location without acquiring GPS.
                        if (weather.observationLocationPosition != null) {
                            refreshSolar(weather.observationLocationPosition, now);
                        }
                    }
                }
            } catch (e) {
                // Weather and solar availability are independent of other readings.
                data.sunrise = null;
                data.sunset = null;
            }
        }
        if (data.weatherWhen != null && (seconds < data.weatherWhen || seconds - data.weatherWhen > WEATHER_MAX_AGE)) {
            clearWeather();
        }
    }

    function refreshSolar(location, now) {
        // Weather events may fall on different dates in the watch's time zone.
        // Ask for actual adjacent-day events rather than shifting a sunset by 24h.
        var rises = [];
        var sets = [];
        for (var offset = -1; offset <= 1; offset += 1) {
            var date = new Time.Moment(now.value() + offset * 86400);
            var rise = Weather.getSunrise(location, date);
            var setting = Weather.getSunset(location, date);
            if (rise != null) { rises.add(rise.value()); }
            if (setting != null) { sets.add(setting.value()); }
        }
        var interval = SolarBar.selectInterval(rises, sets, now.value());
        if (interval != null) {
            data.sunrise = new Time.Moment(interval[0]);
            data.sunset = new Time.Moment(interval[1]);
        }
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
