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
// NestStatus provides the background services for interacting with the Nest API and
// the Google Cloud Project hosting the REST API access we paid for. In the main it
// provides a cache of the online status locally, but is also used to update the
// desired settings and post new settings back to the REST API.
//
// References:
//  * https://developers.google.com/nest/device-access/registration
//  * https://developers.google.com/nest/device-access/api/thermostat
//  * https://developers.google.com/nest/device-access/traits
//
//-----------------------------------------------------------------------------------

import Toybox.System;
import Toybox.Communications;
import Toybox.Authentication;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Properties;
import Toybox.Time;
import Toybox.Math;

(:glance)
class NestStatus {
    // Explicit value assignment
    enum {
        Start    = 0,
        Thermo   = 1,
        NoThermo = 2,
        Eco      = 3,
        NoEco    = 4
    }

    hidden var requestCallback;
    public var isGlance             = false as Lang.Boolean;

    hidden var online               = false as Lang.Boolean;
    hidden var name                 = ""    as Lang.String;
    // Set this to 'C' or '         F' for temperature scale
    hidden var scale                = '-'   as Lang.Char;
    // Always Celsius
    hidden var ambientTemp          = 0.0   as Lang.Number;
    // Always Celsius
    hidden var heatTemp             = 0.0   as Lang.Number;
    // Always Celsius
    hidden var coolTemp             = 0.0   as Lang.Number;
    hidden var humidity             = 0.0   as Lang.Number;
    hidden var availableThermoModes = null  as Lang.Array;
    hidden var thermoMode           = ""    as Lang.String;
    hidden var hvac                 = ""    as Lang.String;
    hidden var availableEcoModes    = null  as Lang.Array;
    hidden var eco                  = false as Lang.Boolean;

    // Copies before edit for a diff
    hidden var _heatTemp             = 0.0   as Lang.Number;
    hidden var _coolTemp             = 0.0   as Lang.Number;
    hidden var _thermoMode           = ""    as Lang.String;
    hidden var _eco                  = false as Lang.Boolean;

    public var gotDeviceData        = false as Lang.Boolean;
    public var gotDeviceDataError   = false as Lang.Boolean;

    // Do we have an Internet connection?
    hidden var wifiConnection = true;

    function initialize(h) {
        requestCallback = h;
        if (System.getDeviceSettings().phoneConnected && System.getDeviceSettings().connectionAvailable) {
            var c = Properties.getValue("oauthCode");
            if (c != null && !c.equals("")) {
                getOAuthToken();
            }
        }
    }

    function getOnline() as Lang.Boolean {
        return online;
    }

    function getName() as Lang.String {
        return name;
    }

    function getScale() as Lang.Char {
        return scale;
    }

    // Convert temperature to the units in 'scale'.
    function getAmbientTemp() as Lang.Number {
        if (scale == 'C') {
            return ambientTemp;
        } else {
            return (ambientTemp * 9/5) + 32;
        }
    }

    // Convert temperature to the units in 'scale'.
    function getHeatTemp() as Lang.Number {
        if (scale == 'C') {
            return heatTemp;
        } else {
            return (heatTemp * 9/5) + 32;
        }
    }
    function setHeatTemp(value as Lang.Number) as Void {
        if (!eco) {
            if (scale == 'C') {
                if (9f <= value && value <= 32f) {
                    heatTemp = value;
                }
            } else {
                if (48f <= value && value <= 90f) {
                    heatTemp = (value - 32) * 5/9;
                }
            }
            requestCallback.invoke();
        }
    }
    function onReturnHeatTemp(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (Globals.debug) {
            System.println("onReturnHeatTemp() Response Code: " + responseCode);
            System.println("onReturnHeatTemp() Response Data: " + data);
        }
        if (responseCode != 200) {
            if (!isGlance) {
                WatchUi.pushView(new ErrorView((data.get("error") as Dictionary).get("message") as String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }
            getDeviceData();
        }
        requestCallback.invoke();
    }
    function executeHeatTemp() as Void {
        if (!eco && (thermoMode.equals("HEAT") || thermoMode.equals("HEATCOOL"))) {
            if (heatTemp != _heatTemp) {
                executeCommand({
                    "command" => "sdm.devices.commands.ThermostatTemperatureSetpoint.SetHeat",
                    "params"  => {
                        "heatCelsius" => heatTemp
                    }
                }, method(:onReturnHeatTemp));
            } else {
                if (Globals.debug) {
                    System.println("Skipping executeHeatTemp() as no change.");
                }
            }
        }
    }

    // Convert temperature to the units in 'scale'.
    function getCoolTemp() as Lang.Number {
        if (scale == 'C') {
            return coolTemp;
        } else {
            return (coolTemp * 9/5) + 32;
        }
    }
    function setCoolTemp(value as Lang.Number) as Void {
        if (!eco) {
            if (scale == 'C') {
                if (9f <= value && value <= 32f) {
                    coolTemp = value;
                }
            } else {
                if (48f <= value && value <= 90f) {
                    coolTemp = (value - 32) * 5/9;
                }
            }
            requestCallback.invoke();
        }
    }
    function onReturnCoolTemp(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (Globals.debug) {
            System.println("onReturnCoolTemp() Response Code: " + responseCode);
            System.println("onReturnCoolTemp() Response Data: " + data);
        }
        if (responseCode != 200) {
            if (!isGlance) {
                WatchUi.pushView(new ErrorView((data.get("error") as Dictionary).get("message") as String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }
            getDeviceData();
        }
        requestCallback.invoke();
    }
    function executeCoolTemp() as Void {
        if (!eco && (thermoMode.equals("COOL") || thermoMode.equals("HEATCOOL"))) {
            if (coolTemp != _coolTemp) {
                executeCommand({
                    "command" => "sdm.devices.commands.ThermostatTemperatureSetpoint.SetCool",
                    "params"  => {
                        "CoolCelsius" => coolTemp
                    }
                }, method(:onReturnCoolTemp));
            } else {
                if (Globals.debug) {
                    System.println("Skipping executeCoolTemp() as no change.");
                }
            }
        }
    }

    function getHumidity() as Lang.Number {
        return humidity;
    }

    function getAvailableThermoModes() as Lang.Array {
        return availableThermoModes;
    }

    function getThermoMode() as Lang.String {
        return thermoMode;
    }
    function setThermoMode(value as Lang.String) as Void {
        if (value.equals("OFF")) {
            eco = false;
        }
        thermoMode = value;
        requestCallback.invoke();
    }
    function nextAvailableThermoModes() as Void {
        setThermoMode((availableThermoModes as Lang.Array)[(availableThermoModes.indexOf(thermoMode)+1) % availableThermoModes.size()]);
    }
    function onReturnThermoMode(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (Globals.debug) {
            System.println("onReturnThermoMode() Response Code: " + responseCode);
            System.println("onReturnThermoMode() Response Data: " + data);
        }
        if (responseCode != 200) {
            if (!isGlance) {
                WatchUi.pushView(new ErrorView((data.get("error") as Dictionary).get("message") as String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }
            getDeviceData();
        }
        executeMode(Thermo);
    }
    function executeThermoMode() as Void {
        if (!thermoMode.equals(_thermoMode)) {
            executeCommand({
                "command" => "sdm.devices.commands.ThermostatMode.SetMode",
                "params"  => {
                    "mode" => thermoMode
                }
            }, method(:onReturnThermoMode));
        } else {
            if (Globals.debug) {
                System.println("Skipping executeThermoMode() as no change.");
            }
            executeMode(NoThermo);
        }
    }

    function getHvac() as Lang.String {
        return hvac;
    }

    function getAvailableEcoModes() as Lang.Array {
        return availableEcoModes;
    }

    function getEco() as Lang.Boolean {
        return eco;
    }
    function setEco(value as Lang.Boolean) as Void {
        if (value) {
            if (availableThermoModes.indexOf("HEATCOOL") != -1) {
                thermoMode = "HEATCOOL";
            } else if (availableThermoModes.indexOf("HEAT") != -1) {
                thermoMode = "HEAT";
            } else if (availableThermoModes.indexOf("COOL") != -1) {
                thermoMode = "COOL";
            }
        }
        eco = value;
        requestCallback.invoke();
    }
    function nextAvailableEcoMode() as Void {
        if (availableEcoModes.indexOf("MANUAL_ECO") != -1) {
            setEco(!eco);
        }
    }
    function onReturnEco(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (Globals.debug) {
            System.println("onReturnEco() Response Code: " + responseCode);
            System.println("onReturnEco() Response Data: " + data);
        }
        if (responseCode != 200) {
            if (!isGlance) {
                WatchUi.pushView(new ErrorView((data.get("error") as Dictionary).get("message") as String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }
            getDeviceData();
        }
        executeMode(Eco);
    }
    function executeEco() as Void {
        if (eco != _eco) {
            executeCommand({
                "command" => "sdm.devices.commands.ThermostatEco.SetMode",
                "params"  => {
                    "mode" => eco ? "MANUAL_ECO" : "OFF"
                }
            }, method(:onReturnEco));
        } else {
            if (Globals.debug) {
                System.println("Skipping executeEco() as no change.");
            }
            executeMode(NoEco);
        }
    }

    // Spawn sub-tasks from here and retain control of execution of asynchronous elements.
    function executeMode(r) as Void {
        switch (r) {
            case Start:
                // Changing ThermoMode also turns off Eco Mode, then setting Eco mode off errors.
                executeThermoMode();
                break;
            case NoThermo:
                executeEco();
                break;
            case Thermo:
                // At this point Eco is always OFF as we set the ThermoMode.
                if (eco) {
                    executeEco();
                }
                break;
            case NoEco: // Fall through
            case Eco:
                // The end
                requestCallback.invoke();
                break;
        }
    }

    // Copy the state at the onShow() of an edit View for comparison later in order to reduce
    // unnecessary API requests. This is then compared by the execute functions in order to
    // decide if they make changes via the API.
    //
    function copyState() {
        _heatTemp   = heatTemp;
        _coolTemp   = coolTemp;
        _thermoMode = thermoMode;
        _eco        = eco;
    }

    private function executeCommand(payload as Dictionary, callback) {
        var url = "https://smartdevicemanagement.googleapis.com/v1/enterprises/" + ClientId.projectId + "/devices/" + Properties.getValue("deviceId") + ":executeCommand";

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Authorization" => "Bearer " + Properties.getValue("accessToken")
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        if (System.getDeviceSettings().phoneConnected && wifiConnection) {
            Communications.makeWebRequest(url, payload, options, callback);
        } else {
            if (Globals.debug) {
                System.println("Note - executeCommand(): No Internet connection, skipping API call.");
            }
        }
    }

    // Set up the response callback function
    function onReceiveDeviceData(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (responseCode == 200) {
            if (data != null) {
                var traits = data.get("traits") as Dictionary;
                if (traits != null) {
                    var con = traits.get("sdm.devices.traits.Connectivity") as Dictionary;
                    if (con != null) {
                        online = (con.get("status") as Lang.String).equals("ONLINE");
                        if (Globals.debug) {
                            System.println(" Status: " + (online ? "On line" : "Off line"));
                        }
                    }
                    var info = traits.get("sdm.devices.traits.Info") as Dictionary;
                    if (info != null) {
                        name = info.get("customName") as Lang.String;
                        if (Globals.debug) {
                            System.println(" Name: '" + name + "'");
                        }
                    }
                    var settings = traits.get("sdm.devices.traits.Settings") as Dictionary;
                    if (settings != null) {
                        scale = (settings.get("temperatureScale") as Lang.String).equals("CELSIUS") ? 'C' : 'F';
                        if (Globals.debug) {
                            System.println(" Scale: '" + scale + "'");
                        }
                    }
                    var e = traits.get("sdm.devices.traits.Temperature") as Dictionary;
                    if (e != null) {
                        ambientTemp = round(e.get("ambientTemperatureCelsius") as Lang.Number);
                        if (Globals.debug) {
                            System.println(" Temperature: " + ambientTemp + " deg C");
                        }
                    }
                    var ttsp = traits.get("sdm.devices.traits.ThermostatTemperatureSetpoint") as Dictionary;
                    if (ttsp != null) {
                        heatTemp = round(ttsp.get("heatCelsius") as Lang.Number);
                        coolTemp = round(ttsp.get("coolCelsius") as Lang.Number);
                        if (Globals.debug) {
                            System.println(" Heat Temperature: " + heatTemp + " deg C");
                            System.println(" Cool Temperature: " + coolTemp + " deg C");
                        }
                    }
                    var h = traits.get("sdm.devices.traits.Humidity") as Dictionary;
                    if (h != null) {
                        humidity = h.get("ambientHumidityPercent") as Lang.Number;
                        if (Globals.debug) {
                            System.println(" Humidity: " + humidity + " %");
                        }
                    }
                    var tm = traits.get("sdm.devices.traits.ThermostatMode") as Dictionary;
                    if (tm != null) {
                        availableThermoModes = tm.get("availableModes") as Lang.Array;
                        thermoMode = tm.get("mode") as Lang.String;
                        if (Globals.debug) {
                            System.println(" Thermo Modes: " + availableThermoModes);
                            System.println(" ThermostatMode: " + thermoMode);
                        }
                    }
                    var th = traits.get("sdm.devices.traits.ThermostatHvac") as Dictionary;
                    if (th != null) {
                        hvac = th.get("status") as Lang.String;
                        if (Globals.debug) {
                            System.println(" ThermostatHvac: " + hvac);
                        }
                    }
                    var te = traits.get("sdm.devices.traits.ThermostatEco") as Dictionary;
                    if (te != null) {
                        availableEcoModes = te.get("availableModes") as Lang.Array;
                        eco = (te.get("mode") as Lang.String).equals("MANUAL_ECO");
                        if (Globals.debug) {
                            System.println(" Eco Modes: " + availableEcoModes);
                            System.println(" ThermostatEco: " + (eco ? "Eco" : "Off"));
                        }
                        if (eco) {
                            heatTemp = round(te.get("heatCelsius") as Lang.Number);
                            coolTemp = round(te.get("coolCelsius") as Lang.Number);
                            if (Globals.debug) {
                                System.println(" Heat Temperature: " + heatTemp + " deg C (eco)");
                                System.println(" Cool Temperature: " + coolTemp + " deg C (eco)");
                            }
                        }
                    }
                }
            }
            gotDeviceData      = true;
            gotDeviceDataError = false;
            requestCallback.invoke();
        } else {
            if (Globals.debug) {
                System.println("onReceiveDeviceData() Response Code: " + responseCode);
                System.println("onReceiveDeviceData() Response Data: " + data);
            }
            gotDeviceData      = true;
            gotDeviceDataError = true;

            if (responseCode == 404) {
                Properties.setValue("deviceId", "");
                if (!isGlance) {
                    WatchUi.pushView(new ErrorView("Device not found."), new ErrorDelegate(), WatchUi.SLIDE_UP);
                }
            } else if (responseCode == 401) {
                Properties.setValue("accessToken", "");
                Properties.setValue("refreshToken", "");
                if (!isGlance) {
                    WatchUi.pushView(new ErrorView("Authentication issue, access and refresh tokens deleted."), new ErrorDelegate(), WatchUi.SLIDE_UP);
                }
            } else {
                // This method might be called before authorisation has completed.
                if (!isGlance && (data != null)) {
                    WatchUi.pushView(new ErrorView((data.get("error") as Dictionary).get("message") as String), new ErrorDelegate(), WatchUi.SLIDE_UP);
                } else {
                    if (Globals.debug) {
                        System.println("onReceiveDeviceData() Response Code: " + responseCode);
                        System.println("onReceiveDeviceData() Response Data: " + data);
                    }
                }
            }

            requestCallback.invoke();
        }
    }

    function getDeviceData() as Void {
        var url     = "https://smartdevicemanagement.googleapis.com/v1/enterprises/" + ClientId.projectId + "/devices/" + Properties.getValue("deviceId");
        var options = {
            :method  => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
                "Authorization" => "Bearer " + Properties.getValue("accessToken")
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        if (System.getDeviceSettings().phoneConnected && wifiConnection) {
            Communications.makeWebRequest(url, null, options, method(:onReceiveDeviceData));
        } else {
            if (Globals.debug) {
                System.println("Note - getDeviceData(): No Internet connection, skipping API call.");
            }
        }
    }

    function onReceiveDevices(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (Globals.debug) {
            System.println("onReceiveDevices() Response Code: " + responseCode);
            System.println("onReceiveDevices() Response Data: " + data);
        }
        if (responseCode == 200) {
            var devices = data.get("devices") as Lang.Array;
            var menu = new WatchUi.Menu2({ :title => "Devices" });
            var o = 21 + ClientId.projectId.length();
            for (var i = 0; i < devices.size(); i++) {
                var device = devices[i];
                // API documentation says not to rely on this value remaining unchanged.
                // See https://developers.google.com/nest/device-access/traits#device-types
                if (device.get("type").equals("sdm.devices.types.THERMOSTAT")) {
                    var n = device.get("traits").get("sdm.devices.traits.Info").get("customName");
                    var r = (device.get("parentRelations") as Lang.Array<Lang.Dictionary>)[0].get("displayName");
                    if (n.equals("")) {
                        n = r + " Thermostat";
                    }
                    menu.addItem(
                        new MenuItem(
                            n,
                            r,
                            device.get("name").substring(o, null),
                            {}
                        )
                    );
                }
            }
            if (!isGlance) {
                WatchUi.pushView(menu, new DevicesMenuInputDelegate(self), WatchUi.SLIDE_IMMEDIATE);
            }
        } else {
            if (!isGlance && (data != null)) {
                WatchUi.pushView(new ErrorView((data.get("error") as Dictionary).get("message") as String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            } else {
                if (Globals.debug) {
                    System.println("onReceiveDeviceData() Response Code: " + responseCode);
                    System.println("onReceiveDeviceData() Response Data: " + data);
                }
            }
        }
    }

    function getDevices() {
        var c = Properties.getValue("deviceId");
        if (c != null && !c.equals("")) {
            getDeviceData();
        } else {
            var url     = "https://smartdevicemanagement.googleapis.com/v1/enterprises/" + ClientId.projectId + "/devices";
            var options  = {
                :method  => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => {
                    "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
                    "Authorization" => "Bearer " + Properties.getValue("accessToken")
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            };

            if (System.getDeviceSettings().phoneConnected && wifiConnection) {
                Communications.makeWebRequest(url, null, options, method(:onReceiveDevices));
            } else {
                if (Globals.debug) {
                    System.println("Note - getDevices(): No Internet connection, skipping API call.");
                }
            }
        }
    }

    function onRecieveRefreshAccessToken(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (Globals.debug) {
            System.println("onRecieveRefreshAccessToken() Response Code: " + responseCode);
            System.println("onRecieveRefreshAccessToken() Response Data: " + data);
        }
        if (responseCode == 200) {
            Properties.setValue("accessToken", data.get("access_token"));
            Properties.setValue("accessTokenExpire", Time.now().value() + (data.get("expires_in") as Number));
            if (Globals.debug) {
                System.println("onRecieveRefreshAccessToken() accessToken: " + Properties.getValue("accessToken"));
            }
            getDevices();
        } else {
            Properties.setValue("accessToken", "");
            Properties.setValue("refreshToken", "");
            requestCallback.invoke();
        }
    }

    function onRecieveAccessToken(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (Globals.debug) {
            System.println("onRecieveAccessToken() Response Code: " + responseCode);
            System.println("onRecieveAccessToken() Response Data: " + data);
        }
        if (responseCode == 200) {
            Properties.setValue("accessToken", data.get("access_token"));
            Properties.setValue("accessTokenExpire", Time.now().value() + (data.get("expires_in") as Number));
            Properties.setValue("refreshToken", data.get("refresh_token"));
            if (Globals.debug) {
                System.println("onRecieveAccessToken() accessToken:  " + Properties.getValue("accessToken"));
                System.println("onRecieveAccessToken() refreshToken: " + Properties.getValue("refreshToken"));
            }
            getDevices();
            Properties.setValue("oauthCode", "Succeeded and deleted");
        } else {
            Properties.setValue("oauthCode", "FAILED, please try again");
            requestCallback.invoke();
        }
    }

    function getAccessToken() as Void {
        var c = Properties.getValue("refreshToken");
        if (c != null && !c.equals("")) {
            var e = Properties.getValue("accessTokenExpire");
            if (e == null || Time.now().value() > e) {
                // Access token expired, use refresh token to get a new one
                var payload = {
                    "refresh_token" => c,
                    "client_id"     => ClientId.clientId,
                    "client_secret" => ClientId.clientSecret,
                    "grant_type"    => "refresh_token"
                };

                var options = {
                    :method => Communications.HTTP_REQUEST_METHOD_POST,
                    :headers => {
                        "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
                    },
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                };
                // This follows a check for Internet access
                Communications.makeWebRequest("https://www.googleapis.com/oauth2/v4/token", payload, options, method(:onRecieveRefreshAccessToken));
            } else {
                getDevices();
            }
        } else {
            var payload = {
                "code"          => Properties.getValue("oauthCode"),
                "client_id"     => ClientId.clientId,
                "client_secret" => ClientId.clientSecret,
                "redirect_uri"  => "https://house-of-abbey.github.io/GarminThermoNest/auth",
                "grant_type"    => "authorization_code"
            };

            var options = {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            };
            // This follows a check for Internet access
            Communications.makeWebRequest("https://www.googleapis.com/oauth2/v4/token", payload, options, method(:onRecieveAccessToken));
        }
    }

    function onOAuthMessage(message as Communications.OAuthMessage) as Void {
        if (message.data != null) {
            Properties.setValue("oauthCode", (message.data as Lang.Dictionary)["oauthCode"]);
            getAccessToken();
        } else {}
    }

    function getOAuthToken() as Void {
        var c = Properties.getValue("oauthCode");
        if (c != null && !c.equals("")) {
            getAccessToken();
            return;
        }

        // for the time being, we cannot use the oauth api because google does not allow signin in a webview
        // instead we will do it manually
        Communications.openWebPage("https://nestservices.google.com/partnerconnections/" + ClientId.projectId + "/auth", {
            "access_type"            => "offline",
            "client_id"              => ClientId.clientId,
            "include_granted_scopes" => "true",
            "prompt"                 => "consent",
            "redirect_uri"           => "https://house-of-abbey.github.io/GarminThermoNest/auth",
            "response_type"          => "code",
            "scope"                  => "https://www.googleapis.com/auth/sdm.service",
            "state"                  => "pass-through value"
        }, {});

        // Communications.registerForOAuthMessages(method(:onOAuthMessage));

        // var params = {
        //     "access_type"            => "offline",
        //     "client_id"              => clientId,
        //     "include_granted_scopes" => "true",
        //     "prompt"                 => "consent",
        //     "redirect_uri"           => "https://house-of-abbey.github.io/GarminThermoNest/auth",
        //     "response_type"          => "code",
        //     "scope"                  => "https://www.googleapis.com/auth/sdm.service",
        //     "state"                  => "pass-through value"
        // };

        // Communications.makeOAuthRequest(
        //     "https://nestservices.google.com/partnerconnections/" + projectId + "/auth",
        //     params,
        //     "https://house-of-abbey.github.io/GarminThermoNest/auth",
        //     Communications.OAUTH_RESULT_TYPE_URL,
        //     { "code" => "oauthCode" }
        // );
    }

    hidden function round(n as Lang.Number) as Lang.Number or Null {
        if (n == null) {
            return null;
        } else {
            return Math.round(n*2) / 2;
        }
    }
}

class DevicesMenuInputDelegate extends WatchUi.Menu2InputDelegate {
    hidden var mNestStatus;
    function initialize(h as NestStatus) {
        Menu2InputDelegate.initialize();
        mNestStatus = h;
    }

    function onSelect(item) {
        Properties.setValue("deviceId", item.getId());
        if (Globals.debug) {
            System.println("deviceId: " + Properties.getValue("deviceId"));
        }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        mNestStatus.getDeviceData();
    }
}
