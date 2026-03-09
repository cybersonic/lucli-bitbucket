component {

    variables.cwd = expandPath("/");

    public any function showHelp(){
        return "";
    }

    public string function getEnv(required string name, string defaultValue=""){
        if(
            structKeyExists(server, "system")
            AND structKeyExists(server.system, "environment")
            AND structKeyExists(server.system.environment, arguments.name)
        ){
            return server.system.environment[arguments.name];
        }

        return arguments.defaultValue;
    }

    public string function getAbsolutePath(required string basePath, required string path){
        if(
            left(arguments.path, 1) EQ "/"
            OR reFind("^[A-Za-z]:[\\/]", arguments.path)
        ){
            return arguments.path;
        }

        var base = arguments.basePath;
        if(!len(base)){
            base = variables.cwd;
        }

        if(right(base, 1) NEQ "/" AND right(base, 1) NEQ chr(92)){
            base &= "/";
        }

        return base & arguments.path;
    }
}
