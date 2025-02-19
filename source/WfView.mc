import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Weather;

class WfView extends WatchUi.WatchFace {
    var _screenWidth as Number = 0;
    var _dateX as Number = 0;
    var _dateY as Number = 0;
    var _sunY as Number = 0;
    var _timeTopLeft as Number = 0;

    var _timeHeight as Number;
    var _halfTimeHeight as Number;

    var _day as Number = 0;
    var _sunriseTime as Moment = new Moment(0);
    var _sunsetTime as Moment = new Moment(0);
    var _sunTime as Moment = new Moment(0);
    var _sunString as String = "";
    var _sunColor as ColorValue = Graphics.COLOR_ORANGE;

    var _dateString as String = "";

    var _font as VectorFont or FontType;

    function updateSunTime(now as Moment) as Void {
        if (now.greaterThan(_sunsetTime)) {
            var pos = Position.getInfo().position;
            if (pos != null) {
                var tomorrowSunrise = Weather.getSunrise(pos, now.add(new Time.Duration(Gregorian.SECONDS_PER_DAY)));
                if (tomorrowSunrise != null) {
                    _sunTime = tomorrowSunrise;
                } else {
                    _sunTime = _sunriseTime.add(new Time.Duration(Gregorian.SECONDS_PER_DAY));
                }
            } else {
                _sunTime = _sunriseTime.add(new Time.Duration(Gregorian.SECONDS_PER_DAY));
            }
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

    function initialize() {
        WatchFace.initialize();

        // Hopefully this looks good on non-enduro devices
        // other fonts that look good on enduro 3: "RobotoCondensedRegular" and "KosugiRegular"
        if (Graphics has :getVectorFont) {
            var tempFont = Graphics.getVectorFont({:face => "BionicSemiBold", :size => 156});
            if (tempFont != null) {
                _font = tempFont;
            } else {
                _font = Graphics.FONT_NUMBER_THAI_HOT;
            }
        } else {
            _font = Graphics.FONT_NUMBER_THAI_HOT;
        }

        _timeHeight = Graphics.getFontHeight(_font) / 2;
        _halfTimeHeight = _timeHeight / 2;
    }

    //// https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/View.html
    /// order of calls: onLayout()->onShow()->onUpdate()
    // Load your resources here
    function onLayout(dc as Dc) as Void {
        _screenWidth = dc.getWidth();

        WfApp.centerX = _screenWidth / 2;
        WfApp.centerY = dc.getHeight() / 2;

        if (Graphics has :getVectorFont) {
            _dateY = WfApp.centerY + _halfTimeHeight;
        } else {
            _dateY = WfApp.centerY + _timeHeight;
        }

        _timeTopLeft = WfApp.centerY - _halfTimeHeight - 10;
        if(Toybox has :Weather) {
            _sunY = _timeTopLeft - Graphics.getFontHeight(Graphics.FONT_MEDIUM) + 5;
        } else {
            _sunY = 0;
        }

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

            _dateString = " " + date.month + " " + date.day;

            // Get the x axis offset for displaying the date. This makes it look like there's one centered string, even though it's really two strings being drawn so we can get different colors for the day and date
            _dateX = WfApp.centerX - ((dc.getTextWidthInPixels(_dateString, Graphics.FONT_MEDIUM) - dc.getTextWidthInPixels(date.day_of_week.toString(), Graphics.FONT_MEDIUM)) / 2);

            // Get sunrise/sunset data
            if (Toybox has :Complications) {
                var today = Time.today();
                _sunriseTime = today.add(new Time.Duration(Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_SUNRISE)).value as Number));
                _sunsetTime = today.add(new Time.Duration(Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_SUNSET)).value as Number));

                // Got new sun data, so update the string
                updateSunTime(now);
            } else if (Toybox has :Weather) {
                var pos = Position.getInfo().position;
                if (pos != null) {
                    var sunriseTime = Weather.getSunrise(pos, now);
                    var sunsetTime = Weather.getSunset(pos, now);
                    if (sunriseTime != null) {
                        _sunriseTime = sunriseTime;
                    }
                    if (sunsetTime != null) {
                        _sunsetTime = sunsetTime;
                    }
                    if (_sunriseTime.value() != 0 && _sunsetTime.value() != 0) {
                        // Got new sun data, so update the string
                        updateSunTime(now);
                    }
                }
            }

            // Also clear the screen at the start of the day
            dc.clear();
        } else if (now.greaterThan(_sunTime)) {
            // The upcoming sun event has passed, update the string.
            if (Toybox has :Weather) {
                updateSunTime(now);
            }
        }

        // System.getDeviceSettings().isNightModeEnabled
        var moveBarLevel = ActivityMonitor.getInfo().moveBarLevel;
        var timeString;
        if (Dc has :setClip) {
            timeString = date.hour + ":" + date.min.format("%02d");
        } else {
            timeString = date.hour.format("%02d") + ":" + date.min.format("%02d");
        }

        // Draw the time with the move bar filling it up
        if (moveBarLevel != null && moveBarLevel > ActivityMonitor.MOVE_BAR_LEVEL_MIN) {
            // todo if it doesn't have setclip, go digit by digit
            if (moveBarLevel < ActivityMonitor.MOVE_BAR_LEVEL_MAX) {
                if (Dc has :setClip) {
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
                    var redString = timeString.substring(ActivityMonitor.MOVE_BAR_LEVEL_MIN, moveBarLevel);
                    var whiteString = timeString.substring(moveBarLevel, ActivityMonitor.MOVE_BAR_LEVEL_MAX);

                    if (redString == null) {
                        dc.drawText(WfApp.centerX, WfApp.centerY, _font, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                    } else if (whiteString == null) {
                        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
                        dc.drawText(WfApp.centerX, WfApp.centerY, _font, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                    } else {
                        var timeX = WfApp.centerX - ((dc.getTextWidthInPixels(whiteString, _font) - dc.getTextWidthInPixels(redString, _font)) / 2);

                        dc.drawText(timeX, WfApp.centerY, _font, whiteString, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
                        dc.drawText(timeX, WfApp.centerY, _font, redString, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
                    }
                }
            } else {
                // The move bar is full, don't mess with clipping and math when we can just draw the text in red
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
                dc.drawText(WfApp.centerX, WfApp.centerY, _font, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        } else {
            // The move bar is empty, don't mess with clipping and math when we can just draw the text in white
            dc.drawText(WfApp.centerX, WfApp.centerY, _font, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        if (Toybox has :Weather) {
            // Draw the sun time and date
            dc.setColor(_sunColor, Graphics.COLOR_BLACK);
            dc.drawText(WfApp.centerX, _sunY, Graphics.FONT_MEDIUM, _sunString, Graphics.TEXT_JUSTIFY_CENTER);
        }

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        dc.drawText(_dateX, _dateY, Graphics.FONT_MEDIUM, date.day_of_week, Graphics.TEXT_JUSTIFY_RIGHT);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_BLACK);
        dc.drawText(_dateX, _dateY, Graphics.FONT_MEDIUM, _dateString, Graphics.TEXT_JUSTIFY_LEFT);
    }
}
