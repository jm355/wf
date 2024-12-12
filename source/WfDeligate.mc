import Toybox.Complications;
import Toybox.WatchUi;

class WfDeligate extends WatchUi.WatchFaceDelegate
{
    private static const _bottomLeftId as Id = new Id(Complications.COMPLICATION_TYPE_CURRENT_WEATHER);
    private static const _bottomRightId as Id = new Id(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS);

	function initialize() {
		WatchFaceDelegate.initialize();
	}

    function onPress(evt as ClickEvent) {
        var coords = evt.getCoordinates();
        if(coords[1] < WfApp.centerY) {
            Complications.exitTo(WfApp.sunriseId);
        } else if(coords[0] < WfApp.centerX) {
            Complications.exitTo(_bottomLeftId);
        } else {
            Complications.exitTo(_bottomRightId);
        }
        return true;
    }
}
