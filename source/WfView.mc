import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Complications;

class WfView extends WatchUi.WatchFace {
    private var _screenWidth as Number;
    private var _dateX as Number;
    private var _dateY as Number;
    private var _sunY as Number;
    private var _timeTopLeft as Number;

    private var _timeHeight as Number;
    private var _halfTimeHeight as Number;

    private var _day as Number;
    private var _sunriseOffset as Number;
    private var _sunriseTime as Moment;
    private var _sunsetTime as Moment;
    private var _sunTime as Moment;
    private var _sunString as String;
    private var _sunColor as ColorValue;

    private var _dayString as String;
    private var _dateString as String;

    private var _font as VectorFont or FontType;

    private const _sunsetId = new Id(Complications.COMPLICATION_TYPE_SUNSET);
    private const _secsPerDay = new Time.Duration(Gregorian.SECONDS_PER_DAY);

    // debug stuff
    //private var cbCount as Number = 0;

    function updateSunTime(now as Moment) as Void {
        if(now.lessThan(_sunriseTime)) {
            _sunTime = _sunriseTime;
            _sunColor = Graphics.COLOR_YELLOW;
        } else if(now.lessThan(_sunsetTime)) {
            _sunTime = _sunsetTime;
            _sunColor = Graphics.COLOR_ORANGE;
        } else {
            _sunColor = Graphics.COLOR_YELLOW;
            _sunTime = _sunriseTime.add(new Time.Duration(_sunriseOffset)).add(_secsPerDay);
        }

        var gregorianSunTime = Gregorian.info(_sunTime, Time.FORMAT_SHORT);
        _sunString = gregorianSunTime.hour + ":" + gregorianSunTime.min.format("%02d");

        Storage.setValue('s', [_sunTime.value(), _sunString, _sunColor]);
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

        // debug stuff
        //Storage.clearValues();

        // If we fail to load sun and date data from memory, fall back to initializing it cleanly, and clear any bad data in storage. Fresh data will be stored in the first call to onUpdate
        try {
            var sunData = Storage.getValue('s') as [Number, String, ColorValue];
            _sunTime = new Moment(sunData[0]);
            _sunString = sunData[1];
            _sunColor = sunData[2];

            var dateData = Storage.getValue('d') as [Number, Number, String, String, Number, Number, Number];
            _day = dateData[0];
            _dateX = dateData[1];
            _dayString = dateData[2];
            _dateString = dateData[3];
            _sunriseTime = new Moment(dateData[4]);
            _sunsetTime = new Moment(dateData[5]);
            _sunriseOffset = dateData[6];
        } catch( ex ) {
            Storage.clearValues();

            _sunTime = new Moment(0);
            _sunString = "";
            _sunColor = Graphics.COLOR_ORANGE;

            _day = 0;
            _dateX = 0;
            _dayString = "";
            _dateString = "";
            // This makes it so the oldSunriseTime logic below works even on the initial run, except in this case the _sunriseOffset will be 0. That's fine, it's not that important and every other time after the initial run will have a real value to work with. Could get wonky if the user uses this face, then switches to another one, then switches back, but it'll only be off for a day and only affect the sunrise time displayed between sunset and midnight of the first run after a long hiatus
            _sunriseTime = Time.today().add(new Time.Duration(Complications.getComplication(WfApp.sunriseId).value as Number)).subtract(_secsPerDay) as Moment;
            _sunsetTime = new Moment(0);
            _sunriseOffset = 0;
        }
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

        // debug stuff
        //cbCount = cbCount + 1;
        //dc.drawText(_dateX, 30, Graphics.FONT_SYSTEM_MEDIUM, "c" + cbCount + "s" + date.sec, Graphics.TEXT_JUSTIFY_CENTER);

        // If the day has changed, get new data for the sunrise, sunset, and how to display the date
        if(_day != date.day) {
            _day = date.day;

            _dayString = date.day_of_week + " ";
            _dateString = date.month + " " + date.day;

            // Get the x axis offset for displaying the date. This makes it look like there's one centered string, even though it's really two strings being drawn so we can get different colors for the day and date
            _dateX = WfApp.centerX - ((dc.getTextWidthInPixels(_dateString, Graphics.FONT_SYSTEM_MEDIUM) - dc.getTextWidthInPixels(_dayString, Graphics.FONT_SYSTEM_MEDIUM)) / 2);

            var oldSunriseTime = _sunriseTime.add(_secsPerDay);
            var today = Time.today();

            _sunriseTime = today.add(new Time.Duration(Complications.getComplication(WfApp.sunriseId).value as Number));
            _sunsetTime = today.add(new Time.Duration(Complications.getComplication(_sunsetId).value as Number));

            // Sunrise and sunset aren't the same time every day. The complication api doesn't allow you to get tomorrows sunrise, so we can use this to estimate it based on how much the time changed yesterday.
            _sunriseOffset = _sunriseTime.compare(oldSunriseTime);

            // Got new sun data, so update the string
            updateSunTime(now);

            // Store all the info that will only change here. The app is entirely re-created every time you leave and come back, so storing some of this stuff that's "expensive" to compute makes the re-initialization process more efficient.
            Storage.setValue('d', [_day, _dateX, _dayString, _dateString, _sunriseTime.value(), _sunsetTime.value(), _sunriseOffset]);

            // Also clear the screen at the start of the day
            dc.clear();
        } else if(now.greaterThan(_sunTime)) {
            // The upcoming sun event has passed, update the string.
            updateSunTime(now);
        }

        var timeString = date.hour + ":" + date.min.format("%02d");
        var moveBarLevel = Toybox.ActivityMonitor.getInfo().moveBarLevel;

        // Draw the time with the move bar filling it up
        if(moveBarLevel != null && moveBarLevel > Toybox.ActivityMonitor.MOVE_BAR_LEVEL_MIN) {
            if(moveBarLevel < Toybox.ActivityMonitor.MOVE_BAR_LEVEL_MAX) {
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
