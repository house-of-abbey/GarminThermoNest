//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminThermoNest/blob/main/LICENSE.
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
using Toybox.Lang;

(:glance)
class Globals {
    // Enable printing of messages to the debug console (don't make this a Property
    // as the messages can't be read from a watch!)
    static const debug        = false;
    // Multi-dot navigation drawable on each View
    static const navRadius    = 2.0f;
    static const navMarginX   = 10f;
    static const navPanes     = 3;
    static const navDelay     = 2000; // ms
    static const navPeriod    = 1.0f; // s

    static const heatingColor = 0xEC7800; // Orange background
    static const coolingColor = 0x285DF7; // Blue background
    static const offColor     = Graphics.COLOR_BLACK;

    static const alertTimeout = 1000; // ms

    // https://developers.google.com/nest/device-access/project/review
    // Products that do not support Heat-Cool limits properly (3 degrees apart in F and 1.5 in C) will be rejected.
    // Products that do not support temperature limits correctly (50-90 F and 9-32 C) will be rejected.
    // NB. The API seems to support 48..90 deg F
    static const maxTempC     =  32f; // deg C
    static const minTempC     =   9f; // deg C
    static const incTempC     = 1.0f; // deg C
    static const sepTempC     = 1.5f;
    static const maxTempF     =  90f; // deg F
    static const minTempF     =  48f; // deg F
    static const incTempF     = 1.0f; // deg F
    static const sepTempF     =   3f;

    static const minTempArc   = 240f; // degrees
    static const maxTempArc   = -60f; // degrees

    // Display the current temperature more finely than heat and cool settings.
    static const ambientRes   = 0.1f;
    static const celciusRes   = 0.5f; // Resolution and increment for deg C
    static const farenheitRes = 1.0f; // Resolution and increment for deg F

    static private const smartDeviceManagementUrl = "https://smartdevicemanagement.googleapis.com/v1/enterprises/";

    static function getStructuresUrl() {
        return smartDeviceManagementUrl + ClientId.projectId + "/structures";
    }

    static function getRoomsUrl(structure as Lang.String) {
        return smartDeviceManagementUrl + ClientId.projectId + "/structures/" + structure + "/rooms";
    }

    static function getDevicesUrl() {
        return smartDeviceManagementUrl + ClientId.projectId + "/devices";
    }

    static function getDeviceDataUrl() {
        return smartDeviceManagementUrl + ClientId.projectId + "/devices/" + Properties.getValue("deviceId");
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
