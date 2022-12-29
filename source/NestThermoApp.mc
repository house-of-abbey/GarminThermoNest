import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Properties;

class NestThermoApp extends Application.AppBase {
    hidden var mView;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        System.println(Lang.format("appVersion: $1$", [Properties.getValue("appVersion")]));
        System.println(Lang.format("accessToken: $1$", [Properties.getValue("accessToken")]));
        System.println(Lang.format("deviceId: $1$", [Properties.getValue("deviceId")]));
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        mView = new NestThermoView();
        return [ mView, new NestThermoDelegate(mView) ] as Array<Views or InputDelegates>;
    }

    function onSettingsChanged() {
        System.println(Lang.format("appVersion: $1$", [Properties.getValue("appVersion")]));
        System.println(Lang.format("accessToken: $1$", [Properties.getValue("accessToken")]));
        System.println(Lang.format("deviceId: $1$", [Properties.getValue("deviceId")]));
    }
}

function getApp() as NestThermoApp {
    return Application.getApp() as NestThermoApp;
}
