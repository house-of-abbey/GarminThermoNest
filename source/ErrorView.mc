import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Communications;

class ErrorView extends WatchUi.View {
    hidden var text as String;

    hidden var errorIcon;
    hidden var textArea;

    function initialize(t as String) {
        View.initialize();
        text = t;
        System.println(t);
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
        dc.drawBitmap(hw - 24, 30, errorIcon);
        textArea.draw(dc);
    }
}

class ErrorDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        WatchUi.BehaviorDelegate.initialize();
    }
    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}