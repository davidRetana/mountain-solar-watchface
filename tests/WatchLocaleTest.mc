using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Test;
using Toybox.Time;
using Toybox.Time.Gregorian;

(:test)
class TestWatchLocale extends WatchLocale {
    var loads = 0;
    function initialize() { WatchLocale.initialize(); }
    function readLabels() as Lang.Array<Lang.String> {
        loads += 1;
        if (language == System.LANGUAGE_SPA) { return ["MIN", "d", "."]; }
        if (language == System.LANGUAGE_JPN) { return ["分", "日", ","]; }
        return ["MIN", "d", ","];
    }
}

(:test)
function localeFormattingAndResourceCaching(logger) {
    var locale = new TestWatchLocale();
    Test.assert(locale.refresh(System.LANGUAGE_SPA));
    Test.assert(Formatters.count(12345, locale).equals("12.345"));
    Test.assert(!locale.refresh(System.LANGUAGE_SPA) && locale.loads == 1);
    Test.assert(locale.refresh(System.LANGUAGE_ENG));
    Test.assert(Formatters.count(12345, locale).equals("12,345"));
    Test.assert(Formatters.count(null, locale).equals("--"));
    Test.assert(Formatters.heartAge(1000, 1000, locale).equals("<1 MIN"));
    Test.assert(Formatters.heartAge(1000, 1060, locale).equals("1 MIN"));
    Test.assert(Formatters.heartAge(1060, 1000, locale).equals("--"));
    locale.refresh(System.LANGUAGE_JPN);
    Test.assert(locale.needsSystemFont());
    Test.assert(Formatters.heartAge(1000, 1120, locale).equals("2 分"));
    var data = new WatchData();
    data.locale = locale;
    data.batteryDays = 12;
    Test.assert(Formatters.batteryText(data).equals("12 日"));
    data.batteryDays = 0.5;
    Test.assert(Formatters.batteryText(data).equals("<1 日"));
    data.batteryDays = null;
    data.battery = 50;
    Test.assert(Formatters.batteryText(data).equals("50%"));
    return true;
}

(:test)
function presentationInvalidatesWhenLanguageChanges(logger) {
    var dc = new EfficiencyDc();
    var cache = new WatchPresentation(7, 5, 10);
    var data = new WatchData();
    data.locale = new TestWatchLocale();
    data.locale.refresh(System.LANGUAGE_SPA);
    data.steps = 1234;
    data.stepGoal = 10000;
    data.batteryDays = 12;
    data.heartRateWhen = 1000;
    data.updatedAt = 1120;
    cache.prepare(dc, data, 1);
    Test.assert(cache.stepsText.equals("1.234"));
    var measurements = dc.measurements;
    data.locale.refresh(System.LANGUAGE_JPN);
    cache.prepare(dc, data, 1); // Same snapshot revision, different language.
    Test.assert(cache.stepsText.equals("1,234") && cache.goalText.equals(" / 10,000"));
    Test.assert(cache.heartAgeText.equals("2 分") && cache.batteryText.equals("12 日"));
    Test.assert(dc.measurements > measurements);
    measurements = dc.measurements;
    cache.prepare(dc, data, 1);
    Test.assert(dc.measurements == measurements);
    return true;
}

(:test)
class LocaleEfficiencyProvider extends EfficiencyProvider {
    var language = System.LANGUAGE_ENG;
    var calendarReads = 0;
    function initialize() {
        EfficiencyProvider.initialize();
        data.locale = new TestWatchLocale();
    }
    function readLanguage() { return language; }
    function readCalendar(now) {
        calendarReads += 1;
        // Use a real Gregorian.Info with controllable strings for this test.
        var info = Gregorian.info(now, Time.FORMAT_MEDIUM);
        info.day_of_week = language == System.LANGUAGE_SPA ? "dom" : "sun";
        info.month = language == System.LANGUAGE_SPA ? "jun" : "jun";
        return info;
    }
}

(:test)
function languageChangesRefreshCalendarWithoutExtraDataReads(logger) {
    var provider = new LocaleEfficiencyProvider();
    provider.refresh();
    Test.assert(provider.data.weekdayText.equals("SUN") && provider.calendarReads == 1);
    provider.clock += 60;
    provider.refresh();
    Test.assert(provider.calendarReads == 1 && provider.data.locale.loads == 1);
    var activity = provider.activityReads;
    var battery = provider.batteryReads;
    var weather = provider.weatherReads;
    var revision = provider.revision;
    provider.language = System.LANGUAGE_SPA;
    provider.invalidateLocale();
    provider.refresh();
    Test.assert(provider.data.weekdayText.equals("DOM") && provider.calendarReads == 2);
    Test.assert(provider.revision == revision + 1 && provider.data.locale.loads == 2);
    Test.assert(provider.activityReads == activity && provider.batteryReads == battery &&
        provider.weatherReads == weather);
    provider.invalidateLocale();
    provider.refresh();
    Test.assert(provider.revision == revision + 1 && provider.calendarReads == 2);
    return true;
}

(:test)
function calendarUsesWatchLanguage(logger) {
    var provider = new EfficiencyProvider();
    provider.refresh();
    var calendar = Gregorian.info(new Time.Moment(provider.clock), Time.FORMAT_MEDIUM);
    Test.assert(provider.data.weekdayText.equals(calendar.day_of_week.toUpper()));
    Test.assert(provider.data.monthText.equals(calendar.month.toUpper()));
    Test.assert(provider.data.locale.minuteUnit.equals(
        Toybox.Application.loadResource(Rez.Strings.MinuteUnit)));
    return true;
}
