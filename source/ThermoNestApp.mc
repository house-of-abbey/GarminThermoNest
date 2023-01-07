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

import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Properties;

(:glance)
class ThermoNestApp extends Application.AppBase {
    hidden var mNestStatus;
    hidden var mView;
    hidden var mGlanceView;

    function initialize() {
        AppBase.initialize();
        // Glance and App each need their own and cannot be shared
        mNestStatus = new NestStatus(method(:requestCallback));
    }

    function getGlanceView() {
        mNestStatus.isGlance = true;
        mGlanceView = new ThermoNestGlanceView(mNestStatus);
        return [ mGlanceView ];
    }

    function requestCallback() as Void {
        if (mView != null) {
            mView.requestCallback();
        }
        if (mGlanceView != null) {
            mGlanceView.requestCallback();
        }
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        if (Globals.debug) {
            System.println(Lang.format("appVersion: $1$",  [Properties.getValue("appVersion")]));
            System.println(Lang.format("accessToken: $1$", [Properties.getValue("accessToken")]));
            System.println(Lang.format("deviceId: $1$",    [Properties.getValue("deviceId")]));
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        mNestStatus.isGlance = false;
        mView = new ThermoNestView(mNestStatus);
        return [ mView, new ThermoNestDelegate(mView) ] as Array<Views or InputDelegates>;
    }

    function onSettingsChanged() {
        if (Globals.debug) {
            System.println(Lang.format("appVersion: $1$",  [Properties.getValue("appVersion")]));
            System.println(Lang.format("accessToken: $1$", [Properties.getValue("accessToken")]));
            System.println(Lang.format("deviceId: $1$",    [Properties.getValue("deviceId")]));
        }
    }
}

function getApp() as ThermoNestApp {
    return Application.getApp() as ThermoNestApp;
}
