import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Complications;
import Toybox.Lang;

class WfApp extends Application.AppBase {

    private var _view as WfView;
    private const _input = new WfDeligate();

    static const sunriseId = new Id(Complications.COMPLICATION_TYPE_SUNRISE);
    static var centerX as Number;
    static var centerY as Number;

    function initialize() {
        AppBase.initialize();

        var settings = System.getDeviceSettings();

        centerX = settings.screenWidth / 2;
        centerY = settings.screenHeight / 2;

        _view = new WfView(settings.screenWidth);
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
