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
// ThermoNestGlanceView provides the summary status as an application 'glance'.
//
// References:
//  * Sandbox Rate Limits https://developers.google.com/nest/device-access/project/limits
//
//-----------------------------------------------------------------------------------

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Communications;
using Toybox.Application.Properties;

(:glance)
class ThermoNestGlanceView extends WatchUi.GlanceView {
    hidden var mNestStatus;
    hidden var phoneDisconnectedIcon;
    hidden var signalDisconnectedIcon;
    hidden var thermostatOfflineIcon;
    hidden var loggedOutIcon;
    hidden var errorIcon;
    hidden var hourglassIcon;
    hidden var setOffLabel as Lang.String;
    hidden var selectDeviceMenuTitle as Lang.String;

    function initialize() {
        GlanceView.initialize();
        mNestStatus           = new NestStatus(method(:requestCallback));
        mNestStatus.isGlance  = true;
        setOffLabel           = WatchUi.loadResource($.Rez.Strings.offStatus   ) as Lang.String;
        selectDeviceMenuTitle = WatchUi.loadResource($.Rez.Strings.selectDevice) as Lang.String;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        phoneDisconnectedIcon  = Application.loadResource(Rez.Drawables.PhoneDisconnectedIcon ) as Graphics.BitmapResource;
        signalDisconnectedIcon = Application.loadResource(Rez.Drawables.SignalDisconnectedIcon) as Graphics.BitmapResource;
        thermostatOfflineIcon  = Application.loadResource(Rez.Drawables.ThermostatOfflineIcon ) as Graphics.BitmapResource;
        loggedOutIcon          = Application.loadResource(Rez.Drawables.LoggedOutIcon         ) as Graphics.BitmapResource;
        errorIcon              = Application.loadResource(Rez.Drawables.ErrorIcon             ) as Graphics.BitmapResource;
        hourglassIcon          = Application.loadResource(Rez.Drawables.HourglassIcon         ) as Graphics.BitmapResource;
    }

    function onUpdate(dc) {
        var d = Properties.getValue("deviceId");
        if (System.getDeviceSettings().phoneConnected) {
            if (System.getDeviceSettings().connectionAvailable) {
                var c = Properties.getValue("oauthCode");
                if (c == null || c.equals("")) {
                    dc.drawBitmap(10, (dc.getHeight()-loggedOutIcon.getHeight())/2, loggedOutIcon);
                    return;
                } else {
                    if (d == null || d.equals("")) {
                        dc.drawBitmap(10, (dc.getHeight()-thermostatOfflineIcon.getHeight())/2, thermostatOfflineIcon);
                        // Else drop through without a return to print text
                    } else {
                        if (mNestStatus.getGotDeviceData()) {
                            if (mNestStatus.getGotDeviceDataError()) {
                                dc.drawBitmap(10, (dc.getHeight()-errorIcon.getHeight())/2, errorIcon);
                                return;
                            } else {
                                if (!mNestStatus.getOnline()) {
                                    dc.drawBitmap(10, (dc.getHeight()-thermostatOfflineIcon.getHeight())/2, thermostatOfflineIcon);
                                    return;
                                }
                                // Else drop through without a return and no icon to print text
                            }
                        } else {
                            dc.drawBitmap(10, (dc.getHeight()-hourglassIcon.getHeight())/2, hourglassIcon);
                            return;
                        }
                    }
                }
            } else {
                dc.drawBitmap(10, (dc.getHeight()-signalDisconnectedIcon.getHeight())/2, signalDisconnectedIcon);
                return;
            }
        } else {
            dc.drawBitmap(10, (dc.getHeight()-phoneDisconnectedIcon.getHeight())/2, phoneDisconnectedIcon);
            return;
        }

        var heat = mNestStatus.getHeatTemp();
        var cool = mNestStatus.getCoolTemp();
        var text;

        if (d == null || d.equals("")) {
            text = selectDeviceMenuTitle;
        } else if (mNestStatus.getThermoMode().equals("HEATCOOL") && (heat != null) && (cool != null)) {
            text = Lang.format("$1$°$3$ • $2$°$3$", [heat.format("%2.1f"), cool.format("%2.1f"), mNestStatus.getScale()]);
        } else if (mNestStatus.getThermoMode().equals("HEAT") && (heat != null)) {
            text = Lang.format("$1$°$2$", [heat.format("%2.1f"), mNestStatus.getScale()]);
        } else if (mNestStatus.getThermoMode().equals("COOL") && (cool != null)) {
            text = Lang.format("$1$°$2$", [cool.format("%2.1f"), mNestStatus.getScale()]);
        } else {
            text = setOffLabel;
        }

        dc.setColor(
            Graphics.COLOR_WHITE,
            mNestStatus.getHvac().equals("HEATING")
                ? Globals.heatingColor
                : mNestStatus.getHvac().equals("COOLING")
                    ? Globals.coolingColor
                    : Globals.offColor
        );
        dc.clear();
        dc.drawText(
            10,
            dc.getHeight()/2,
            Graphics.FONT_SMALL,
            text,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function requestCallback() as Void {
        requestUpdate();
    }
}