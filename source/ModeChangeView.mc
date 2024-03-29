//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminThermoNest/blob/main/LICENSE.
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
// ModeChangeView provides the screen view to change both the thermostats HVAC mode
// and the eco mode.
//
//-----------------------------------------------------------------------------------

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;

class ModeChangeView extends ScalableView {
    private var mNestStatus;
    private var mViewNav;
    private var modeButton;
    private var ecoButton;
    private var heatOffIcon;
    private var heatOnIcon;
    private var coolOnIcon;
    private var heatCoolIcon;
    private var ecoOffIcon;
    private var ecoOnIcon;
    private var setModeLabel         as Lang.String;
    private var tapIconLabel         as Lang.String;
    private var thermoMode           as Lang.String or Null;
    private var ecoMode              as Lang.Boolean or Null;
    private var availableThermoModes as Lang.Array;
    private var availableEcoModes    as Lang.Array;

    function initialize(ns as NestStatus) {
        ScalableView.initialize();
        mNestStatus          = ns;
        setModeLabel         = WatchUi.loadResource($.Rez.Strings.setMode) as Lang.String;
        tapIconLabel         = WatchUi.loadResource($.Rez.Strings.tapIcon) as Lang.String;
        availableThermoModes = mNestStatus.getAvailableThermoModes();
        availableEcoModes    = mNestStatus.getAvailableEcoModes();
    }

    function getThermoMode() as Lang.String {
        return thermoMode;
    }

    function getEcoMode() as Lang.Boolean {
        return ecoMode;
    }

    // Load your resources here
    function onLayout(dc as Graphics.Dc) as Void {
        heatOffIcon  = Application.loadResource(Rez.Drawables.HeatOffLgIcon ) as Graphics.BitmapResource;
        heatOnIcon   = Application.loadResource(Rez.Drawables.HeatOnLgIcon  ) as Graphics.BitmapResource;
        coolOnIcon   = Application.loadResource(Rez.Drawables.CoolOnLgIcon  ) as Graphics.BitmapResource;
        heatCoolIcon = Application.loadResource(Rez.Drawables.HeatCoolLgIcon) as Graphics.BitmapResource;
        ecoOffIcon   = Application.loadResource(Rez.Drawables.EcoOffLgIcon  ) as Graphics.BitmapResource;
        ecoOnIcon    = Application.loadResource(Rez.Drawables.EcoOnLgIcon   ) as Graphics.BitmapResource;
        mViewNav     = new ViewNav({
            :identifier => "ModePane",
            :locX       => pixelsForScreen(Globals.navMarginX),
            :locY       => dc.getHeight() / 2,
            :radius     => pixelsForScreen(Globals.navRadius),
            :panes      => Globals.navPanes,
            :nth        => 1, // 1-based numbering
            :visible    => true,
            :timeout    => Globals.navDelay,
            :period     => Globals.navPeriod
        });

        var w = dc.getWidth();
        var h = dc.getHeight();
        ecoButton = new WatchUi.Button({
            :stateDefault             => Graphics.COLOR_TRANSPARENT,
            :stateHighlighted         => Graphics.COLOR_TRANSPARENT,
            :stateSelected            => Graphics.COLOR_TRANSPARENT,
            :stateDisabled            => Graphics.COLOR_TRANSPARENT,
            :stateHighlightedSelected => Graphics.COLOR_TRANSPARENT,
            :background               => Graphics.COLOR_TRANSPARENT,
            :behavior                 => :onEcoButton,
            :locX                     => w/8,
            :locY                     => h/4,
            :width                    => w/4,
            :height                   => h/2
        });
        modeButton = new WatchUi.Button({
            :stateDefault             => Graphics.COLOR_TRANSPARENT,
            :stateHighlighted         => Graphics.COLOR_TRANSPARENT,
            :stateSelected            => Graphics.COLOR_TRANSPARENT,
            :stateDisabled            => Graphics.COLOR_TRANSPARENT,
            :stateHighlightedSelected => Graphics.COLOR_TRANSPARENT,
            :background               => Graphics.COLOR_TRANSPARENT,
            :behavior                 => :onModeButton,
            :locX                     => w*5/8,
            :locY                     => h/4,
            :width                    => w/4,
            :height                   => h/2
        });
        setLayout([modeButton, ecoButton] as Lang.Array<WatchUi.Button>);
    }

    function onShow() {
        thermoMode = mNestStatus.getThermoMode();
        ecoMode    = mNestStatus.getEco();
        mViewNav.animate();
    }

    // Update the view
    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        if(dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(Graphics.COLOR_WHITE, Globals.offColor);
        dc.clear();

        dc.drawText(
            w/2,
            h/4,
            Graphics.FONT_SMALL,
            setModeLabel, // "Set Modes"
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        modeButton.draw(dc);
        ecoButton.draw(dc);
        dc.setColor(Graphics.COLOR_WHITE, Globals.offColor);
        dc.drawText(
            w/2,
            h*3/4,
            Graphics.FONT_XTINY,
            tapIconLabel, // "Tap Icons"
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        if (mNestStatus.getGotDeviceData()) {
            var posx = w/4-heatOffIcon.getWidth()/2;
            var posy = h/2-heatOffIcon.getHeight()/2;
            if (ecoMode) {
                dc.drawBitmap(posx, posy, ecoOnIcon);
            } else {
                dc.drawBitmap(posx, posy, ecoOffIcon);
            }

            posx = w*3/4-heatOffIcon.getWidth()/2;
            //mNestStatus.setThermoMode(supportedModes[modeStatus]);
            switch (thermoMode) {
                case "OFF":
                    dc.drawBitmap(posx, posy, heatOffIcon);
                    break;

                case "HEAT":
                    dc.drawBitmap(posx, posy, heatOnIcon);
                    break;

                case "COOL":
                    dc.drawBitmap(posx, posy, coolOnIcon);
                    break;

                case "HEATCOOL":
                    dc.drawBitmap(posx, posy, heatCoolIcon);
                    break;

                default:
                    if (Globals.debug) {
                        System.print("ERROR - ModeChangeView: Unsupported HVAC mode '" + thermoMode + "'");
                    }
                    break;
            }
        }

        mViewNav.draw(dc);
    }

    function onHide() as Void {
        mViewNav.resetAnimation();
    }

    // Action for tapping the mode button
    //
    function onModeButton() as Void {
        thermoMode = availableThermoModes[(availableThermoModes.indexOf(thermoMode)+1) % availableThermoModes.size()];
        if (thermoMode.equals("OFF")) {
            ecoMode = false;
        }
    }

    // Action for tapping the eco button
    //
    function onEcoButton() as Void {
        if (availableEcoModes.indexOf("MANUAL_ECO") != -1) {
            ecoMode = !ecoMode;
            if (ecoMode) {
                if (availableThermoModes.indexOf("HEATCOOL") != -1) {
                    thermoMode = "HEATCOOL";
                } else if (availableThermoModes.indexOf("HEAT") != -1) {
                    thermoMode = "HEAT";
                } else if (availableThermoModes.indexOf("COOL") != -1) {
                    thermoMode = "COOL";
                }
            }
        }
    }

    function getNestStatus() as NestStatus {
        return mNestStatus;
    }

}

class ModeChangeDelegate extends WatchUi.BehaviorDelegate {
    private var mView;
    private var cancelledAlert;

    function initialize(view as ModeChangeView) {
        WatchUi.BehaviorDelegate.initialize();
        mView = view;
        cancelledAlert = new Alert({
            :timeout => Globals.alertTimeout,
            :font    => Graphics.FONT_MEDIUM,
            :text    => WatchUi.loadResource($.Rez.Strings.cancelledAlert) as Lang.String,
            :fgcolor => Graphics.COLOR_RED,
            :bgcolor => Graphics.COLOR_BLACK
        });
    }

    function onModeButton() {
        mView.onModeButton(); 
    }

    function onEcoButton() {
        mView.onEcoButton(); 
    }

    function onBack() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_UP);
        cancelledAlert.pushView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onNextPage() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_UP);
        mView.getNestStatus().executeMode(
            NestStatus.Start,
            {
                :thermoMode => mView.getThermoMode(),
                :ecoMode    => mView.getEcoMode()
            }
        );
        return true;
    }
}
