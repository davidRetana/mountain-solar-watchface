using Toybox.Application.Storage;
using Toybox.Background;
using Toybox.Communications;
using Toybox.System;
using Toybox.Time;
using Toybox.Weather;

(:background)
class CityService extends System.ServiceDelegate {
    var requestKey;

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
        try {
            var weather = Weather.getCurrentConditions();
            var now = Time.now().value();
            if (weather == null || weather.observationTime == null ||
                weather.observationLocationPosition == null) {
                Background.exit(null);
                return;
            }
            var age = now - weather.observationTime.value();
            if (age < 0 || age > 7200) {
                Background.exit(null);
                return;
            }
            requestKey = CityLookup.locationKey(weather.observationLocationPosition);
            if (CityLookup.cachedName(requestKey) != null) {
                Background.exit(null);
                return;
            }
            // Global backoff also covers failures, restarts and a moving user.
            var attempt = Storage.getValue("cityAttempt");
            if (attempt != null && now >= attempt && now - attempt < 3600) {
                Background.exit(null);
                return;
            }
            Storage.setValue("cityAttempt", now);
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
            Background.exit(null);
        }
    }

    function onResponse(code as Toybox.Lang.Number, body as Null or Toybox.Lang.Dictionary or Toybox.Lang.String or Toybox.PersistedContent.Iterator) as Void {
        var name = code == 200 ? CityLookup.responseName(body) : null;
        if (name != null) {
            Storage.setValue("cityCache", [requestKey[0], requestKey[1], name]);
        }
        Background.exit(name);
    }
}
