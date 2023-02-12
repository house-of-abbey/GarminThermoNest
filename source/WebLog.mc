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
// deployed to the watch. This is only used for development and use of it must not
// persist into a deployed version.
//
//-----------------------------------------------------------------------------------
// 
// https://domain.name/path/test_clear.php
// 
// <?php
//   $myfile = fopen("test", "w");
//   fwrite("");
// ?>
// 
// https://domain.name/path/test.php
// 
// <?php
//   $myfile = fopen("test", "a");
//   $queries = array();
//   parse_str($_SERVER['QUERY_STRING'], $queries);
//   fwrite($myfile, $queries['test']);
// ?>
// 
// Logs published to: https://domain.name/path/test
//

using Toybox.Communications;
using Toybox.Lang;

(:glance)
class WebLog {

    // Create a debug log over the Internet to keep track of the watch's runtime
    // execution.
    //
    function print(a as Lang.String) {
        Communications.makeWebRequest(
            ClientId.webLogUrl,
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

    function println(a as Lang.String) {
        print(a + "\n");
    }

    function on(responseCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void {}
}
