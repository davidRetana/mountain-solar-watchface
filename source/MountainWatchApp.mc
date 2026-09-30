using Toybox.Application;
using Toybox.Background;
using Toybox.WatchUi;

(:background)
class MountainWatchApp extends Application.AppBase {
    var view;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        // Remove the legacy periodic event and re-evaluate current Weather.
        Background.deleteTemporalEvent();
        view = new MountainWatchView();
        return [view];
    }

    function getServiceDelegate() {
        return [new CityService()];
    }

    function onBackgroundData(result) {
        if (view != null && result != null) {
            view.provider.invalidateWeather();
            // The service may have resolved a newer weather location.
            // Reload its coordinates before matching the city cache.
            WatchUi.requestUpdate();
        }
    }
}
