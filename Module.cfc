        
/**
 * Module component for Bitbucket integration.
 *
 * @extends modules.BaseModule
 */
component extends="modules.BaseModule" {

        /*
        Bitbucket Pipelines set the following variables anyway
        Default variables:
            BITBUCKET_BRANCH
            BITBUCKET_BUILD_NUMBER
            BITBUCKET_CLONE_DIR
            BITBUCKET_COMMIT
            BITBUCKET_GIT_HTTP_ORIGIN
            BITBUCKET_GIT_SSH_ORIGIN
            BITBUCKET_PIPELINES_VARIABLES_PATH
            BITBUCKET_PIPELINE_UUID
            BITBUCKET_PROJECT_KEY
            BITBUCKET_PROJECT_UUID
            BITBUCKET_PR_DESTINATION_BRANCH
            BITBUCKET_PR_DESTINATION_COMMIT
            BITBUCKET_PR_ID
            BITBUCKET_REPO_FULL_NAME
            BITBUCKET_REPO_IS_PRIVATE
            BITBUCKET_REPO_OWNER
            BITBUCKET_REPO_OWNER_UUID
            BITBUCKET_REPO_SLUG
            BITBUCKET_REPO_UUID
            BITBUCKET_SSH_KEY_FILE
            BITBUCKET_STEP_RUN_NUMBER
            BITBUCKET_STEP_TRIGGERER_UUID
            BITBUCKET_STEP_UUID
            BITBUCKET_TEST_METADATA_FILE_PATH
            BITBUCKET_WORKSPACE
            CI
            DOCKER_HOST
        */
    function main(string action="") {

        var possibleActions = ["createReport", "createAnnotations", "getPullRequestDiff", "addPullRequestTask"];
        if(!arrayContains(possibleActions, arguments.action)){
            out("❌ Unknown action: " & action);
            out("Available actions: " & arrayToList(possibleActions));
            return;
        }

        // Read from arguments or environment variables
        arguments["repoSlug"] = arguments.repoSlug ?: getEnv("BITBUCKET_REPO_SLUG", "");
        arguments["workspace"] = arguments.workspace ?: getEnv("BITBUCKET_WORKSPACE", "");
        arguments["commit"] = arguments.commit ?: getEnv("BITBUCKET_COMMIT", "");
        arguments["authToken"] = arguments.authToken ?: getEnv("BITBUCKET_AUTH_TOKEN", "");

        
        var bitbucket = new BitbucketClient(
            repoSlug = arguments.repoSlug,
            workspace = arguments.workspace,
            authToken = arguments.authToken);
    
        switch(arguments.action){
            case "createReport":
                var reportData = deserializeJson(fileRead(arguments.file));
                var response = bitbucket.createReport(
                    reportData = reportData,
                    commit = arguments.commit
                );
                out("Report created:");
                var bitbucketResponse = DeserializeJSON(response.fileContent);
                out(bitbucketResponse);

                if(reportData.keyExists("annotations") && arrayLen(reportData.annotations) GT 0){
                    out("Annotations included: " & arrayLen(reportData.annotations));
                
                    var annotationResponse = bitbucket.createAnnotations(
                        annotations = reportData.annotations,
                        commit = arguments.commit,
                        reportSlug = bitbucketResponse.external_id
                    );
                    var annotationResp = DeserializeJSON(annotationResponse.fileContent);
                    out(annotationResp);   
                }
                
                break;
            case "createAnnotations":
                var reportData = deserializeJson(fileRead(arguments.file));
                if(NOT reportData.keyExists("annotations") || arrayLen(reportData.annotations) EQ 0){
                    out("❌ No annotations found in report data");
                    return;
                }
                var annotationResponse = bitbucket.createAnnotations(
                    annotations = reportData.annotations,
                    commit = arguments.commit,
                    reportSlug = arguments.reportSlug
                );
            case "getPullRequestDiff":

                // For this function we need a pull request id
                arguments["pullRequestId"] = arguments.pullRequestId ?: getEnv("BITBUCKET_PR_ID", "");
                var diffStatResponse = bitbucket.getPullRequestDiff(
                    pullRequestId = arguments.pullRequestId
                );
                out("Pull Request Diff:");
                var prDiffStat = DeserializeJSON(diffStatResponse.fileContent);
                out(prDiffStat);
                break;
            case "addPullRequestTask":
                arguments["pullRequestId"] = arguments.pullRequestId ?: getEnv("BITBUCKET_PR_ID", "");
                var taskResponse = bitbucket.addPullRequestTask(
                    pullRequestId = arguments.pullRequestId,
                    taskContent = arguments.taskContent
                );
                out("Task added to pull request:");
                var taskResult = DeserializeJSON(taskResponse.fileContent);
                out(taskResult);
                break;
            default:
                out("❌ Action not implemented: #arguments.action#");
            
        }
        
        return "Module executed successfully";
    }


    /**
     * Returns the Diff text of a pull request
     *
     * @pullRequestId The id of the pull request
     * @outputPath Optional path to save the diff to a file
     */
    function getPullRequestDiff(
        numeric pullRequestId = 0,
        string outputPath=""
        // TODO: add authToken, repoSlug, workspace as args?
    ){
        // For this function we need a pull request id
        var pullRequestId = arguments.pullRequestId ?: getEnv("BITBUCKET_PR_ID", "");
        var bitbucket = new BitbucketClient(
            repoSlug = getEnv("BITBUCKET_REPO_SLUG", ""),
            workspace = getEnv("BITBUCKET_WORKSPACE", ""),
            authToken = getEnv("BITBUCKET_AUTH_TOKEN", "")
        );
        var diffStatResponse = bitbucket.getPullRequestDiff(
            pullRequestId = pullRequestId
        );

        var prDiffStat = "";

        var absOutputPath = getAbsolutePath(variables.cwd, arguments.outputPath);
        
        if(diffStatREsponse.mimetype EQ "application/json"){
            var prDiffStat = DeserializeJSON(diffStatResponse.fileContent);
            if(Len(arguments.outputPath)){
                // Save to file
                fileWrite(absOutputPath, serializeJson(diffStatResponse.fileContent));
                out("Pull Request Diff written to: " & absOutputPath);
                return;
            }
            else{
                out(prDiffStat);
            }
            return prDiffStat;
        }

        if(Len(arguments.outputPath)){
                // Save to file
                fileWrite(absOutputPath, diffStatResponse.fileContent);
                out("Pull Request Diff written to: " & absOutputPath);
                return;
            }
            else{
                out(diffStatResponse.fileContent);
            }
        return diffStatResponse.fileContent;
    }
    
    /*
        Filter annotations using a diff file to only include those that are in the diff
        @reportPath string Path to the Pull Request report file
        @diffFilePath string Path to the diff file
        @rootPath string Root path to strip from annotation paths
    */
    function filterAnnotationsInDiff(string reportPath, string diffFilePath, string rootPath="", string outputPath="") {
        var filtered = [];
        var reportData = deserializeJson(fileRead(reportPath));
        var diffStruct = parseDiffSimple(diffFilePath)
        var changedLinesByFile = {};
        
       

        for(var filePath in diffStruct){
            changedLinesByFile[filePath] = [];
            changedLinesByFile[filePath] = diffStruct[filePath].map(
                function(lineDiff){
                    return lineDiff.line;
                }
            );
        }
        // out(changedLinesByFile);
        
        foundAnnotations = []
        
        // Note: making the assumption that the changedLinesByFile are sequential. Kinda important.

        for(var filePath in changedLinesByFile){
            // dump(var=filePath, label="Processing file: " & filePath);
            for(var lineNum in changedLinesByFile[filePath]){
                // dump(var=lineNum, label="Changed line: " & lineNum);
                // Now loop through all the annotations to see if they match
                for(var annotation in reportData.annotations){
                    // out("Annotation real path: " & annotation.path);
                    var annotationRealPath = Right((annotation.path), Len(annotation.path) - Len(rootPath));
                    // out("Annotation real path: " & annotationRealPath);
                    if(annotationRealPath NEQ filePath){
                        continue;
                    }
                    // if we dont have a annotation.line this applies to the whole file, so we include it
                    if(!structKeyExists(annotation, "line")){
                        annotation.path = annotationRealPath;
                        if(!arrayContains(foundAnnotations, annotation)){
                            arrayAppend(foundAnnotations, annotation);
                        }
                        continue;
                    }
                    // dump(var=annotation, label="Checking annotation " & annotationRealPath & ":" & annotation.line);
                    // If we have an end_line, check the range
                    if( structKeyExists(annotation, "end_line") ){
                        if( lineNum GTE annotation.line AND lineNum LTE annotation.end_line ){
                            // dump(var=annotation, label="FOUND annotation in range " & annotationRealPath & ":" & annotation.line & "-" & annotation.end_line);
                            if(!arrayContains(foundAnnotations, annotation)){
                                annotation.path = annotationRealPath;
                                arrayAppend(foundAnnotations, annotation);
                            }
                        }
                    } else {
                        if( lineNum EQ annotation.line ){
                            // dump(var=annotation, label="FOUND annotation at line " & annotationRealPath & ":" & annotation.line);
                            if(!arrayContains(foundAnnotations, annotation)){
                                annotation.path = annotationRealPath;
                                arrayAppend(foundAnnotations, annotation);
                            }
                        }
                    }
                }
            }
            
        }
        verbose(foundAnnotations);

        if(Len(arguments.outputPath)){
                // Save to file
                var absOutputPath = getAbsolutePath(variables.cwd, outputPath);
                fileWrite(absOutputPath, serializeJson(foundAnnotations));
                out("Filtered annotations written to: " & absOutputPath);
                return foundAnnotations;
        }

        verbose(foundAnnotations);
        return foundAnnotations;
    }



    /**
     * Downloads the files associated with a specified pull request to a local path.
     *
     * @pullRequestId The ID of the pull request to download files for.
     * @downloadPath The local directory where files should be downloaded.
     * @return void
     */
    function downloadPRFiles(numeric pullRequestId = 0, string downloadPath="") {
        var pullRequestId = arguments.pullRequestId ?: getEnv("BITBUCKET_PR_ID", "");
        var bitbucket = new BitbucketClient(
            repoSlug = getEnv("BITBUCKET_REPO_SLUG", ""),
            workspace = getEnv("BITBUCKET_WORKSPACE", ""),
            authToken = getEnv("BITBUCKET_AUTH_TOKEN", "")
        );
        var prFilesResponse = bitbucket.getPullRequestDiffStat(
            pullRequestId = pullRequestId
        );

     

        var prFiles = DeserializeJSON(prFilesResponse.fileContent);
        var absDownloadPath = getAbsolutePath(variables.cwd, arguments.downloadPath);
       
        // // Create download path if it doesn't exist
        if(!directoryExists(absDownloadPath)){
            directoryCreate(absDownloadPath, true);
        }

        // output how many files to download and the list:
        for(var fileInfo in prFiles.values) {     
            out("File to download: " & fileInfo?.new?.path & " (status: " & fileInfo.status & ")");
        }
        out("Downloading " & arrayLen(prFiles.values) & " files to " & absDownloadPath);


        
        var count = 0;
        for(var fileInfo in prFiles.values){

            
            var fileURL = fileInfo.new?.links?.self?.href;
            if(fileInfo.status EQ "removed"){
                continue;
            }
            var filePath =  fileInfo?.new?.path;

                verbose( [
                    "Downloading file: " & filePath,
                    "From URL: " & fileURL,
                    "To Path: " & absDownloadPath & "/" & filePath
                ]);

            if(!Len(fileURL) OR !Len(filePath)){
                verbose(fileInfo)
                out("❌ Skipping file due to missing URL or path");
                continue;
            }
          
            try{
                var fileContentResponse = bitbucket.downloadFile(
                    fileURL = fileURL,
                    destinationPath = absDownloadPath & "/" & filePath
                );
                var msg = "Downloaded file: " & fileURL & " to " & absDownloadPath & "/" & filePath
                out(msg);
                count++;
               
            }
            catch (ex) {
                out("❌ Error downloading file: " & fileURL & " - " & ex.message);
            }
            

        }

        return "Downloaded " & arrayLen(prFiles.values) & " files to " & absDownloadPath;
    }

    /**
     * Retrieves a pull request by its identifier from the configured Bitbucket repository.
     *
     * @id The pull request ID to retrieve.
     * @fields An optional list of fields to include in the response.
     * @outputPath Optional path to save the pull request details to a file
     * @return The pull request details as a struct.
     */
    function getPullRequest(
        numeric pullRequestId = 0,
        String fields = "",
        String outputPath=""
        ){
        var pullRequestId = arguments.pullRequestId ?: getEnv("BITBUCKET_PR_ID", "");
        var bitbucket = new BitbucketClient(
            repoSlug = getEnv("BITBUCKET_REPO_SLUG", ""),
            workspace = getEnv("BITBUCKET_WORKSPACE", ""),
            authToken = getEnv("BITBUCKET_AUTH_TOKEN", "")
        );

        var resp = bitbucket.getPullRequest(
            pullRequestId = pullRequestId,
            fields = fields
        );

        if(Len(arguments.outputPath)){
            var absOutputPath = getAbsolutePath(variables.cwd, arguments.outputPath);
            // Save to file
            fileWrite(absOutputPath, resp.fileContent);
            out("Pull Request written to: " & absOutputPath);
            return;
        }
        else{
            out(resp.fileContent);
        }
        return resp.fileContent;
    }



    /**
     * Add reviewers to a pull request. 
     *
     * @pullRequestId the ID of the pull request to which reviewers will be added.
     * @reviewerUuids a list of reviewer UUIDs to add. Reviewer UUIDs should be in the format "{uuid}"
     */
    function addReviewers(
        required string pullRequestId,
        required string reviewerUuids
        ){

        // Move this to the bitbucket object!
      
        var bitbucket = new BitbucketClient(
            repoSlug = getEnv("BITBUCKET_REPO_SLUG", ""),
            workspace = getEnv("BITBUCKET_WORKSPACE", ""),
            authToken = getEnv("BITBUCKET_AUTH_TOKEN", "")
        );

        var originalPullRequest = bitbucket.getPullRequest(
            pullRequestId = arguments.pullRequestId,
            fields= "reviewers"
        );

        var prData = DeserializeJSON(originalPullRequest.fileContent);

        if(!structKeyExists(prData, "reviewers")){
            prData["reviewers"] = [];
        }

        var reviewerUuidsArray = listToArray(arguments.reviewerUuids, ",");

        for(var reviewerUuid in reviewerUuidsArray){
            // Check if reviewer already exists
            var alreadyReviewer = false;
            for(var existingReviewer in prData.reviewers){
                if(existingReviewer.uuid EQ reviewerUuid){
                    alreadyReviewer = true;
                    break;
                }
            }
            if(alreadyReviewer){
                out("Reviewer " & reviewerUuid & " already exists on pull request " & pullRequestId);
                continue;
            }
            arrayAppend(prData.reviewers, {"uuid"=reviewerUuid});
        }
        out("Updating pull request " & pullRequestId & " with reviewers: " & arrayToList(reviewerUuidsArray));

        var resp = bitbucket.putPullRequest(
            pullRequestId = arguments.pullRequestId,
            data=prData
        );
        return resp;
    }


    /**
     * Adds a task to a pull request.
     *
     * @pullRequestId The ID of the pull request.
     * @taskContent   The text content of the task to create.
     * @return The API response (task created).
     */
    function addPullRequestTask(
        numeric pullRequestId = 0,
        required string taskContent
    ){
        var pullRequestId = arguments.pullRequestId ?: getEnv("BITBUCKET_PR_ID", "");
        var bitbucket = new BitbucketClient(
            repoSlug = getEnv("BITBUCKET_REPO_SLUG", ""),
            workspace = getEnv("BITBUCKET_WORKSPACE", ""),
            authToken = getEnv("BITBUCKET_AUTH_TOKEN", "")
        );
        return bitbucket.addPullRequestTask(
            pullRequestId = pullRequestId,
            taskContent = arguments.taskContent
        );
    }


    /**
     * Downloads a file from a given URL to a specified local destination.
     *
     * @fileURL The URL of the file to download.
     * @destinationPath The local path where the file should be saved.
     * @return The content of the downloaded file.
     */
    function downloadFile(
        required string fileURL,
        required string destinationPath
        ){
          var bitbucket = new BitbucketClient(
            repoSlug = getEnv("BITBUCKET_REPO_SLUG", ""),
            workspace = getEnv("BITBUCKET_WORKSPACE", ""),
            authToken = getEnv("BITBUCKET_AUTH_TOKEN", "")
        );
        try{
                var destPath = getAbsolutePath(variables.cwd, arguments.destinationPath);
                var folder = getDirectoryFromPath(destPath);
                var fileContentResponse = bitbucket.downloadFile(
                    fileURL = fileURL,
                    destinationPath = destPath
                );
                out("Downloaded file: " & fileURL & " to " & destinationPath);
                
            }
            catch (ex) {
                out("❌ Error downloading file: " & fileURL & " - " & ex.message);
            }
        return "Downloaded file: " & fileURL & " to " & destinationPath;
    }

    /**
     * Simple Helper to convert a yaml file to JSON
     *
     * @filePath The path to the yaml file
     */
    function convertYamlToJson(required string filePath, string outputPath="") {
        var yamlReader = new YAML2CFML();
         var yamlData = yamlReader.read(filePath);
       
        if(Len(arguments.outputPath)){
            var absPath = getAbsolutePath(variables.cwd, arguments.outputPath);
            var jsonData = serializeJson(yamlData, true);
            fileWrite(absPath, jsonData);
            out("YAML converted to JSON and written to: " & absPath);
            return;
        }
        return yamlData;
    }



    /**
     * posts a report to bitbuclet from a report formatted json file
     *
     * @commit the commit
     * @reportPath the path to the bitbucket report json file
     * @reportTitle the title of the report (optional) If not provided, will use the title from the report file
     */
    function postReport(
        required string commit, 
        required string reportPath, 
        required string reportID, 
        string title="",
        string details=""
        ) {
        var bitbucket = new BitbucketClient(
            repoSlug = getEnv("BITBUCKET_REPO_SLUG", ""),
            workspace = getEnv("BITBUCKET_WORKSPACE", ""),
            authToken = getEnv("BITBUCKET_AUTH_TOKEN", "")
        );


        var reportData = deserializeJson(fileRead(reportPath));
        if(Len(title)){
            reportData.title = title;
        }
        if(Len(details)){
            reportData.details = details;
        }

        var response = bitbucket.createReport(
            reportData = reportData,
            commit = commit,
            reportID = reportID
        );
        out("Report [#reportID#] created");
        var bitbucketResponse = DeserializeJSON(response.fileContent);
        // verbose(response);
        verbose(bitbucketResponse);
        return response;

    }
   
    /**
     * adds annotations to a report
     *
     * @commit the commit
     * @annotationFile the path to the annotation file with a JSON array of annotations
     * @reportTitle the title of the report to add the annotations to
     */

    function postReportAnnotations(required string commit, required string annotationFile, required string reportId) {
        var bitbucket = new BitbucketClient(
            repoSlug = getEnv("BITBUCKET_REPO_SLUG", ""),
            workspace = getEnv("BITBUCKET_WORKSPACE", ""),
            authToken = getEnv("BITBUCKET_AUTH_TOKEN", "")
        );

        var annotations = deserializeJson(fileRead(annotationFile));

        if(!annotations.len()){
            out("❌ No annotations found in file: #annotationFile#");
            return;
        }
        var annotationResponse = bitbucket.createAnnotations(
            annotations = annotations,
            commit = commit,
            reportId = reportId
        );
        var annotationResp = DeserializeJSON(annotationResponse.fileContent);
        // verbose(annotationResp);   
        out("Annotations added to report [#reportId#]");
        return annotationResponse;
    }


    /**
     * Creates and returns a client instance for the Bitbucket module.
     *
     * @return any The initialized client object.
     */
    private function createCient(){

        // need to check for errors if env vars not set
        return new BitbucketClient(
            repoSlug = getEnv("BITBUCKET_REPO_SLUG", ""),
            workspace = getEnv("BITBUCKET_WORKSPACE", ""),
            authToken = getEnv("BITBUCKET_AUTH_TOKEN", "")
        );
    }

    /**
     * Function to parse a diff file to extract the file and changed lines
     *
     * @diffFilePath the path to the diff text file (not the diffstat)
     */
    private function parseDiffSimple(diffFilePath) {
        var result = {};
        var diffContent = fileRead(diffFilePath);
        var lines = listToArray(diffContent, chr(10));
        
        var currentFile = "";
        var currentLineNum = 0;
        var lastWasRemoved = false;
        var lastRemovedLine = 0;
        
        for (var line in lines) {
           
            // Extract file path from diff header
            if (reFindNoCase("^diff --git", line)) {
                var pathMatch = reMatch("b/(.+?)(\s|$)", line);
               
                if (arrayLen(pathMatch) > 0) {
                    currentFile = pathMatch[1].substring(2);
                    if (!structKeyExists(result, currentFile)) {
                        result[currentFile] = [];
                    }
                }
                lastWasRemoved = false;
            }
            
            // Extract line number from hunk header
            if (reFindNoCase("^@@", line)) {
                var hunkMatch = reMatch("\+(\d+)(?:,(\d+))?", line);
                if (arrayLen(hunkMatch) > 0) {
                    currentLineNum = val(hunkMatch[1]);
                }
                lastWasRemoved = false;
            }
            
            // Track added lines
            if (left(line, 1) == "+" && !reFindNoCase("^\+\+\+", line)) {
                var action = "added";
                
                // If last line was removed, mark as changed instead
                // if (lastWasRemoved) {
                //     action = "changed";
                //     // Update the last removed entry to changed
                //     var lastEntry = result[currentFile][arrayLen(result[currentFile])];
                    
                // }
                
                if (currentFile != "") {
                    arrayAppend(result[currentFile], {
                        line: currentLineNum,
                        action: action
                    });
                }
                currentLineNum++;
                lastWasRemoved = false;
            }
            // Track removed lines
            else if (left(line, 1) == "-" && !reFindNoCase("^---", line)) {
                if (currentFile != "") {
                    arrayAppend(result[currentFile], {
                        line: currentLineNum,
                        action: "removed"
                    });
                }
                lastWasRemoved = true;
                lastRemovedLine = currentLineNum;
            }
            // Context lines increment line counter
            else if (left(line, 1) == " ") {
                currentLineNum++;
                lastWasRemoved = false;
            }
        }
        
        return result;
    }

}
