import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Communications;

class NestThermoView extends WatchUi.View {
    hidden var mNestStatus;
    hidden var ecoIcon as Bitmap;

    function initialize() {
        View.initialize();
        mNestStatus = new NestStatus(method(:updateTemp));
        ecoIcon = new WatchUi.Bitmap({
            :rezId => $.Rez.Drawables.EcoOnIcon,
            :locX => 100,
            :locY => 100
        });
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout($.Rez.Layouts.NestStatus(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Get and show the current time
        var view = View.findDrawableById("TempLabel") as Text;
        view.setText(Lang.format("$1$ °$2$", [mNestStatus.getAmbientTemp().format("%2.1f"), mNestStatus.getScale()]));
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        ecoIcon.draw(dc);
    }

    function updateTemp() as Void {
        requestUpdate();
    }

    function touch() as Void {
        mNestStatus.makeRequest();
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

}

class LoadDelegate extends WatchUi.BehaviorDelegate {
    var touch;
    function initialize(h) {
        WatchUi.BehaviorDelegate.initialize();
        touch = h;
    }
    function onMenu  () { return touch.invoke(); }
    function onSelect() { return touch.invoke(); }
}