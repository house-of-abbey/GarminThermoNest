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
// TempChangeView provides the screen view to change both the heat and the cool
// temperatures.
//
//-----------------------------------------------------------------------------------

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Communications;

class TempChangeView extends WatchUi.View {
    hidden var mNestStatus;
    var mViewNav;
    hidden var incTempButton;
    hidden var decTempButton;
    hidden var heatTempButton;
    hidden var coolTempButton;
    hidden var thermostatIcon;
    hidden var settingCool as Lang.Boolean;

    function initialize(s) {
        View.initialize();
        mNestStatus = s;
        settingCool = mNestStatus.getThermoMode().equals("COOL");
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        thermostatIcon = Application.loadResource(Rez.Drawables.ThermostatIcon) as Graphics.BitmapResource;
        var bArrowUpIcon   = new WatchUi.Bitmap({ :rezId => $.Rez.Drawables.ArrowUpIcon   });
        var bArrowDownIcon = new WatchUi.Bitmap({ :rezId => $.Rez.Drawables.ArrowDownIcon });
        // A two element array containing the width and height of the Bitmap object
        var dim = bArrowUpIcon.getDimensions();
        incTempButton = new WatchUi.Button({
            :stateDefault             => bArrowUpIcon,
            :stateHighlighted         => bArrowUpIcon,
            :stateSelected            => bArrowUpIcon,
            :stateDisabled            => bArrowUpIcon,
            :stateHighlightedSelected => bArrowUpIcon,
            :background               => Graphics.COLOR_TRANSPARENT,
            :behavior                 => :onIncTempButton,
            :locX                     => (dc.getWidth() - dim[0]) / 2,
            :locY                     => 20,
            :width                    => dim[0],
            :height                   => dim[1]
        });
        // A two element array containing the width and height of the Bitmap object
        dim = bArrowDownIcon.getDimensions();
        decTempButton = new WatchUi.Button({
            :stateDefault             => bArrowDownIcon,
            :stateHighlighted         => bArrowDownIcon,
            :stateSelected            => bArrowDownIcon,
            :stateDisabled            => bArrowDownIcon,
            :stateHighlightedSelected => bArrowDownIcon,
            :background               => Graphics.COLOR_TRANSPARENT,
            :behavior                 => :onDecTempButton,
            :locX                     => (dc.getWidth() - dim[0]) / 2,
            :locY                     => (dc.getHeight() - dim[1] - 20),
            :width                    => dim[0],
            :height                   => dim[1]
        });
        heatTempButton = new WatchUi.Button({
            :stateDefault             => Graphics.COLOR_TRANSPARENT,
            :stateHighlighted         => Graphics.COLOR_TRANSPARENT,
            :stateSelected            => Graphics.COLOR_TRANSPARENT,
            :stateDisabled            => Graphics.COLOR_TRANSPARENT,
            :stateHighlightedSelected => Graphics.COLOR_TRANSPARENT,
            :background               => Graphics.COLOR_TRANSPARENT,
            :behavior                 => :onHeatTempButton,
            :locX                     => dc.getWidth()/2 - 50,
            :locY                     => dc.getHeight()/2 - 45,
            :width                    => 100,
            :height                   => 40
        });
        coolTempButton = new WatchUi.Button({
            :stateDefault             => Graphics.COLOR_TRANSPARENT,
            :stateHighlighted         => Graphics.COLOR_TRANSPARENT,
            :stateSelected            => Graphics.COLOR_TRANSPARENT,
            :stateDisabled            => Graphics.COLOR_TRANSPARENT,
            :stateHighlightedSelected => Graphics.COLOR_TRANSPARENT,
            :background               => Graphics.COLOR_TRANSPARENT,
            :behavior                 => :onCoolTempButton,
            :locX                     => dc.getWidth()/2 - 50,
            :locY                     => dc.getHeight()/2 + 5,
            :width                    => 100,
            :height                   => 40
        });
        mViewNav = new ViewNav({
            :identifier => "TempPane",
            :locX       => Globals.navMarginX,
            :locY       => dc.getHeight()/2,
            :radius     => Globals.navRadius,
            :panes      => Globals.navPanes,
            :nth        => 3, // 1-based numbering
            :visible    => true
        });
        setLayout([mViewNav, incTempButton, decTempButton, heatTempButton, coolTempButton]);
    }

    function onShow() {
        // Track changes to NestStatus state
        mNestStatus.copyState();
        mViewNav.animate();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var hw = w/2;
        var hh = h/2;
        var bg = 0x3B444C;

        dc.setAntiAlias(true);
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
            incTempButton.setState(:stateDisabled);
            decTempButton.setState(:stateDisabled);
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

                heatTempButton.setState(:stateDefault);
                coolTempButton.setState(:stateDefault);
                incTempButton.draw(dc);
                decTempButton.draw(dc);
            } else if (mNestStatus.getThermoMode().equals("HEAT")) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(hw, hh, Graphics.FONT_MEDIUM,
                            Lang.format("$1$°$2$", [mNestStatus.getHeatTemp().format("%2.1f"), mNestStatus.getScale()]),
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                heatTempButton.setState(:stateDisabled);
                coolTempButton.setState(:stateDisabled);
            } else if (mNestStatus.getThermoMode().equals("COOL")) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(hw, hh, Graphics.FONT_MEDIUM,
                            Lang.format("$1$°$2$", [mNestStatus.getCoolTemp().format("%2.1f"), mNestStatus.getScale()]),
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                heatTempButton.setState(:stateDisabled);
                coolTempButton.setState(:stateDisabled);
            }

            incTempButton.setState(:stateDefault);
            decTempButton.setState(:stateDefault);
            incTempButton.draw(dc);
            decTempButton.draw(dc);
        }
        mViewNav.draw(dc);
    }

    function onHide() as Void {
        mViewNav.resetAnimation();
    }

    function onIncTempButton() as Void {
        if (settingCool) {
            mNestStatus.setCoolTemp(mNestStatus.getCoolTemp() + 0.5);
        } else {
            mNestStatus.setHeatTemp(mNestStatus.getHeatTemp() + 0.5);
        }
    }

    function onDecTempButton() as Void {
        if (settingCool) {
            mNestStatus.setCoolTemp(mNestStatus.getCoolTemp() - 0.5);
        } else {
            mNestStatus.setHeatTemp(mNestStatus.getHeatTemp() - 0.5);
        }
    }

    function onHeatTempButton() as Void {
        settingCool = false;
    }

    function onCoolTempButton() as Void {
        settingCool = true;
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
    function onIncTempButton() {
        return mView.onIncTempButton(); 
    }
    function onDecTempButton() {
        return mView.onDecTempButton(); 
    }
    function onHeatTempButton() {
        return mView.onHeatTempButton(); 
    }
    function onCoolTempButton() {
        return mView.onCoolTempButton(); 
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