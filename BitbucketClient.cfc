
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
        string reportId=""
        ){
            
        if(isEmpty(arguments.reportId)){
            if(!isEmpty(reportData.title)){
                arguments.reportId = lCase(replace(reportData.title, " ", "_", "all"));
            }
            else{
                throw("Report ID is required if no title is provided");
            }
        }


        var path = "repositories/#variables.workspace#/#variables.repoSlug#/commit/#commit#/reports/#arguments.reportId#";

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
        required string reportId

    ){
        
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/commit/#commit#/reports/#arguments.reportId#/annotations";
        // make sure we clean up the annotations to match Bitbucket's expected format
        for(var i=1; i LTE arrayLen(arguments.annotations); i++){
            var annotation = arguments.annotations[i];

            if(annotation.keyExists("summary") && Len(annotation.summary) GTE 450){
                annotation.summary = Left(annotation.summary, 447) & "...";
            }

            if(NOT annotation.keyExists("external_id")){
                annotation.external_id = reportId & "_" & numberFormat(i, "000");
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

    /**
     * getPullRequest
     * returns details about a specific pull request
     *
     * @pullRequestId The ID of the pull request to retrieve.
     * @fields Array Optional fields to include in the response (see https://developer.atlassian.com/cloud/bitbucket/rest/intro/#partial-response)
     */
    function getPullRequest(
        required numeric pullRequestId,
        string fields=""
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/";

        if(listLen(arguments.fields) GT 0){
            var fieldParam = arguments.fields;
            path = path & "?fields=" & URLEncodedFormat(arguments.fields);
        }

        var response = doCall(
            path=path,
            method="GET",
            data={}
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

    function putPullRequest(
        required numeric pullRequestId,
        required struct data
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/";

        var response = doCall(
            path=path,
            method="PUT",
            data=arguments.data
        );
        return response;
    }

    function downloadFile(
        required string fileURL,
        required string destinationPath
    ){

        var fileResp = doCall(
            path=fileURL,
            method="GET",
            data={},
            overrideURL=true
        );
        var folder = getDirectoryFromPath(destinationPath);
        if(NOT directoryExists(folder)){
            directoryCreate(folder, true);
        }

       
        fileWrite(destinationPath, fileResp.fileContent);
        return fileResp.fileContent;
    } 

    function getRepository(){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#";

        var response = doCall(
            path=path,
            method="GET",
            data={}
        );
        return response;
    }

    /**
     * addPullRequestTask
     * Adds a task to a pull request
     *
     * @pullRequestId The ID of the pull request
     * @taskContent   The text content of the task to create
     */
    function addPullRequestTask(
        required numeric pullRequestId,
        required string taskContent
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/tasks/";

        var response = doCall(
            path=path,
            method="POST",
            data={"content": {"raw": arguments.taskContent}}
        );
        return response;
    }

    function doCall(required string path, string method="GET", any data, boolean overrideURL=false)  cachedwithin="request"{

		var resourcePath = overrideURL ? path : "https://api.bitbucket.org/2.0/#path#";
		// printGreen(method & ": " & resourcePath);
            resourcePath = Trim(resourcePath);
		var useBearer=false;
		var token="";

		//change the auth. 

		var bitbucketresponse = {};
		// if(variables.authType EQ BitbucketClient::REPO_BEARER) {
			useBearer=true;
			token = variables.authToken;
		// } else if(variables.authType EQ BitbucketClient::WORKSPACE_BEARER) {
		// 	useBearer=true;
		// 	token = variables.authToken;
		// }



		// if(useBearer){
			// out("Using Bearer Token", "red");
			http method="#arguments.method#" url="#resourcePath#"
				result="local.bitbucketresponse"
			{
				httpparam type="header" name="Authorization" value="Bearer #Trim(token)#";
                if(NOT overrideURL){
                    httpparam type="header" name="Content-Type" value="application/json";

                }
                
			
				if(!isNull(arguments.data) AND method NEQ "GET"){
					httpparam type="body" value="#SerializeJSON(arguments.data)#";
				}
				if(!isNull(arguments.data) AND method EQ "GET"){
					for(var item in data){
						httpparam type="url" name="#item#" value="#data[item]#";
					}
				}
            }
	
			// }
			// out("Bitbucket response:", "red");
			// out(bitbucketresponse, "red");
		// } else {
		// 	http method="#arguments.method#" url="#resourcePath#"
		// 		username="#variables.username#" password="#variables.password#"
		// 		result="local.bitbucketresponse"
		// 	{
	
		// 		httpparam type="header" name="Content-Type" value="application/json";
			
		// 		if(!isNull(arguments.data) AND method NEQ "GET"){
		// 			httpparam type="body" value="#SerializeJSON(arguments.data)#";
		// 		}
		// 		if(!isNull(arguments.data) AND method EQ "GET"){
		// 			for(var item in data){
		// 				httpparam type="url" name="#item#" value="#data[item]#";
		// 			}
		// 		}
	
		// 	}

		// }
		if(NOT listFind("200,201", bitbucketresponse.status_code)){
			// printRed(bitbucketresponse);
            
			SystemOutput(SerializeJSON(data=bitbucketresponse, compact=false), true, true);
            var outtoken = Len(token) GT 10 ? Left(token , 10) & "..." : "xxxxx";
            throw("Bitbucket API call to [#resourcePath#] using bearer [#useBearer#] [#outtoken#] failed with status code #bitbucketresponse.status_code# and response: #bitbucketresponse.fileContent#");
		}
		return bitbucketresponse;
	}

}