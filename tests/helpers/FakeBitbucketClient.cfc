component extends="BitbucketClient" {

    variables.lastCall = {};

    function doCall(
        required string path,
        string method="GET",
        any data={},
        boolean overrideURL=false,
        boolean parseResponse=true
    ){
        variables.lastCall = {
            path = arguments.path,
            method = arguments.method,
            data = arguments.data,
            overrideURL = arguments.overrideURL,
            parseResponse = arguments.parseResponse
        };
        return serializeJson({ "ok" = true });
    }

    struct function getLastCall(){
        return variables.lastCall;
    }
}
