using Toybox.Test;
using Toybox.Application.Storage;
using Toybox.Position;

(:test)
function cityResponseParsing(logger) {
    Test.assert(CityLookup.responseName({"address" => {"city" => "Madrid"}}).equals("Madrid"));
    Test.assert(CityLookup.responseName({"address" => {"town" => "Jaca"}}).equals("Jaca"));
    Test.assert(CityLookup.responseName({"address" => {"city" => "", "village" => "Torla"}}).equals("Torla"));
    Test.assert(CityLookup.responseName({"address" => {"county" => "Huesca"}}) == null);
    Test.assert(CityLookup.responseName({"address" => {"city" => 1}}) == null);
    Test.assert(CityLookup.responseName({"error" => "No result"}) == null);
    Test.assert(CityLookup.responseName("unavailable") == null);
    Test.assert(CityLookup.responseName(null) == null);
    return true;
}

(:test)
function cityCacheFollowsLocation(logger) {
    var previous = Storage.getValue("cityCache");
    Storage.setValue("cityCache", ["40.42", "-3.70", "Madrid"]);
    var same = CityLookup.cachedName(["40.42", "-3.70"]);
    var moved = CityLookup.cachedName(["42.57", "-0.55"]);
    if (previous == null) { Storage.deleteValue("cityCache"); }
    else { Storage.setValue("cityCache", previous); }
    Test.assert(same.equals("Madrid"));
    Test.assert(moved == null);
    return true;
}

(:test)
function cityCacheRejectsMalformedValues(logger) {
    var previous = Storage.getValue("cityCache");
    var key = ["40.42", "-3.70"];
    var invalidValues = ["Madrid", [], ["40.42"], ["40.42", "-3.70", 1],
        [null, "-3.70", "Madrid"], ["40.42", null, "Madrid"]];
    var rejected = true;
    for (var i = 0; i < invalidValues.size(); i += 1) {
        Storage.setValue("cityCache", invalidValues[i]);
        if (CityLookup.cachedName(key) != null) { rejected = false; }
    }
    if (previous == null) { Storage.deleteValue("cityCache"); }
    else { Storage.setValue("cityCache", previous); }
    Test.assert(rejected);
    return true;
}
