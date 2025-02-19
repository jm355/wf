import Toybox.Application;
import Toybox.WatchUi;

class WfApp extends Application.AppBase {

    private var _view as WfView;
    private var _input as WfDeligate;
    function initialize() {
        AppBase.initialize();

        var settings = System.getDeviceSettings();

        _view = new WfView(settings.screenHeight, settings.screenWidth);
        _input = new WfDeligate(settings.screenHeight, settings.screenWidth);
    }

    // onStart() is called on application start up
    //function onStart(state as Dictionary?) as Void {}

    // onStop() is called when your application is exiting
    //function onStop(state as Dictionary?) as Void {}

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ _view, _input ];
    }
}

function getApp() as WfApp {
    return Application.getApp() as WfApp;
}
