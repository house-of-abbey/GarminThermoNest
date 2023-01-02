import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Communications;

class TempChangeView extends WatchUi.View {
    var mNestStatus;

    var buttons as Array<WatchUi.Button> = new Array<WatchUi.Button>[4];
    var settingCool as Lang.Boolean;

    function initialize(s) {
        View.initialize();
        mNestStatus = s;
        settingCool = mNestStatus.getThermoMode().equals("COOL");
        System.println(settingCool);
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
        buttons[2] = new WatchUi.Button({
            :stateDefault             => Graphics.COLOR_TRANSPARENT,
            :stateHighlighted         => Graphics.COLOR_TRANSPARENT,
            :stateSelected            => Graphics.COLOR_TRANSPARENT,
            :stateDisabled            => Graphics.COLOR_TRANSPARENT,
            :stateHighlightedSelected => Graphics.COLOR_TRANSPARENT,
            :background               => Graphics.COLOR_TRANSPARENT,
            :behavior                 => :onButton2,
            :locX                     => dc.getWidth()/2 - 50,
            :locY                     => dc.getHeight()/2 - 45,
            :width                    => 100,
            :height                   => 40
        });
        buttons[3] = new WatchUi.Button({
            :stateDefault             => Graphics.COLOR_TRANSPARENT,
            :stateHighlighted         => Graphics.COLOR_TRANSPARENT,
            :stateSelected            => Graphics.COLOR_TRANSPARENT,
            :stateDisabled            => Graphics.COLOR_TRANSPARENT,
            :stateHighlightedSelected => Graphics.COLOR_TRANSPARENT,
            :background               => Graphics.COLOR_TRANSPARENT,
            :behavior                 => :onButton3,
            :locX                     => dc.getWidth()/2 - 50,
            :locY                     => dc.getHeight()/2 + 5,
            :width                    => 100,
            :height                   => 40
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

        if (mNestStatus.getEco() || mNestStatus.getThermoMode().equals("OFF")) {
            buttons[0].setState(:stateDisabled);
            buttons[1].setState(:stateDisabled);
        } else {
            if (mNestStatus.getThermoMode().equals("HEATCOOL")) {
                dc.setColor(settingCool ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(hw, hh - 25, Graphics.FONT_MEDIUM,
                            Lang.format("$1$°$2$", [mNestStatus.getHeatTemp().format("%2.1f"), mNestStatus.getScale()]),
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                dc.setColor(settingCool ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(hw, hh + 25, Graphics.FONT_MEDIUM,
                            Lang.format("$1$°$2$", [mNestStatus.getCoolTemp().format("%2.1f"), mNestStatus.getScale()]),
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                buttons[2].setState(:stateDefault);
                buttons[3].setState(:stateDefault);
                buttons[0].draw(dc);
                buttons[1].draw(dc);
            } else if (mNestStatus.getThermoMode().equals("HEAT")) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(hw, hh, Graphics.FONT_MEDIUM,
                            Lang.format("$1$°$2$", [mNestStatus.getHeatTemp().format("%2.1f"), mNestStatus.getScale()]),
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                buttons[2].setState(:stateDisabled);
                buttons[3].setState(:stateDisabled);
            } else if (mNestStatus.getThermoMode().equals("COOL")) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(hw, hh, Graphics.FONT_MEDIUM,
                            Lang.format("$1$°$2$", [mNestStatus.getCoolTemp().format("%2.1f"), mNestStatus.getScale()]),
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                buttons[2].setState(:stateDisabled);
                buttons[3].setState(:stateDisabled);
            }

            buttons[0].setState(:stateDefault);
            buttons[1].setState(:stateDefault);
            buttons[0].draw(dc);
            buttons[1].draw(dc);
        }
    }

    function onButton0() as Void {
        if (settingCool) {
            mNestStatus.setCoolTemp(mNestStatus.getCoolTemp() + 0.5);
        } else {
            mNestStatus.setHeatTemp(mNestStatus.getHeatTemp() + 0.5);
        }
    }

    function onButton1() as Void {
        if (settingCool) {
            mNestStatus.setCoolTemp(mNestStatus.getCoolTemp() - 0.5);
        } else {
            mNestStatus.setHeatTemp(mNestStatus.getHeatTemp() - 0.5);
        }
    }

    function onButton2() as Void {
        settingCool = false;
        System.println(settingCool);
    }

    function onButton3() as Void {
        settingCool = true;
        System.println(settingCool);
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
    function onButton2() {
        return mView.onButton2(); 
    }
    function onButton3() {
        return mView.onButton3(); 
    }
    function onBack() {
        mView.mNestStatus.executeCoolTemp();
        mView.mNestStatus.executeHeatTemp();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
    function onPreviousPage() {
        mView.mNestStatus.executeCoolTemp();
        mView.mNestStatus.executeHeatTemp();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}