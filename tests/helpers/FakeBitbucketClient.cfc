component extends="BitbucketClient" {

    variables.lastCall = {};
    variables.calls = [];
    variables.responses = {};

    any function setResponse(
        required string path,
        required struct data,
        string method=""
    ){
        var responseKey = Len(arguments.method) ? uCase(arguments.method) & " " & arguments.path : arguments.path;
        variables["responses"][responseKey] = arguments.data;

        return this;
    }

    any function doCall(
        required string path,
        string method="GET",
        any data={},
        boolean overrideURL=false,
        boolean parseResponse=true
    ){
        variables.lastCall = {
            "path" = arguments.path,
            "method" = arguments.method,
            "data" = arguments.data,
            "overrideURL" = arguments.overrideURL,
            "parseResponse" = arguments.parseResponse
        };
        arrayAppend(variables.calls, variables.lastCall);

        var methodResponseKey = uCase(arguments.method) & " " & arguments.path;
        if(structKeyExists(variables.responses, methodResponseKey)){
            return isSimpleValue(variables.responses[methodResponseKey]) ? variables.responses[methodResponseKey] : serializeJson(variables.responses[methodResponseKey]);
        }
        if(structKeyExists(variables.responses, arguments.path)){
            return isSimpleValue(variables.responses[arguments.path]) ? variables.responses[arguments.path] : serializeJson(variables.responses[arguments.path]);
        }

        return serializeJson({ "ok" = true });
    }

    struct function getLastCall(){
        return variables.lastCall;
    }

    array function getCalls(){
        return variables.calls;
    }
}
