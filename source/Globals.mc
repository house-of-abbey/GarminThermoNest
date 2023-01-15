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
// Globals contains constants used throughout the application, typically related to
// layout positions.
//
//-----------------------------------------------------------------------------------

using Toybox.Graphics;
using Toybox.Application.Properties;

(:glance)
class Globals {
    // Enable printing of messages to the debug console (don't make this a Property
    // as the messages can't be read from a watch!)
    static const debug        = true;
    // Multi-dot navigation drawable on each View
    static const navRadius    = 8;
    static const navMarginX   = 40;
    static const navPanes     = 3;
    static const navDelay     = 1000; // ms
    static const navPeriod    = 0.5;  // s

    static const heatingColor = 0xEC7800;
    static const coolingColor = 0x285DF7;
    static const offColor     = Graphics.COLOR_BLACK;

    static const alertTimeout = 2000; // ms

    static const maxTempC = 32f; // deg C
    static const minTempC =  9f; // deg C
    static const maxTempF = 90f; // deg F
    static const minTempF = 48f; // deg F

    static hidden const smartDeviceManagementUrl = "https://smartdevicemanagement.googleapis.com/v1/enterprises/";

    static function getDevicesUrl() {
        return smartDeviceManagementUrl + ClientId.projectId + "/devices";
    }

    static function getDeviceDataUrl() {
        return smartDeviceManagementUrl + ClientId.projectId + "/devices/" + Properties.getValue("deviceId");
        //return "https://www.melrose.ruins/cgi-bin/fake-nest.json";
        //return "https://www.melrose.ruins/cgi-bin/fake-nest.json?capability=heat";
    }

    static function getExecuteCommandUrl() {
        return smartDeviceManagementUrl + ClientId.projectId + "/devices/" + Properties.getValue("deviceId") + ":executeCommand";
    }

    static function getOAuthTokenUrl() {
        return "https://www.googleapis.com/oauth2/v4/token";
    }

    static function getRedirectUrl() {
        return "https://house-of-abbey.github.io/GarminThermoNest/auth";
    }

}
