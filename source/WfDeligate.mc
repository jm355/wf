import Toybox.Complications;
import Toybox.WatchUi;

class WfDeligate extends WatchUi.WatchFaceDelegate {
    private const sunriseComplication as Complications.Id = new Complications.Id(Complications.COMPLICATION_TYPE_SUNRISE);
    private const weatherComplication as Complications.Id = new Complications.Id(Complications.COMPLICATION_TYPE_CURRENT_WEATHER);
    private const calendarComplication as Complications.Id = new Complications.Id(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS);

    function initialize() {
        WatchFaceDelegate.initialize();
    }

    function onPress(evt as ClickEvent) {
        var coords = evt.getCoordinates();
        var hasStyles =
            //true;/*
            Rez has :Styles;
            //*/

        if (hasStyles) {
            if(coords[1] < Rez.Styles.device_info.screenHeight as Toybox.Lang.Number / 2) {
                Complications.exitTo(sunriseComplication);
            } else if(coords[0] < Rez.Styles.device_info.screenWidth as Toybox.Lang.Number / 2) {
                Complications.exitTo(weatherComplication);
            } else {
                Complications.exitTo(calendarComplication);
            }
        } else {
            var settings = Toybox.System.getDeviceSettings();
            if(coords[1] < (settings.screenHeight / 2)) {
                Complications.exitTo(sunriseComplication);
            } else if(coords[0] < (settings.screenWidth / 2)) {
                Complications.exitTo(weatherComplication);
            } else {
                Complications.exitTo(calendarComplication);
            }
        }

        return true;
    }
}
