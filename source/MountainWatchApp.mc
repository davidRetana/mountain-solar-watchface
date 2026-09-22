using Toybox.Application;
using Toybox.Background;
using Toybox.Time;
using Toybox.WatchUi;

(:background)
class MountainWatchApp extends Application.AppBase {
    var view;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        Background.registerForTemporalEvent(new Time.Duration(900));
        view = new MountainWatchView();
        return [view];
    }

    function getServiceDelegate() {
        return [new CityService()];
    }

    function onBackgroundData(result) {
        if (view != null && result != null) {
            view.provider.lastMinute = null;
            WatchUi.requestUpdate();
        }
    }
}
