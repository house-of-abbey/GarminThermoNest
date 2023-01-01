import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Application.Properties;

class NestThermoView extends WatchUi.View {
    public var mNestStatus;

    hidden var ecoOffIcon;
    hidden var ecoOnIcon;
    hidden var heatOffIcon;
    hidden var heatOnIcon;
    hidden var coolOnIcon;
    hidden var heatCoolIcon;
    hidden var thermostatIcon;
    hidden var phoneDisconnectedIcon;
    hidden var signalDisconnectedIcon;
    hidden var thermostatOfflineIcon;
    hidden var refreshIcon;
    hidden var loggedOutIcon;
    hidden var errorIcon;

    var buttons as Array<WatchUi.Button> = new Array<WatchUi.Button>[1];

    hidden var wifiConnection = true;
    function onRecieveWifiConnection(result as { :errorCode as Communications.WifiConnectionStatus, :wifiAvailable as Lang.Boolean }) as Void {
        wifiConnection = result.get(:wifiAvailable);
        requestUpdate();
    }
    function onRecieveWifiConnectionA(result as { :errorCode as Communications.WifiConnectionStatus, :wifiAvailable as Lang.Boolean }) as Void {
        if (result.get(:wifiAvailable)) {
            var c = Properties.getValue("oauthCode");
            if (c != null && !c.equals("")) {
                mNestStatus.getOAuthToken();
                requestUpdate();
            }
        }
        onRecieveWifiConnection(result);
    }

    function initialize() {
        View.initialize();
        mNestStatus = new NestStatus(method(:requestCallback));
        Communications.checkWifiConnection(method(:onRecieveWifiConnectionA));
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        ecoOffIcon             = Application.loadResource(Rez.Drawables.EcoOffIcon            ) as Graphics.BitmapResource;
        ecoOnIcon              = Application.loadResource(Rez.Drawables.EcoOnIcon             ) as Graphics.BitmapResource;
        heatOffIcon            = Application.loadResource(Rez.Drawables.HeatOffIcon           ) as Graphics.BitmapResource;
        heatOnIcon             = Application.loadResource(Rez.Drawables.HeatOnIcon            ) as Graphics.BitmapResource;
        coolOnIcon             = Application.loadResource(Rez.Drawables.CoolOnIcon            ) as Graphics.BitmapResource;
        heatCoolIcon           = Application.loadResource(Rez.Drawables.HeatCoolIcon          ) as Graphics.BitmapResource;
        thermostatIcon         = Application.loadResource(Rez.Drawables.ThermostatIcon        ) as Graphics.BitmapResource;
        phoneDisconnectedIcon  = Application.loadResource(Rez.Drawables.PhoneDisconnectedIcon ) as Graphics.BitmapResource;
        signalDisconnectedIcon = Application.loadResource(Rez.Drawables.SignalDisconnectedIcon) as Graphics.BitmapResource;
        thermostatOfflineIcon  = Application.loadResource(Rez.Drawables.ThermostatOfflineIcon ) as Graphics.BitmapResource;
        refreshIcon            = Application.loadResource(Rez.Drawables.RefreshIcon           ) as Graphics.BitmapResource;
        loggedOutIcon          = Application.loadResource(Rez.Drawables.LoggedOutIcon         ) as Graphics.BitmapResource;
        errorIcon              = Application.loadResource(Rez.Drawables.ErrorIcon             ) as Graphics.BitmapResource;

        var bRefreshDisabledIcon = new WatchUi.Bitmap({ :rezId => $.Rez.Drawables.RefreshDisabledIcon });
        buttons[0] = new WatchUi.Button({
            :stateDefault             => Graphics.COLOR_TRANSPARENT,
            :stateHighlighted         => Graphics.COLOR_TRANSPARENT,
            :stateSelected            => Graphics.COLOR_TRANSPARENT,
            :stateDisabled            => bRefreshDisabledIcon,
            :stateHighlightedSelected => Graphics.COLOR_TRANSPARENT,
            :background               => Graphics.COLOR_TRANSPARENT,
            :behavior                 => :onButton0,
            :locX                     => dc.getWidth()/2 - 24,
            :locY                     => 30,
            :width                    => 48,
            :height                   => 48
        });
        setLayout(buttons);
    }

    function lerp(x, a, b, A, B) {
        return (x - a) / (b - a) * (B - A) + A;
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var hw = w/2;
        var hh = h/2;
        var bg = 0x3B444C;
        dc.setColor(Graphics.COLOR_WHITE,
                    mNestStatus.getHvac().equals("HEATING")
                        ? 0xEC7800
                        : mNestStatus.getHvac().equals("COOLING")
                            ? 0x285DF7
                            : bg);
        dc.clear();
        dc.setColor(0xaaaaaa, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(hw, hh, hw - 10, Graphics.ARC_CLOCKWISE, 240f, -60f);

        if (mNestStatus.gotDeviceData) {
            var ambientTemperature = mNestStatus.getAmbientTemp();
            if (ambientTemperature != null) {
                var heat = mNestStatus.getHeatTemp();
                var cool = mNestStatus.getCoolTemp();
                var ambientTemperatureArc = mNestStatus.getScale() == 'C'
                    ? lerp(ambientTemperature, 9f, 32f, 240f, -60f)
                    : lerp(ambientTemperature, 48f, 90f, 240f, -60f);
                if (heat != null) {
                    var heatArc = mNestStatus.getScale() == 'C'
                        ? lerp(heat, 9f, 32f, 240f, -60f)
                        : lerp(heat, 48f, 90f, 240f, -60f);
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    if (ambientTemperature > heat) {
                        dc.drawArc(hw, hh, hw -  9, Graphics.ARC_CLOCKWISE, heatArc, ambientTemperatureArc);
                        dc.drawArc(hw, hh, hw - 10, Graphics.ARC_CLOCKWISE, heatArc, ambientTemperatureArc);
                        dc.drawArc(hw, hh, hw - 11, Graphics.ARC_CLOCKWISE, heatArc, ambientTemperatureArc);
                    } else {
                        dc.drawArc(hw, hh, hw -  9, Graphics.ARC_CLOCKWISE, ambientTemperatureArc, heatArc);
                        dc.drawArc(hw, hh, hw - 10, Graphics.ARC_CLOCKWISE, ambientTemperatureArc, heatArc);
                        dc.drawArc(hw, hh, hw - 11, Graphics.ARC_CLOCKWISE, ambientTemperatureArc, heatArc);
                    }
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    var hrad = Math.toRadians(360 - heatArc);
                    var ha = Math.cos(hrad);
                    var hb = Math.sin(hrad);
                    dc.drawLine(ha*(hw - 20) + hw, hb*(hh - 20) + hh, ha*(hw - 5) + hw, hb*(hh - 5) + hh);
                }
                if (cool != null) {
                    var coolArc = mNestStatus.getScale() == 'C'
                        ? lerp(cool, 9f, 32f, 240f, -60f)
                        : lerp(cool, 48f, 90f, 240f, -60f);
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    if (ambientTemperature > cool) {
                        dc.drawArc(hw, hh, hw -  9, Graphics.ARC_CLOCKWISE, coolArc, ambientTemperatureArc);
                        dc.drawArc(hw, hh, hw - 10, Graphics.ARC_CLOCKWISE, coolArc, ambientTemperatureArc);
                        dc.drawArc(hw, hh, hw - 11, Graphics.ARC_CLOCKWISE, coolArc, ambientTemperatureArc);
                    } else {
                        dc.drawArc(hw, hh, hw -  9, Graphics.ARC_CLOCKWISE, ambientTemperatureArc, coolArc);
                        dc.drawArc(hw, hh, hw - 10, Graphics.ARC_CLOCKWISE, ambientTemperatureArc, coolArc);
                        dc.drawArc(hw, hh, hw - 11, Graphics.ARC_CLOCKWISE, ambientTemperatureArc, coolArc);
                    }
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    var crad = Math.toRadians(360 - coolArc);
                    var ca = Math.cos(crad);
                    var cb = Math.sin(crad);
                    dc.drawLine(ca*(hw - 20) + hw, cb*(hh - 20) + hh, ca*(hw - 5) + hw, cb*(hh - 5) + hh);
                }
                dc.setColor(0xaaaaaa, Graphics.COLOR_TRANSPARENT);
                var arad = Math.toRadians(360 - ambientTemperatureArc + 1);
                var aa = Math.cos(arad);
                var ab = Math.sin(arad);
                dc.drawLine(aa*(hw - 15) + hw, ab*(hh - 15) + hh, aa*(hw - 5) + hw, ab*(hh - 5) + hh);

                if (mNestStatus.getEco()) {
                    dc.setColor(0x00801c, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(hw, hh - 30, Graphics.FONT_MEDIUM, "ECO",
                                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                } else {
                    if (mNestStatus.getThermoMode().equals("HEATCOOL") && (heat != null) && (cool != null)) {
                        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(hw, hh - 30, Graphics.FONT_MEDIUM,
                                    Lang.format("$1$°$3$ • $2$°$3$", [heat.format("%2.1f"), cool.format("%2.1f"), mNestStatus.getScale()]),
                                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                    } else if (mNestStatus.getThermoMode().equals("HEAT") && (heat != null)) {
                        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(hw, hh - 30, Graphics.FONT_MEDIUM,
                                    Lang.format("$1$°$2$", [heat.format("%2.1f"), mNestStatus.getScale()]),
                                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                    } else if (mNestStatus.getThermoMode().equals("COOL") && (cool != null)) {
                        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(hw, hh - 30, Graphics.FONT_MEDIUM,
                                    Lang.format("$1$°$2$", [cool.format("%2.1f"), mNestStatus.getScale()]),
                                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                    } else {
                        dc.setColor(0xaaaaaa, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(hw, hh - 30, Graphics.FONT_MEDIUM, "OFF",
                                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                    }
                }
                dc.setColor(0xaaaaaa, Graphics.COLOR_TRANSPARENT);
                dc.drawText(hw, hh + 30, Graphics.FONT_MEDIUM,
                            Lang.format("$1$°$2$", [ambientTemperature.format("%2.1f"), mNestStatus.getScale()]),
                            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }

            if (mNestStatus.getEco()) {
                dc.drawBitmap(hw - 53, h - 80, ecoOnIcon);
            } else {
                dc.drawBitmap(hw - 53, h - 80, ecoOffIcon);
            }

            if (mNestStatus.getThermoMode().equals("HEATCOOL")) {
                dc.drawBitmap(hw + 5, h - 80, heatCoolIcon);
            } else if (mNestStatus.getThermoMode().equals("HEAT")) {
                dc.drawBitmap(hw + 5, h - 80, heatOnIcon);
            } else if (mNestStatus.getThermoMode().equals("COOL")) {
                dc.drawBitmap(hw + 5, h - 80, heatOnIcon);
            } else {
                dc.drawBitmap(hw + 5, h - 80, heatOffIcon);
            }
        }

        if (System.getDeviceSettings().phoneConnected) {
            if (wifiConnection) {
                var c = Properties.getValue("oauthCode");
                if (c != null && !c.equals("")) {
                    if (mNestStatus.getOnline() || !mNestStatus.gotDeviceData) {
                        if (!mNestStatus.gotDeviceDataError) {
                            dc.drawBitmap(hw - 24, 30, refreshIcon);
                        } else {
                            dc.drawBitmap(hw - 24, 30, errorIcon);
                        }
                    } else {
                        dc.drawBitmap(hw - 24, 30, thermostatOfflineIcon);
                    }
                } else {
                    dc.drawBitmap(hw - 24, 30, loggedOutIcon);
                }
            } else {
                dc.drawBitmap(hw - 24, 30, signalDisconnectedIcon);
            }
        } else {
            dc.drawBitmap(hw - 24, 30, phoneDisconnectedIcon);
        }
        buttons[0].draw(dc);
    }

    function requestCallback() as Void {
        buttons[0].setState(:stateDefault);
        requestUpdate();
    }

    function onButton0() as Void {
        Communications.checkWifiConnection(method(:onRecieveWifiConnection));
        mNestStatus.getOAuthToken();
        buttons[0].setState(:stateDisabled);
        requestUpdate();
    }
}

class NestThermoDelegate extends WatchUi.BehaviorDelegate {
    var mView;
    function initialize(v) {
        WatchUi.BehaviorDelegate.initialize();
        mView = v;
    }
    function onButton0() {
        return mView.onButton0(); 
    }
    function onPreviousPage() {
        if (System.getDeviceSettings().phoneConnected) {
            var v = new ModeChangeView(mView.mNestStatus);
            WatchUi.pushView(v, new ModeChangeDelegate(v), WatchUi.SLIDE_UP);
        }
        return true;
    }
    function onNextPage() {
        if (System.getDeviceSettings().phoneConnected) {
            var v = new TempChangeView(mView.mNestStatus);
            WatchUi.pushView(v, new TempChangeDelegate(v), WatchUi.SLIDE_UP);
        }
        return true;
    }
}