import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Complications;

class wfDeligate extends WatchUi.WatchFaceDelegate
{
    private var center_y as Number;
    private var center_x as Number;
    private const topId as Id = new Id(Complications.COMPLICATION_TYPE_SUNRISE);
    private const bottomLeftId as Id = new Id(Complications.COMPLICATION_TYPE_CURRENT_WEATHER);
    private const bottomRightId as Id = new Id(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS);

	function initialize(h as Number, w as Number) {
		WatchFaceDelegate.initialize();

		center_y = h/2;
		center_x = w/2;
	}

    function onPress(evt as WatchUi.ClickEvent) {
        var c=evt.getCoordinates();
        if(c[1] < center_y) {
            Complications.exitTo(topId);
        } else if(c[0] < center_x) {
            Complications.exitTo(bottomLeftId);
        } else {
            Complications.exitTo(bottomRightId);
        }
        return true;
    }
}
