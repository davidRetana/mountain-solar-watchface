using Toybox.Background;
using Toybox.Communications;
using Toybox.System;
using Toybox.Time;
using Toybox.Weather;

(:background)
class CityService extends System.ServiceDelegate {
    var requestKey as Toybox.Lang.Array<Toybox.Lang.String> or Null = null;

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
        try {
            // Consume the one-shot event, including any registration left by
            // an older build. The foreground schedules only pending work.
            Background.deleteTemporalEvent();
            var weather = Weather.getCurrentConditions();
            var now = Time.now().value();
            if (weather == null || weather.observationTime == null ||
                weather.observationLocationPosition == null) {
                System.println("CityService: weather observation or coordinates unavailable");
                Background.exit(true);
                return;
            }
            var age = now - weather.observationTime.value();
            if (age < 0 || age > 7200) {
                System.println("CityService: weather observation expired or in the future");
                Background.exit(true);
                return;
            }
            requestKey = CityLookup.locationKey(weather.observationLocationPosition);
            var cached = CityLookup.cachedName(requestKey);
            if (cached != null) {
                System.println("CityService: using cached city");
                Background.exit(true);
                return;
            }
            var due = CityRetry.nextAttempt(now);
            if (due > now) {
                System.println("CityService: retry in " + (due - now).toString() + " seconds");
                Background.exit(true);
                return;
            }
            CityRetry.beginAttempt(now);
            System.println("CityService: requesting city from Nominatim");
            Communications.makeWebRequest("https://nominatim.openstreetmap.org/reverse", {
                "lat" => requestKey[0], "lon" => requestKey[1],
                "format" => "jsonv2", "zoom" => "10", "addressdetails" => "1",
                "accept-language" => "es"
            }, {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
                :headers => {"User-Agent" => "MountainSolarWatchface/1.0 (https://github.com/davidRetana/mountain-solar-watchface)"}
            }, method(:onResponse));
        } catch (e) {
            System.println("CityService: failed: " + e.toString());
            CityRetry.failed(Time.now().value());
            Background.exit(true);
        }
    }

    function onResponse(code as Toybox.Lang.Number, body as Null or Toybox.Lang.Dictionary or Toybox.Lang.String or Toybox.PersistedContent.Iterator) as Void {
        var name = code == 200 ? CityLookup.responseName(body) : null;
        if (name != null && requestKey != null) {
            CityLookup.remember(requestKey, name);
            CityRetry.succeeded();
            System.println("CityService: city cached successfully");
        } else {
            CityRetry.failed(Time.now().value());
            System.println("CityService: no city returned, response code " + code.toString());
        }
        Background.exit(true);
    }
}
