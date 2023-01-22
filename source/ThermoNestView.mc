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
// ThermoNestView provides the main status view of the application.
//
//-----------------------------------------------------------------------------------

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Application.Properties;
using Toybox.Timer;


class ThermoNestView extends ThermoView {
    // Vertical space of bottom either side of centre icons for HVAC & Eco mode statuses
    hidden const modeHeight  = 60;
    // Horizontal spacing either side of centre for the HVAC & Eco mode statuses, i.e. the
    // icons are spaced at twice this value.
    hidden const modeSpacing = 5;
    // Vertical spacing either side of centre for the temperature values
    hidden const tempSpace   = 40;
    hidden const timeout     = 10000; // ms

    hidden var mViewNav;
    hidden var refreshButton;
    hidden var ecoOffIcon;
    hidden var ecoOnIcon;
    hidden var heatOffIcon;
    hidden var heatOnIcon;
    hidden var coolOnIcon;
    hidden var heatCoolIcon;
    hidden var humidityIcon;
    hidden var thermostatIcon;
    hidden var phoneDisconnectedIcon;
    hidden var signalDisconnectedIcon;
    hidden var thermostatOfflineIcon;
    hidden var refreshIcon;
    hidden var hourglassIcon;
    hidden var loggedOutIcon;
    hidden var errorIcon;
    hidden var setOffLabel as Lang.String;
    hidden var timer;

    function initialize(ns as NestStatus) {
        ThermoView.initialize(ns);
        setOffLabel = WatchUi.loadResource($.Rez.Strings.offStatus) as Lang.String;
    }

    // Load your resources here
    function onLayout(dc as Graphics.Dc) as Void {
        ecoOffIcon             = Application.loadResource(Rez.Drawables.EcoOffIcon            ) as Graphics.BitmapResource;
        ecoOnIcon              = Application.loadResource(Rez.Drawables.EcoOnIcon             ) as Graphics.BitmapResource;
        heatOffIcon            = Application.loadResource(Rez.Drawables.HeatOffIcon           ) as Graphics.BitmapResource;
        heatOnIcon             = Application.loadResource(Rez.Drawables.HeatOnIcon            ) as Graphics.BitmapResource;
        coolOnIcon             = Application.loadResource(Rez.Drawables.CoolOnIcon            ) as Graphics.BitmapResource;
        heatCoolIcon           = Application.loadResource(Rez.Drawables.HeatCoolIcon          ) as Graphics.BitmapResource;
        humidityIcon           = Application.loadResource(Rez.Drawables.HumidityIcon          ) as Graphics.BitmapResource;
        thermostatIcon         = Application.loadResource(Rez.Drawables.ThermostatIcon        ) as Graphics.BitmapResource;
        phoneDisconnectedIcon  = Application.loadResource(Rez.Drawables.PhoneDisconnectedIcon ) as Graphics.BitmapResource;
        signalDisconnectedIcon = Application.loadResource(Rez.Drawables.SignalDisconnectedIcon) as Graphics.BitmapResource;
        thermostatOfflineIcon  = Application.loadResource(Rez.Drawables.ThermostatOfflineIcon ) as Graphics.BitmapResource;
        refreshIcon            = Application.loadResource(Rez.Drawables.RefreshIcon           ) as Graphics.BitmapResource;
        hourglassIcon          = Application.loadResource(Rez.Drawables.HourglassIcon         ) as Graphics.BitmapResource;
        loggedOutIcon          = Application.loadResource(Rez.Drawables.LoggedOutIcon         ) as Graphics.BitmapResource;
        errorIcon              = Application.loadResource(Rez.Drawables.ErrorIcon             ) as Graphics.BitmapResource;
        mViewNav               = new ViewNav({
            :identifier => "StatusPane",
            :locX       => Globals.navMarginX,
            :locY       => dc.getHeight()/2,
            :radius     => Globals.navRadius,
            :panes      => Globals.navPanes,
            :nth        => 2, // 1-based numbering
            :visible    => true,
            :timeout    => Globals.navDelay,
            :period     => Globals.navPeriod
        });
        timer = new Timer.Timer();

        var bRefreshDisabledIcon = new WatchUi.Bitmap({ :rezId => $.Rez.Drawables.RefreshDisabledIcon });

        // A two element array containing the width and height of the Bitmap object
        var dim = bRefreshDisabledIcon.getDimensions();
        refreshButton = new WatchUi.Button({
            :stateDefault             => Graphics.COLOR_TRANSPARENT,
            :stateHighlighted         => Graphics.COLOR_TRANSPARENT,
            :stateSelected            => Graphics.COLOR_TRANSPARENT,
            :stateDisabled            => bRefreshDisabledIcon,
            :stateHighlightedSelected => Graphics.COLOR_TRANSPARENT,
            :background               => Graphics.COLOR_TRANSPARENT,
            :behavior                 => :onRefreshButton,
            :locX                     => (dc.getWidth() - dim[0]) / 2,
            :locY                     => statusHeight,
            :width                    => dim[0],
            :height                   => dim[1]
        });
        setLayout([refreshButton]);
    }

    function onShow() as Void {
        mViewNav.animate();
        enableRefresh();
    }

    // Update the view
    function onUpdate(dc as Graphics.Dc) as Void {
        if (Globals.debug) {
            System.println("ThermoNestView onUpdate()");
        }
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var hw = w/2;
        var hh = h/2;

        dc.setAntiAlias(true);
        dc.setColor(
            Graphics.COLOR_WHITE,
            mNestStatus.getHvac().equals("HEATING")
                ? Globals.heatingColor
                : mNestStatus.getHvac().equals("COOLING")
                    ? Globals.coolingColor
                    : Globals.offColor
        );
        dc.clear();
        if (mNestStatus.getGotDeviceData()) {
            var ambientTemp = mNestStatus.getAmbientTemp();
            if (ambientTemp != null) {
                var heatTemp = null;
                var coolTemp = null;
                var thermoMode = mNestStatus.getThermoMode();
                if (mNestStatus.getEco()) {
                    if (thermoMode.equals("HEAT") || thermoMode.equals("HEATCOOL")) {
                        heatTemp = mNestStatus.getEcoHeatTemp();
                    }
                    if (thermoMode.equals("COOL") || thermoMode.equals("HEATCOOL")) {
                        coolTemp = mNestStatus.getEcoCoolTemp();
                    }
                } else {
                    if (thermoMode.equals("HEAT") || thermoMode.equals("HEATCOOL")) {
                        heatTemp = mNestStatus.getHeatTemp();
                    }
                    if (thermoMode.equals("COOL") || thermoMode.equals("HEATCOOL")) {
                        coolTemp = mNestStatus.getCoolTemp();
                    }
                }

                drawTempScale(dc, ambientTemp, heatTemp, coolTemp);

                if (mNestStatus.getThermoMode().equals("HEATCOOL") && (heatTemp != null) && (coolTemp != null)) {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(
                        hw,
                        hh - tempSpace,
                        Graphics.FONT_MEDIUM,
                        Lang.format("$1$°$3$ • $2$°$3$", [heatTemp.format("%2.1f"), coolTemp.format("%2.1f"), mNestStatus.getScale()]),
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                    );
                } else if (mNestStatus.getThermoMode().equals("HEAT") && (heatTemp != null)) {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(
                        hw,
                        hh - tempSpace,
                        Graphics.FONT_MEDIUM,
                        Lang.format("$1$°$2$", [heatTemp.format("%2.1f"), mNestStatus.getScale()]),
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                    );
                } else if (mNestStatus.getThermoMode().equals("COOL") && (coolTemp != null)) {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(
                        hw,
                        hh - tempSpace,
                        Graphics.FONT_MEDIUM,
                        Lang.format("$1$°$2$", [coolTemp.format("%2.1f"), mNestStatus.getScale()]),
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                    );
                } else {
                    dc.setColor(darkGreyColor, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(
                        hw,
                        hh - tempSpace,
                        Graphics.FONT_MEDIUM,
                        setOffLabel,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                    );
                }

                dc.setColor(darkGreyColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    hw,
                    hh + tempSpace,
                    Graphics.FONT_MEDIUM,
                    Lang.format("$1$°$2$", [ambientTemp.format("%2.1f"), mNestStatus.getScale()]),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }

            var humidity = mNestStatus.getHumidity();
            dc.drawBitmap(hw - humidityIcon.getWidth() - 15, h * 3/4 - humidityIcon.getHeight()/2, humidityIcon);
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                hw + 25,
                h * 3/4,
                Graphics.FONT_TINY,
                Lang.format("$1$%", [humidity.format("%2.0f")]),
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
        }

        refreshButton.draw(dc);
        // Overdraw the button when enabled
        if (refreshButton.getState() != :stateDisabled) {
            if (System.getDeviceSettings().phoneConnected) {
                if (System.getDeviceSettings().connectionAvailable) {
                    var c = Properties.getValue("oauthCode");
                    if (c != null && !c.equals("")) {
                        if (mNestStatus.getGotDeviceData()) {
                            if (mNestStatus.getGotDeviceDataError()) {
                                dc.drawBitmap(hw - errorIcon.getWidth()/2, statusHeight, errorIcon);
                            } else if (!mNestStatus.getOnline()) {
                                dc.drawBitmap(hw - thermostatOfflineIcon.getWidth()/2, statusHeight, thermostatOfflineIcon);
                            } else {
                                dc.drawBitmap(hw - refreshIcon.getWidth()/2, statusHeight, refreshIcon);
                            }
                        } else {
                            dc.drawBitmap(hw - hourglassIcon.getWidth()/2, statusHeight, hourglassIcon);
                        }
                    } else {
                        dc.drawBitmap(hw - loggedOutIcon.getWidth()/2, statusHeight, loggedOutIcon);
                    }
                } else {
                    dc.drawBitmap(hw - signalDisconnectedIcon.getWidth()/2, statusHeight, signalDisconnectedIcon);
                }
            } else {
                dc.drawBitmap(hw - phoneDisconnectedIcon.getWidth()/2, statusHeight, phoneDisconnectedIcon);
            }
        }

        mViewNav.draw(dc);
    }

    function onHide() as Void {
        mViewNav.resetAnimation();
        timer.stop();
        enableRefresh();
    }

    function onRefreshButton() as Void {
        // Assume the application has not been used in excess of 3600s such that the token has expired
        mNestStatus.getDeviceData();
        refreshButton.setState(:stateDisabled);
        timer.start(method(:enableRefresh), timeout, false);
    }

    function enableRefresh() as Void {
        if (refreshButton != null) {
            refreshButton.setState(:stateDefault);
        }
        requestUpdate();
    }

    function getNestStatus() as NestStatus {
        return mNestStatus;
    }
}

class ThermoNestDelegate extends WatchUi.BehaviorDelegate {
    hidden var mView;

    function initialize(view) {
        WatchUi.BehaviorDelegate.initialize();
        mView = view;
    }

    function onRefreshButton() {
        return mView.onRefreshButton();
    }

    function onPreviousPage() {
        if (System.getDeviceSettings().phoneConnected && System.getDeviceSettings().connectionAvailable) {
            var v = new ModeChangeView(mView.getNestStatus());
            WatchUi.pushView(v, new ModeChangeDelegate(v), WatchUi.SLIDE_UP);
        }
        return true;
    }

    function onNextPage() {
        if (System.getDeviceSettings().phoneConnected && System.getDeviceSettings().connectionAvailable) {
            var v = new TempChangeView(mView.getNestStatus());
            WatchUi.pushView(v, new TempChangeDelegate(v), WatchUi.SLIDE_UP);
        }
        return true;
    }
}
