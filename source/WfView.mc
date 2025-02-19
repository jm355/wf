import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Weather;

class WfView extends WatchUi.WatchFace {
    var _dateX as Number;
    var _timeTopLeft as Number;

    var _step as Number;

    var _day as Number;
    var _sunriseTime as Moment;
    var _nextSunriseTime as Moment;
    var _sunsetTime as Moment;
    var _sunTime as Moment;
    var _sunString as String;
    var _sunColor as ColorValue;

    var _dateString as String;

    var _font as VectorFont or FontType;

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

        var halfTimeHeight = Graphics.getFontHeight(_font) / 4;
        _step = halfTimeHeight / 4;

        if (Rez has :Styles) {
            _timeTopLeft = (Rez.Styles.device_info.screenHeight as Number / 2) - halfTimeHeight - 4;
        } else {
            _timeTopLeft = 0;
        }

        _dateX = 0;

        _day = 0;
        _sunriseTime = new Time.Moment(0);
        _sunsetTime = new Time.Moment(0);
        _nextSunriseTime = new Time.Moment(0);
        _sunTime = new Time.Moment(0);
        _sunString = "";
        _sunColor = 0 as ColorValue;

        _dateString = "";
    }

    //// https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/View.html
    /// order of calls: onLayout()->onShow()->onUpdate()
    // Load your resources here
    //function onLayout(dc as Dc) as Void {}

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    //function onShow() as Void {}

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var now = Time.now();
        var date = Gregorian.info(now, Time.FORMAT_MEDIUM);

        var screenWidth, centerX, centerY, dateY, sunY;
        if (Rez has :Styles) {
            screenWidth = Rez.Styles.device_info.screenWidth as Number;
            centerX = screenWidth / 2;
            centerY = Rez.Styles.device_info.screenHeight as Number / 2;

            var quarterScreenHeight = centerY / 2;
            dateY = centerY + quarterScreenHeight;
            sunY = centerY - quarterScreenHeight;
        } else {
            screenWidth = dc.getWidth();
            centerX = screenWidth / 2;
            centerY = dc.getHeight() / 2;

            if (Graphics.Dc has :setClip) {
                _timeTopLeft = centerY - (_step * 4) - 4;
            }

            var quarterScreenHeight = centerY / 2;
            dateY = centerY + quarterScreenHeight;
            sunY = centerY - quarterScreenHeight;
        }

        // Set the color before potentially calling dc.clear() and before drawing time text
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        // If the day has changed, get new data for the sunrise, sunset, and how to display the date
        if (_day != date.day) {
            _day = date.day;

            _dateString = " " + date.month + " " + date.day;

            // Get the x axis offset for displaying the date. This makes it look like there's one centered string, even though it's really two strings being drawn so we can get different colors for the day and date
            _dateX = centerX - ((dc.getTextWidthInPixels(_dateString, Graphics.FONT_MEDIUM) - dc.getTextWidthInPixels(date.day_of_week.toString(), Graphics.FONT_MEDIUM)) / 2);

            // Get sunrise/sunset data
            if (Toybox has :Weather && Weather has :getSunrise) {
                var pos = Position.getInfo().position;

                if (pos == null) {
                    pos = new Location({:latitude => 0, :longitude => 0, :format => :degrees});
                }

                var sunriseTime = Weather.getSunrise(pos, now);
                var sunsetTime = Weather.getSunset(pos, now);
                var nextSunriseTime = Weather.getSunrise(pos, now.add(new Time.Duration(Gregorian.SECONDS_PER_DAY)));
                if (sunriseTime != null && sunsetTime != null && nextSunriseTime != null) {
                    _sunriseTime = sunriseTime;
                    _sunsetTime = sunsetTime;
                    _nextSunriseTime = nextSunriseTime;
                }
            }
        }

        if (Toybox has :Weather && Weather has :getSunrise) {
            if (now.greaterThan(_sunTime)) {
            // The upcoming sun event has passed, update the string.
                if (now.greaterThan(_sunsetTime)) {
                    //re-retrieve sun data next update
                    if(_sunsetTime.value() == 0) {
                        _day = 0;
                    } else {
                        _sunTime = _nextSunriseTime;
                        _sunColor = Graphics.COLOR_YELLOW;
                    }
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
        }

        var moveBarLevel = ActivityMonitor.getInfo().moveBarLevel;
        var timeString;
        if (Graphics.Dc has :setClip) {
            timeString = date.hour + ":" + date.min.format("%02d");
        } else {
            timeString = date.hour.format("%02d") + ":" + date.min.format("%02d");
        }

        // Draw the time with the move bar filling it up
        if (moveBarLevel != null && moveBarLevel > ActivityMonitor.MOVE_BAR_LEVEL_MIN) {
            if (moveBarLevel < ActivityMonitor.MOVE_BAR_LEVEL_MAX) {
                if (Graphics.Dc has :setClip) {
                    // _timeTopLeft has the 4 pixel offset already accounted for
                    var offset = ((ActivityMonitor.MOVE_BAR_LEVEL_MAX - moveBarLevel) * _step) + 4;

                    // Draw the white part of the text.
                    dc.setClip(0, _timeTopLeft, screenWidth, offset);
                    dc.drawText(centerX, centerY, _font, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                    // Draw the red part of the text
                    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                    dc.setClip(0, _timeTopLeft + offset, screenWidth, screenWidth);
                    dc.drawText(centerX, centerY, _font, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                    dc.clearClip();
                } else {
                    var redString = timeString.substring(ActivityMonitor.MOVE_BAR_LEVEL_MIN, moveBarLevel);
                    var whiteString = timeString.substring(moveBarLevel, ActivityMonitor.MOVE_BAR_LEVEL_MAX);

                    if (redString == null) {
                        dc.drawText(centerX, centerY, _font, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                    } else if (whiteString == null) {
                        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(centerX, centerY, _font, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                    } else {
                        var timeX = centerX - ((dc.getTextWidthInPixels(whiteString, _font) - dc.getTextWidthInPixels(redString, _font)) / 2);

                        dc.drawText(timeX, centerY, _font, whiteString, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

                        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(timeX, centerY, _font, redString, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
                    }
                }
            } else {
                // The move bar is full, don't mess with clipping and math when we can just draw the text in red
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, centerY, _font, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        } else {
            // The move bar is empty, don't mess with clipping and math when we can just draw the text in white
            dc.drawText(centerX, centerY, _font, timeString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Draw the sun time and date
        dc.setColor(_sunColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, sunY, Graphics.FONT_MEDIUM, _sunString, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_dateX, dateY, Graphics.FONT_MEDIUM, date.day_of_week, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_dateX, dateY, Graphics.FONT_MEDIUM, _dateString, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
