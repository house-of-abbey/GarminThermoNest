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
// the Google Cloud Project hosting the REST API access we paid for. It provides a
// cache of the online status locally, and is also used to post new settings back to
// the REST API.
//
// References:
//  * https://developers.google.com/nest/device-access/registration
//  * https://developers.google.com/nest/device-access/api/thermostat
//  * https://developers.google.com/nest/device-access/traits
//
//-----------------------------------------------------------------------------------

using Toybox.System;
using Toybox.Communications;
using Toybox.Authentication;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Application.Properties;
using Toybox.Time;
using Toybox.Math;

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
    // Always Celsius
    hidden var ecoHeatTemp          = 0.0   as Lang.Number;
    // Always Celsius
    hidden var ecoCoolTemp          = 0.0   as Lang.Number;
    hidden var humidity             = 0.0   as Lang.Number;
    hidden var availableThermoModes = null  as Lang.Array;
    hidden var thermoMode           = ""    as Lang.String;
    hidden var hvac                 = ""    as Lang.String;
    hidden var availableEcoModes    = null  as Lang.Array;
    hidden var eco                  = false as Lang.Boolean;
    hidden var gotDeviceData        = false as Lang.Boolean;
    hidden var gotDeviceDataError   = false as Lang.Boolean;
    hidden var alertSending;
    hidden var alertNoChange;

    // Parameters:
    //  * ig = isGlance, true when initialised from a GlanceView, otherwise false.
    //
    function initialize(isGlance) {
        self.isGlance = isGlance;
        if (!isGlance) {
            alertSending = new Alert({
                :timeout => Globals.alertTimeout,
                :font    => Graphics.FONT_MEDIUM,
                :text    => WatchUi.loadResource($.Rez.Strings.sendingAlert) as Lang.String,
                :fgcolor => Graphics.COLOR_GREEN,
                :bgcolor => Graphics.COLOR_BLACK
            });
            alertNoChange = new Alert({
                :timeout => Globals.alertTimeout,
                :font    => Graphics.FONT_MEDIUM,
                :text    => WatchUi.loadResource($.Rez.Strings.noChangeAlert) as Lang.String,
                :fgcolor => Graphics.COLOR_YELLOW,
                :bgcolor => Graphics.COLOR_BLACK
            });
        }
        if (System.getDeviceSettings().phoneConnected && System.getDeviceSettings().connectionAvailable) {
            getOAuthToken();
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

    function getGotDeviceData() as Lang.Boolean {
        return gotDeviceData;
    }

    function getGotDeviceDataError() as Lang.Boolean {
        return gotDeviceDataError;
    }

    // Convert temperature to the units in 'scale'.
    function getAmbientTemp() as Lang.Float or Null {
        if (ambientTemp == null) {
            return null;
        } else {
            if (scale == 'C') {
                return ambientTemp;
            } else {
                return cToF(ambientTemp);
            }
        }
    }

    // Convert temperature to the units in 'scale'.
    function getHeatTemp() as Lang.Float or Null {
        if (heatTemp == null) {
            return null;
        } else {
            if (scale == 'C') {
                return limitC(heatTemp);
            } else {
                return cToF(heatTemp);
            }
        }
    }

    function setHeatTemp(value as Lang.Float) as Void {
        if (!eco) {
            if (scale == 'C') {
                if (9f <= value && value <= 32f) {
                    heatTemp = limitC(value);
                } else {
                    if (Globals.debug) {
                        System.println("setHeatTemp() temperature: " + value + "°" + scale + " is out of range.");
                    }
                }
            } else {
                if (48f <= value && value <= 90f) {
                    heatTemp = fToC(value);
                } else {
                    if (Globals.debug) {
                        System.println("setHeatTemp() temperature: " + value + "°" + scale + " is out of range.");
                    }
                }
            }
        }
    }

    // Convert temperature to the units in 'scale'.
    function getCoolTemp() as Lang.Float or Null {
        if (coolTemp == null) {
            return null;
        } else {
            if (scale == 'C') {
                return coolTemp;
            } else {
                return cToF(coolTemp);
            }
        }
    }

    function setCoolTemp(value as Lang.Float) as Void {
        if (!eco) {
            if (scale == 'C') {
                if (9f <= value && value <= 32f) {
                    coolTemp = value;
                } else {
                    if (Globals.debug) {
                        System.println("setCoolTemp() temperature: " + value + "°" + scale + " is out of range.");
                    }
                }
            } else {
                if (48f <= value && value <= 90f) {
                    coolTemp = fToC(value);
                } else {
                    if (Globals.debug) {
                        System.println("setCoolTemp() temperature: " + value + "°" + scale + " is out of range.");
                    }
                }
            }
        }
    }

    // Convert temperature to the units in 'scale'.
    function getEcoHeatTemp() as Lang.Float or Null {
        if (ecoHeatTemp == null) {
            return null;
        } else {
            if (scale == 'C') {
                return limitC(ecoHeatTemp);
            } else {
                return cToF(ecoHeatTemp);
            }
        }
    }

    // Convert temperature to the units in 'scale'.
    function getEcoCoolTemp() as Lang.Float or Null {
        if (ecoCoolTemp == null) {
            return null;
        } else {
            if (scale == 'C') {
                return ecoCoolTemp;
            } else {
                return cToF(ecoCoolTemp);
            }
        }
    }

    function onReturnChangeTemp(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.debug) {
            System.println("onReturnChangeTemp() Response Code: " + responseCode);
            System.println("onReturnChangeTemp() Response Data: " + data);
        }
        if (responseCode != 200) {
            if (!isGlance) {
                WatchUi.pushView(new ErrorView((data.get("error") as Lang.Dictionary).get("message") as Lang.String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }
            getDeviceData();
        }
        if (Globals.debug) {
            System.println("onReturnChangeTemp() Display Update");
        }
        WatchUi.requestUpdate();
    }

    function executeChangeTemp(ht as Lang.Float, ct as Lang.Float) as Void {
        if (scale == 'C') {
            if (ht != null) { ht = limitC(ht); }
            if (ct != null) { ct = limitC(ct); }
        } else {
            if (ht != null) { ht = fToC(ht); }
            if (ct != null) { ct = fToC(ct); }
        }
        if (!eco && !thermoMode.equals("OFF")) {
            // https://developers.google.com/nest/device-access/traits/device/thermostat-temperature-setpoint
            switch (thermoMode as Lang.String) {
                case "OFF":
                    break;

                case "HEAT":
                    if (heatTemp != ht) {
                        executeCommand(
                            {
                                "command" => "sdm.devices.commands.ThermostatTemperatureSetpoint.SetHeat",
                                "params"  => {
                                    "heatCelsius" => ht
                                }
                            },
                            method(:onReturnChangeTemp),
                            null
                        );
                        // Sets heatTemp below within the allowed limits in Celcius
                        setHeatTemp(ht);
                        alertSending.pushView(WatchUi.SLIDE_IMMEDIATE);
                    } else {
                        if (Globals.debug) {
                            System.println("Skipping executeChangeTemp() as no change.");
                        }
                        alertNoChange.pushView(WatchUi.SLIDE_IMMEDIATE);
                    }
                    break;

                case "COOL":
                    if (coolTemp != ct) {
                        executeCommand(
                            {
                                "command" => "sdm.devices.commands.ThermostatTemperatureSetpoint.SetCool",
                                "params"  => {
                                    "CoolCelsius" => ct
                                }
                            },
                            method(:onReturnChangeTemp),
                            null
                        );
                        // Sets heatTemp below within the allowed limits in Celcius
                        setCoolTemp(ct);
                        alertSending.pushView(WatchUi.SLIDE_IMMEDIATE);
                    } else {
                        if (Globals.debug) {
                            System.println("Skipping executeChangeTemp() as no change.");
                        }
                        alertNoChange.pushView(WatchUi.SLIDE_IMMEDIATE);
                    }
                    break;

                case "HEATCOOL":
                    if (heatTemp != ht || coolTemp != ct) {
                        executeCommand(
                            {
                                "command" => "sdm.devices.commands.ThermostatTemperatureSetpoint.SetRange",
                                "params"  => {
                                    "heatCelsius" => ht,
                                    "CoolCelsius" => ct
                                }
                            },
                            method(:onReturnChangeTemp),
                            null
                        );
                        // Sets heatTemp below within the allowed limits in Celcius
                        setHeatTemp(ht);
                        setCoolTemp(ct);
                        alertSending.pushView(WatchUi.SLIDE_IMMEDIATE);
                    } else {
                        if (Globals.debug) {
                            System.println("Skipping executeChangeTemp() as no change.");
                        }
                        alertNoChange.pushView(WatchUi.SLIDE_IMMEDIATE);
                    }
                    break;

                default:
                    if (Globals.debug) {
                        System.print("ERROR - ModeChangeView: Unsupported HVAC mode '" + thermoMode + "'");
                    }
                    break;
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

    function onReturnThermoMode(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String, context as Lang.Object) as Void {
        if (Globals.debug) {
            System.println("onReturnThermoMode() Response Code: " + responseCode);
            System.println("onReturnThermoMode() Response Data: " + data);
        }
        if (responseCode != 200) {
            if (!isGlance) {
                WatchUi.pushView(new ErrorView((data.get("error") as Lang.Dictionary).get("message") as Lang.String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }
        }
        executeMode(Thermo, context as Lang.Dictionary);
    }

    function executeThermoMode(params as Lang.Dictionary) as Void {
        var mode = params.get(:thermoMode);
        if (mode.equals(thermoMode)) {
            if (Globals.debug) {
                System.println("Skipping executeThermoMode() as no change.");
            }
            executeMode(NoThermo, params);
        } else {
            executeCommand(
                {
                    "command" => "sdm.devices.commands.ThermostatMode.SetMode",
                    "params"  => {
                        "mode" => mode
                    }
                },
                method(:onReturnThermoMode),
                params as Lang.Object
            );
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

    function onReturnEco(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String, context as Lang.Object) as Void {
        if (Globals.debug) {
            System.println("onReturnEco() Response Code: " + responseCode);
            System.println("onReturnEco() Response Data: " + data);
        }
        if (responseCode != 200) {
            if (!isGlance) {
                WatchUi.pushView(new ErrorView((data.get("error") as Lang.Dictionary).get("message") as Lang.String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }
        }
        executeMode(Eco, context as Lang.Dictionary);
    }

    function executeEco(
        params as {
            :thermoMode as Lang.String,
            :ecoMode    as Lang.Boolean
        }
    ) as Void {
        var e = params.get(:ecoMode);
        if (eco == e) {
            if (Globals.debug) {
                System.println("Skipping executeEco() as no change.");
            }
            executeMode(NoEco, params);
        } else {
            executeCommand(
                {
                    "command" => "sdm.devices.commands.ThermostatEco.SetMode",
                    "params"  => {
                        "mode" => e ? "MANUAL_ECO" : "OFF"
                    }
                },
                method(:onReturnEco),
                params
            );
            eco = e;
        }
    }

    // Spawn sub-tasks from here and retain control of execution of asynchronous elements.
    function executeMode(
        r      as Lang.Number,
        params as {
            :thermoMode as Lang.String,
            :ecoMode    as Lang.Boolean
        }
    ) as Void {
        switch (r) {
            case Start:
                if (Globals.debug) {
                    System.println("executeMode() Start: thermoMode=" + params.get(:thermoMode) + ", ecoMode=" + params.get(:ecoMode));
                }
                if (params.get(:thermoMode) == thermoMode && params.get(:ecoMode) == eco) {
                    alertNoChange.pushView(WatchUi.SLIDE_IMMEDIATE);
                } else {
                    alertSending.pushView(WatchUi.SLIDE_IMMEDIATE);
                }
                // Changing ThermoMode also turns off Eco Mode, then setting Eco mode off errors.
                executeThermoMode(params);
                break;
            case NoThermo:
                if (Globals.debug) {
                    System.println("executeMode() NoThermo");
                }
                executeEco(params);
                break;
            case Thermo:
                if (Globals.debug) {
                    System.println("executeMode() Thermo");
                }
                // At this point Eco is always OFF as we set the ThermoMode.
                if (params.get(:ecoMode)) {
                    executeEco(params);
                } else {
                    // The end
                    getDeviceData();
                }
                break;
            case NoEco: // Fall through
            case Eco:
                if (Globals.debug) {
                    System.println("executeMode() NoEco & Eco");
                }
                // The end
                getDeviceData();
                break;
        }
    }

    private function executeCommand(payload as Lang.Dictionary, callback, context as Lang.Object or Null) {
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Authorization" => "Bearer " + Properties.getValue("accessToken")
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        if (context != null) {
            options.put(:context, context);
        }
        if (System.getDeviceSettings().phoneConnected && System.getDeviceSettings().connectionAvailable) {
            Communications.makeWebRequest(Globals.getExecuteCommandUrl(), payload, options, callback);
        } else {
            if (Globals.debug) {
                System.println("Note - executeCommand(): No Internet connection, skipping API call.");
            }
        }
    }

    // Set up the response callback function
    function onReceiveDeviceData(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (responseCode == 200) {
            if (data != null) {
                var traits = data.get("traits") as Lang.Dictionary;
                if (traits != null) {
                    var con = traits.get("sdm.devices.traits.Connectivity") as Lang.Dictionary;
                    if (con != null) {
                        online = (con.get("status") as Lang.String).equals("ONLINE");
                        if (Globals.debug) {
                            System.println(" Status: " + (online ? "On line" : "Off line"));
                        }
                    }
                    var info = traits.get("sdm.devices.traits.Info") as Lang.Dictionary;
                    if (info != null) {
                        name = info.get("customName") as Lang.String;
                        if (Globals.debug) {
                            System.println(" Name: '" + name + "'");
                        }
                    }
                    var settings = traits.get("sdm.devices.traits.Settings") as Lang.Dictionary;
                    if (settings != null) {
                        scale = (settings.get("temperatureScale") as Lang.String).equals("CELSIUS") ? 'C' : 'F';
                        if (Globals.debug) {
                            System.println(" Scale: '" + scale + "'");
                        }
                    }
                    var e = traits.get("sdm.devices.traits.Temperature") as Lang.Dictionary;
                    if (e != null) {
                        ambientTemp = round(e.get("ambientTemperatureCelsius") as Lang.Float, Globals.celciusRes);
                        if (Globals.debug) {
                            System.println(" Temperature: " + ambientTemp + " deg C");
                        }
                    }
                    var ttsp = traits.get("sdm.devices.traits.ThermostatTemperatureSetpoint") as Lang.Dictionary;
                    if (ttsp != null) {
                        heatTemp = round(ttsp.get("heatCelsius") as Lang.Float, Globals.celciusRes);
                        coolTemp = round(ttsp.get("coolCelsius") as Lang.Float, Globals.celciusRes);
                        if (Globals.debug) {
                            System.println(" Heat Temperature: " + heatTemp + " deg C");
                            System.println(" Cool Temperature: " + coolTemp + " deg C");
                        }
                    }
                    var h = traits.get("sdm.devices.traits.Humidity") as Lang.Dictionary;
                    if (h != null) {
                        humidity = h.get("ambientHumidityPercent") as Lang.Number;
                        if (Globals.debug) {
                            System.println(" Humidity: " + humidity + " %");
                        }
                    }
                    var tm = traits.get("sdm.devices.traits.ThermostatMode") as Lang.Dictionary;
                    if (tm != null) {
                        availableThermoModes = tm.get("availableModes") as Lang.Array;
                        thermoMode = tm.get("mode") as Lang.String;
                        if (Globals.debug) {
                            System.println(" Thermo Modes: " + availableThermoModes);
                            System.println(" ThermostatMode: " + thermoMode);
                        }
                    }
                    var th = traits.get("sdm.devices.traits.ThermostatHvac") as Lang.Dictionary;
                    if (th != null) {
                        hvac = th.get("status") as Lang.String;
                        if (Globals.debug) {
                            System.println(" ThermostatHvac: " + hvac);
                        }
                    }
                    var te = traits.get("sdm.devices.traits.ThermostatEco") as Lang.Dictionary;
                    if (te != null) {
                        availableEcoModes = te.get("availableModes") as Lang.Array;
                        eco = (te.get("mode") as Lang.String).equals("MANUAL_ECO");
                        if (Globals.debug) {
                            System.println(" Eco Modes: " + availableEcoModes);
                            System.println(" ThermostatEco: " + (eco ? "Eco" : "Off"));
                        }
                        ecoHeatTemp = round(te.get("heatCelsius") as Lang.Float or Null, Globals.celciusRes);
                        if (Globals.debug) {
                            System.println(" Eco Heat Temperature: " + ecoHeatTemp + " deg C");
                        }
                        ecoCoolTemp = round(te.get("coolCelsius") as Lang.Float or Null, Globals.celciusRes);
                        if (Globals.debug) {
                            System.println(" Eco Cool Temperature: " + ecoCoolTemp + " deg C");
                        }
                    }
                }
            }
            gotDeviceData      = true;
            gotDeviceDataError = false;
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
                Properties.setValue("accessTokenExpire", 0);
                Properties.setValue("refreshToken", "");
                if (!isGlance) {
                    WatchUi.pushView(new ErrorView("Authentication issue, access and refresh tokens deleted."), new ErrorDelegate(), WatchUi.SLIDE_UP);
                }
            } else {
                // This method might be called before authorisation has completed.
                if (!isGlance && (data != null)) {
                    WatchUi.pushView(new ErrorView((data.get("error") as Lang.Dictionary).get("message") as Lang.String), new ErrorDelegate(), WatchUi.SLIDE_UP);
                }
            }
        }
        if (Globals.debug) {
            System.println("onReceiveDeviceData() Display Update");
        }
        WatchUi.requestUpdate();
    }

    function getDeviceData() as Void {
        var options = {
            :method  => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
                "Authorization" => "Bearer " + Properties.getValue("accessToken")
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        if (System.getDeviceSettings().phoneConnected && System.getDeviceSettings().connectionAvailable) {
            Communications.makeWebRequest(Globals.getDeviceDataUrl(), null, options, method(:onReceiveDeviceData));
        } else {
            if (Globals.debug) {
                System.println("Note - getDeviceData(): No Internet connection, skipping API call.");
            }
        }
    }

    function onReceiveDevices(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.debug) {
            System.println("onReceiveDevices() Response Code: " + responseCode);
            System.println("onReceiveDevices() Response Data: " + data);
        }
        if (responseCode == 200) {
            if (!isGlance) {
                var devices = data.get("devices") as Lang.Array;
                var menu = new WatchUi.Menu2({ :title => WatchUi.loadResource($.Rez.Strings.deviceList) });
                var thermStr = WatchUi.loadResource($.Rez.Strings.thermostat) as Lang.String;
                var o = 21 + ClientId.projectId.length();
                for (var i = 0; i < devices.size(); i++) {
                    var device = devices[i];
                    // API documentation says not to rely on this value remaining unchanged.
                    // See https://developers.google.com/nest/device-access/traits#device-types
                    if (device.get("type").equals("sdm.devices.types.THERMOSTAT")) {
                        var n = device.get("traits").get("sdm.devices.traits.Info").get("customName");
                        var r = (device.get("parentRelations") as Lang.Array<Lang.Dictionary>)[0].get("displayName");
                        if (n.equals("")) {
                            n = r + " " + thermStr;
                        }
                        menu.addItem(
                            new WatchUi.MenuItem(
                                n,
                                r,
                                device.get("name").substring(o, null),
                                {}
                            )
                        );
                    }
                }
                WatchUi.pushView(menu, new DevicesMenuInputDelegate(self), WatchUi.SLIDE_IMMEDIATE);
            }
        } else {
            if (!isGlance && (data != null)) {
                WatchUi.pushView(new ErrorView((data.get("error") as Lang.Dictionary).get("message") as Lang.String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            } else {
                if (Globals.debug) {
                    System.println("onReceiveDevices() Response Code: " + responseCode);
                    System.println("onReceiveDevices() Response Data: " + data);
                }
            }
        }
    }

    function getDevices() {
        var c = Properties.getValue("deviceId");
        if (c == null || c.equals("")) {
            if (System.getDeviceSettings().phoneConnected && System.getDeviceSettings().connectionAvailable) {
                var options  = {
                    :method  => Communications.HTTP_REQUEST_METHOD_GET,
                    :headers => {
                        "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
                        "Authorization" => "Bearer " + Properties.getValue("accessToken")
                    },
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                };
                Communications.makeWebRequest(Globals.getDevicesUrl(), null, options, method(:onReceiveDevices));
            } else {
                if (Globals.debug) {
                    System.println("Note - getDevices(): No Internet connection, skipping API call.");
                }
            }
        } else {
            getDeviceData();
        }
    }

    function onReceiveRefreshToken(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.debug) {
            System.println("onReceiveRefreshToken() Response Code: " + responseCode);
            System.println("onReceiveRefreshToken() Response Data: " + data);
        }
        if (responseCode == 200) {
            Properties.setValue("accessToken", data.get("access_token"));
            Properties.setValue("accessTokenExpire", Time.now().value() + (data.get("expires_in") as Lang.Number));
            if (Globals.debug) {
                System.println("onReceiveRefreshToken() accessToken: " + Properties.getValue("accessToken"));
            }
            getDevices();
        } else {
            Properties.setValue("accessToken", "");
            Properties.setValue("accessTokenExpire", 0);
            Properties.setValue("refreshToken", "");
            if (Globals.debug) {
                System.println("onReceiveRefreshToken() Display Update");
            }
            WatchUi.requestUpdate();
        }
    }

    function onRecieveAccessToken(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.debug) {
            System.println("onRecieveAccessToken() Response Code: " + responseCode);
            System.println("onRecieveAccessToken() Response Data: " + data);
        }
        if (responseCode == 200) {
            Properties.setValue("accessToken", data.get("access_token"));
            Properties.setValue("accessTokenExpire", Time.now().value() + (data.get("expires_in") as Lang.Number));
            Properties.setValue("refreshToken", data.get("refresh_token"));
            if (Globals.debug) {
                System.println("onRecieveAccessToken() accessToken:  " + Properties.getValue("accessToken"));
                System.println("onRecieveAccessToken() refreshToken: " + Properties.getValue("refreshToken"));
            }
            getDevices();
            Properties.setValue("oauthCode", "Succeeded and deleted");
        } else {
            Properties.setValue("oauthCode", "FAILED, please try again");
            if (!isGlance) {
                WatchUi.pushView(new ErrorView((data.get("error") as Lang.Dictionary).get("message") as Lang.String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }
            if (Globals.debug) {
                System.println("onRecieveAccessToken() Display Update");
            }
            WatchUi.requestUpdate();
        }
    }

    function getAccessToken() as Void {
        // Both Access and Refresh tokens are truncated when authentication with them fails
        var e = Properties.getValue("accessTokenExpire");
        if (e == null || Time.now().value() > e) {
            // Access token expired, use refresh token to get a new one
            var c = Properties.getValue("refreshToken");
            if (c == null || c.equals("")) {
                // Full OAuth
                var payload = {
                    "code"          => Properties.getValue("oauthCode"),
                    "client_id"     => ClientId.clientId,
                    "client_secret" => ClientId.clientSecret,
                    "redirect_uri"  => Globals.getRedirectUrl(),
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
                Communications.makeWebRequest(Globals.getOAuthTokenUrl(), payload, options, method(:onRecieveAccessToken));
            } else {
                // Refresh Auth
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
                Communications.makeWebRequest(Globals.getOAuthTokenUrl(), payload, options, method(:onReceiveRefreshToken));
            }
        } else {
            // Token is current, just use it
            getDevices();
        }
    }

    // Park of the SDK's broken OAuth - Commented out for now.
    //
    // private function onOAuthMessage(message as Communications.OAuthMessage) as Void {
    //     if (message.data != null) {
    //         Properties.setValue("oauthCode", (message.data as Lang.Dictionary)["oauthCode"]);
    //         getAccessToken();
    //     } else {
    //         if (Globals.debug) {
    //             System.println("onOAuthMessage() message.data was null.");
    //         }
    //     }
    // }

    function getOAuthToken() as Void {
        var c = Properties.getValue("oauthCode");
        if (c == null || c.equals("")) {
            if (!isGlance) {
                WatchUi.pushView(new ErrorView("Need to complete OAuth externally first"), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }
            return;
        } else {
            getAccessToken();
            return;
        }

        // For the time being, we cannot use the OAuth API because Google does not allow sign in in a
        // webview. Instead we will do it manually outside the application.
        //
        // Communications.openWebPage(
        //     "https://nestservices.google.com/partnerconnections/" + ClientId.projectId + "/auth",
        //     {
        //         "access_type"            => "offline",
        //         "client_id"              => ClientId.clientId,
        //         "include_granted_scopes" => "true",
        //         "prompt"                 => "consent",
        //         "redirect_uri"           => Globals.getRedirectUrl(),
        //         "response_type"          => "code",
        //         "scope"                  => "https://www.googleapis.com/auth/sdm.service",
        //         "state"                  => "pass-through value"
        //     },
        //     {}
        // );
        // Communications.registerForOAuthMessages(method(:onOAuthMessage));
        //
        // var params = {
        //     "access_type"            => "offline",
        //     "client_id"              => clientId,
        //     "include_granted_scopes" => "true",
        //     "prompt"                 => "consent",
        //     "redirect_uri"           => Globals.getRedirectUrl(),
        //     "response_type"          => "code",
        //     "scope"                  => "https://www.googleapis.com/auth/sdm.service",
        //     "state"                  => "pass-through value"
        // };
        // Communications.makeOAuthRequest(
        //     "https://nestservices.google.com/partnerconnections/" + projectId + "/auth",
        //     params,
        //     Globals.getRedirectUrl(),
        //     Communications.OAUTH_RESULT_TYPE_URL,
        //     {
        //         "code" => "oauthCode"
        //     }
        // );
    }

    // Rounds to a resolution
    // Parameters:
    // * n   = Number to round
    // * res = Resolution, e.g. 0.5
    static function round(n as Lang.Float or Null, res as Lang.Float) as Lang.Float or Null {
        var invres = 1 / res;
        if (n == null) {
            return null;
        } else {
            return Math.round(n * invres) / invres;
        }
    }

    // Limit the Celcius range.
    //
    static function limitC(t as Lang.Float) as Lang.Float {
        if (t > Globals.maxTempC) {
            t = Globals.maxTempC;
        }
        if (t < Globals.minTempC) {
            t = Globals.minTempC;
        }
        return t;
    }

    // Convert Celcius to Fahrenheit with the correct rounding and within the range limits.
    //
    static function cToF(t as Lang.Float) as Lang.Float {
        return round((limitC(t) * 9/5) + 32, Globals.farenheitRes);
    }

    // Limit the Fahrenheit range.
    //
    static function limitF(t as Lang.Float) as Lang.Float {
        if (t > Globals.maxTempF) {
            t = Globals.maxTempF;
        }
        if (t < Globals.minTempF) {
            t = Globals.minTempF;
        }
        return t;
    }

    // Convert Fahrenheit to Celcius with the correct rounding and within the range limits.
    //
    static function fToC(t as Lang.Float) as Lang.Float {
        return round((limitF(t) - 32) * 5/9, Globals.celciusRes);
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
