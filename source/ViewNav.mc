//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/scratch_vhdl/blob/main/LICENCE.
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

class ViewNav extends WatchUi.Drawable {
    hidden var radius = 5;
    hidden var panes  = 1;
    hidden var nth    = 1;
    hidden var timer as Timer.Timer;
    hidden var ilocX;

    function initialize(settings as {
            :identifier as Lang.Object,  // Just use a string if nothing else to provide
            :locX       as Lang.Numeric, // Of centre of active pane (filled circle)
            :locY       as Lang.Numeric, // Of centre of active pane (filled circle)
            :radius     as Lang.Numeric,
            :panes      as Lang.Numeric, // Number of panes, 1..n
            :nth        as Lang.Numeric, // Pane index (1-based)
            :visible    as Lang.Boolean
        }) {
        radius = settings.get(:radius);
        panes  = settings.get(:panes);
        nth    = settings.get(:nth);
        ilocX  = settings.get(:locX) - settings.get(:radius);
        Drawable.initialize({
            :identifier => settings.get(:identifier),
            :locX       => ilocX,
            :locY       => settings.get(:locY) - (settings.get(:radius) * (settings.get(:nth)*2 - 1)),
            :width      => settings.get(:radius) * 2,
            :height     => settings.get(:radius) * 2 * settings.get(:panes),
            :visible    => settings.get(:visible)
        });
        timer = new Timer.Timer();
    }

    function draw(dc as Graphics.Dc) as Void {
        if (isVisible) {
            dc.setPenWidth(1);
            for (var i = 0; i < panes; i++) {
                if (i == nth-1) {
                    dc.setColor(
                        Graphics.COLOR_WHITE,
                        Graphics.COLOR_TRANSPARENT
                    );
                    dc.fillCircle(
                        locX + radius,
                        locY + radius + (i * radius * 2),
                        radius-1
                    );
                } else {
                    dc.setColor(
                        Graphics.COLOR_BLACK,
                        Graphics.COLOR_TRANSPARENT
                    );
                    dc.fillCircle(
                        locX + radius,
                        locY + radius + (i * radius * 2),
                        radius-3
                    );
                    dc.setColor(
                        Graphics.COLOR_WHITE,
                        Graphics.COLOR_TRANSPARENT
                    );
                    dc.drawCircle(
                        locX + radius,
                        locY + radius + (i * radius * 2),
                        radius-2
                    );
                }
            }
        }
    }

    function animateCallback() as Void {
        // Have to add 1 to the width to get rid of the last circle pixels. Feature of
        // drawCircle/fillCircle? Perhaps anti-aliasing?
        WatchUi.animate(self, :locX, WatchUi.ANIM_TYPE_LINEAR, ilocX, -width-1, Globals.navPeriod, null);
    }

    function animate() as Void {
        timer.start(method(:animateCallback), Globals.navDelay, false);
    }

    function resetAnimation() as Void {
        timer.stop();
        WatchUi.cancelAllAnimations();
        // Put this widget back in its default location
        locX = ilocX;
    }
}
