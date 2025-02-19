import Toybox.Application;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.WatchUi;

class WfApp extends Application.AppBase {
    static var sunriseId as Id;
    static var centerX as Number;
    static var centerY as Number;

    function initialize() {
        AppBase.initialize();

        if (Toybox has :Complications) {
            sunriseId = new Id(Complications.COMPLICATION_TYPE_SUNRISE);
        } else {
            sunriseId = 0 as Id;
        }

        var settings = System.getDeviceSettings();

        centerX = settings.screenWidth / 2;
        centerY = settings.screenHeight / 2;
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
