import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Communications;

class NestThermoView extends WatchUi.View {
    hidden var mNestStatus;

    hidden var ecoOffIcon;
    hidden var ecoOnIcon;
    hidden var heatOffIcon;
    hidden var heatOnIcon;
    hidden var coolOnIcon;
    hidden var heatCoolIcon;
    hidden var thermostatIcon;

    var buttons = new Array<WatchUi.Button>[1];

    function initialize() {
        View.initialize();
        mNestStatus = new NestStatus(method(:requestCallback));
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        ecoOffIcon     = Application.loadResource(Rez.Drawables.EcoOffIcon    ) as Graphics.BitmapResource;
        ecoOnIcon      = Application.loadResource(Rez.Drawables.EcoOnIcon     ) as Graphics.BitmapResource;
        heatOffIcon    = Application.loadResource(Rez.Drawables.HeatOffIcon   ) as Graphics.BitmapResource;
        heatOnIcon     = Application.loadResource(Rez.Drawables.HeatOnIcon    ) as Graphics.BitmapResource;
        coolOnIcon     = Application.loadResource(Rez.Drawables.CoolOnIcon    ) as Graphics.BitmapResource;
        heatCoolIcon   = Application.loadResource(Rez.Drawables.HeatCoolIcon  ) as Graphics.BitmapResource;
        thermostatIcon = Application.loadResource(Rez.Drawables.ThermostatIcon) as Graphics.BitmapResource;

        var bRefreshIcon         = new WatchUi.Bitmap({ :rezId => $.Rez.Drawables.RefreshIcon         });
        var bRefreshDisabledIcon = new WatchUi.Bitmap({ :rezId => $.Rez.Drawables.RefreshDisabledIcon });
        buttons[0] = new WatchUi.Button({
            :stateDefault             => bRefreshIcon,
            :stateHighlighted         => bRefreshIcon,
            :stateSelected            => bRefreshIcon,
            :stateDisabled            => bRefreshDisabledIcon,
            :stateHighlightedSelected => bRefreshIcon,
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
        if (System.getDeviceSettings().phoneConnected) {
            var heat = mNestStatus.getHeatTemp();
            var ambientTemperature = mNestStatus.getAmbientTemp();
            var heatArc = mNestStatus.getScale() == 'C'
                ? lerp(heat, 9f, 32f, 240f, -60f)
                : lerp(heat, 48f, 90f, 240f, -60f);
            var ambientTemperatureArc = mNestStatus.getScale() == 'C'
                ? lerp(ambientTemperature, 9f, 32f, 240f, -60f)
                : lerp(ambientTemperature, 48f, 90f, 240f, -60f);
            dc.setColor(0xaaaaaa, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(hw, hh, hw - 10, Graphics.ARC_CLOCKWISE, 240f, -60f);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            if (ambientTemperature > heat) {
                dc.drawArc(hw, hh, hw - 10, Graphics.ARC_CLOCKWISE, heatArc, ambientTemperatureArc);
            } else {
                dc.drawArc(hw, hh, hw - 10, Graphics.ARC_CLOCKWISE, ambientTemperatureArc, heatArc);
            }

            dc.setColor(0xaaaaaa, Graphics.COLOR_TRANSPARENT);
            dc.drawText(hw, hh - 40, Graphics.FONT_MEDIUM,
                        "HEAT SET TO",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(hw, hh, Graphics.FONT_MEDIUM,
                        Lang.format("$1$°$2$", [heat.format("%2.1f"), mNestStatus.getScale()]),
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

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

            buttons[0].draw(dc);
        } else {
            dc.drawBitmap(hw - 24, hh - 24, thermostatIcon);
            dc.drawText(hw, hh + 60, Graphics.FONT_MEDIUM,
                        "Not connected",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function requestCallback() as Void {
        buttons[0].setState(:stateDefault);
        requestUpdate();
    }

    function onButton0() as Void {
        buttons[0].setState(:stateDisabled);
        requestUpdate();
        mNestStatus.makeRequest();
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
    function onNextPage() {
        if (System.getDeviceSettings().phoneConnected) {
            var v = new TempChangeView();
            WatchUi.pushView(v, new TempChangeDelegate(v), WatchUi.SLIDE_DOWN);
        }
        return true;
    }
}