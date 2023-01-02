import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
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

    function initialize(n) {
        View.initialize();
        mNestStatus = n;
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
        var w           = dc.getWidth();
        var h           = dc.getHeight();
        var hw          = w/2;
        var hh          = h/2;

        // These could be constants, but then they are located a long textual distance away
        // Between the full range arc and the outside of the watch face
        var margin      = 14;
        // Line width of the full range arc
        var full_arc_w  = 4;
        // Line width of the range arc (thicker than full_arc_w)
        var range_arc_w = 8;
        // Line width of a tick mark
        var tick_w      = 4;
        // Ticks start at: watch radius - tick_st_r
        var tick_st_r   = 5;
        // Temperature range ends: watch radius - tick_ren_r
        var tick_ren_r   = 25;
        // Ambient temperature: watch radius - tick_aen_r
        var tick_aen_r   = 20;

        dc.setColor(Graphics.COLOR_WHITE,
                    mNestStatus.getHvac().equals("HEATING")
                        ? 0xEC7800
                        : mNestStatus.getHvac().equals("COOLING")
                            ? 0x285DF7
                            : 0x3B444C);
        dc.clear();
        dc.setColor(0xaaaaaa, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(full_arc_w);
        dc.drawArc(hw, hh, hw - margin, Graphics.ARC_CLOCKWISE, 240f, -60f);
        if (mNestStatus.gotDeviceData) {
            var ambientTemperature = mNestStatus.getAmbientTemp();
            if (ambientTemperature != null) {
                var heat = mNestStatus.getHeatTemp();
                var cool = mNestStatus.getCoolTemp();
                var ambientTemperatureArc = mNestStatus.getScale() == 'C'
                    ? lerp(ambientTemperature, 9f, 32f, 240f, -60f)
                    : lerp(ambientTemperature, 48f, 90f, 240f, -60f);
                if ((heat != null) && (heat != ambientTemperature)) {
                    var heatArc = mNestStatus.getScale() == 'C'
                        ? lerp(heat, 9f, 32f, 240f, -60f)
                        : lerp(heat, 48f, 90f, 240f, -60f);
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    dc.setPenWidth(range_arc_w);
                    if (ambientTemperature > heat) {
                        dc.drawArc(hw, hh, hw - margin, Graphics.ARC_CLOCKWISE, heatArc, ambientTemperatureArc);
                    } else {
                        dc.drawArc(hw, hh, hw - margin, Graphics.ARC_CLOCKWISE, ambientTemperatureArc, heatArc);
                    }
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    dc.setPenWidth(tick_w);
                    var hrad = Math.toRadians(360 - heatArc);
                    var ha = Math.cos(hrad);
                    var hb = Math.sin(hrad);
                    dc.drawLine(ha*(hw - tick_ren_r) + hw, hb*(hh - tick_ren_r) + hh, ha*(hw - tick_st_r) + hw, hb*(hh - tick_st_r) + hh);
                }
                if ((cool != null) && (cool != ambientTemperature)) {
                    var coolArc = mNestStatus.getScale() == 'C'
                        ? lerp(cool, 9f, 32f, 240f, -60f)
                        : lerp(cool, 48f, 90f, 240f, -60f);
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    dc.setPenWidth(range_arc_w);
                    if (ambientTemperature > cool) {
                        dc.drawArc(hw, hh, hw - margin, Graphics.ARC_CLOCKWISE, coolArc, ambientTemperatureArc);
                    } else {
                        dc.drawArc(hw, hh, hw - margin, Graphics.ARC_CLOCKWISE, ambientTemperatureArc, coolArc);
                    }
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    dc.setPenWidth(tick_w);
                    var crad = Math.toRadians(360 - coolArc);
                    var ca = Math.cos(crad);
                    var cb = Math.sin(crad);
                    dc.drawLine(ca*(hw - tick_ren_r) + hw, cb*(hh - tick_ren_r) + hh, ca*(hw - tick_st_r) + hw, cb*(hh - tick_st_r) + hh);
                }
                dc.setColor(0xaaaaaa, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(tick_w);
                var arad = Math.toRadians(360 - ambientTemperatureArc + 1);
                var aa = Math.cos(arad);
                var ab = Math.sin(arad);
                dc.drawLine(aa*(hw - tick_aen_r) + hw, ab*(hh - tick_aen_r) + hh, aa*(hw - tick_st_r) + hw, ab*(hh - tick_st_r) + hh);

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
            if (mNestStatus.getWifiConnection()) {
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
        if (buttons[0] != null) {
            buttons[0].setState(:stateDefault);
        }
        requestUpdate();
    }

    function onButton0() as Void {
        mNestStatus.checkWifiConnection();
        mNestStatus.getOAuthToken();
        buttons[0].setState(:stateDisabled);
        requestUpdate();
    }

    function getNestStatus() as NestStatus {
        return mNestStatus;
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
        if (System.getDeviceSettings().phoneConnected && mView.getNestStatus().getWifiConnection()) {
            var v = new ModeChangeView(mView.getNestStatus());
            WatchUi.pushView(v, new ModeChangeDelegate(v), WatchUi.SLIDE_UP);
        }
        return true;
    }
    function onNextPage() {
        if (System.getDeviceSettings().phoneConnected && mView.getNestStatus().getWifiConnection()) {
            var v = new TempChangeView(mView.getNestStatus());
            WatchUi.pushView(v, new TempChangeDelegate(v), WatchUi.SLIDE_UP);
        }
        return true;
    }
}