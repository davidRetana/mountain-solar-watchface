using Toybox.Application.Storage;
using Toybox.Lang;

(:background)
module CityRetry {
    function state() as Lang.Array<Lang.Number> or Null {
        var saved = Storage.getValue("cityRetry");
        if (saved instanceof Lang.Array && saved.size() == 2 &&
            saved[0] instanceof Lang.Number && saved[0] >= 1 && saved[0] <= 4 &&
            saved[1] instanceof Lang.Number) {
            return saved as Lang.Array<Lang.Number>;
        }
        return null;
    }

    function delay(failures) {
        return [300, 900, 1800, 3600][failures - 1];
    }

    function nextAttempt(now) {
        var saved = state();
        // A clock correction must not leave a stale retry deadline indefinitely.
        if (saved == null || now < saved[1]) { return now; }
        var due = saved[1] + delay(saved[0]);
        return due > now ? due : now;
    }

    function beginAttempt(now) {
        var saved = state();
        var failures = saved == null ? 1 : saved[0] + 1;
        if (failures > 4) { failures = 4; }
        // Reserve the retry before networking: a killed/timed-out service also
        // backs off. A successful response removes this provisional failure.
        Storage.setValue("cityRetry", [failures, now]);
    }

    function failed(now) {
        var saved = state();
        Storage.setValue("cityRetry", [saved == null ? 1 : saved[0], now]);
    }

    function succeeded() {
        Storage.deleteValue("cityRetry");
    }
}
