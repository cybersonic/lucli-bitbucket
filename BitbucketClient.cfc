
component {

    static {
        REPO_BEARER=0;
        WORKSPACE_BEARER=1;
        BASIC=2;
    }

    function init(
        string workspace,
        string repoSlug,
        string authToken,
        string authType=static.WORKSPACE_BEARER
    ){
        variables.workspace = arguments.workspace;
        variables.repoSlug = arguments.repoSlug;
        variables.authToken = arguments.authToken;
        variables.authType = arguments.authType;
    }


    function createReport(
        required struct reportData,
        required string commit,
        string reportSlug="",
        ){
            
        //TODO: Do a check of the contents of the report
        if(isEmpty(arguments.reportSlug)){
            if(!isEmpty(reportData.title)){
                arguments.reportSlug = lCase(replace(reportData.title, " ", "_", "all"));
            }
            else{
                throw("Report Slug is required if no title is provided");
            }
        }
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/commit/#commit#/reports/#arguments.reportSlug#";

        
        var response = doCall(
            path=path,
            method="PUT",
            data=reportData
        );
        return response;
    }

    function createAnnotations(
        required array annotations,
        required string commit,
        required string reportSlug

    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/commit/#commit#/reports/#reportSlug#/annotations";

        // make sure we clean up the annotations to match Bitbucket's expected format
        for(var i=1; i LTE arrayLen(arguments.annotations); i++){
            var annotation = arguments.annotations[i];

            if(annotation.keyExists("summary") && Len(annotation.summary) GTE 450){
                annotation.summary = Left(annotation.summary, 447) & "...";
            }

            if(NOT annotation.keyExists("external_id")){
                annotation.external_id = reportSlug & "_" & numberFormat(i, "000");
            }
            // // Bitbucket expects "path" not "file"
            // if(annotation.keyExists("file")){
            //     annotation.path = annotation.file;
            //     structDelete(annotation, "file");
            // }
            // // Bitbucket expects "line" not "lineNumber"
            // if(annotation.keyExists("lineNumber")){
            //     annotation.line = annotation.lineNumber;
            //     structDelete(annotation, "lineNumber");
            // }
        }
        
        var response = doCall(
            path=path,
            method="POST",
            data=arguments.annotations
        );
        return response;
    }

    function getPullRequestDiffStat(
        required numeric pullRequestId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/diffstat";

        var response = doCall(
            path=path,
            method="GET",
            data={}
        );
        return response;
    }

    
    function getPullRequestDiff(
        required numeric pullRequestId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/diff";

        var response = doCall(
            path=path,
            method="GET",
            data={}
        );
        return response;
    }


    

    function doCall(required string path, string method="GET", any data)  cachedwithin="request"{

		var resourcePath = "https://api.bitbucket.org/2.0/#path#"
		printGreen(method & ": " & resourcePath);
		var useBearer=false;
		var token="";

		//change the auth. 

		var bitbucketresponse = {};
		if(variables.authType EQ BitbucketClient::REPO_BEARER) {
			useBearer=true;
			token = variables.authToken;
		} else if(variables.authType EQ BitbucketClient::WORKSPACE_BEARER) {
			useBearer=true;
			token = variables.authToken;
		}

		if(useBearer){
			printRed("Using Bearer Token");
			http method="#arguments.method#" url="#resourcePath#"
				result="local.bitbucketresponse"
			{
	
				httpparam type="header" name="Authorization" value="Bearer #token#";
				httpparam type="header" name="Content-Type" value="application/json";
			
				if(!isNull(arguments.data) AND method NEQ "GET"){
					httpparam type="body" value="#SerializeJSON(arguments.data)#";
				}
				if(!isNull(arguments.data) AND method EQ "GET"){
					for(var item in data){
						httpparam type="url" name="#item#" value="#data[item]#";
					}
				}
	
			}
			printRed(bitbucketresponse);
		} else {
			http method="#arguments.method#" url="#resourcePath#"
				username="#variables.username#" password="#variables.password#"
				result="local.bitbucketresponse"
			{
	
				httpparam type="header" name="Content-Type" value="application/json";
			
				if(!isNull(arguments.data) AND method NEQ "GET"){
					httpparam type="body" value="#SerializeJSON(arguments.data)#";
				}
				if(!isNull(arguments.data) AND method EQ "GET"){
					for(var item in data){
						httpparam type="url" name="#item#" value="#data[item]#";
					}
				}
	
			}

		}
		if(bitbucketresponse.status_code NEQ "200"){
			printRed(bitbucketresponse);
			error(bitbucketresponse.errordetail);
		}
		return bitbucketresponse;
	}


    function printGreen(any message){
        out(arguments.message);
    }
    function printRed(any message){
        out(arguments.message);
    }
    function error(any message){
        out(arguments.message);
    }

    function out(any message){
         if(!isSimpleValue(message)){
        message = serializeJson(var=message, compact=false);
        }
        // dump(message & chr(10));
    }
}