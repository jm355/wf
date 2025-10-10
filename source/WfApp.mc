import Toybox.Application;
import Toybox.WatchUi;

class WfApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    //function onStart(state as Dictionary?) as Void {}

    // onStop() is called when your application is exiting
    //function onStop(state as Dictionary?) as Void {}

    // Return the initial view of your application here
    function getInitialView() as [Views] {
        return [ new WfView() ];
    }
}

function getApp() as WfApp {
    return Application.getApp() as WfApp;
}
