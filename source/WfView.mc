import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Complications;

class WfView extends WatchUi.WatchFace {
    private static var _screenWidth as Number;
    private var _dateX as Number = 0;
    private static var _dateY as Number;
    private static var _sunY as Number;
    private static var _timeTopLeft as Number;

    private static var _timeHeight as Number;
    private static var _halfTimeHeight as Number;

    private var _day as Number = 0;
    private var _nextSunriseTime as Moment = new Moment(0);
    private var _sunriseTime as Moment = new Moment(0);
    private var _sunsetTime as Moment = new Moment(0);
    private var _sunTime as Moment = new Moment(0);
    private var _sunString as String = "";
    private var _sunColor as ColorValue = Graphics.COLOR_ORANGE;

    private var _dayString as String = "";
    private var _dateString as String = "";

    private static var _font as VectorFont or FontType;

    private static const _sunsetId = new Id(Complications.COMPLICATION_TYPE_SUNSET);
    private static const _secsPerDay = new Time.Duration(Gregorian.SECONDS_PER_DAY);

    function updateSunTime(now as Moment) as Void {
        if (now.greaterThan(_sunsetTime)) {
            _sunTime = _nextSunriseTime;
            _sunColor = Graphics.COLOR_YELLOW;
        } else if (now.greaterThan(_sunriseTime)) {
            _sunTime = _sunsetTime;
            _sunColor = Graphics.COLOR_ORANGE;
        } else {
            _sunTime = _sunriseTime;
            _sunColor = Graphics.COLOR_YELLOW;
        }

        var gregorianSunTime = Gregorian.info(_sunTime, Time.FORMAT_SHORT);
        _sunString = gregorianSunTime.hour + ":" + gregorianSunTime.min.format("%02d");
    }

    function initialize(w as Number) {
        WatchFace.initialize();

        // Hopefully this looks good on non-enduro devices
        // other fonts that look good on enduro 3: "RobotoCondensedRegular" and "KosugiRegular"
        var tempFont = Graphics.getVectorFont({:face => "BionicSemiBold", :size => 155});
        if (tempFont != null) {
            _font = tempFont;
        } else {
            _font = Graphics.FONT_SYSTEM_NUMBER_THAI_HOT;
        }

        _timeHeight = Graphics.getFontHeight(_font) / 2;
        _halfTimeHeight = _timeHeight / 2;

		_screenWidth = w;
        _dateY = WfApp.centerY + _halfTimeHeight;

        _timeTopLeft = WfApp.centerY - _halfTimeHeight - 10;
        _sunY = _timeTopLeft - Graphics.getFontHeight(Graphics.FONT_SYSTEM_MEDIUM) + 5;
    }

    //// https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/View.html
    /// order of calls: onLayout()->onShow()->onUpdate()
    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // We can limit the number of calls to dc.clear() by only running it on layout and at the start of the day, because the text only gets wider throughout the day
        // Unfortunately, the device clears the screen before calling onUpdate in high power mode (i.e. on wrist gesture), so we can't check the minute to decide whether to exit onUpdate() early
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    //function onShow() as Void {}

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var now = Time.now();
        var date = Gregorian.info(now, Time.FORMAT_MEDIUM);

        // Set the color before potentially calling dc.clear() and before drawing time text
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        // If the day has changed, get new data for the sunrise, sunset, and how to display the date
        if (_day != date.day) {
            _day = date.day;

            _dayString = date.day_of_week + " ";
            _dateString = date.month + " " + date.day;

            // Get the x axis offset for displaying the date. This makes it look like there's one centered string, even though it's really two strings being drawn so we can get different colors for the day and date
            _dateX = WfApp.centerX - ((dc.getTextWidthInPixels(_dateString, Graphics.FONT_SYSTEM_MEDIUM) - dc.getTextWidthInPixels(_dayString, Graphics.FONT_SYSTEM_MEDIUM)) / 2);

            // Get sunrise/sunset data
            var today = Time.today();

            // We have yesterdays _sunriseTime, so we can calculate the sunrise offset. At this point _sunriseTime is for yesterday, so pull it up to today
            if (_sunriseTime.value() != 0) {
                _nextSunriseTime = _sunriseTime.add(_secsPerDay);
            }

            _sunriseTime = today.add(new Time.Duration(Complications.getComplication(WfApp.sunriseId).value as Number));
            _sunsetTime = today.add(new Time.Duration(Complications.getComplication(_sunsetId).value as Number));

            // Similar to above, _nextSunriseTime has been set, so we can compare it to the new _sunriseTime to get the amount to adjust by for a slightly more accurate _nextSunriseTime. Add a day to make _nextSunriseTime the sunrise time for tomorrow
            if (_nextSunriseTime.value() != 0) {
                _nextSunriseTime = _sunriseTime.add(new Time.Duration(_sunriseTime.compare(_nextSunriseTime) + Gregorian.SECONDS_PER_DAY));
            } else {
                // We didn't have the old sunrise time, so just naively add a day to _sunriseTime
                _nextSunriseTime = _sunriseTime.add(_secsPerDay);
            }

            // Got new sun data, so update the string
            updateSunTime(now);

            // Also clear the screen at the start of the day
            dc.clear();
        } else if (now.greaterThan(_sunTime)) {
            // The upcoming sun event has passed, update the string.
            updateSunTime(now);
        }

        var timeString = date.hour + ":" + date.min.format("%02d");
        var moveBarLevel = ActivityMonitor.getInfo().moveBarLevel;

        // Draw the time with the move bar filling it up
        if (moveBarLevel != null && moveBarLevel > ActivityMonitor.MOVE_BAR_LEVEL_MIN) {
            if (moveBarLevel < ActivityMonitor.MOVE_BAR_LEVEL_MAX) {
                var clipScale = (moveBarLevel - 1) / 4.0f;

                // Draw the white part of the text. _timeTopLeft has the 10 pixel offset already accounted for
                dc.setClip(0, _timeTopLeft, _screenWidth, (_halfTimeHeight * (1 - clipScale)) + 10);
                dc.drawText(WfApp.centerX, WfApp.centerY, _font, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                // Draw the red part of the text
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
                dc.setClip(0, WfApp.centerY - (_halfTimeHeight * clipScale), _screenWidth, _timeHeight);
                dc.drawText(WfApp.centerX, WfApp.centerY, _font, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                dc.clearClip();
            } else {
                // The move bar is full, don't mess with clipping and math when we can just draw the text in red
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
                dc.drawText(WfApp.centerX, WfApp.centerY, _font, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        } else {
            // The move bar is empty, don't mess with clipping and math when we can just draw the text in white
            dc.drawText(WfApp.centerX, WfApp.centerY, _font, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Draw the sun time and date
        dc.setColor(_sunColor, Graphics.COLOR_BLACK);
        dc.drawText(WfApp.centerX, _sunY, Graphics.FONT_SYSTEM_MEDIUM, _sunString, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        dc.drawText(_dateX, _dateY, Graphics.FONT_SYSTEM_MEDIUM, _dayString, Graphics.TEXT_JUSTIFY_RIGHT);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_BLACK);
        dc.drawText(_dateX, _dateY, Graphics.FONT_SYSTEM_MEDIUM, _dateString, Graphics.TEXT_JUSTIFY_LEFT);
    }
}
