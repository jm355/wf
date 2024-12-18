import Toybox.Complications;
import Toybox.WatchUi;

class WfDeligate extends WatchUi.WatchFaceDelegate {
	function initialize() {
		WatchFaceDelegate.initialize();
	}

    function onPress(evt as ClickEvent) {
        var coords = evt.getCoordinates();
        if(coords[1] < WfView.centerY) {
            Complications.exitTo(new Complications.Id(Complications.COMPLICATION_TYPE_SUNRISE));
        } else if(coords[0] < WfView.centerX) {
            Complications.exitTo(new Complications.Id(Complications.COMPLICATION_TYPE_CURRENT_WEATHER));
        } else {
            Complications.exitTo(new Complications.Id(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS));
        }
        return true;
    }
}
