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
