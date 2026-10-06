using Toybox.Application;
using Toybox.Lang;
using Toybox.System;

// Garmin selects resource translations using the watch language. Keep the
// small labels cached; redraws must not reload resources or device settings.
class WatchLocale {
    var language = null;
    var revision = 0;
    var minuteUnit = "MIN";
    var dayUnit = "d";
    var groupSeparator = ".";

    function initialize() {}

    function refresh(nextLanguage) {
        if (language != null && language == nextLanguage) { return false; }
        language = nextLanguage;
        var labels = readLabels();
        minuteUnit = labels[0];
        dayUnit = labels[1];
        groupSeparator = labels[2];
        revision += 1;
        return true;
    }

    function readLabels() as Lang.Array<Lang.String> {
        return [Application.loadResource(Rez.Strings.MinuteUnit) as Lang.String,
            Application.loadResource(Rez.Strings.DayUnit) as Lang.String,
            Application.loadResource(Rez.Strings.GroupSeparator) as Lang.String];
    }

    function needsSystemFont() {
        return language == System.LANGUAGE_ARA || language == System.LANGUAGE_HEB ||
            language == System.LANGUAGE_GRE || language == System.LANGUAGE_BUL ||
            language == System.LANGUAGE_RUS || language == System.LANGUAGE_UKR ||
            language == System.LANGUAGE_CHS || language == System.LANGUAGE_CHT ||
            language == System.LANGUAGE_JPN || language == System.LANGUAGE_KOR ||
            language == System.LANGUAGE_THA;
    }
}
