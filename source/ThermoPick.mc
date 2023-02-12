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
// ThermoPick provides the a list of thermostats from which to select one to control.
//
// References:
//  * https://developers.google.com/nest/device-access/traits/structure/info
//  * https://developers.google.com/nest/device-access/traits/structure/room-info
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Application.Properties;

class ThermoPick extends WatchUi.Menu2 {
    // Assume all structure IDs, room IDs and device IDs are globally unique.
    // A device can be moved between rooms and structures.
    // A room can't so easily be moved... but are Nest really going to duplicate room
    // IDs across structures?
    // We just need enough information to reverse a string:
    //   "enterprises/<project id>/structures/<structure id>/rooms/<room id>/*"
    // to something human readable with the respective custom names.
    // Lookup with key: structure id, value: custom name
    var structures as Lang.Dictionary = {};
    // Lookup with key: structure id, value: custom name
    var rooms as Lang.Dictionary      = {};
    // The number of structures for which the rooms need to be fetched.
    hidden var structures_total       = -1 as Lang.Number;
    // The number of structures for which the rooms have been fetched.
    hidden var structures_fetched     = 0 as Lang.Number;
    //
    hidden var menu_populated as Lang.Boolean = false;

    function initialize(options) {
        WatchUi.Menu2.initialize(options);
        // Assumes we have an access token
        initData();
    }

    // Initialise 'structures' and 'rooms' using asynchronous GET requests.
    //
    function initData() {
        structures_total   = 0;
        structures_fetched = 0;
        // Start to initialise, but this call completes asynchronously.
        getStructures();
    }

    // Initialise the thrmostate selection menu from 'structures' and 'rooms'.
    // Assumes we have now got an access token.
    //
    function initMenu() as Void {
        if (
            (structures_total > 0) &&
            (structures_total == structures_fetched) &&
            !menu_populated
        ) {
            getDevices();
            menu_populated = true;
        }
    }

    // Test whether the structures have been fully enumerated with rooms by
    // comparing the number of structures to the number of getRooms() calls returning.
    //
    // Return:
    //  * True  - All structures fully enumerated with rooms and the devices have
    //            been added to the menu.
    //  * False - Some calls to getRooms() remain outstanding
    //
    function isInit() as Lang.Boolean {
        return (
            (structures_total > 0) &&
            (structures_total == structures_fetched) &&
            menu_populated
        );
    }

    // Debug routine
    //
    function printData() {
        System.println("ThermoPick Structures:");
        var keys = structures.keys();
        for (var i = 0; i < keys.size(); i++) {
            System.println(" * " + structures.get(keys[i]));
        }
        System.println("ThermoPick Rooms:");
        keys = rooms.keys();
        for (var i = 0; i < keys.size(); i++) {
            System.println(" * " + rooms.get(keys[i]));
        }
    }

    // Split a string by the specified character.
    //
    // Parameters:
    // * s - String to split.
    // * c - Character to split the string on.
    //
    hidden function split(s as Lang.String, c as Lang.Char) as Lang.Array<Lang.String> {
        var lastCharPos = -1; // Default to the whole string
        var charArr = s.toCharArray();
        var ret = new Lang.Array<Lang.String>[0];
        // Loop through the characters in the string to find the position of the last instance of 'c'
        for (var i = 0; i < s.length(); i++) {
            if (charArr[i] == c) {
                ret.add(s.substring(lastCharPos+1, i) as Lang.String);
                lastCharPos = i;
            }
        }
        if (lastCharPos < s.length()-1) {
            ret.add(s.substring(lastCharPos+1, s.length()) as Lang.String);
        }
        return ret;
    }

    hidden function lastSection(s as Lang.String, c as Lang.Char) as Lang.String {
        var lastCharPos = 0; // Default to the whole string
        var charArr = s.toCharArray();
        // Loop through the characters in the string to find the position of the last instance of 'c'
        for (var i = 0; i < s.length(); i++) {
            if (charArr[i] == c) {
                lastCharPos = i;
            }
        }
        return s.substring(lastCharPos+1, s.length());
    }

    function onReceiveStructures(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.debug) {
            System.println("ThermoPick onReceiveStructures() Response Code: " + responseCode);
            System.println("ThermoPick onReceiveStructures() Response Data: " + data);
        }
        if (responseCode == 200) {
            var structures = data.get("structures") as Lang.Array;
            for (var i = 0; i < structures.size(); i++) {
                var structure = structures[i] as Lang.Dictionary;
                // "enterprises/<project id>/structures/<structure id>"
                var structureid = lastSection(structure.get("name") as Lang.String, '/');
                var traits      = structure.get("traits") as Lang.Dictionary;
                var info        = traits.get("sdm.structures.traits.Info") as Lang.Dictionary;
                var customName  = info.get("customName") as Lang.String;
                self.structures.put(structureid, customName);
                // Each of these calls complete asynchronously
                structures_total++;
                getRooms(structureid);
            }
        } else {
            if (data != null) {
                WatchUi.pushView(new ErrorView((data.get("error") as Lang.Dictionary).get("message") as Lang.String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }
        }
    }

    // Initiate the GET request to fetch the list of structures from the user's Nest account.
    //
    hidden function getStructures() {
        var at = Properties.getValue("accessToken");
        if (at != null && !at.equals("")) {
            if (System.getDeviceSettings().phoneConnected && System.getDeviceSettings().connectionAvailable) {
                var options  = {
                    :method  => Communications.HTTP_REQUEST_METHOD_GET,
                    :headers => {
                        "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
                        "Authorization" => "Bearer " + Properties.getValue("accessToken")
                    },
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                };
                Communications.makeWebRequest(Globals.getStructuresUrl(), null, options, method(:onReceiveStructures));
            } else {
                if (Globals.debug) {
                    System.println("ThermoPick Note - getStructures(): No Internet connection, skipping API call.");
                }
            }
        } else {
            if (Globals.debug) {
                System.println("ThermoPick Note - getStructures(): No access token yet.");
            }
        }
    }

    // Callback function to execute when fetching a list of thermostats to choose to query and control.
    //
    function onReceiveRooms(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.debug) {
            System.println("ThermoPick onReceiveRooms() Response Code: " + responseCode);
            System.println("ThermoPick onReceiveRooms() Response Data: " + data);
        }
        if (responseCode == 200) {
            var rooms = data.get("rooms") as Lang.Array;
            for (var i = 0; i < rooms.size(); i++) {
                var room       = rooms[i] as Lang.Dictionary;
                // "enterprises/<project id>/devices/<device id>"
                var roomid     = lastSection(room.get("name") as Lang.String, '/');
                var traits     = room.get("traits") as Lang.Dictionary;
                var info       = traits.get("sdm.structures.traits.RoomInfo") as Lang.Dictionary;
                var customName = info.get("customName") as Lang.String;
                self.rooms.put(roomid, customName);
            }
            structures_fetched++;
        } else {
            if (data != null) {
                WatchUi.pushView(new ErrorView((data.get("error") as Lang.Dictionary).get("message") as Lang.String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }
        }
    }

    // Initiate the GET request to fetch the list of devices to control from the user's Nest account.
    //
    hidden function getRooms(structure) {
        if (System.getDeviceSettings().phoneConnected && System.getDeviceSettings().connectionAvailable) {
            var options  = {
                :method  => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => {
                    "Content-Type"  => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
                    "Authorization" => "Bearer " + Properties.getValue("accessToken")
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            };
            Communications.makeWebRequest(Globals.getRoomsUrl(structure), null, options, method(:onReceiveRooms));
        } else {
            if (Globals.debug) {
                System.println("ThermoPick Note - getRooms(): No Internet connection, skipping API call.");
            }
        }
    }

    // Callback function to execute when fetching a list of thermostats to choose to query and control.
    //
    function onReceiveDevices(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {
        if (Globals.debug) {
            System.println("ThermoPick onReceiveDevices() Response Code: " + responseCode);
            System.println("ThermoPick onReceiveDevices() Response Data: " + data);
        }
        if (responseCode == 200) {
            if (structures.size() == 0 || rooms.size() == 0) {
                if (Globals.debug) {
                    System.println("ThermoPick onReceiveDevices() one or both of structures or rooms has not yet been fetched.");
                }
                // Leave the selector view.
                WatchUi.popView(WatchUi.SLIDE_LEFT);
                WatchUi.pushView(new ErrorView(WatchUi.loadResource($.Rez.Strings.noDevicesErrMsg) as Lang.String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            } else {
                var devices = data.get("devices") as Lang.Array;
                for (var i = 0; i < devices.size(); i++) {
                    var device = devices[i];
                    // API documentation says not to rely on this value remaining unchanged.
                    // See https://developers.google.com/nest/device-access/traits#device-types
                    if (device.get("type").equals("sdm.devices.types.THERMOSTAT")) {
                        // "assignee": "enterprises/<project id>/structures/<structure id>/rooms/<room id>"
                        var assignee = device.get("assignee");
                        // Extract structure and room from 'assignee' field
                        var parts = split(assignee, '/');
                        // Thermostats tend not to have a custom name, so we have to make one up
                        var customName = device.get("traits").get("sdm.devices.traits.Info").get("customName") as Lang.String;
                        addItem(
                            new WatchUi.MenuItem(
                                (customName.equals("") ? (rooms.get(parts[5]) as Lang.String) : customName),
                                structures.get(parts[3]) as Lang.String,
                                lastSection(device.get("name") as Lang.String, '/'),
                                {}
                            )
                        );
                    }
                }
                if (Globals.debug) {
                    System.println("ThermoPick onReceiveDevices() Requesting device list update.");
                }
                requestUpdate();
            }
        } else {
            if (data != null) {
                WatchUi.pushView(new ErrorView((data.get("error") as Lang.Dictionary).get("message") as Lang.String), new ErrorDelegate(), WatchUi.SLIDE_UP);
            }
        }
    }

    // Initiate the GET request to fetch the list of devices to control from the user's Nest account.
    //
    hidden function getDevices() {
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
                System.println("ThermoPick Note - getDevices(): No Internet connection, skipping API call.");
            }
        }
    }

}

class ThermoPickDelegate extends WatchUi.Menu2InputDelegate {
    hidden var mView;
    hidden var mNestStatus;

    function initialize(view as ThermoPick, ns as NestStatus) {
        Menu2InputDelegate.initialize();
        mView       = view;
        mNestStatus = ns;
    }

    function onSelect(item as WatchUi.MenuItem) {
        if (Globals.debug) {
            System.println("ThermoPickDelegate deviceId: " + item.getId());
        }
        Properties.setValue("deviceId", item.getId());
        WatchUi.popView(WatchUi.SLIDE_LEFT);
        mNestStatus.getDeviceData();
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_LEFT);
    }

}