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
    hidden var refreshIcon;
    hidden var refreshDisabledIcon;

    var buttons = new Array<WatchUi.Button>[1];

    function initialize() {
        View.initialize();
        mNestStatus = new NestStatus(method(:updateTemp));
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        ecoOffIcon          = Application.loadResource(Rez.Drawables.EcoOffIcon         ) as Graphics.BitmapResource;
        ecoOnIcon           = Application.loadResource(Rez.Drawables.EcoOnIcon          ) as Graphics.BitmapResource;
        heatOffIcon         = Application.loadResource(Rez.Drawables.HeatOffIcon        ) as Graphics.BitmapResource;
        heatOnIcon          = Application.loadResource(Rez.Drawables.HeatOnIcon         ) as Graphics.BitmapResource;
        coolOnIcon          = Application.loadResource(Rez.Drawables.CoolOnIcon         ) as Graphics.BitmapResource;
        heatCoolIcon        = Application.loadResource(Rez.Drawables.HeatCoolIcon       ) as Graphics.BitmapResource;
        thermostatIcon      = Application.loadResource(Rez.Drawables.ThermostatIcon     ) as Graphics.BitmapResource;
        refreshIcon         = Application.loadResource(Rez.Drawables.RefreshIcon        ) as Graphics.BitmapResource;
        refreshDisabledIcon = Application.loadResource(Rez.Drawables.RefreshDisabledIcon) as Graphics.BitmapResource;

        var bRefreshIcon         = new WatchUi.Bitmap({ :rezId=>$.Rez.Drawables.RefreshIcon         });
        var bRefreshDisabledIcon = new WatchUi.Bitmap({ :rezId=>$.Rez.Drawables.RefreshDisabledIcon });
        buttons[0] = new WatchUi.Button({
            :stateDefault             => bRefreshIcon,
            :stateHighlighted         => bRefreshIcon,
            :stateSelected            => bRefreshIcon,
            :stateDisabled            => bRefreshDisabledIcon,
            :stateHighlightedSelected => bRefreshIcon,
            :background               => Graphics.COLOR_TRANSPARENT,
            :behavior                 => :onButton0,
            :locX                     => dc.getWidth()/2 - 24,
            :locY                     => dc.getHeight()/2 - 150,
            :width                    => 48,
            :height                   => 48
        });
        setLayout(buttons);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
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
            dc.drawText(hw, hh - 60, Graphics.FONT_MEDIUM,
                        "HEAT SET TO",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(hw, hh, Graphics.FONT_MEDIUM,
                        Lang.format("$1$°$2$", [heat.format("%2.1f"), mNestStatus.getScale()]),
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            if (mNestStatus.getEco()) {
                dc.drawBitmap(hw - 53, hh + 90, ecoOnIcon);
            } else {
                dc.drawBitmap(hw - 53, hh + 90, ecoOffIcon);
            }

            if (mNestStatus.getThermoMode().equals("HEATCOOL")) {
                dc.drawBitmap(hw + 5, hh + 90, heatCoolIcon);
            } else if (mNestStatus.getThermoMode().equals("HEAT")) {
                dc.drawBitmap(hw + 5, hh + 90, heatOnIcon);
            } else if (mNestStatus.getThermoMode().equals("COOL")) {
                dc.drawBitmap(hw + 5, hh + 90, heatOnIcon);
            } else {
                dc.drawBitmap(hw + 5, hh + 90, heatOffIcon);
            }

            buttons[0].draw(dc);
        } else {
            dc.drawBitmap(hw - 24, hh - 24, thermostatIcon);
            dc.drawText(hw, hh + 60, Graphics.FONT_MEDIUM,
                        "Not connected",
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function updateTemp() as Void {
        buttons[0].setState(:stateDefault);
        requestUpdate();
    }

    function onButton0() as Void {
        buttons[0].setState(:stateDisabled);
        requestUpdate();
        mNestStatus.makeRequest();
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }
}

class LoadDelegate extends WatchUi.BehaviorDelegate {
    var mView;
    function initialize(v) {
        WatchUi.BehaviorDelegate.initialize();
        mView = v;
    }
    function onButton0() {
        return mView.onButton0(); 
    }
    function onNextPage() {
        System.println("next page");
        return true;
    }
    function onPreviousPage() {
        System.println("prev page");
        return true;
    }
    // function onSelect() { return touch.invoke(); }
}