// Snapshot used by the view. Missing readings remain null.
class WatchData {
    var updatedAt = 0;
    var utcOffset = 0;
    var timeText = "--:--";
    var dayText = "--";
    var weekdayText = "--";
    var monthText = "--";
    var heartRate = null;
    var heartRateWhen = null;
    var elevation = null;
    var elevationWhen = null;
    var city = null;
    var temperature = null;
    var weatherWhen = null;
    var solarInterval as Toybox.Lang.Array or Null = null;
    var steps = null;
    var stepGoal = null;
    var battery = null;
    var batteryDays = null;
}
