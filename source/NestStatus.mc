import Toybox.System;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;

class NestStatus {
    hidden var updateTemp;
    hidden var debug       = true  as Lang.Boolean;
    hidden var online      = false as Lang.Boolean;
    hidden var name        = ""    as Lang.String; 
    // Set this to 'C' or 'F' for temperature scale
    hidden var scale       = '-'   as Lang.Char;
    // Always Celsius
    hidden var ambientTemp = 0.0   as Lang.Number;
    // Always Celsius
    hidden var heatTemp    = 0.0   as Lang.Number;
    // Always Celsius
    hidden var coolTemp    = 0.0   as Lang.Number;
    hidden var humidity    = 0.0   as Lang.Number;
    hidden var thermoMode  = ""    as Lang.String;
    hidden var hvac        = ""    as Lang.String;
    hidden var eco         = false as Lang.Boolean;

    function initialize(h) {
        updateTemp = h;
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

    // Convert temperature to the units in 'scale'.
    function getCoolTemp() as Lang.Number {
        if (scale == 'C') {
            return coolTemp;
        } else {
            return (coolTemp * 9/5) + 32;
        }
    }

    function getHumidity() as Lang.Number {
        return humidity;
    }

    function getThermoMode() as Lang.String {
        return thermoMode;
    }

    function getHvac() as Lang.String {
        return hvac;
    }

    function getEco() as Lang.Boolean {
        return eco;
    }

    // Set up the response callback function
    function onReceive(responseCode as Number, data as Null or Dictionary or String) as Void {
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
                        thermoMode = tm.get("mode") as Lang.String;
                        if (debug) {
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
                        eco = (te.get("mode") as Lang.String).equals("MANUAL_ECO");
                        if (debug) {
                            System.println("ThermostatEco: " + (eco ? "Eco" : "Off"));
                        }
                    }
                }
            }
            updateTemp.invoke();
        } else {
            System.println("Response: " + responseCode);
        }
    }

    function makeRequest() as Void {
        // var url = "https://smartdevicemanagement.googleapis.com/v1/enterprises/<project-id>/devices/<device-id>";
        var url = "https://www.melrose.ruins/cgi-bin/fake-nest.json";

        var params = {
            "web-cache" => "10"
        };

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, params, options, method(:onReceive));
    }
}
