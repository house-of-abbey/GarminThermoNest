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
// WebLog provides a logging and hence debugging aid for when the application is
//  deployed to the watch. This is only used for development and use must not be made
// on a deployed version.
//
//-----------------------------------------------------------------------------------

import Toybox.System;
import Toybox.Communications;
import Toybox.Lang;

(:glance)
class WebLog {

    function print(a as String) {
        Communications.makeWebRequest(
            "https://joseph.abbey1.org.uk/test.php",
            {
                "test" => a
            },
            {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:on)
        );
    }

    function println(a as String) {
        print(a + "\n");
    }

    function on(responseCode as Number, data as Null or Dictionary or String) as Void {}
}
