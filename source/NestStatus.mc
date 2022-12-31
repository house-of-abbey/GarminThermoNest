import Toybox.System;
import Toybox.Communications;
import Toybox.Authentication;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Properties;
import Toybox.Time;

const clientId = "663092493602-gkj7tshigspr28717gl3spred11oufpf.apps.googleusercontent.com";
const clientSecret = "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";
const projectId = "0d2f1cec-7a7f-4435-99c9-6ed664080826";

class NestStatus {
    hidden var requestCallback;
    hidden var debug                = true  as Lang.Boolean;

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

    public var gotDeviceData        = false as Lang.Boolean;
    public var gotDeviceDataError   = false as Lang.Boolean;

    function initialize(h) {
        requestCallback = h;
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
                heatTemp = value;
            } else {
                heatTemp = (value - 32) * 5/9;
            }
            requestCallback.invoke();
        }
    }
    function onReturnHeatTemp(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (responseCode != 200) {
            System.println("Response: " + responseCode);
            System.println("Response: " + data);
            WatchUi.pushView(new ErrorView((data.get("error") as Dictionary).get("message") as String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            getDeviceData();
        }
        requestCallback.invoke();
    }
    function executeHeatTemp() as Void {
        if (!eco) {
            executeCommand({
                "command" => "sdm.devices.commands.ThermostatTemperatureSetpoint.SetHeat",
                "params"  => {
                    "heatCelsius" => heatTemp
                }
            }, method(:onReturnHeatTemp));
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
                coolTemp = value;
            } else {
                coolTemp = (value - 32) * 5/9;
            }
            requestCallback.invoke();
        }
    }
    function onReturnCoolTemp(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (responseCode != 200) {
            System.println("Response: " + responseCode);
            System.println("Response: " + data);
            WatchUi.pushView(new ErrorView((data.get("error") as Dictionary).get("message") as String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            getDeviceData();
        }
        requestCallback.invoke();
    }
    function executeCoolTemp() as Void {
        if (!eco) {
            executeCommand({
                "command" => "sdm.devices.commands.ThermostatTemperatureSetpoint.SetCool",
                "params"  => {
                    "CoolCelsius" => coolTemp
                }
            }, method(:onReturnCoolTemp));
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
        var a = availableThermoModes.indexOf(thermoMode);
        var b = availableThermoModes.size();
        setThermoMode(availableThermoModes[(a+1) % b] as Lang.String);
    }
    function onReturnThermoMode(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (responseCode != 200) {
            System.println("Response: " + responseCode);
            System.println("Response: " + data);
            WatchUi.pushView(new ErrorView((data.get("error") as Dictionary).get("message") as String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            getDeviceData();
        }
        requestCallback.invoke();
    }
    function executeThermoMode() as Void {
        executeCommand({
            "command" => "sdm.devices.commands.ThermostatMode.SetMode",
            "params"  => {
                "mode" => thermoMode
            }
        }, method(:onReturnThermoMode));
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
        setEco(!eco);
    }
    function onReturnEco(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (responseCode != 200) {
            if (debug) {
                System.println("Response: " + responseCode);
                System.println("Response: " + data);
            }
            WatchUi.pushView(new ErrorView((data.get("error") as Dictionary).get("message") as String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            getDeviceData();
        }
        requestCallback.invoke();
    }
    function executeEco() as Void {
        executeCommand({
            "command" => "sdm.devices.commands.ThermostatEco.SetMode",
            "params"  => {
                "mode" => eco ? "MANUAL_ECO" : "OFF"
            }
        }, method(:onReturnEco));
    }

    private function executeCommand(payload as Dictionary, callback) {
        var url = "https://smartdevicemanagement.googleapis.com/v1/enterprises/" + projectId + "/devices/" + Properties.getValue("deviceId") + ":executeCommand";

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Authorization" => "Bearer " + Properties.getValue("accessToken")
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, payload, options, callback);
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
                        if (debug) {
                            System.println("Status: " + (online ? "On line" : "Off line"));
                        }
                    }
                    var info = traits.get("sdm.devices.traits.Info") as Dictionary;
                    if (info != null) {
                        name = info.get("customName") as Lang.String;
                        if (debug) {
                            System.println("Name: '" + name + "'");
                        }
                    }
                    var settings = traits.get("sdm.devices.traits.Settings") as Dictionary;
                    if (settings != null) {
                        scale = (settings.get("temperatureScale") as Lang.String).equals("CELSIUS") ? 'C' : 'F';
                        if (debug) {
                            System.println("Scale: '" + scale + "'");
                        }
                    }
                    var e = traits.get("sdm.devices.traits.Temperature") as Dictionary;
                    if (e != null) {
                        ambientTemp = e.get("ambientTemperatureCelsius") as Lang.Number;
                        if (debug) {
                            System.println("Temperature: " + ambientTemp + " deg C");
                        }
                    }
                    var ttsp = traits.get("sdm.devices.traits.ThermostatTemperatureSetpoint") as Dictionary;
                    if (ttsp != null) {
                        heatTemp = ttsp.get("heatCelsius") as Lang.Number;
                        coolTemp = ttsp.get("coolCelsius") as Lang.Number;
                        if (debug) {
                            System.println("Heat Temperature: " + heatTemp + " deg C");
                            System.println("Cool Temperature: " + coolTemp + " deg C");
                        }
                    }
                    var h = traits.get("sdm.devices.traits.Humidity") as Dictionary;
                    if (h != null) {
                        humidity = h.get("ambientHumidityPercent") as Lang.Number;
                        if (debug) {
                            System.println("Humidity: " + humidity + " %");
                        }
                    }
                    var tm = traits.get("sdm.devices.traits.ThermostatMode") as Dictionary;
                    if (tm != null) {
                        availableThermoModes = tm.get("availableModes") as Lang.Array;
                        thermoMode = tm.get("mode") as Lang.String;
                        if (debug) {
                            System.println("Thermo Modes: " + availableThermoModes);
                            System.println("ThermostatMode: " + thermoMode);
                        }
                    }
                    var th = traits.get("sdm.devices.traits.ThermostatHvac") as Dictionary;
                    if (th != null) {
                        hvac = th.get("status") as Lang.String;
                        if (debug) {
                            System.println("ThermostatHvac: " + hvac);
                        }
                    }
                    var te = traits.get("sdm.devices.traits.ThermostatEco") as Dictionary;
                    if (te != null) {
                        availableEcoModes = te.get("availableModes") as Lang.Array;
                        eco = (te.get("mode") as Lang.String).equals("MANUAL_ECO");
                        if (debug) {
                            System.println("Eco Modes: " + availableEcoModes);
                            System.println("ThermostatEco: " + (eco ? "Eco" : "Off"));
                        }
                        if (eco) {
                            heatTemp = te.get("heatCelsius") as Lang.Number;
                            coolTemp = te.get("coolCelsius") as Lang.Number;
                            if (debug) {
                                System.println("Heat Temperature: " + heatTemp + " deg C (eco)");
                                System.println("Cool Temperature: " + coolTemp + " deg C (eco)");
                            }
                        }
                    }
                }
            }
            gotDeviceData      = true;
            gotDeviceDataError = false;
            requestCallback.invoke();
        } else {
            System.println("Response: " + responseCode);
            System.println("Response: " + data);
            gotDeviceData      = true;
            gotDeviceDataError = true;

            if (responseCode == 404) {
                Properties.setValue("deviceId", "");
                WatchUi.pushView(new ErrorView("Device not found."), new ErrorDelegate(), WatchUi.SLIDE_UP);
            } else if (responseCode == 401) {
                Properties.setValue("accessToken", "");
                Properties.setValue("refreshToken", "");
                WatchUi.pushView(new ErrorView("Authentication failed."), new ErrorDelegate(), WatchUi.SLIDE_UP);
            } else {
                WatchUi.pushView(new ErrorView((data.get("error") as Dictionary).get("message") as String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }

            requestCallback.invoke();
        }
    }

    function getDeviceData() as Void {
        var url = "https://smartdevicemanagement.googleapis.com/v1/enterprises/" + projectId + "/devices/" + Properties.getValue("deviceId");

        var params = {
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
                "Authorization" => "Bearer " + Properties.getValue("accessToken")
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, params, options, method(:onReceiveDeviceData));
    }

    function onReceiveDevices(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (responseCode == 200) {
            System.println("Response: " + data);
            var devices = data.get("devices") as Lang.Array;
            var menu = new WatchUi.Menu2({ :title => "Devices" });
            var o = 21 + projectId.length();
            for (var i = 0; i < devices.size(); i++) {
                var device = devices[i];
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
            WatchUi.pushView(menu, new DevicesMenuInputDelegate(self), WatchUi.SLIDE_IMMEDIATE);
        } else {
            System.println("Response: " + responseCode);
            System.println("Response: " + data);
            WatchUi.pushView(new ErrorView((data.get("error") as Dictionary).get("message") as String), new ErrorDelegate(), WatchUi.SLIDE_UP);
        }
    }

    function getDevices() {
        var c = Properties.getValue("deviceId");
        if (c != null && !c.equals("")) {
            getDeviceData();
        } else {
            var url = "https://smartdevicemanagement.googleapis.com/v1/enterprises/" + projectId + "/devices";

            var params = {
            };

            var options = {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => {
                    "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
                    "Authorization" => "Bearer " + Properties.getValue("accessToken")
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            };

            Communications.makeWebRequest(url, params, options, method(:onReceiveDevices));
        }
    }

    function onRecieveRefreshAccessToken(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (responseCode == 200) {
            System.println("Response: " + data);
            Properties.setValue("accessToken", data.get("access_token"));
            Properties.setValue("accessTokenExpire", Time.today().value() + (data.get("expires_in") as Number));
            System.println(Lang.format("accessToken: $1$", [Properties.getValue("accessToken")]));
            getDevices();
        } else {
            System.println("Response: " + responseCode);
            System.println("Response: " + data);
            Properties.setValue("oauthCode", "");
            requestCallback.invoke();
        }
    }

    function onRecieveAccessToken(responseCode as Number, data as Null or Dictionary or String) as Void {
        if (responseCode == 200) {
            System.println("Response: " + data);
            Properties.setValue("accessToken", data.get("access_token"));
            Properties.setValue("accessTokenExpire", Time.today().value() + (data.get("expires_in") as Number));
            Properties.setValue("refreshToken", data.get("refresh_token"));
            System.println(Lang.format("accessToken: $1$", [Properties.getValue("accessToken")]));
            System.println(Lang.format("refreshToken: $1$", [Properties.getValue("refreshToken")]));
            getDevices();
        } else {
            System.println("Response: " + responseCode);
            System.println("Response: " + data);
            Properties.setValue("oauthCode", "");
            requestCallback.invoke();
        }
    }

    function getAccessToken() as Void {
        var c = Properties.getValue("refreshToken");
        if (c != null && !c.equals("")) {
            var e = Properties.getValue("accessTokenExpire");
            if (e == null || Time.today().value() > e) {
                var payload = {
                    "refresh_token" => c,
                    "client_id"     => clientId,
                    "client_secret" => clientSecret,
                    "grant_type"    => "refresh_token"
                };

                var options = {
                    :method => Communications.HTTP_REQUEST_METHOD_POST,
                    :headers => {
                        "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
                    },
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                };

                Communications.makeWebRequest("https://www.googleapis.com/oauth2/v4/token", payload, options, method(:onRecieveRefreshAccessToken));
            } else {
                getDevices();
            }
        } else {
            var payload = {
                "code"          => Properties.getValue("oauthCode"),
                "client_id"     => clientId,
                "client_secret" => clientSecret,
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
        Communications.openWebPage("https://nestservices.google.com/partnerconnections/" + projectId + "/auth", {
            "access_type"            => "offline",
            "client_id"              => clientId,
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
}

class DevicesMenuInputDelegate extends WatchUi.Menu2InputDelegate {
    hidden var mNestStatus;
    function initialize(h as NestStatus) {
        Menu2InputDelegate.initialize();
        mNestStatus = h;
    }

    function onSelect(item) {
        Properties.setValue("deviceId", item.getId());
        System.println("deviceId: " + Properties.getValue("deviceId"));
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        mNestStatus.getDeviceData();
    }
}
