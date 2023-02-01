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

class TempChangeView extends ThermoView {
    private const settings as Lang.Dictionary = {
        :incDecMargin        => 4f,
        :tempSpace           => 7f,
        :thermoIconMargin    => 29f,
        :heatCoolIconSpacing => 24f,
        :modeSpacing         => 1f,
        :modeHeight          => 14f
    };
    // Vertical spacing between the outside of the face and the temperature change (arrow) buttons
    hidden var incDecMargin;
    // Vertical spacing either side of centre for the temperature values
    hidden var tempSpace;
    // Vertical spacing between the outside of the face and the thermostat icon
    hidden var thermoIconMargin;
    // Horizontal offset from screen centre of the heat and cool icons to the left of the one or two temperature values.
    hidden var heatCoolIconSpacing;
    // Horizontal spacing either side of centre for the HVAC & Eco mode statuses, i.e. the
    // icons are spaced at twice this value.
    hidden var modeSpacing;
    // Vertical space of bottom either side of centre icons for HVAC & Eco mode statuses
    hidden var modeHeight;

    hidden var mViewNav;
    hidden var incTempButton;
    hidden var decTempButton;
    hidden var heatTempButton;
    hidden var coolTempButton;
    hidden var thermostatIcon;
    hidden var settingCool as Lang.Boolean = false;
    hidden var ecoOffIcon;
    hidden var ecoOnIcon;
    hidden var heatOffIcon;
    hidden var heatOnIcon;
    hidden var coolOnIcon;
    hidden var heatCoolIcon;
    hidden var changeModeLabel;

    hidden var heatTemp;
    hidden var coolTemp;

    function initialize(ns as NestStatus) {
        ThermoView.initialize(ns);
        changeModeLabel  = WatchUi.loadResource($.Rez.Strings.changeModeLabel) as Lang.String;changeModeLabel;
        // Convert the settings from % of screen size to pixels
        incDecMargin        = pixelsForScreen(settings.get(:incDecMargin       ) as Lang.Float);
        tempSpace           = pixelsForScreen(settings.get(:tempSpace          ) as Lang.Float);
        thermoIconMargin    = pixelsForScreen(settings.get(:thermoIconMargin   ) as Lang.Float);
        heatCoolIconSpacing = pixelsForScreen(settings.get(:heatCoolIconSpacing) as Lang.Float);
        modeSpacing         = pixelsForScreen(settings.get(:modeSpacing        ) as Lang.Float);
        modeHeight          = pixelsForScreen(settings.get(:modeHeight         ) as Lang.Float);
    }

    function getHeatTemp() as  Lang.Number or Null {
        return heatTemp;
    }

    function getCoolTemp() as  Lang.Number or Null {
        return coolTemp;
    }

    // Load your resources here
    function onLayout(dc as Graphics.Dc) as Void {
        thermostatIcon     = Application.loadResource(Rez.Drawables.ThermostatIcon) as Graphics.BitmapResource;
        ecoOffIcon         = Application.loadResource(Rez.Drawables.EcoOffIcon    ) as Graphics.BitmapResource;
        ecoOnIcon          = Application.loadResource(Rez.Drawables.EcoOnIcon     ) as Graphics.BitmapResource;
        heatOffIcon        = Application.loadResource(Rez.Drawables.HeatOffIcon   ) as Graphics.BitmapResource;
        heatOnIcon         = Application.loadResource(Rez.Drawables.HeatOnIcon    ) as Graphics.BitmapResource;
        coolOnIcon         = Application.loadResource(Rez.Drawables.CoolOnIcon    ) as Graphics.BitmapResource;
        heatCoolIcon       = Application.loadResource(Rez.Drawables.HeatCoolIcon  ) as Graphics.BitmapResource;
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
            :locX       => pixelsForScreen(Globals.navMarginX),
            :locY       => dc.getHeight() / 2,
            :radius     => pixelsForScreen(Globals.navRadius),
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

        if(dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(Graphics.COLOR_WHITE, Globals.offColor);
        dc.clear();

        dc.drawBitmap(hw - thermostatIcon.getWidth()/2, thermoIconMargin - thermostatIcon.getHeight()/2, thermostatIcon);

        if (mNestStatus.getGotDeviceData()) {
            // https://developers.google.com/nest/device-access/traits/device/thermostat-temperature-setpoint
            // The temperature setpoint cannot be set when the thermostat is in manual Eco mode.
            if (mNestStatus.getEco() || mNestStatus.getThermoMode().equals("OFF")) {
                dc.drawText(
                    hw,
                    hh,
                    Graphics.FONT_MEDIUM,
                    changeModeLabel,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );

                if (mNestStatus.getEco()) {
                    dc.drawBitmap(hw - ecoOnIcon.getWidth() - modeSpacing, h - modeHeight, ecoOnIcon);
                } else {
                    dc.drawBitmap(hw - ecoOffIcon.getWidth() - modeSpacing, h - modeHeight, ecoOffIcon);
                }

                if (mNestStatus.getThermoMode().equals("HEATCOOL")) {
                    dc.drawBitmap(hw + modeSpacing, h - modeHeight, heatCoolIcon);
                } else if (mNestStatus.getThermoMode().equals("HEAT")) {
                    dc.drawBitmap(hw + modeSpacing, h - modeHeight, heatOnIcon);
                } else if (mNestStatus.getThermoMode().equals("COOL")) {
                    dc.drawBitmap(hw + modeSpacing, h - modeHeight, coolOnIcon);
                } else {
                    dc.drawBitmap(hw + modeSpacing, h - modeHeight, heatOffIcon);
                }

                incTempButton.setState(:stateDisabled);
                decTempButton.setState(:stateDisabled);
            } else {
                drawTempScale(dc, mNestStatus.getAmbientTemp(), heatTemp, coolTemp);
                switch (mNestStatus.getThermoMode()) {
                    case "HEATCOOL":
                        dc.drawBitmap(
                            hw - coolOnIcon.getWidth()/2 - heatCoolIconSpacing,
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
                            hw - heatOnIcon.getWidth()/2 - heatCoolIconSpacing,
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
                            hw - heatOnIcon.getWidth()/2 - heatCoolIconSpacing,
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
                            hw - coolOnIcon.getWidth()/2 - heatCoolIconSpacing,
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

    // Work to do when the increment temperature button is pressed.
    //
    function onIncTempButton() as Void {
        if (mNestStatus.getScale() == 'C') {
            if (settingCool) {
                if (coolTemp < Globals.maxTempC) {
                    coolTemp = coolTemp + Globals.celciusRes;
                }
            } else {
                if (heatTemp < Globals.maxTempC && (coolTemp == null || heatTemp + Globals.sepTempC < coolTemp)) {
                    heatTemp = heatTemp + Globals.celciusRes;
                }
            }
        } else {
            if (settingCool) {
                if (coolTemp < Globals.maxTempF) {
                    coolTemp = coolTemp + Globals.farenheitRes;
                }
            } else {
                if (heatTemp < Globals.maxTempF && (coolTemp == null || heatTemp + Globals.sepTempF < coolTemp)) {
                    heatTemp = heatTemp + Globals.farenheitRes;
                }
            }
        }
        requestUpdate();
    }

    // Work to do when the decrement temperature button is pressed.
    //
    function onDecTempButton() as Void {
        if (mNestStatus.getScale() == 'C') {
            if (settingCool) {
                if (coolTemp > Globals.minTempC && (heatTemp == null || coolTemp > heatTemp + Globals.sepTempC)) {
                    coolTemp = coolTemp - Globals.celciusRes;
                }
            } else {
                if (heatTemp > Globals.minTempC) {
                    heatTemp = heatTemp - Globals.celciusRes;
                }
            }
        } else {
            if (settingCool) {
                if (coolTemp > Globals.minTempF && (heatTemp == null || coolTemp > heatTemp + Globals.sepTempF)) {
                    coolTemp = coolTemp - Globals.farenheitRes;
                }
            } else {
                if (heatTemp > Globals.minTempF) {
                    heatTemp = heatTemp - Globals.farenheitRes;
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
    hidden var mView;
    hidden var cancelledAlert;

    function initialize(v) {
        WatchUi.BehaviorDelegate.initialize();
        mView = v;
        cancelledAlert = new Alert({
            :timeout => Globals.alertTimeout,
            :font    => Graphics.FONT_MEDIUM,
            :text    => WatchUi.loadResource($.Rez.Strings.cancelledAlert) as Lang.String,
            :fgcolor => Graphics.COLOR_RED,
            :bgcolor => Graphics.COLOR_BLACK
        });
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
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        cancelledAlert.pushView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
    function onPreviousPage() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        mView.getNestStatus().executeChangeTemp(mView.getHeatTemp(), mView.getCoolTemp());
        return true;
    }
}
