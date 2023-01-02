import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Application.Properties;

(:glance)
class NestThermoGlanceView extends WatchUi.GlanceView {
    hidden var mNestStatus;

    hidden var phoneDisconnectedIcon;
    hidden var signalDisconnectedIcon;
    hidden var thermostatOfflineIcon;
    hidden var loggedOutIcon;
    hidden var errorIcon;
    hidden var refreshIcon;

    function initialize(n) {
        GlanceView.initialize();
        mNestStatus = n;
    }

    function onLayout(dc as Dc) as Void {
        phoneDisconnectedIcon  = Application.loadResource(Rez.Drawables.PhoneDisconnectedIcon ) as Graphics.BitmapResource;
        signalDisconnectedIcon = Application.loadResource(Rez.Drawables.SignalDisconnectedIcon) as Graphics.BitmapResource;
        thermostatOfflineIcon  = Application.loadResource(Rez.Drawables.ThermostatOfflineIcon ) as Graphics.BitmapResource;
        loggedOutIcon          = Application.loadResource(Rez.Drawables.LoggedOutIcon         ) as Graphics.BitmapResource;
        errorIcon              = Application.loadResource(Rez.Drawables.ErrorIcon             ) as Graphics.BitmapResource;
        refreshIcon            = Application.loadResource(Rez.Drawables.RefreshIcon           ) as Graphics.BitmapResource;
    }

    function onUpdate(dc) {
        if (System.getDeviceSettings().phoneConnected) {
            if (mNestStatus.getWifiConnection()) {
                var c = Properties.getValue("oauthCode");
                if (c != null && !c.equals("")) {
                    if (!mNestStatus.gotDeviceDataError) {
                        if (mNestStatus.gotDeviceData) {
                            if (!mNestStatus.getOnline()) {
                                dc.drawBitmap(10, dc.getHeight()/2 - 24, thermostatOfflineIcon);
                                return;
                            }
                        } else {
                            dc.drawBitmap(10, dc.getHeight()/2 - 24, refreshIcon);
                            return;
                        }
                    } else {
                        dc.drawBitmap(10, dc.getHeight()/2 - 24, errorIcon);
                    }
                } else {
                    dc.drawBitmap(10, dc.getHeight()/2 - 24, loggedOutIcon);
                    return;
                }
            } else {
                dc.drawBitmap(10, dc.getHeight()/2 - 24, signalDisconnectedIcon);
                return;
            }
        } else {
            dc.drawBitmap(10, dc.getHeight()/2 - 24, phoneDisconnectedIcon);
            return;
        }

        var heat = mNestStatus.getHeatTemp();
        var cool = mNestStatus.getCoolTemp();
        var text;

        if (mNestStatus.getThermoMode().equals("HEATCOOL") && (heat != null) && (cool != null)) {
            text = Lang.format("$1$°$3$ • $2$°$3$", [heat.format("%2.1f"), cool.format("%2.1f"), mNestStatus.getScale()]);
        } else if (mNestStatus.getThermoMode().equals("HEAT") && (heat != null)) {
            text = Lang.format("$1$°$2$", [heat.format("%2.1f"), mNestStatus.getScale()]);
        } else if (mNestStatus.getThermoMode().equals("COOL") && (cool != null)) {
            text = Lang.format("$1$°$2$", [cool.format("%2.1f"), mNestStatus.getScale()]);
        } else {
            text = "OFF";
        }

        dc.setColor(Graphics.COLOR_WHITE,
                    mNestStatus.getHvac().equals("HEATING")
                        ? 0xEC7800
                        : mNestStatus.getHvac().equals("COOLING")
                            ? 0x285DF7
                            : 0x3B444C);
        dc.clear();
        dc.drawText(
            10, dc.getHeight()/2, Graphics.FONT_SMALL,
            text,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function requestCallback() as Void {
        requestUpdate();
    }
}