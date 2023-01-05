import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Communications;

class ModeChangeView extends WatchUi.View {
    hidden var mNestStatus;
    hidden var modeButton;
    hidden var ecoButton;
    hidden var heatOffIcon;
    hidden var heatOnIcon;
    hidden var coolOnIcon;
    hidden var heatCoolIcon;
    hidden var ecoOffIcon;
    hidden var ecoOnIcon;
    hidden var setModeLabel as String;
    hidden var tapIconLabel as String;

    function initialize(s) {
        View.initialize();
        mNestStatus  = s;
        setModeLabel = WatchUi.loadResource($.Rez.Strings.setMode) as String;
        tapIconLabel = WatchUi.loadResource($.Rez.Strings.tapIcon) as String;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {

        // modeOffIndex = getIndexOfMode("OFF", mNestStatus.getAvailableThermoModes());
        // ecoOffIndex  = getIndexOfMode("OFF", mNestStatus.getAvailableEcoModes()   );

        heatOffIcon  = Application.loadResource(Rez.Drawables.HeatOffLgIcon ) as Graphics.BitmapResource;
        heatOnIcon   = Application.loadResource(Rez.Drawables.HeatOnLgIcon  ) as Graphics.BitmapResource;
        coolOnIcon   = Application.loadResource(Rez.Drawables.CoolOnLgIcon  ) as Graphics.BitmapResource;
        heatCoolIcon = Application.loadResource(Rez.Drawables.HeatCoolLgIcon) as Graphics.BitmapResource;
        ecoOffIcon   = Application.loadResource(Rez.Drawables.EcoOffLgIcon  ) as Graphics.BitmapResource;
        ecoOnIcon    = Application.loadResource(Rez.Drawables.EcoOnLgIcon   ) as Graphics.BitmapResource;

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
        setLayout([modeButton, ecoButton] as Array<WatchUi.Button>);
    }

    function onShow() {
        // Track changes to NestStatus state
        mNestStatus.copyState();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var bg = 0x3B444C;
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, bg);
        dc.clear();

        dc.drawText(
            w/2, h/4, Graphics.FONT_SMALL,
            setModeLabel, // "Set Modes"
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        modeButton.draw(dc);
        ecoButton.draw(dc);
        dc.setColor(Graphics.COLOR_WHITE, bg);
        dc.drawText(
            w/2, h*3/4, Graphics.FONT_XTINY,
            tapIconLabel, // "Tap Icons"
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        var posx = w/4-heatOffIcon.getWidth()/2;
        var posy = h/2-heatOffIcon.getHeight()/2;
        if (mNestStatus.getEco()) {
            dc.drawBitmap(posx, posy, ecoOnIcon);
        } else {
            dc.drawBitmap(posx, posy, ecoOffIcon);
        }

        posx = w*3/4-heatOffIcon.getWidth()/2;
        //mNestStatus.setThermoMode(supportedModes[modeStatus]);
        switch (mNestStatus.getThermoMode() as Lang.String) {
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
                System.print("ERROR - ModeChangeView: Unsupported HVAC mode '" + mNestStatus.getThermoMode() + "'");
                break;
        }

    }

    // private function getIndexOfMode(item as Lang.String, arr as Lang.Array) {
    //     for (var i = 0; i < arr.size(); i++) {
    //         if (item.equals(arr[i])) {
    //             return i;
    //         }
    //     }
    //     // Error
    //     return arr.size()+1;
    // }

    function onModeButton() as Void {
        mNestStatus.nextAvailableThermoModes();
    }

    function onEcoButton() as Void {
        mNestStatus.nextAvailableEcoMode();
    }

    function getNestStatus() as NestStatus {
        return mNestStatus;
    }
}

class ModeChangeDelegate extends WatchUi.BehaviorDelegate {
    var mView;
    function initialize(v) {
        WatchUi.BehaviorDelegate.initialize();
        mView = v;
    }
    function onModeButton() {
        return mView.onModeButton(); 
    }
    function onEcoButton() {
        return mView.onEcoButton(); 
    }
    function onBack() {
        mView.getNestStatus().executeMode(NestStatus.Start);
        WatchUi.popView(WatchUi.SLIDE_UP);
        return true;
    }
    function onNextPage() {
        mView.getNestStatus().executeMode(NestStatus.Start);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}