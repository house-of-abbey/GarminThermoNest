import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Communications;

class ModeChangeView extends WatchUi.View {
    var mNestStatus;
    // hidden var modeOffIndex; // Index of "OFF" in available HVAC mode list
    // hidden var ecoOffIndex;  // Index of "OFF" in available Eco  mode list
    // hidden var ecoStatus = 0;
    // hidden var modeStatus = 0;
    hidden var modeButton;
    hidden var ecoButton;
    hidden var heatOffIcon;
    hidden var heatOnIcon;
    hidden var coolOnIcon;
    hidden var heatCoolIcon;
    hidden var ecoOffIcon;
    hidden var ecoOnIcon;

    function initialize(s) {
        View.initialize();
        mNestStatus = s;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {

        // modeOffIndex = getIndexOfMode("OFF", mNestStatus.getAvailableThermoModes());
        // ecoOffIndex  = getIndexOfMode("OFF", mNestStatus.getAvailableEcoModes()   );

        heatOffIcon  = Application.loadResource(Rez.Drawables.HeatOffIcon ) as Graphics.BitmapResource;
        heatOnIcon   = Application.loadResource(Rez.Drawables.HeatOnIcon  ) as Graphics.BitmapResource;
        coolOnIcon   = Application.loadResource(Rez.Drawables.CoolOnIcon  ) as Graphics.BitmapResource;
        heatCoolIcon = Application.loadResource(Rez.Drawables.HeatCoolIcon) as Graphics.BitmapResource;
        ecoOffIcon   = Application.loadResource(Rez.Drawables.EcoOffIcon  ) as Graphics.BitmapResource;
        ecoOnIcon    = Application.loadResource(Rez.Drawables.EcoOnIcon   ) as Graphics.BitmapResource;

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

        modeButton.draw(dc);
        ecoButton.draw(dc);

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
        // var supportedModes = mNestStatus.getAvailableThermoModes();
        mNestStatus.nextAvailableThermoModes();
        // modeStatus = (modeStatus + 1) % supportedModes.size();
        // ecoStatus = ecoOffIndex;
    }

    function onEcoButton() as Void {
        // var supportedModes = mNestStatus.getAvailableEcoModes();
        mNestStatus.nextAvailableEcoMode();
        // ecoStatus = (ecoStatus + 1) % supportedModes.size();
        // modeStatus = modeOffIndex;
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
        mView.mNestStatus.executeMode(NestStatus.Start);
        WatchUi.popView(WatchUi.SLIDE_UP);
        return true;
    }
    function onNextPage() {
        mView.mNestStatus.executeMode(NestStatus.Start);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}