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
    hidden var mView;
    hidden var mGlanceView;

    function initialize() {
        AppBase.initialize();
    }

    function getGlanceView() {
        mGlanceView = new ThermoNestGlanceView(new NestStatus(true));
        return [mGlanceView];
    }

    // onStart() is called on application start up
    function onStart(state as Lang.Dictionary?) as Void {
        if (Globals.debug) {
            System.println(Lang.format("accessToken: $1$", [Properties.getValue("accessToken")]));
            System.println(Lang.format("deviceId: $1$",    [Properties.getValue("deviceId")]));
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state as Lang.Dictionary?) as Void {}

    // Return the initial view of your application here
    function getInitialView() as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>? {
        mView = new ThermoNestView(new NestStatus(false));
        return [mView, new ThermoNestDelegate(mView)] as Lang.Array<WatchUi.Views or WatchUi.InputDelegates>;
    }

    function onSettingsChanged() {
        if (Globals.debug) {
            System.println(Lang.format("accessToken: $1$", [Properties.getValue("accessToken")]));
            System.println(Lang.format("deviceId: $1$",    [Properties.getValue("deviceId")]));
        }
    }
}

function getApp() as ThermoNestApp {
    return Application.getApp() as ThermoNestApp;
}
