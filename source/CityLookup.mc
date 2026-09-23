using Toybox.Application.Storage;
using Toybox.Lang;

// Shared by the foreground and the small background service.
(:background)
module CityLookup {
    function locationKey(location as Toybox.Position.Location) as Lang.Array<Lang.String> {
        var degrees = location.toDegrees();
        // Approx. 1 km precision is sufficient for a city, and avoids sending
        // unnecessarily precise coordinates or requesting every small movement.
        return [degrees[0].format("%.2f"), degrees[1].format("%.2f")];
    }

    function cachedName(key as Lang.Array<Lang.String>) as Lang.String or Null {
        var cached = Storage.getValue("cityCache");
        if (cached instanceof Lang.Array && cached.size() == 3 &&
            cached[0] instanceof Lang.String && cached[1] instanceof Lang.String &&
            cached[2] instanceof Lang.String &&
            cached[0].equals(key[0]) && cached[1].equals(key[1])) {
            return cached[2];
        }
        return null;
    }

    function responseName(body) {
        if (!(body instanceof Lang.Dictionary)) { return null; }
        var address = body.get("address");
        if (!(address instanceof Lang.Dictionary)) { return null; }
        var fields = ["city", "town", "village", "municipality", "hamlet"];
        for (var i = 0; i < fields.size(); i += 1) {
            var name = address.get(fields[i]);
            if (name instanceof Lang.String && name.length() > 0) { return name; }
        }
        return null;
    }
}
