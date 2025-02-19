import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class WfApp extends Application.AppBase {
    static var centerX as Number = 0;
    static var centerY as Number = 0;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    //function onStart(state as Dictionary?) as Void {}

    // onStop() is called when your application is exiting
    //function onStop(state as Dictionary?) as Void {}

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        if (Toybox has :Complications) {
            return [ new WfView(), new WfDeligate() ];
        } else {
            return [ new WfView() ];
        }
    }
}

function getApp() as WfApp {
    return Application.getApp() as WfApp;
}
