import Toybox.Application;
import Toybox.WatchUi;

class wfApp extends Application.AppBase {

    var view as wfView;
    var input as wfDeligate;
    function initialize() {
        AppBase.initialize();

        var settings = System.getDeviceSettings();

        view = new wfView(settings.screenHeight, settings.screenWidth);
        input = new wfDeligate(settings.screenHeight, settings.screenWidth);
    }

    // onStart() is called on application start up
    //function onStart(state as Dictionary?) as Void {}

    // onStop() is called when your application is exiting
    //function onStop(state as Dictionary?) as Void {}

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ view, input ];
    }
}

function getApp() as wfApp {
    return Application.getApp() as wfApp;
}
