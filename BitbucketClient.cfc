
component {

    static {
        REPO_BEARER=0;
        WORKSPACE_BEARER=1;
        BASIC=2;
    }

    private string function normalizeAuthType(any authTypeValue){
        var rawValue = Trim(authTypeValue & "");
        if(!Len(rawValue)){
            return "";
        }

        switch(lCase(rawValue)){
            case "basic":
            case "basic_api_token":
            case "2":
                return "basic_api_token";
            case "bearer":
            case "repo_bearer":
            case "workspace_bearer":
            case "0":
            case "1":
                return "bearer";
            default:
                return "";
        }
    }

    function getAuthMode(){
        return variables.authType ?: "bearer";
    }

    function getAuthorizationHeader(){
        var token = Trim(variables.authToken ?: "");
        if(!Len(token)){
            throw("BITBUCKET_AUTH_TOKEN is required.");
        }

        if(getAuthMode() EQ "basic_api_token"){
            var authUser = Trim(variables.authUser ?: "");
            if(!Len(authUser)){
                throw("BITBUCKET_AUTH_USER is required when using personal API token auth.");
            }
            if(!isValid("email", authUser)){
                throw("BITBUCKET_AUTH_USER must be a valid email address when using personal API token auth.");
            }
            return "Basic " & toBase64(authUser & ":" & token);
        }

        return "Bearer " & token;
    }

    function init(
        string workspace,
        string repoSlug,
        string authToken,
        string authType="",
        string authUser=""
    ){
        variables.workspace = arguments.workspace;
        variables.repoSlug = arguments.repoSlug;
        variables.authToken = arguments.authToken ?: "";
        variables.authUser = arguments.authUser ?: "";

        var requestedAuthType = normalizeAuthType(arguments.authType);
        if(Len(requestedAuthType)){
            variables.authType = requestedAuthType;
        }
        else if(Len(Trim(variables.authUser))){
            variables.authType = "basic_api_token";
        }
        else{
            variables.authType = "bearer";
        }
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

    function listReports(
        required string commit,
        numeric page=0,
        numeric pagelen=0
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/commit/#arguments.commit#/reports";

        var params = {};
        if(arguments.page GT 0){
            params.page = arguments.page;
        }
        if(arguments.pagelen GT 0){
            params.pagelen = arguments.pagelen;
        }

        return doCall(
            path=path,
            method="GET",
            data=params
        );
    }

    function getReport(
        required string commit,
        required string reportId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/commit/#arguments.commit#/reports/#arguments.reportId#";

        return doCall(
            path=path,
            method="GET",
            data={}
        );
    }

    function deleteReport(
        required string commit,
        required string reportId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/commit/#arguments.commit#/reports/#arguments.reportId#";

        return doCall(
            path=path,
            method="DELETE",
            data={}
        );
    }

    function listReportAnnotations(
        required string commit,
        required string reportId,
        numeric page=0,
        numeric pagelen=0
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/commit/#arguments.commit#/reports/#arguments.reportId#/annotations";

        var params = {};
        if(arguments.page GT 0){
            params.page = arguments.page;
        }
        if(arguments.pagelen GT 0){
            params.pagelen = arguments.pagelen;
        }

        return doCall(
            path=path,
            method="GET",
            data=params
        );
    }

    function getReportAnnotation(
        required string commit,
        required string reportId,
        required string annotationId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/commit/#arguments.commit#/reports/#arguments.reportId#/annotations/#arguments.annotationId#";

        return doCall(
            path=path,
            method="GET",
            data={}
        );
    }

    function putReportAnnotation(
        required string commit,
        required string reportId,
        required string annotationId,
        required struct annotationData
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/commit/#arguments.commit#/reports/#arguments.reportId#/annotations/#arguments.annotationId#";

        return doCall(
            path=path,
            method="PUT",
            data=arguments.annotationData
        );
    }

    function deleteReportAnnotation(
        required string commit,
        required string reportId,
        required string annotationId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/commit/#arguments.commit#/reports/#arguments.reportId#/annotations/#arguments.annotationId#";

        return doCall(
            path=path,
            method="DELETE",
            data={}
        );
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

    function getPullRequestDiffStat(
        required numeric pullRequestId,
        numeric page=0,
        numeric pagelen=0,
        string fields=""
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/diffstat";

        var params = {};
        if(arguments.page GT 0){
            params.page = arguments.page;
        }
        if(arguments.pagelen GT 0){
            params.pagelen = arguments.pagelen;
        }
        if(Len(arguments.fields)){
            params.fields = arguments.fields;
        }

        var response = doCall(
            path=path,
            method="GET",
            data=params
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

    function getPullRequestPatch(
        required numeric pullRequestId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/patch";

        var response = doCall(
            path=path,
            method="GET",
            data={}
        );
        return response;
    }

    function listPullRequests(
        string state="",
        string q="",
        string sort="",
        numeric page=0,
        numeric pagelen=0,
        string fields=""
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests";

        var params = {};
        if(Len(arguments.state)){
            params.state = arguments.state;
        }
        if(Len(arguments.q)){
            params.q = arguments.q;
        }
        if(Len(arguments.sort)){
            params.sort = arguments.sort;
        }
        if(arguments.page GT 0){
            params.page = arguments.page;
        }
        if(arguments.pagelen GT 0){
            params.pagelen = arguments.pagelen;
        }
        if(Len(arguments.fields)){
            params.fields = arguments.fields;
        }

        return doCall(
            path=path,
            method="GET",
            data=params
        );
    }

    function getPullRequest(
        required numeric pullRequestId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#";

        return doCall(
            path=path,
            method="GET",
            data={}
        );
    }

    function createPullRequest(
        required struct pullRequestData
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests";

        return doCall(
            path=path,
            method="POST",
            data=pullRequestData
        );
    }

    function updatePullRequest(
        required numeric pullRequestId,
        required struct pullRequestData
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#";

        return doCall(
            path=path,
            method="PUT",
            data=pullRequestData
        );
    }

    function declinePullRequest(
        required numeric pullRequestId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/decline";

        return doCall(
            path=path,
            method="POST",
            data={}
        );
    }

    function mergePullRequest(
        required numeric pullRequestId,
        struct mergeData={}
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/merge";

        return doCall(
            path=path,
            method="POST",
            data=mergeData
        );
    }

    function getPullRequestMergeTaskStatus(
        required numeric pullRequestId,
        required string taskId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/merge/task-status/#arguments.taskId#";

        return doCall(
            path=path,
            method="GET",
            data={}
        );
    }

    function approvePullRequest(
        required numeric pullRequestId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/approve";

        return doCall(
            path=path,
            method="POST",
            data={}
        );
    }

    function unapprovePullRequest(
        required numeric pullRequestId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/approve";

        return doCall(
            path=path,
            method="DELETE",
            data={}
        );
    }

    function requestChangesPullRequest(
        required numeric pullRequestId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/request-changes";

        return doCall(
            path=path,
            method="POST",
            data={}
        );
    }

    function removeRequestChangesPullRequest(
        required numeric pullRequestId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/request-changes";

        return doCall(
            path=path,
            method="DELETE",
            data={}
        );
    }

    function listPullRequestActivity(
        required numeric pullRequestId,
        numeric page=0,
        numeric pagelen=0
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/activity";

        var params = {};
        if(arguments.page GT 0){
            params.page = arguments.page;
        }
        if(arguments.pagelen GT 0){
            params.pagelen = arguments.pagelen;
        }

        return doCall(
            path=path,
            method="GET",
            data=params
        );
    }

    function listPullRequestCommits(
        required numeric pullRequestId,
        numeric page=0,
        numeric pagelen=0,
        string fields=""
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/commits";

        var params = {};
        if(arguments.page GT 0){
            params.page = arguments.page;
        }
        if(arguments.pagelen GT 0){
            params.pagelen = arguments.pagelen;
        }
        if(Len(arguments.fields)){
            params.fields = arguments.fields;
        }

        return doCall(
            path=path,
            method="GET",
            data=params
        );
    }

    function listPullRequestComments(
        required numeric pullRequestId,
        numeric page=0,
        numeric pagelen=0
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/comments";

        var params = {};
        if(arguments.page GT 0){
            params.page = arguments.page;
        }
        if(arguments.pagelen GT 0){
            params.pagelen = arguments.pagelen;
        }

        return doCall(
            path=path,
            method="GET",
            data=params
        );
    }

    function createPullRequestComment(
        required numeric pullRequestId,
        required struct commentData
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/comments";

        return doCall(
            path=path,
            method="POST",
            data=commentData
        );
    }

    function getPullRequestComment(
        required numeric pullRequestId,
        required numeric commentId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/comments/#commentId#";

        return doCall(
            path=path,
            method="GET",
            data={}
        );
    }

    function updatePullRequestComment(
        required numeric pullRequestId,
        required numeric commentId,
        required struct commentData
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/comments/#commentId#";

        return doCall(
            path=path,
            method="PUT",
            data=commentData
        );
    }

    function deletePullRequestComment(
        required numeric pullRequestId,
        required numeric commentId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/comments/#commentId#";

        return doCall(
            path=path,
            method="DELETE",
            data={}
        );
    }

    function listPullRequestTasks(
        required numeric pullRequestId,
        string q="",
        string sort="",
        numeric page=0,
        numeric pagelen=0
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/tasks";

        var params = {};
        if(Len(arguments.q)){
            params.q = arguments.q;
        }
        if(Len(arguments.sort)){
            params.sort = arguments.sort;
        }
        if(arguments.page GT 0){
            params.page = arguments.page;
        }
        if(arguments.pagelen GT 0){
            params.pagelen = arguments.pagelen;
        }

        return doCall(
            path=path,
            method="GET",
            data=params
        );
    }

    function createPullRequestTask(
        required numeric pullRequestId,
        required struct taskData
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/tasks";

        return doCall(
            path=path,
            method="POST",
            data=taskData
        );
    }

    function getPullRequestTask(
        required numeric pullRequestId,
        required numeric taskId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/tasks/#taskId#";

        return doCall(
            path=path,
            method="GET",
            data={}
        );
    }

    function updatePullRequestTask(
        required numeric pullRequestId,
        required numeric taskId,
        required struct taskData
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/tasks/#taskId#";

        return doCall(
            path=path,
            method="PUT",
            data=taskData
        );
    }

    function deletePullRequestTask(
        required numeric pullRequestId,
        required numeric taskId
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/pullrequests/#pullRequestId#/tasks/#taskId#";

        return doCall(
            path=path,
            method="DELETE",
            data={}
        );
    }

    function listPullRequestsForCommit(
        required string commit,
        numeric page=0,
        numeric pagelen=0
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/commit/#commit#/pullrequests";

        var params = {};
        if(arguments.page GT 0){
            params.page = arguments.page;
        }
        if(arguments.pagelen GT 0){
            params.pagelen = arguments.pagelen;
        }

        return doCall(
            path=path,
            method="GET",
            data=params
        );
    }

    function listDefaultReviewers(
        numeric page=0,
        numeric pagelen=0
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/default-reviewers";

        var params = {};
        if(arguments.page GT 0){
            params.page = arguments.page;
        }
        if(arguments.pagelen GT 0){
            params.pagelen = arguments.pagelen;
        }

        return doCall(
            path=path,
            method="GET",
            data=params
        );
    }

    function downloadFile(
        required string fileURL,
        required string destinationPath
    ){

        var fileContent = doCall(
            path=fileURL,
            method="GET",
            data={},
            overrideURL=true,
            parseResponse=false
        );
        var folder = getDirectoryFromPath(destinationPath);
        if(NOT directoryExists(folder)){
            directoryCreate(folder, true);
        }

       
        fileWrite(destinationPath, fileContent);
        return fileContent;
    } 

    function getBranchRef(
        required string branch
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/refs/branches/#arguments.branch#";

        return doCall(
            path=path,
            method="GET",
            data={}
        );
    }

    function listCommits(
        required string revision,
        numeric page=0,
        numeric pagelen=0
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/commits/#arguments.revision#";

        var params = {};
        if(arguments.page GT 0){
            params.page = arguments.page;
        }
        if(arguments.pagelen GT 0){
            params.pagelen = arguments.pagelen;
        }

        return doCall(
            path=path,
            method="GET",
            data=params
        );
    }

    function listTags(
        string q="",
        string sort="",
        numeric page=0,
        numeric pagelen=0
    ){
        var path = "repositories/#variables.workspace#/#variables.repoSlug#/refs/tags";

        var params = {};
        if(Len(arguments.q)){
            params.q = arguments.q;
        }
        if(Len(arguments.sort)){
            params.sort = arguments.sort;
        }
        if(arguments.page GT 0){
            params.page = arguments.page;
        }
        if(arguments.pagelen GT 0){
            params.pagelen = arguments.pagelen;
        }

        return doCall(
            path=path,
            method="GET",
            data=params
        );
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

    function doCall(required string path, string method="GET", any data={}, boolean overrideURL=false, boolean parseResponse=true){

		var resourcePath = overrideURL ? path : "https://api.bitbucket.org/2.0/#path#";
		// printGreen(method & ": " & resourcePath);
            resourcePath = Trim(resourcePath);
		var token = Trim(variables.authToken ?: "");
		var authMode = getAuthMode();
		var authorizationHeader = getAuthorizationHeader();

		//change the auth. 

		var bitbucketresponse = {};

            var sendBody = false;
            if(!isNull(arguments.data) AND method NEQ "GET"){
                if(isStruct(arguments.data)){
                    sendBody = !structIsEmpty(arguments.data);
                }
                else if(isArray(arguments.data)){
                    sendBody = arrayLen(arguments.data) GT 0;
                }
                else if(isSimpleValue(arguments.data)){
                    sendBody = Len(arguments.data & "") GT 0;
                }
                else {
                    sendBody = true;
                }
            }

		// if(useBearer){
			// out("Using Bearer Token", "red");
			http method="#arguments.method#" url="#resourcePath#"
				result="local.bitbucketresponse"
			{
				httpparam type="header" name="Authorization" value="#authorizationHeader#";
                if(NOT overrideURL){
                    httpparam type="header" name="Content-Type" value="application/json";

                }
                
			
				if(sendBody){
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
		var statusCode = bitbucketresponse.status_code & "";
		if(Len(statusCode) EQ 0 OR left(statusCode, 1) NEQ "2"){
			// printRed(bitbucketresponse);
			SystemOutput(SerializeJSON(data=bitbucketresponse, compact=false), true, true);
            var outtoken = Len(token) GT 10 ? Left(token , 10) & "..." : "xxxxx";
            throw("Bitbucket API call to [#resourcePath#] using auth mode [#authMode#] [#outtoken#] failed with status code #statusCode# and response: #bitbucketresponse.fileContent#");
		}

        // Return raw response content.
        // For now, we return JSON responses as *strings* ("bare JSON") instead of
        // deserializing into CFML structs/arrays. This keeps module output pipe-friendly
        // (e.g. to jq) until LuCLI implements a global --format.
        var content = bitbucketresponse.fileContent;
        if(isNull(content) OR !Len(trim(content & ""))){
            return "";
        }

        // parseResponse=false is used for endpoints where we must guarantee raw bytes/text
        // (e.g. downloads). With parseResponse=true, we still return the raw string.
        return content;
	}

}