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
// ErrorView provides a means to present application errors to the user. These
// should not happen of course... but they do, so best make sure errors can be
// reported.
//
//-----------------------------------------------------------------------------------

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Communications;

(:glance)
class ErrorView extends WatchUi.View {
    hidden var text as String;

    hidden var errorIcon;
    hidden var textArea;

    function initialize(t as String) {
        View.initialize();
        text = t;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        errorIcon = Application.loadResource(Rez.Drawables.ErrorIcon) as Graphics.BitmapResource;

        var w = dc.getWidth();
        var h = dc.getHeight();
        var hw = w/2;
        var hh = h/2;

        textArea = new WatchUi.TextArea({
            :text          => text,
            :color         => Graphics.COLOR_WHITE,
            :font          => Graphics.FONT_XTINY,
            :justification => Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            :locX          => 0,
            :locY          => 83,
            :width         => w,
            :height        => h - 166
        });
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var hw = w/2;
        var hh = h/2;
        var bg = 0x3B444C;
        dc.setColor(Graphics.COLOR_WHITE, bg);
        dc.clear();
        dc.setAntiAlias(true);
        dc.drawBitmap(hw - 24, 30, errorIcon);
        textArea.draw(dc);
    }
}

(:glance)
class ErrorDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        WatchUi.BehaviorDelegate.initialize();
    }
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}