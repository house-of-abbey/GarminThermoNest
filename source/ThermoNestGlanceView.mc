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
    private var screenWidth;
    private const cXOffset = 2.4f;
    // Horizontal offset at which to draw the icon or write text
    private var xOffset;
    private var mNestStatus;
    private var phoneDisconnectedIcon;
    private var signalDisconnectedIcon;
    private var thermostatOfflineIcon;
    private var errorIcon;
    private var hourglassIcon;
    private var setOffLabel   as Lang.String;
    private var oAuthPropFail as Lang.String;

    function initialize(ns as NestStatus) {
        GlanceView.initialize();
        mNestStatus     = ns;
        xOffset         = pixelsForScreen(cXOffset);
        setOffLabel     = WatchUi.loadResource($.Rez.Strings.offStatus    ) as Lang.String;
        oAuthPropFail   = WatchUi.loadResource($.Rez.Strings.oAuthPropFail) as Lang.String;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        phoneDisconnectedIcon  = Application.loadResource(Rez.Drawables.PhoneDisconnectedIcon ) as Graphics.BitmapResource;
        signalDisconnectedIcon = Application.loadResource(Rez.Drawables.SignalDisconnectedIcon) as Graphics.BitmapResource;
        thermostatOfflineIcon  = Application.loadResource(Rez.Drawables.ThermostatOfflineIcon ) as Graphics.BitmapResource;
        errorIcon              = Application.loadResource(Rez.Drawables.ErrorIcon             ) as Graphics.BitmapResource;
        hourglassIcon          = Application.loadResource(Rez.Drawables.HourglassIcon         ) as Graphics.BitmapResource;
    }

    function onUpdate(dc) {
        var o = Properties.getValue("oauthCode");
        var d = Properties.getValue("deviceId");
        if (System.getDeviceSettings().phoneConnected) {
            if (System.getDeviceSettings().connectionAvailable) {
                if (o == null || o.equals("")) {
                    // Drop through without a return to print text
                } else {
                    if (d == null || d.equals("")) {
                        // Drop through without a return to print text
                    } else {
                        if (mNestStatus.getGotDeviceData()) {
                            if (mNestStatus.getGotDeviceDataError()) {
                                dc.drawBitmap(xOffset, (dc.getHeight()-errorIcon.getHeight())/2, errorIcon);
                                return;
                            } else {
                                if (!mNestStatus.getOnline()) {
                                    dc.drawBitmap(xOffset, (dc.getHeight()-thermostatOfflineIcon.getHeight())/2, thermostatOfflineIcon);
                                    return;
                                }
                                // Else drop through without a return and no icon to print text
                            }
                        } else {
                            dc.drawBitmap(xOffset, (dc.getHeight()-hourglassIcon.getHeight())/2, hourglassIcon);
                            return;
                        }
                    }
                }
            } else {
                dc.drawBitmap(xOffset, (dc.getHeight()-signalDisconnectedIcon.getHeight())/2, signalDisconnectedIcon);
                return;
            }
        } else {
            dc.drawBitmap(xOffset, (dc.getHeight()-phoneDisconnectedIcon.getHeight())/2, phoneDisconnectedIcon);
            return;
        }

        var heat = mNestStatus.getHeatTemp();
        var cool = mNestStatus.getCoolTemp();
        var text;

        if (o == null || o.equals("") || o.equals(oAuthPropFail)) {
            text = WatchUi.loadResource($.Rez.Strings.getOAuthCodeMsg) as Lang.String;
        } else if (d == null || d.equals("")) {
            text = WatchUi.loadResource($.Rez.Strings.selectDevice) as Lang.String;;
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
                    : Graphics.COLOR_TRANSPARENT
        );
        dc.clear();
        dc.drawText(
            xOffset,
            dc.getHeight() / 2,
            Graphics.FONT_SMALL,
            text,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // Convert a fraction expressed as a percentage (%) to a number of pixels for the
    // screen's dimensions.
    //
    // Parameters:
    //  * dc - Device context
    //  * pc - Percentage (%) expressed as a number in the range 0.0..100.0
    //
    // Uses screen width rather than screen height as rectangular screens tend to have
    // height > width.
    //
    function pixelsForScreen(pc as Lang.Float) as Lang.Number {
        if (screenWidth == null) {
            screenWidth = System.getDeviceSettings().screenWidth;
        }
        return Math.round(pc * screenWidth) / 100;
    }

}
