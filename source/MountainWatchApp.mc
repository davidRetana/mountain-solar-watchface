using Toybox.Application;

class MountainWatchApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [new MountainWatchView()];
    }
}
