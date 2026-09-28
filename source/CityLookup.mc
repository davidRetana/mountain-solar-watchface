using Toybox.Application.Storage;
using Toybox.Lang;

// Shared by the foreground and the small background service.
(:background)
module CityLookup {
    const CACHE_LIMIT = 8;

    function sameKey(a as Lang.Array<Lang.String> or Null, b as Lang.Array<Lang.String> or Null) as Lang.Boolean {
        return a != null && b != null && a[0].equals(b[0]) && a[1].equals(b[1]);
    }

    function locationKey(location as Toybox.Position.Location) as Lang.Array<Lang.String> {
        var degrees = location.toDegrees();
        // Approx. 1 km precision is sufficient for a city, and avoids sending
        // unnecessarily precise coordinates or requesting every small movement.
        return [degrees[0].format("%.2f"), degrees[1].format("%.2f")];
    }

    function cachedName(key as Lang.Array<Lang.String>) as Lang.String or Null {
        var entries = cacheEntries();
        for (var i = 0; i < entries.size(); i += 1) {
            if (sameKey(entries[i], key)) { return entries[i][2]; }
        }
        return null;
    }

    function validEntry(entry) {
        return entry instanceof Lang.Array && entry.size() == 3 &&
            entry[0] instanceof Lang.String && entry[1] instanceof Lang.String &&
            entry[2] instanceof Lang.String && entry[2].length() > 0;
    }

    function cacheEntries() as Lang.Array<Lang.Array<Lang.String>> {
        var saved = Storage.getValue("cityCache");
        // Read the previous single-location format without losing its city.
        if (validEntry(saved)) { return [saved as Lang.Array<Lang.String>]; }
        var entries = [] as Lang.Array<Lang.Array<Lang.String>>;
        if (saved instanceof Lang.Array) {
            for (var i = 0; i < saved.size() && entries.size() < CACHE_LIMIT; i += 1) {
                if (validEntry(saved[i])) { entries.add(saved[i] as Lang.Array<Lang.String>); }
            }
        }
        return entries;
    }

    // Most recently visited first. Call on arrival or on a successful lookup,
    // not on every minute tick, to avoid repeated persistent writes.
    function remember(key as Lang.Array<Lang.String>, name as Lang.String) as Void {
        var entries = cacheEntries();
        if (entries.size() > 0 && sameKey(entries[0], key) && entries[0][2].equals(name)) {
            return;
        }
        var updated = [[key[0], key[1], name]];
        for (var i = 0; i < entries.size() && updated.size() < CACHE_LIMIT; i += 1) {
            if (!sameKey(entries[i], key)) { updated.add(entries[i]); }
        }
        Storage.setValue("cityCache", updated);
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
