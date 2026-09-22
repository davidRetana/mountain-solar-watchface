using Toybox.Test;

(:test)
function solarAcrossMidnight(logger) {
    // 14:04 -> 02:21 next day, observed at 15:28 and again at 01:00.
    var rises = [50640 - 86400, 50640, 50640 + 86400];
    var sets = [8460, 8460 + 86400, 8460 + 172800];
    var afternoon = SolarBar.selectInterval(rises, sets, 55680);
    Test.assert(afternoon[0] == 50640 && afternoon[1] == 94860);
    var afterMidnight = SolarBar.selectInterval(rises, sets, 90000);
    Test.assert(afterMidnight[0] == 50640 && afterMidnight[1] == 94860);
    return true;
}

(:test)
function solarDayNightAndMissing(logger) {
    var rises = [21600, 108000];
    var sets = [64800, 151200];
    var day = SolarBar.selectInterval(rises, sets, 43200);
    Test.assert(day[0] == 21600 && day[1] == 64800);
    var night = SolarBar.selectInterval(rises, sets, 72000);
    Test.assert(night[0] == 64800 && night[1] == 108000 && !night[2]);
    Test.assert(SolarBar.selectInterval([], sets, 43200) == null);
    Test.assert(SolarBar.selectInterval(rises, [], 43200) == null);
    return true;
}

(:test)
function solarTransitions(logger) {
    var rises = [21600, 108000];
    var sets = [-21600, 64800, 151200];
    var dawn = SolarBar.selectInterval(rises, sets, 21600);
    Test.assert(dawn[0] == 21600 && dawn[2]);
    var dusk = SolarBar.selectInterval(rises, sets, 64800);
    Test.assert(dusk[0] == 64800 && !dusk[2]);
    var beforeDawn = SolarBar.selectInterval(rises, sets, 21599);
    Test.assert(beforeDawn[0] == -21600 && beforeDawn[1] == 21600 && !beforeDawn[2]);
    Test.assert(SolarBar.selectInterval(rises, sets, 172800) == null);
    return true;
}
