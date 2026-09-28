using Toybox.Background;
using Toybox.Time;

// Foreground only. A single Moment replaces the old recurring 15-minute event.
class CityScheduler {
    function initialize() {}

    function update(needed, now) {
        var registered = registeredTime();
        if (!needed) {
            if (registered != null) { cancel(); }
            return;
        }
        var last = lastEventTime();
        var due = CityRetry.nextAttempt(now);
        if (last != null && due < last.value() + 300) {
            due = last.value() + 300;
        }
        if (registered instanceof Time.Moment) {
            var scheduled = registered.value();
            if (scheduled == due) { return; }
            // Keep a due event which Garmin has not dispatched yet. Moving it
            // forward every minute could starve the background service.
            if (scheduled <= now && due <= now &&
                (last == null || scheduled > last.value())) { return; }
        }
        register(new Time.Moment(due));
    }

    function registeredTime() { return Background.getTemporalEventRegisteredTime(); }
    function lastEventTime() { return Background.getLastTemporalEventTime(); }
    function register(when) { Background.registerForTemporalEvent(when); }
    function cancel() { Background.deleteTemporalEvent(); }
}
