//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminThermoNest/blob/main/LICENSE.
//
//-----------------------------------------------------------------------------------
//
// ThermoNest is a Garmin IQ application written in Monkey C and routinely tested on
// a Venu 2 device. The source code is provided at:
//            https://github.com/house-of-abbey/GarminThermoNest.
//
// J D Abbey & P A Abbey, 28 December 2022
//
//
// Description:
//
// ViewNav is an attempt to imitate the Garmin application's "navigation dots".
// That's n vertical dots, one for each view you can swipe to. Then the dots are
// outlined except for the dot representing the current view, which is filled. The
// filled dot is always half way up the screen.
//
//-----------------------------------------------------------------------------------

using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Lang;
using Toybox.Timer;
using Toybox.Math;

class ViewNav extends WatchUi.Drawable {
    hidden var olocX;
    hidden var ilocX;
    hidden var ilocY;
    hidden var radius  = 5;
    hidden var panes   = 1;
    hidden var nth     = 1;
    hidden var timeout = 2000; // ms
    hidden var period  = 0.5;  // s
    hidden var timer as Timer.Timer;

    function initialize(settings as {
            :identifier as Lang.Object,  // Just use a string if nothing else to provide
            :locX       as Lang.Numeric, // Of centre of active pane (filled circle)
            :locY       as Lang.Numeric, // Of centre of active pane (filled circle)
            :radius     as Lang.Numeric,
            :panes      as Lang.Numeric, // Number of panes, 1..n
            :nth        as Lang.Numeric, // Pane index (1-based)
            :visible    as Lang.Boolean,
            :timeout    as Lang.Numeric,
            :period     as Lang.Numeric
        }) {
        ilocX   = settings.get(:locX);
        ilocY   = settings.get(:locY);
        radius  = settings.get(:radius);
        olocX   = ilocX - radius; // Original iLocX
        panes   = settings.get(:panes);
        nth     = settings.get(:nth);
        timeout = settings.get(:timeout);
        period  = settings.get(:period);

        var lr    = (System.getDeviceSettings().screenWidth / 2) - ilocX; // Large radius from the centre of the screen
        var theta = Math.acos(1 - (2 * Math.pow(radius, 2) / Math.pow(lr, 2)));
        var x0, y0, xn, yn;
        if ((1-nth) * theta < Math.PI) {
            x0 = ilocX + (lr * (1 - Math.cos((1-nth) * theta)));
        } else {
            // Max out the horizonal width at PI
            x0 = ilocX + 2 * lr;
        }
        if ((1-nth) * theta * 2.0f < Math.PI) {
            y0 = ilocY + (lr * Math.sin((1-nth) * theta));
        } else {
            // Min out the vertical height at PI/2
            y0 = ilocY - lr;
        }
        if ((panes-nth) * theta < Math.PI) {
            xn = ilocX + (lr * (1 - Math.cos((panes-nth) * theta)));
        } else {
            // Max out the horizonal width at PI
            xn = ilocX + 2 * lr;
        }
        if ((panes-nth) * theta * 2.0f < Math.PI) {
            yn = ilocY + (lr * Math.sin((panes-nth) * theta));
        } else {
            // Max out the vertical height at PI/2
            yn = ilocY + lr;
        }

        Drawable.initialize({
            :identifier => settings.get(:identifier),
            :locX       => olocX,
            :locY       => NestStatus.round(y0 - radius, 1.0f),
            :width      => NestStatus.round(radius * 2 + (((x0 > xn) ? x0 : xn) - ilocX), 1.0f),
            :height     => NestStatus.round(radius * 2 + (yn - y0), 1.0f),
            :visible    => settings.get(:visible)
        });
        timer = new Timer.Timer();
    }

    function draw(dc as Graphics.Dc) as Void {
        // Required for when we animate since locX gets altered and this method draws relative to ilocX
        ilocX = locX + radius; // radius is always the difference between locX and ilocX
        if (isVisible) {
            dc.setPenWidth(1);
            var lr = (dc.getWidth() / 2) - ilocX; // Large radius from the centre of the screen
            var theta = Math.acos(1 - (2 * Math.pow(radius, 2) / Math.pow(lr, 2)));
            for (var i = 1-nth; i < (panes+1-nth); i++) {
                var x = ilocX + (lr * (1 - Math.cos(i * theta)));
                var y = ilocY + (lr *      Math.sin(i * theta) );
                if (i == 0) {
                    dc.setColor(
                        Graphics.COLOR_WHITE,
                        Graphics.COLOR_TRANSPARENT
                    );
                    dc.fillCircle(x, y, radius-1);
                } else {
                    dc.setColor(
                        Graphics.COLOR_BLACK,
                        Graphics.COLOR_TRANSPARENT
                    );
                    dc.fillCircle(x, y, radius-3);
                    dc.setColor(
                        Graphics.COLOR_WHITE,
                        Graphics.COLOR_TRANSPARENT
                    );
                    dc.drawCircle(x, y, radius-2);
                }
            }
        }
    }

    function animateCallback() as Void {
        // Have to add 1 to the width to get rid of the last circle pixels. Feature of
        // drawCircle/fillCircle? Perhaps anti-aliasing?
        WatchUi.animate(self, :locX, WatchUi.ANIM_TYPE_LINEAR, olocX, -width, Globals.navPeriod, null);
    }

    function animate() as Void {
        timer.start(method(:animateCallback), timeout, false);
    }

    function resetAnimation() as Void {
        timer.stop();
        WatchUi.cancelAllAnimations();
        // Put this widget back in its default location
        locX = olocX;
    }

}
