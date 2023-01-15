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

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Communications;

class TempChangeView extends WatchUi.View {
    // Vertical spacing between the outside of the face and the temperature change (arrow) buttons
    hidden const incDecMargin     = 15;
    // Vertical spacing either side of centre for the temperature values
    hidden const tempSpace        = 30;
    // Vertical spacing between the outside of the face and the thermostat icon
    hidden const thermoIconMargin = 120;

    hidden var mNestStatus;
    hidden var mViewNav;
    hidden var incTempButton;
    hidden var decTempButton;
    hidden var heatTempButton;
    hidden var coolTempButton;
    hidden var thermostatIcon;
    hidden var heatOnIcon;
    hidden var coolOnIcon;
    hidden var settingCool as Lang.Boolean = false;
    hidden var setOffLabel as Lang.String;

    hidden var heatTemp;
    hidden var coolTemp;

    function initialize(ns as NestStatus) {
        View.initialize();
        mNestStatus = ns;
        setOffLabel = WatchUi.loadResource($.Rez.Strings.offStatus) as Lang.String;
    }

    function getHeatTemp() as  Lang.Number or Null {
        return heatTemp;
    }

    function getCoolTemp() as  Lang.Number or Null {
        return coolTemp;
    }

    // Load your resources here
    function onLayout(dc as Graphics.Dc) as Void {
        thermostatIcon = Application.loadResource(Rez.Drawables.ThermostatIcon) as Graphics.BitmapResource;
        heatOnIcon     = Application.loadResource(Rez.Drawables.HeatOnIcon    ) as Graphics.BitmapResource;
        coolOnIcon     = Application.loadResource(Rez.Drawables.CoolOnIcon    ) as Graphics.BitmapResource;
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
            :locY                     => incDecMargin,
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
            :locY                     => (dc.getHeight() - dim[1] - incDecMargin),
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
            :locY                     => dc.getHeight()/2 + 5,
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
            :locY                     => dc.getHeight()/2 - 45,
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
            :visible    => true,
            :timeout    => Globals.navDelay,
            :period     => Globals.navPeriod
        });
        setLayout([mViewNav, incTempButton, decTempButton, heatTempButton, coolTempButton]);
    }

    function onShow() {
        // Track changes to NestStatus state
        settingCool = mNestStatus.getThermoMode().equals("COOL");
        heatTemp    = mNestStatus.getHeatTemp();
        coolTemp    = mNestStatus.getCoolTemp();
        mViewNav.animate();
    }

    // Update the view
    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var hw = w/2;
        var hh = h/2;

        dc.setAntiAlias(true);
        dc.setColor(Graphics.COLOR_WHITE, Globals.offColor);
        dc.clear();

        dc.drawBitmap(hw - thermostatIcon.getWidth()/2, thermoIconMargin - thermostatIcon.getHeight()/2, thermostatIcon);

        if (mNestStatus.gotDeviceData) {
            if (mNestStatus.getEco() || mNestStatus.getThermoMode().equals("OFF")) {
                dc.drawText(
                    hw,
                    hh,
                    Graphics.FONT_MEDIUM,
                    setOffLabel,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
                incTempButton.setState(:stateDisabled);
                decTempButton.setState(:stateDisabled);
            } else {
                switch (mNestStatus.getThermoMode()) {
                    case "HEATCOOL":
                        dc.drawBitmap(
                            hw - coolOnIcon.getWidth()/2 - 100,
                            hh - coolOnIcon.getHeight()/2 - tempSpace,
                            coolOnIcon
                        );
                        dc.setColor(settingCool ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(
                            hw,
                            hh - tempSpace,
                            Graphics.FONT_MEDIUM,
                            Lang.format("$1$°$2$", [coolTemp.format("%2.1f"), mNestStatus.getScale()]),
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                        );

                        dc.drawBitmap(
                            hw - heatOnIcon.getWidth()/2 - 100,
                            hh - heatOnIcon.getHeight()/2 + tempSpace,
                            heatOnIcon
                        );
                        dc.setColor(settingCool ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(
                            hw,
                            hh + tempSpace,
                            Graphics.FONT_MEDIUM,
                            Lang.format("$1$°$2$", [heatTemp.format("%2.1f"), mNestStatus.getScale()]),
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                        );

                        heatTempButton.setState(:stateDefault);
                        coolTempButton.setState(:stateDefault);
                        break;

                    case "HEAT":
                        dc.drawBitmap(
                            hw - heatOnIcon.getWidth()/2 - 100,
                            hh - heatOnIcon.getHeight()/2,
                            heatOnIcon
                        );
                        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(
                            hw,
                            hh,
                            Graphics.FONT_MEDIUM,
                            Lang.format("$1$°$2$", [heatTemp.format("%2.1f"), mNestStatus.getScale()]),
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                        );

                        heatTempButton.setState(:stateDisabled);
                        coolTempButton.setState(:stateDisabled);
                        break;

                    case "COOL":
                        dc.drawBitmap(
                            hw - coolOnIcon.getWidth()/2 - 100,
                            hh - coolOnIcon.getHeight()/2,
                            coolOnIcon
                        );
                        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(
                            hw,
                            hh,
                            Graphics.FONT_MEDIUM,
                            Lang.format("$1$°$2$", [coolTemp.format("%2.1f"), mNestStatus.getScale()]),
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                        );

                        heatTempButton.setState(:stateDisabled);
                        coolTempButton.setState(:stateDisabled);
                        break;

                    default:
                        if (Globals.debug) {
                            System.print("ERROR - TempChangeView: HVAC mode '" + mNestStatus.getThermoMode() + "', so nothing to draw.");
                        }
                        break;
                }

                incTempButton.setState(:stateDefault);
                decTempButton.setState(:stateDefault);
                incTempButton.draw(dc);
                decTempButton.draw(dc);
            }
        }
        mViewNav.draw(dc);
    }

    function onHide() as Void {
        mViewNav.resetAnimation();
    }

    function onIncTempButton() as Void {
        if (mNestStatus.getScale() == 'C') {
            if (settingCool) {
                if (coolTemp < Globals.maxTempC) {
                    coolTemp = coolTemp + 0.5;
                }
            } else {
                if (heatTemp < Globals.maxTempC && (coolTemp == null || heatTemp < coolTemp)) {
                    heatTemp = heatTemp + 0.5;
                }
            }
        } else {
            if (settingCool) {
                if (coolTemp < Globals.maxTempF) {
                    coolTemp = coolTemp + 1.0;
                }
            } else {
                if (heatTemp < Globals.maxTempF && (coolTemp == null || heatTemp  < coolTemp)) {
                    heatTemp = heatTemp + 1.0;
                }
            }
        }
        requestUpdate();
    }

    function onDecTempButton() as Void {
        if (mNestStatus.getScale() == 'C') {
            if (settingCool) {
                if (coolTemp > Globals.minTempC && (heatTemp == null || coolTemp > heatTemp)) {
                    coolTemp = coolTemp - 0.5;
                }
            } else {
                if (heatTemp > Globals.minTempC) {
                    heatTemp = heatTemp - 0.5;
                }
            }
        } else {
            if (settingCool) {
                if (coolTemp > Globals.minTempF && (heatTemp == null || coolTemp > heatTemp)) {
                    coolTemp = coolTemp - 1.0;
                }
            } else {
                if (heatTemp > Globals.minTempF) {
                    heatTemp = heatTemp - 1.0;
                }
            }
        }
        requestUpdate();
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
        var alert = new Alert({
            :timeout => Globals.alertTimeout,
            :font    => Graphics.FONT_MEDIUM,
            :text    => "Cancelled",
            :fgcolor => Graphics.COLOR_RED,
            :bgcolor => Graphics.COLOR_BLACK
        });
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        alert.pushView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
    function onPreviousPage() {
        var alert = new Alert({
            :timeout => Globals.alertTimeout,
            :font    => Graphics.FONT_MEDIUM,
            :text    => "Sending",
            :fgcolor => Graphics.COLOR_GREEN,
            :bgcolor => Graphics.COLOR_BLACK
        });
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        alert.pushView(WatchUi.SLIDE_IMMEDIATE);
        mView.getNestStatus().executeChangeTemp(mView.getHeatTemp(), mView.getCoolTemp());
        return true;
    }
}
