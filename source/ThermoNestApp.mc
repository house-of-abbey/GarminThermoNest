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
// ThermoNestApp provides the base of the application.
//
//-----------------------------------------------------------------------------------

using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Application.Properties;

(:glance)
class ThermoNestApp extends Application.AppBase {
    hidden var mNestStatus;
    hidden var oAuthPropUsed as Lang.String;
    hidden var oAuthPropFail as Lang.String;

    function initialize() {
        AppBase.initialize();
        oAuthPropUsed = WatchUi.loadResource($.Rez.Strings.oAuthPropUsed) as Lang.String;
        oAuthPropFail = WatchUi.loadResource($.Rez.Strings.oAuthPropFail) as Lang.String;
    }

    function getGlanceView() {
        var mySettings = System.getDeviceSettings();
        if ((mySettings has :isGlanceModeEnabled) && mySettings.isGlanceModeEnabled) {
            mNestStatus = new NestStatus(true);
            return [new ThermoNestGlanceView(mNestStatus)];
        } else {
            return null;
        }
    }

    // onStart() is called on application start up
    function onStart(state as Lang.Dictionary?) as Void {
        if (Properties.getValue("oauthCode").equals("")) {
            // The OAuth code has been reset, so force reset of the tokens.
            Storage.setValue("accessToken", "");
            Storage.setValue("accessTokenExpire", 0);
            Storage.setValue("refreshToken", "");
            var mySettings = System.getDeviceSettings();
            if (Globals.debug) {
                System.println("ThermoNestApp onStart() - Force full OAuth");
            }
        }
        if (Globals.debug) {
            System.println("ThermoNestApp onStart() oauthCode:   " + Properties.getValue("oauthCode"));
            System.println("ThermoNestApp onStart() accessToken: " + Storage.getValue("accessToken"));
            System.println("ThermoNestApp onStart() deviceId:    " + Properties.getValue("deviceId"));
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state as Lang.Dictionary?) as Void {}

    // Return the initial view of your application here
    function getInitialView() as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>? {
        mNestStatus = new NestStatus(false);
        var mView   = new ThermoNestView(mNestStatus);
        return [mView, new ThermoNestDelegate(mView)] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
    }

    function onSettingsChanged() {
        var o = Properties.getValue("oauthCode");
        var d = Properties.getValue("deviceId");
        if (Globals.debug) {
            System.println("ThermoNestApp onSettingsChanged() oauthCode:   " + o);
            System.println("ThermoNestApp onSettingsChanged() accessToken: " + Storage.getValue("accessToken"));
            System.println("ThermoNestApp onSettingsChanged() deviceId:    " + d);
        }
        if (o != null && !o.equals("")) {
            if (!o.equals(oAuthPropUsed) && !o.equals(oAuthPropFail)) {
                if (Globals.debug) {
                    System.println("ThermoNestApp onSettingsChanged() New OAuth Code, getting new access token.");
                }
                // New oauthCode
                Storage.setValue("accessToken", "");
                Storage.setValue("accessTokenExpire", 0);
                Storage.setValue("refreshToken", "");
                var mySettings = System.getDeviceSettings();
                if (Globals.debug) {
                    System.println("ThermoNestApp onSettingsChanged() - Force full OAuth");
                }
                mNestStatus.getAccessToken();
                // Need new list of structures and rooms
                mNestStatus.updateAuthView();
                WatchUi.requestUpdate();
            } else if (d != null && !d.equals("")) {
                if (Globals.debug) {
                    System.println("ThermoNestApp onSettingsChanged() Getting Device Data");
                }
                // Setting change might be a new devide ID
                mNestStatus.getDeviceData();
            }
        } else {
            WatchUi.requestUpdate();
        }
    }
}

function getApp() as ThermoNestApp {
    return Application.getApp() as ThermoNestApp;
}
