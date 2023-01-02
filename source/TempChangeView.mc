import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Communications;

class TempChangeView extends WatchUi.View {
    var mNestStatus;

    hidden var thermostatIcon;

    hidden var buttons as Array<WatchUi.Button> = new Array<WatchUi.Button>[4];
    hidden var settingCool as Lang.Boolean;

    function initialize(s) {
        View.initialize();
        mNestStatus = s;
        settingCool = mNestStatus.getThermoMode().equals("COOL");
        System.println(settingCool);
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        thermostatIcon = Application.loadResource(Rez.Drawables.ThermostatIcon) as Graphics.BitmapResource;
        var bArrowUpIcon   = new WatchUi.Bitmap({ :rezId => $.Rez.Drawables.ArrowUpIcon   });
        var bArrowDownIcon = new WatchUi.Bitmap({ :rezId => $.Rez.Drawables.ArrowDownIcon });
        // A two element array containing the width and height of the Bitmap object
        var dim = bArrowUpIcon.getDimensions();
        buttons[0] = new WatchUi.Button({
            :stateDefault             => bArrowUpIcon,
            :stateHighlighted         => bArrowUpIcon,
            :stateSelected            => bArrowUpIcon,
            :stateDisabled            => bArrowUpIcon,
            :stateHighlightedSelected => bArrowUpIcon,
            :background               => Graphics.COLOR_TRANSPARENT,
            :behavior                 => :onButton0,
            :locX                     => (dc.getWidth() - dim[0]) / 2,
            :locY                     => 20,
            :width                    => dim[0],
            :height                   => dim[1]
        });
        // A two element array containing the width and height of the Bitmap object
        dim = bArrowDownIcon.getDimensions();
        buttons[1] = new WatchUi.Button({
            :stateDefault             => bArrowDownIcon,
            :stateHighlighted         => bArrowDownIcon,
            :stateSelected            => bArrowDownIcon,
            :stateDisabled            => bArrowDownIcon,
            :stateHighlightedSelected => bArrowDownIcon,
            :background               => Graphics.COLOR_TRANSPARENT,
            :behavior                 => :onButton1,
            :locX                     => (dc.getWidth() - dim[0]) / 2,
            :locY                     => (dc.getHeight() - dim[1] - 20),
            :width                    => dim[0],
            :height                   => dim[1]
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

    function onShow() {
        // Track changes to NestStatus state
        mNestStatus.copyState();
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

        dc.drawBitmap(hw - thermostatIcon.getWidth()/2, h/3 - thermostatIcon.getHeight()/2, thermostatIcon);
        var temp = mNestStatus.getHeatTemp();
        if (temp != null) {
            dc.drawText(
                hw, hh, Graphics.FONT_MEDIUM,
                Lang.format("$1$°$2$", [temp.format("%2.1f"), mNestStatus.getScale()]),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }

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

    function getNestStatus() as NestStatus {
        return mNestStatus;
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
        mView.getNestStatus().executeCoolTemp();
        mView.getNestStatus().executeHeatTemp();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
    function onPreviousPage() {
        mView.getNestStatus().executeCoolTemp();
        mView.getNestStatus().executeHeatTemp();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}