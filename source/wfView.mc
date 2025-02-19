import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Complications;

class wfView extends WatchUi.WatchFace {
    private var screenWidth as Number;
    private var center_x as Number;
    private var center_y as Number;
    private var date_x as Number;
    private var date_y as Number;
    private var sun_y as Number;
    private var timeTopLeft as Number;

    private var timeHeight as Number;
    private var halfTimeHeight as Number;

    private var day as Number;
    private var sunriseOffset as Number;
    private var sunriseTime as Moment;
    private var sunsetTime as Moment;
    private var sunTime as Moment;
    private var sunString as String;

    private var dayString as String;
    private var dateString as String;

    private var font as VectorFont or FontType;

    private const sunriseId as Id = new Id(Complications.COMPLICATION_TYPE_SUNRISE);
    private const sunsetId as Id = new Id(Complications.COMPLICATION_TYPE_SUNSET);
    private const centerJust as Number = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    private const secs_per_day as Duration = new Time.Duration(Gregorian.SECONDS_PER_DAY);

    // debug stuff
    //private var cbCount as Number = 0;

    function updateSun(now as Moment) as Void {
        if( now.lessThan(sunriseTime) ) {
            sunTime = sunriseTime;
        } else if( now.lessThan(sunsetTime) ) {
            sunTime = sunsetTime;
        } else {
            sunTime = sunriseTime.add(new Time.Duration(sunriseOffset)).add(secs_per_day);
        }

        var gregorianSunTime = Gregorian.info(sunTime, Time.FORMAT_SHORT);
        sunString = Lang.format("$1$:$2$", [gregorianSunTime.hour, gregorianSunTime.min.format("%02d")]);

        Storage.setValue('s', [sunTime.value(), sunString]);
    }

    function initialize(h as Number, w as Number) {
        WatchFace.initialize();

        // Hopefully these look good on non-enduro devices
        var tempFont = Graphics.getVectorFont({:face => ["BionicSemiBold", "RobotoCondensedRegular", "KosugiRegular"], :size => 155});
        if (tempFont != null) {
            font = tempFont;
        } else {
            font = Graphics.FONT_SYSTEM_NUMBER_THAI_HOT;
        }

        timeHeight = Graphics.getFontHeight(font) / 2;
        halfTimeHeight = timeHeight / 2;

		center_y = h/2;
		screenWidth = w;
        center_x = screenWidth / 2;
        date_y = center_y+halfTimeHeight;

        timeTopLeft = center_y - halfTimeHeight - 10;
        sun_y = timeTopLeft - 15;

        // debug stuff
        //Storage.clearValues();

        var sundata = Storage.getValue('s') as [Number, String];
        if(sundata != null) {
            sunTime = new Moment(sundata[0]);
            sunString = sundata[1];

            var datedata = Storage.getValue('d') as [Number, Number, String, String, Number, Number, Number];
            day = datedata[0];
            date_x = datedata[1];
            dayString = datedata[2];
            dateString = datedata[3];
            sunriseTime = new Moment(datedata[4]);
            sunsetTime = new Moment(datedata[5]);
            sunriseOffset = datedata[6];
        } else {
            sunTime = new Moment(0);
            sunString = "";

            day = 0;
            date_x = 0;
            dayString = "";
            dateString = "";
            // This makes it so the oldSunriseTime logic below works even on the initial run, except in this case the sunriseOffset will be 0. That's fine, it's not that important and every other time after the initial run will have a real value to work with. Could get wonky if the user uses this face, then switches to another one, then switches back, but it'll only be off for a day and only affect the sunrise time displayed between sunset and midnight of the first run after a long hiatus
            sunriseTime = Time.today().add(new Time.Duration(Complications.getComplication(sunriseId).value as Number)).subtract(secs_per_day) as Moment;
            sunsetTime = new Moment(0);
            sunriseOffset = 0;
        }
    }

    //// https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/View.html
    /// order of calls: onLayout()->onShow()->onUpdate()
    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // We can limit the number of calls to dc.clear() by only running it on layout and at the start of the day, because the text only gets wider throughout the day
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
        var timeString = Lang.format("$1$:$2$", [date.hour, date.min.format("%02d")]);
        var moveBarLevel = Toybox.ActivityMonitor.getInfo().moveBarLevel;

        // Set the color before potentially calling dc.clear() and before drawing time text
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        // debug stuff
        //cbCount = cbCount + 1;
        //dc.drawText(date_x, 30, Graphics.FONT_SYSTEM_MEDIUM, Lang.format("c$1$ s$2$", [cbCount, date.sec]), Graphics.TEXT_JUSTIFY_CENTER);

        // If the day has changed, get new data for the sunrise, sunset, and how to display the date
        if( day != date.day ) {
            dc.clear();

            day = date.day;

            dayString = Lang.format("$1$ ", [date.day_of_week]);
            dateString = Lang.format("$1$ $2$", [date.month, date.day]);

            // Get the x axis offset for displaying the date. This makes it look like there's one centered string, even though it's really two strings being drawn so we can get different colors for the day and date
            date_x = center_x - ((dc.getTextWidthInPixels(dateString, Graphics.FONT_SYSTEM_MEDIUM) - dc.getTextWidthInPixels(dayString, Graphics.FONT_SYSTEM_MEDIUM))/2);

            var today = Time.today();
            var oldSunriseTime = sunriseTime.add(secs_per_day);

            sunriseTime = today.add(new Time.Duration(Complications.getComplication(sunriseId).value as Number));
            sunsetTime = today.add(new Time.Duration(Complications.getComplication(sunsetId).value as Number));

            // Sunrise and sunset aren't the same time every day. The complication api doesn't allow you to get tomorrows sunrise, so we can use this to estimate it based on how much the time changed yesterday.
            sunriseOffset = sunriseTime.compare(oldSunriseTime);

            // Got new sun data, so update the string
            updateSun(now);

            // Store all the info that will only change here. The app is entirely re-created every time you leave and come back, so storing some of this stuff that's "expensive" to compute makes the re-initialization process more efficient.
            Storage.setValue('d', [day, date_x, dayString, dateString, sunriseTime.value(), sunsetTime.value(), sunriseOffset]);
        } else if( now.greaterThan(sunTime) ) {
            // The upcoming sun event has passed, update the string.
            updateSun(now);
        }

        // Draw the time with the move bar filling it up
        if(moveBarLevel != null && moveBarLevel > Toybox.ActivityMonitor.MOVE_BAR_LEVEL_MIN) {
            if(moveBarLevel < Toybox.ActivityMonitor.MOVE_BAR_LEVEL_MAX) {
                var clipScale = (moveBarLevel - 1) / 4.0f;

                // Draw the white part of the text. timeTopLeft has the 10 pixel offset already accounted for
                dc.setClip(0, timeTopLeft, screenWidth, (halfTimeHeight * (1-clipScale))+10);
                dc.drawText(center_x, center_y, font, timeString, centerJust);

                // Draw the red part of the text
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
                dc.setClip(0, center_y - (halfTimeHeight * clipScale), screenWidth, timeHeight);
                dc.drawText(center_x, center_y, font, timeString, centerJust);

                dc.clearClip();
            } else {
                // The move bar is full, don't mess with clipping and math when we can just draw the text in red
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
                dc.drawText(center_x, center_y, font, timeString, centerJust);
            }
        } else {
            // The move bar is empty, don't mess with clipping and math when we can just draw the text in white
            dc.drawText(center_x, center_y, font, timeString, centerJust);
        }

        // Draw the sun time and date
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_BLACK);
        dc.drawText(center_x, sun_y, Graphics.FONT_SYSTEM_MEDIUM, sunString, centerJust);

        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        dc.drawText(date_x, date_y, Graphics.FONT_SYSTEM_MEDIUM, dayString, Graphics.TEXT_JUSTIFY_RIGHT);

        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_BLACK);
        dc.drawText(date_x, date_y, Graphics.FONT_SYSTEM_MEDIUM, dateString, Graphics.TEXT_JUSTIFY_LEFT);
    }
}
