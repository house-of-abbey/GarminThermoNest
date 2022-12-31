import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Communications;

class TempChangeView extends WatchUi.View {
    var mNestStatus;

    var buttons as Array<WatchUi.Button> = new Array<WatchUi.Button>[2];

    function initialize(s) {
        View.initialize();
        mNestStatus = s;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        var bArrowUpIcon   = new WatchUi.Bitmap({ :rezId => $.Rez.Drawables.ArrowUpIcon   });
        var bArrowDownIcon = new WatchUi.Bitmap({ :rezId => $.Rez.Drawables.ArrowDownIcon });
        buttons[0] = new WatchUi.Button({
            :stateDefault             => bArrowUpIcon,
            :stateHighlighted         => bArrowUpIcon,
            :stateSelected            => bArrowUpIcon,
            :stateDisabled            => bArrowUpIcon,
            :stateHighlightedSelected => bArrowUpIcon,
            :background               => Graphics.COLOR_TRANSPARENT,
            :behavior                 => :onButton0,
            :locX                     => dc.getWidth()/2 - 24,
            :locY                     => 30,
            :width                    => 48,
            :height                   => 48
        });
        buttons[1] = new WatchUi.Button({
            :stateDefault             => bArrowDownIcon,
            :stateHighlighted         => bArrowDownIcon,
            :stateSelected            => bArrowDownIcon,
            :stateDisabled            => bArrowDownIcon,
            :stateHighlightedSelected => bArrowDownIcon,
            :background               => Graphics.COLOR_TRANSPARENT,
            :behavior                 => :onButton1,
            :locX                     => dc.getWidth()/2 - 24,
            :locY                     => dc.getHeight() - 78,
            :width                    => 48,
            :height                   => 48
        });
        setLayout(buttons);
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

        dc.drawText(hw, hh, Graphics.FONT_MEDIUM,
                    Lang.format("$1$°$2$", [mNestStatus.getHeatTemp().format("%2.1f"), mNestStatus.getScale()]),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (mNestStatus.getEco() || mNestStatus.getThermoMode() == "OFF") {
            buttons[0].setState(:stateDisabled);
            buttons[1].setState(:stateDisabled);
        } else {
            buttons[0].setState(:stateDefault);
            buttons[1].setState(:stateDefault);
        }
        buttons[0].draw(dc);
        buttons[1].draw(dc);
    }

    function onButton0() as Void {
        mNestStatus.setHeatTemp(mNestStatus.getHeatTemp() + 0.5);
    }

    function onButton1() as Void {
        mNestStatus.setHeatTemp(mNestStatus.getHeatTemp() - 0.5);
    }
}

class TempChangeDelegate extends WatchUi.BehaviorDelegate {
    var mView;
    function initialize(v) {
        WatchUi.BehaviorDelegate.initialize();
        mView = v;
    }
    function onButton0() {
        return mView.onButton0(); 
    }
    function onButton1() {
        return mView.onButton1(); 
    }
    function onBack() {
        mView.mNestStatus.executeHeatTemp();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
    function onPreviousPage() {
        mView.mNestStatus.executeHeatTemp();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}