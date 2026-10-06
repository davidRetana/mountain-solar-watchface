using Toybox.ActivityMonitor;
using Toybox.System;
using Toybox.Weather;
using Toybox.SensorHistory;
using Toybox.Time;
using Toybox.Time.Gregorian;

class DataProvider {
    var data as WatchData;
    var lastHistoryUpdate = null;
    const HEART_MAX_AGE = 900;
    const ELEVATION_MAX_AGE = 1800;
    var solarDay = null;
    var solarKey = null;
    var lastSolarUpdate = null;
    const WEATHER_MAX_AGE = 7200;
    var lastMinute = null;
    var solarRises = [];
    var solarSets = [];
    var cityKey = null;
    var cityScheduler;
    const SLOW_REFRESH_INTERVAL = 300;
    var lastBatteryUpdate = null;
    var lastWeatherUpdate = null;
    var weatherLocation = null;
    var cityCacheDirty = true;
    var schedulerDirty = true;
    var calendarDay = null;
    var localeDirty = true;
    var revision = 0;

    function initialize() {
        data = new WatchData();
        cityScheduler = new CityScheduler();
    }

    function refresh() {
        return refreshAt(Time.now());
    }

    // Also used by deterministic tests; all deadlines use the same instant.
    function refreshAt(now) {
        var seconds = now.value();
        var minute = (seconds / 60).toNumber();
        var minuteChanged = minute != lastMinute;
        if (!minuteChanged && !cityCacheDirty && !localeDirty) { return data; }
        var languageChanged = false;
        if (minuteChanged || localeDirty) {
            languageChanged = data.locale.refresh(readLanguage());
            localeDirty = false;
        }
        if (!minuteChanged && !cityCacheDirty && !languageChanged) { return data; }
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        // Local offset modulo one day also detects DST/time-zone changes.
        data.utcOffset = (info.hour * 3600 + info.min * 60 + info.sec - seconds % 86400 + 86400) % 86400;
        data.updatedAt = seconds;
        if (minuteChanged) {
            lastMinute = minute;
            data.timeText = info.hour.format("%02d") + ":" + info.min.format("%02d");
            refreshActivity();
            if (isDue(lastBatteryUpdate, seconds, SLOW_REFRESH_INTERVAL)) {
                lastBatteryUpdate = seconds;
                refreshBattery();
            }
            refreshHistory(seconds);
        }
        var day = info.year * 10000 + info.month * 100 + info.day;
        if (day != calendarDay || languageChanged) {
            calendarDay = day;
            var calendar = readCalendar(now);
            data.dayText = info.day.toString();
            data.weekdayText = calendar.day_of_week.toUpper();
            data.monthText = calendar.month.toUpper();
        }
        if (cityCacheDirty || isDue(lastWeatherUpdate, seconds, SLOW_REFRESH_INTERVAL)) {
            lastWeatherUpdate = seconds;
            refreshWeather(now, info);
            cityCacheDirty = false;
            schedulerDirty = true;
        }
        // A cache must not extend a reading's validity beyond its age limit.
        if (data.weatherWhen != null &&
            (seconds < data.weatherWhen || seconds - data.weatherWhen > WEATHER_MAX_AGE)) {
            clearWeather();
            schedulerDirty = true;
        }
        if (weatherLocation != null) { updateSolar(weatherLocation, now, info); }
        if (schedulerDirty) {
            try {
                cityScheduler.update(cityKey != null && data.city == null, seconds);
                schedulerDirty = false;
            } catch (e) {
                // Retry scheduling on the next normal minute update.
                System.println("CityScheduler: " + e.toString());
            }
        }
        var interval = data.solarInterval;
        if (interval == null || seconds < interval[0] || seconds >= interval[1]) {
            data.solarInterval = SolarBar.selectInterval(solarRises, solarSets, seconds);
        }
        revision += 1;
        return data;
    }

    function isDue(last, now, interval) {
        return last == null || now < last || now - last >= interval;
    }

    function invalidateWeather() {
        // Background data can arrive within the current minute. Refresh only
        // Weather/city, without repeating activity, battery or history reads.
        cityCacheDirty = true;
    }

    function invalidateLocale() { localeDirty = true; }
    function readLanguage() { return System.getDeviceSettings().systemLanguage; }
    function readCalendar(now) { return Gregorian.info(now, Time.FORMAT_MEDIUM); }

    function refreshActivity() {
        // Clear previous readings so failures cannot leave stale values on screen.
        data.steps = null;
        data.stepGoal = null;
        try {
            var activity = readActivity();
            if (activity != null) {
                if (activity.steps != null && activity.steps >= 0) { data.steps = activity.steps; }
                if (activity.stepGoal != null && activity.stepGoal > 0) { data.stepGoal = activity.stepGoal; }
            }
        } catch (e) {
            // Activity tracking may be unavailable.
        }
    }

    function refreshBattery() {
        data.battery = null;
        data.batteryDays = null;
        try {
            var stats = readBattery();
            if (stats == null) { return; }
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
    }

    function readActivity() { return ActivityMonitor.getInfo(); }
    function readBattery() { return System.getSystemStats(); }
    function readWeather() { return Weather.getCurrentConditions(); }
    function readCity(key) { return CityLookup.cachedName(key); }

    function clearWeather() {
        data.city = null;
        cityKey = null;
        data.temperature = null;
        data.weatherWhen = null;
        weatherLocation = null;
        data.solarInterval = null;
        if (solarRises.size() > 0) { solarRises = []; }
        if (solarSets.size() > 0) { solarSets = []; }
        solarKey = null;
        solarDay = null;
        lastSolarUpdate = null;
    }

    function refreshWeather(now, info) {
        // Five-minute local reads, plus background invalidation; no GPS/network.
        try {
            applyWeather(readWeather(), now, info);
        } catch (e) {
            clearWeather();
        }
    }

    function applyWeather(weather, now, info) {
        var seconds = now.value();
        if (weather == null || weather.observationTime == null ||
            seconds < weather.observationTime.value() ||
            seconds - weather.observationTime.value() > WEATHER_MAX_AGE) {
            clearWeather();
            return;
        }
        data.temperature = weather.temperature;
        data.weatherWhen = weather.observationTime.value();
        weatherLocation = weather.observationLocationPosition;
        if (weather.observationLocationPosition == null) {
            data.city = null;
            cityKey = null;
            if (solarRises.size() > 0) { solarRises = []; }
            if (solarSets.size() > 0) { solarSets = []; }
            solarKey = null;
            data.solarInterval = null;
            return;
        }
        var key = CityLookup.locationKey(weather.observationLocationPosition);
        var changed = !CityLookup.sameKey(cityKey, key);
        if (changed || cityCacheDirty) {
            cityKey = key;
            data.city = readCity(cityKey);
            if (data.city != null && changed) { CityLookup.remember(cityKey, data.city); }
        }
        updateSolar(weather.observationLocationPosition, now, info);
    }

    function updateSolar(location, now, info) {
        var seconds = now.value();
        var day = info.year * 10000 + info.month * 100 + info.day;
        // Solar calculations are separate from the cheap weather read. Keep
        // successful results until date/location changes; retry failures at 15m.
        var changed = !CityLookup.sameKey(solarKey, cityKey) || solarDay != day;
        if (changed || lastSolarUpdate == null || seconds < lastSolarUpdate ||
            ((solarRises.size() == 0 || solarSets.size() == 0) && seconds - lastSolarUpdate >= 900)) {
            solarKey = cityKey;
            solarDay = day;
            lastSolarUpdate = seconds;
            data.solarInterval = null;
            try {
                refreshSolar(location, now);
            } catch (e) {
                if (solarRises.size() > 0) { solarRises = []; }
                if (solarSets.size() > 0) { solarSets = []; }
            }
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
        solarRises = rises;
        solarSets = sets;
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
