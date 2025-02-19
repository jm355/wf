import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Complications;

class WfDeligate extends WatchUi.WatchFaceDelegate
{
    private var _centerY as Number;
    private var _centerX as Number;
    private const _topId as Id = new Id(Complications.COMPLICATION_TYPE_SUNRISE);
    private const _bottomLeftId as Id = new Id(Complications.COMPLICATION_TYPE_CURRENT_WEATHER);
    private const _bottomRightId as Id = new Id(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS);

	function initialize(h as Number, w as Number) {
		WatchFaceDelegate.initialize();

		_centerY = h/2;
		_centerX = w/2;
	}

    function onPress(evt as WatchUi.ClickEvent) {
        var coords = evt.getCoordinates();
        if(coords[1] < _centerY) {
            Complications.exitTo(_topId);
        } else if(coords[0] < _centerX) {
            Complications.exitTo(_bottomLeftId);
        } else {
            Complications.exitTo(_bottomRightId);
        }
        return true;
    }
}
