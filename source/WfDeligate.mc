import Toybox.Complications;
import Toybox.WatchUi;

class WfDeligate extends WatchUi.WatchFaceDelegate {
	function initialize() {
		WatchFaceDelegate.initialize();
	}

    function onPress(evt as ClickEvent) {
        var coords = evt.getCoordinates();
        if (Rez has :Styles && Rez.Styles has :device_info && Rez.Styles.device_info has :screenWidth && Rez.Styles.device_info has :screenHeight) {
            if(coords[1] < Rez.Styles.device_info.screenHeight as Number / 2) {
                Complications.exitTo(new Complications.Id(Complications.COMPLICATION_TYPE_SUNRISE));
            } else if(coords[0] < Rez.Styles.device_info.screenWidth as Number / 2) {
                Complications.exitTo(new Complications.Id(Complications.COMPLICATION_TYPE_CURRENT_WEATHER));
            } else {
                Complications.exitTo(new Complications.Id(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS));
            }
        } else {
            if(coords[1] < WfView.centerY) {
                Complications.exitTo(new Complications.Id(Complications.COMPLICATION_TYPE_SUNRISE));
            } else if(coords[0] < WfView.centerX) {
                Complications.exitTo(new Complications.Id(Complications.COMPLICATION_TYPE_CURRENT_WEATHER));
            } else {
                Complications.exitTo(new Complications.Id(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS));
            }
        }
        return true;
    }
}
