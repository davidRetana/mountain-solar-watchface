using Toybox.Math;
using Toybox.Lang;

// Canonical 260px design. Compute geometry once, never scale a framebuffer.
class WatchLayout {
    var width;
    var height;
    var scale;
    var offsetX;
    var offsetY;
    var centerX;
    var centerY;
    var dayY;
    var timeY;
    var timeWidth;
    var dateRadius;
    var dateLeftX;
    var dateRightX;
    var dateY;
    var cityX;
    var cityY;
    var cityWidth;
    var temperatureX;
    var pin as Lang.Array<Lang.Number>;
    var thermometer as Lang.Array<Lang.Number>;
    var leftSole as Lang.Array<Lang.Array<Lang.Number>>;
    var rightSole as Lang.Array<Lang.Array<Lang.Number>>;
    var leftHeel as Lang.Array<Lang.Number>;
    var rightHeel as Lang.Array<Lang.Number>;
    var stepsX;
    var stepsY;
    var stepsBar as Lang.Array<Lang.Number>;
    var stepsTextWidth;
    var dividers as Lang.Array<Lang.Array<Lang.Number>>;
    var heart as Lang.Array<Lang.Array<Lang.Number>>;
    var heartLeft as Lang.Array<Lang.Number>;
    var heartRight as Lang.Array<Lang.Number>;
    var heartX;
    var heartY;
    var heartAgeY;
    var mountain as Lang.Array<Lang.Array<Lang.Number>>;
    var valueY;
    var elevationWidth;
    var battery as Lang.Array<Lang.Number>;
    var batteryCap as Lang.Array<Lang.Number>;
    var batteryFill as Lang.Array<Lang.Number>;
    var batteryX;
    var solarStartX;
    var solarEndX;
    var solarY;
    var solarLine as Lang.Array<Lang.Number>;
    var solarTrack as Lang.Array<Lang.Number>;
    // Marker offsets move with the sun/moon; sizes themselves stay cached.
    var marker2;
    var marker3;
    var marker4;
    var marker5;
    var marker6;
    var marker8;
    var marker9;

    function initialize(w, h) {
        width = w;
        height = h;
        scale = (w < h ? w : h).toFloat() / 260;
        offsetX = (w - 260 * scale) / 2;
        offsetY = (h - 260 * scale) / 2;
        centerX = x(130);
        centerY = y(130);
        dayY = y(25);
        timeY = y(124);
        timeWidth = size(232);
        dateRadius = size(109);
        dateLeftX = x(85);
        dateRightX = x(175);
        dateY = y(20);
        cityX = x(64);
        cityY = y(74);
        cityWidth = size(88);
        temperatureX = x(202);
        pin = rectangle(50, 68, 9, 14);
        thermometer = rectangle(163, 66, 13, 17);
        leftSole = points([[36, 182], [37, 179], [40, 179], [41, 182], [40, 187], [37, 187]]);
        rightSole = points([[44, 178], [45, 175], [48, 175], [49, 178], [48, 183], [45, 183]]);
        leftHeel = rectangle(37, 189, 4, 4);
        rightHeel = rectangle(45, 185, 4, 4);
        stepsX = x(60);
        stepsY = y(174);
        stepsBar = rectangle(60, 184, 156, 7);
        stepsTextWidth = size(150);
        dividers = [[x(100), y(201), x(100), y(233)], [x(160), y(201), x(160), y(233)]];
        heart = points([[68, 204], [80, 204], [74, 212]]);
        heartLeft = [x(71), y(204), size(3)];
        heartRight = [x(77), y(204), size(3)];
        heartX = x(74);
        heartY = y(221);
        heartAgeY = y(236);
        mountain = points([[120, 213], [124, 207], [126, 209], [130, 201], [134, 208], [136, 206], [140, 213]]);
        valueY = y(224);
        elevationWidth = size(56);
        battery = rectangle(179, 202, 16, 10);
        batteryCap = rectangle(195, 205, 2, 4);
        batteryFill = rectangle(181, 204, 12, 6);
        batteryX = x(186);
        solarStartX = x(38);
        solarEndX = x(222);
        solarY = y(54);
        solarLine = rectangle(80, 53, 100, 2);
        solarTrack = rectangle(90, 53, 80, 2);
        marker2 = size(2);
        marker3 = size(3);
        marker4 = size(4);
        marker5 = size(5);
        marker6 = size(6);
        marker8 = size(8);
        marker9 = size(9);
    }

    function x(value) { return Math.round(offsetX + value * scale).toNumber(); }
    function y(value) { return Math.round(offsetY + value * scale).toNumber(); }
    function size(value) {
        var result = Math.round(value * scale).toNumber();
        return result < 1 ? 1 : result;
    }
    function rectangle(left, top, w, h) as Lang.Array<Lang.Number> { return [x(left), y(top), size(w), size(h)]; }
    function points(values as Lang.Array<Lang.Array<Lang.Number>>) as Lang.Array<Lang.Array<Lang.Number>> {
        for (var i = 0; i < values.size(); i += 1) {
            values[i][0] = x(values[i][0]);
            values[i][1] = y(values[i][1]);
        }
        return values;
    }
}
