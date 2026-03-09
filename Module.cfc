        
component extends="modules.BaseModule" {
    /**
     * bitbucket Module
     * 
     * This is the main entry point for your module.
     * Implement your module logic in the main() function.
     */
    
   
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
    /**
     * Default command when calling `lucli bitbucket` without a subcommand.
     *
     * Backward compatible: if `--action` is provided, we will invoke that method.
     */
    public any function main(
        string action="",
        string file="",
        string commit="",
        string reportId="",
        string reportSlug="",
        numeric pullRequestId=0,
        string outputPath="",
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        if(!Len(arguments.action)){
            return showHelp();
        }

        var actionName = arguments.action;

        // Only allow invoking *public* functions, and only pass accepted params.
        var md = getComponentMetadata(this);
        var fnMeta = md.functions.filter(function(fn){
            return compareNoCase(fn.name, actionName) EQ 0;
        });

        if(!arrayLen(fnMeta) || fnMeta[1].access NEQ "public"){
            throw("Unknown action: #actionName#");
        }

        var args = duplicate(arguments);
        structDelete(args, "action");

        var callArgs = {};
        for(var p in fnMeta[1].parameters){
            if(structKeyExists(args, p.name)){
                callArgs[p.name] = args[p.name];
            }
        }

        return invoke(this, actionName, callArgs);
    }

    /**
     * Shared Bitbucket client factory.
     */
    private any function createClient(
        string repoSlug="",
        string workspace="",
        string authToken=""
    ){

        // If we don't have the required params, get it from the env, and if we still don't have it show a proper error message
        return new BitbucketClient(
            repoSlug = Len(arguments.repoSlug) ? arguments.repoSlug : getEnv("BITBUCKET_REPO_SLUG", ""),
            workspace = Len(arguments.workspace) ? arguments.workspace : getEnv("BITBUCKET_WORKSPACE", ""),
            authToken = Len(arguments.authToken) ? arguments.authToken : getEnv("BITBUCKET_AUTH_TOKEN", "")
        );
    }

    /**
     * Read JSON from a file and return the native CFML struct/array.
     */
    private any function readJsonFile(required string filePath){
        if(!Len(arguments.filePath)){
            throw("filePath is required");
        }

        var absPath = getAbsolutePath(variables.cwd, arguments.filePath);
        if(!fileExists(absPath)){
            throw("JSON file not found: #absPath#");
        }

        return deserializeJson(fileRead(absPath));
    }

    /**
     * Backward-compatible wrapper for reports.
     * Previously supported via `lucli bitbucket --action=createReport`.
     */
    public any function createReport(
        required string commit,
        required string file,
        string reportId="",
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        var reportData = readJsonFile(arguments.file);
        var bb = createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken);

        var reportIdToUse = arguments.reportId;
        if(!Len(reportIdToUse) AND isStruct(reportData) AND structKeyExists(reportData, "title") AND Len(reportData.title)){
            reportIdToUse = lCase(replace(reportData.title, " ", "_", "all"));
        }

        var reportResponse = bb.createReport(
            reportData=reportData,
            commit=arguments.commit,
            reportId=reportIdToUse
        );

        var result = {
            report = reportResponse
        };

        // If the report JSON has annotations embedded, post them too.
        if(isStruct(reportData) AND structKeyExists(reportData, "annotations") AND isArray(reportData.annotations) AND arrayLen(reportData.annotations) GT 0){
            result.annotations = bb.createAnnotations(
                annotations=reportData.annotations,
                commit=arguments.commit,
                reportId=reportIdToUse
            );
        }

        return result;
    }

    /**
     * Backward-compatible wrapper for report annotations.
     * Previously supported via `lucli bitbucket --action=createAnnotations`.
     */
    public any function createAnnotations(
        required string commit,
        required string file,
        required string reportId,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        var payload = readJsonFile(arguments.file);
        var bb = createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken);

        var annotations = [];
        if(isArray(payload)){
            annotations = payload;
        }
        else if(isStruct(payload) AND structKeyExists(payload, "annotations")){
            annotations = payload.annotations;
        }

        if(!isArray(annotations) OR arrayLen(annotations) EQ 0){
            throw("No annotations found in file: #arguments.file#");
        }

        return bb.createAnnotations(
            annotations=annotations,
            commit=arguments.commit,
            reportId=arguments.reportId
        );
    }

    // --- Pull Requests (API group: /pullrequests) ---

    /**
     * List pull requests for the repo.
     * Maps to GET /repositories/{workspace}/{repo_slug}/pullrequests
     */
    public any function pullrequests(
        string state="",
        string q="",
        string sort="",
        numeric page=0,
        numeric pagelen=0,
        string workspace="",
        string repoSlug="",
        string authToken="",
        string format=""
    ){
        var bb = createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken);
        var res = bb.listPullRequests(
            state=arguments.state,
            q=arguments.q,
            sort=arguments.sort,
            page=Int(arguments.page),
            pagelen=Int(arguments.pagelen)
        );

        // Backward-compat: if older callers still pass --format=json, avoid double-serializing
        // now that the client returns JSON as a string.
        if(lCase(arguments.format) EQ "json" OR lCase(arguments.format) EQ "json-compact"){
            if(isSimpleValue(res) AND isJSON(res)){
                return res;
            }
            // Fallback (if some call path still returns native CFML)
            return serializeJson(res, lCase(arguments.format) EQ "json-compact");
        }

        return res;
    }

    /**
     * Get a single pull request by id.
     * Maps to GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}
     */
    public any function pullrequests_get(
        required numeric pullRequestId,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .getPullRequest(pullRequestId=arguments.pullRequestId);
    }

    /**
     * Create a pull request.
     * Maps to POST /repositories/{workspace}/{repo_slug}/pullrequests
     */
    public any function pullrequests_create(
        required string dataFile,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .createPullRequest(
                pullRequestData=readJsonFile(arguments.dataFile)
            );
    }

    /**
     * Update a pull request.
     * Maps to PUT /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}
     */
    public any function pullrequests_update(
        required numeric pullRequestId,
        required string dataFile,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .updatePullRequest(
                pullRequestId=arguments.pullRequestId,
                pullRequestData=readJsonFile(arguments.dataFile)
            );
    }

    /**
     * Decline a pull request.
     * Maps to POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/decline
     */
    public any function pullrequests_decline(
        required numeric pullRequestId,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .declinePullRequest(pullRequestId=arguments.pullRequestId);
    }

    /**
     * Merge a pull request.
     * Maps to POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/merge
     */
    public any function pullrequests_merge(
        required numeric pullRequestId,
        string dataFile="",
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        var mergeData = {};
        if(Len(arguments.dataFile)){
            mergeData = readJsonFile(arguments.dataFile);
        }
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .mergePullRequest(
                pullRequestId=arguments.pullRequestId,
                mergeData=mergeData
            );
    }

    /**
     * Get the merge task status.
     * Maps to GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/merge/task-status/{task_id}
     */
    public any function pullrequests_merge_task_status(
        required numeric pullRequestId,
        required string taskId,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .getPullRequestMergeTaskStatus(
                pullRequestId=arguments.pullRequestId,
                taskId=arguments.taskId
            );
    }

    /**
     * Get the diffstat for a pull request.
     * Maps to GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/diffstat
     */
    public any function pullrequests_diffstat(
        required numeric pullRequestId,
        numeric page=0,
        numeric pagelen=0,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .getPullRequestDiffStat(
                pullRequestId=arguments.pullRequestId,
                page=Int(arguments.page),
                pagelen=Int(arguments.pagelen)
            );
    }

    /**
     * Get the diff for a pull request.
     * Maps to GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/diff
     */
    public any function pullrequests_diff(
        required numeric pullRequestId,
        string outputPath="",
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        var diffContent = createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .getPullRequestDiff(pullRequestId=arguments.pullRequestId);

        if(Len(arguments.outputPath)){
            var absOutputPath = getAbsolutePath(variables.cwd, arguments.outputPath);
            fileWrite(absOutputPath, diffContent);
        }

        return diffContent;
    }

    /**
     * Get the patch for a pull request.
     * Maps to GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/patch
     */
    public any function pullrequests_patch(
        required numeric pullRequestId,
        string outputPath="",
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        var patchContent = createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .getPullRequestPatch(pullRequestId=arguments.pullRequestId);

        if(Len(arguments.outputPath)){
            var absOutputPath = getAbsolutePath(variables.cwd, arguments.outputPath);
            fileWrite(absOutputPath, patchContent);
        }

        return patchContent;
    }

    /**
     * Approve a pull request.
     * Maps to POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/approve
     */
    public any function pullrequests_approve(
        required numeric pullRequestId,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .approvePullRequest(pullRequestId=arguments.pullRequestId);
    }

    /**
     * Unapprove a pull request.
     * Maps to DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/approve
     */
    public any function pullrequests_unapprove(
        required numeric pullRequestId,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .unapprovePullRequest(pullRequestId=arguments.pullRequestId);
    }

    /**
     * Request changes on a pull request.
     * Maps to POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/request-changes
     */
    public any function pullrequests_request_changes(
        required numeric pullRequestId,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .requestChangesPullRequest(pullRequestId=arguments.pullRequestId);
    }

    /**
     * Remove change request on a pull request.
     * Maps to DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/request-changes
     */
    public any function pullrequests_remove_request_changes(
        required numeric pullRequestId,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .removeRequestChangesPullRequest(pullRequestId=arguments.pullRequestId);
    }

    /**
     * List PR activity.
     * Maps to GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/activity
     */
    public any function pullrequests_activity(
        required numeric pullRequestId,
        numeric page=0,
        numeric pagelen=0,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .listPullRequestActivity(
                pullRequestId=arguments.pullRequestId,
                page=arguments.page,
                pagelen=arguments.pagelen
            );
    }

    /**
     * List PR commits.
     * Maps to GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/commits
     */
    public any function pullrequests_commits(
        required numeric pullRequestId,
        numeric page=0,
        numeric pagelen=0,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .listPullRequestCommits(
                pullRequestId=arguments.pullRequestId,
                page=arguments.page,
                pagelen=arguments.pagelen
            );
    }

    /**
     * List PR comments.
     * Maps to GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments
     */
    public any function pullrequests_comments(
        required numeric pullRequestId,
        numeric page=0,
        numeric pagelen=0,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .listPullRequestComments(
                pullRequestId=arguments.pullRequestId,
                page=arguments.page,
                pagelen=arguments.pagelen
            );
    }

    /**
     * Create a PR comment.
     * Maps to POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments
     */
    public any function pullrequests_comments_create(
        required numeric pullRequestId,
        required string dataFile,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .createPullRequestComment(
                pullRequestId=arguments.pullRequestId,
                commentData=readJsonFile(arguments.dataFile)
            );
    }

    /**
     * Get a PR comment.
     * Maps to GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}
     */
    public any function pullrequests_comments_get(
        required numeric pullRequestId,
        required numeric commentId,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .getPullRequestComment(
                pullRequestId=arguments.pullRequestId,
                commentId=arguments.commentId
            );
    }

    /**
     * Update a PR comment.
     * Maps to PUT /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}
     */
    public any function pullrequests_comments_update(
        required numeric pullRequestId,
        required numeric commentId,
        required string dataFile,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .updatePullRequestComment(
                pullRequestId=arguments.pullRequestId,
                commentId=arguments.commentId,
                commentData=readJsonFile(arguments.dataFile)
            );
    }

    /**
     * Delete a PR comment.
     * Maps to DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/comments/{comment_id}
     */
    public any function pullrequests_comments_delete(
        required numeric pullRequestId,
        required numeric commentId,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .deletePullRequestComment(
                pullRequestId=arguments.pullRequestId,
                commentId=arguments.commentId
            );
    }

    /**
     * List PR tasks.
     * Maps to GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/tasks
     */
    public any function pullrequests_tasks(
        required numeric pullRequestId,
        string q="",
        string sort="",
        numeric page=0,
        numeric pagelen=0,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .listPullRequestTasks(
                pullRequestId=arguments.pullRequestId,
                q=arguments.q,
                sort=arguments.sort,
                page=arguments.page,
                pagelen=arguments.pagelen
            );
    }

    /**
     * Create a PR task.
     * Maps to POST /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/tasks
     */
    public any function pullrequests_tasks_create(
        required numeric pullRequestId,
        required string dataFile,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .createPullRequestTask(
                pullRequestId=arguments.pullRequestId,
                taskData=readJsonFile(arguments.dataFile)
            );
    }

    /**
     * Get a PR task.
     * Maps to GET /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/tasks/{task_id}
     */
    public any function pullrequests_tasks_get(
        required numeric pullRequestId,
        required numeric taskId,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .getPullRequestTask(
                pullRequestId=arguments.pullRequestId,
                taskId=arguments.taskId
            );
    }

    /**
     * Update a PR task.
     * Maps to PUT /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/tasks/{task_id}
     */
    public any function pullrequests_tasks_update(
        required numeric pullRequestId,
        required numeric taskId,
        required string dataFile,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .updatePullRequestTask(
                pullRequestId=arguments.pullRequestId,
                taskId=arguments.taskId,
                taskData=readJsonFile(arguments.dataFile)
            );
    }

    /**
     * Delete a PR task.
     * Maps to DELETE /repositories/{workspace}/{repo_slug}/pullrequests/{pull_request_id}/tasks/{task_id}
     */
    public any function pullrequests_tasks_delete(
        required numeric pullRequestId,
        required numeric taskId,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .deletePullRequestTask(
                pullRequestId=arguments.pullRequestId,
                taskId=arguments.taskId
            );
    }

    /**
     * List pull requests for a commit.
     * Maps to GET /repositories/{workspace}/{repo_slug}/commit/{commit}/pullrequests
     */
    public any function pullrequests_for_commit(
        required string commit,
        numeric page=0,
        numeric pagelen=0,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .listPullRequestsForCommit(
                commit=arguments.commit,
                page=arguments.page,
                pagelen=arguments.pagelen
            );
    }

    // --- Refs (API group: /refs) ---

    /**
     * List tags.
     * Maps to GET /repositories/{workspace}/{repo_slug}/refs/tags
     */
    public any function refs_tags(
        string q="",
        string sort="",
        numeric page=0,
        numeric pagelen=0,
        string workspace="",
        string repoSlug="",
        string authToken="",
        string format=""
    ){
        var bb = createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken);
        var res = bb.listTags(
            q=arguments.q,
            sort=arguments.sort,
            page=Int(arguments.page),
            pagelen=Int(arguments.pagelen)
        );

        if(lCase(arguments.format) EQ "json" OR lCase(arguments.format) EQ "json-compact"){
            if(isSimpleValue(res) AND isJSON(res)){
                return res;
            }
            return serializeJson(res, lCase(arguments.format) EQ "json-compact");
        }

        return res;
    }

    // --- Decorated helpers (not 1:1 REST endpoints) ---

    /**
     * Build a weekly "merged to main" release context without requiring a git clone.
     *
     * This is intended to feed an AI summarizer (e.g. Oz/Warp) or to be rendered into a human report.
     *
     * Strategy:
     * - List MERGED PRs into the destination branch (default: main)
     * - Filter locally by merged timestamp (prefers closed_on)
     * - Optionally fetch diffstat/commits per PR and compute aggregates
     */
    public any function weeklyReleaseContext(
        string branch="main",
        string sinceISO="",
        string untilISO="",
        boolean includeDiffstat=true,
        boolean includeCommits=false,
        string mode="detailed",
        boolean includeBaseHead=false,
        numeric maxPRs=200,
        numeric prPageLen=50,
        numeric childPageLen=100,
        numeric maxFilesPerPR=500,
        numeric maxCommitsPerPR=200,
        string workspace="",
        string repoSlug="",
        string authToken="",
        string format="json"
    ){
        var bb = createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken);
        var modeNorm = lCase(trim(arguments.mode));
        if(modeNorm NEQ "fast" AND modeNorm NEQ "detailed"){
            modeNorm = "detailed";
        }
        var shouldIncludeDiffstat = arguments.includeDiffstat;
        var shouldIncludeCommits = arguments.includeCommits;
        if(modeNorm EQ "fast"){
            shouldIncludeDiffstat = false;
            shouldIncludeCommits = false;
        }

        // Robust ISO8601 parsing.
        // Primary: Lucee/CFML's parseDateTime(), which typically handles `...Z` and `...+00:00`.
        // Fallbacks: java.time parsers.
        var instant = createObject("java", "java.time.Instant");
        var odt = createObject("java", "java.time.OffsetDateTime");

        function isoToEpochMillis(required string iso){
            try {
                var d = parseDateTime(arguments.iso);
                return d.getTime();
            } catch(any e0){
                // ignore
            }
            try {
                return instant.parse(arguments.iso).toEpochMilli();
            } catch(any e1){
                // ignore
            }
            try {
                return odt.parse(arguments.iso).toInstant().toEpochMilli();
            } catch(any e2){
                return 0;
            }
        }

        // Defaults: last 7 days, UTC
        var nowUtc = dateConvert("local2utc", now());
        if(!Len(arguments.untilISO)){
            arguments.untilISO = dateTimeFormat(nowUtc, "yyyy-mm-dd'T'HH:nn:ss") & "Z";
        }
        if(!Len(arguments.sinceISO)){
            var sinceUtc = dateAdd("d", -7, nowUtc);
            arguments.sinceISO = dateTimeFormat(sinceUtc, "yyyy-mm-dd'T'HH:nn:ss") & "Z";
        }

        var sinceMs = isoToEpochMillis(arguments.sinceISO);
        var untilMs = isoToEpochMillis(arguments.untilISO);
        if(sinceMs EQ 0 OR untilMs EQ 0){
            throw("sinceISO/untilISO must be ISO8601 (e.g. 2026-03-01T00:00:00Z). Got sinceISO='#arguments.sinceISO#' untilISO='#arguments.untilISO#'.");
        }
        if(untilMs LT sinceMs){
            throw("untilISO must be >= sinceISO. Got sinceISO='#arguments.sinceISO#' untilISO='#arguments.untilISO#'.");
        }

        var headSha = "";
        var baseSha = "";

        // Optional, disabled by default for PR-window reporting performance.
        if(arguments.includeBaseHead){
            try {
                var brStr = bb.getBranchRef(branch=arguments.branch);
                if(isSimpleValue(brStr) AND isJSON(brStr)){
                    var br = deserializeJson(brStr);
                    headSha = br.target?.hash ?: "";
                }
            } catch(any e){
                // ignore; we'll leave head/base blank if unavailable
            }

            if(Len(headSha)){
                var cPage = 1;
                var maxPages = 25; // safety
                while(cPage LTE maxPages AND !Len(baseSha)){
                    var cStr = bb.listCommits(revision=arguments.branch, page=cPage, pagelen=100);
                    if(!isSimpleValue(cStr) OR !isJSON(cStr)){
                        break;
                    }
                    var cs = deserializeJson(cStr);
                    if(!isStruct(cs) OR !structKeyExists(cs, "values") OR !isArray(cs.values) OR arrayLen(cs.values) EQ 0){
                        break;
                    }

                    for(var cv in cs.values){
                        var dStr = cv.date ?: "";
                        var dMs = Len(dStr) ? isoToEpochMillis(dStr) : 0;
                        if(dMs GT 0 AND dMs LT sinceMs){
                            baseSha = cv.hash ?: "";
                            break;
                        }
                    }

                    if(Len(baseSha) OR !structKeyExists(cs, "next")){
                        break;
                    }
                    cPage++;
                }
            }
        }

        var qFilter = 'destination.branch.name="' & arguments.branch & '" AND closed_on >= "' & arguments.sinceISO & '" AND closed_on <= "' & arguments.untilISO & '"';
        var prFields = "next,values.id,values.title,values.state,values.closed_on,values.updated_on,values.author.display_name,values.source.branch.name,values.destination.branch.name,values.merge_commit.hash,values.links.html.href,values.summary.raw,values.description";
        var diffstatFields = "next,values.lines_added,values.lines_removed,values.new.path,values.old.path";
        var commitFields = "next,values.hash,values.date,values.message,values.author.user.display_name,values.author.raw";

        var collected = [];
        var page = 1;
        while(arrayLen(collected) LT Int(arguments.maxPRs)){
            var resStr = bb.listPullRequests(
                state="MERGED",
                q=qFilter,
                sort="-closed_on",
                page=page,
                pagelen=Int(arguments.prPageLen),
                fields=prFields
            );

            if(!isSimpleValue(resStr) OR !isJSON(resStr)){
                throw("Expected JSON string from listPullRequests()");
            }

            var res = deserializeJson(resStr);
            if(!isStruct(res) OR !structKeyExists(res, "values") OR !isArray(res.values) OR arrayLen(res.values) EQ 0){
                break;
            }

            for(var pr in res.values){
                var mergedOn = pr.closed_on ?: pr.updated_on;
                var mergedMs = Len(mergedOn) ? isoToEpochMillis(mergedOn) : 0;
                if(mergedMs EQ 0 OR mergedMs LT sinceMs OR mergedMs GT untilMs){
                    continue;
                }

                arrayAppend(collected, pr);
                if(arrayLen(collected) GTE Int(arguments.maxPRs)){
                    break;
                }
            }

            if(!structKeyExists(res, "next")){
                break;
            }
            page++;
        }

        var prContexts = [];
        var totals = {
            pr_count = arrayLen(collected),
            unique_authors = {},
            files_changed = 0,
            lines_added = 0,
            lines_removed = 0,
            top_level_paths = {}
        };

        for(var pr in collected){
            var prCtx = {
                id = pr.id,
                title = pr.title,
                state = pr.state,
                merged_on = pr.closed_on ?: pr.updated_on,
                author = pr.author?.display_name ?: "",
                source_branch = pr.source?.branch?.name ?: "",
                destination_branch = pr.destination?.branch?.name ?: "",
                merge_commit = pr.merge_commit?.hash ?: "",
                link = pr.links?.html?.href ?: "",
                summary = pr.summary?.raw ?: pr.description ?: ""
            };

            if(Len(prCtx.author)){
                totals.unique_authors[prCtx.author] = true;
            }

            if(shouldIncludeDiffstat){
                var diffValues = [];
                var dsPage = 1;

                while(arrayLen(diffValues) LT Int(arguments.maxFilesPerPR)){
                    var dsStr = bb.getPullRequestDiffStat(
                        pullRequestId=pr.id,
                        page=dsPage,
                        pagelen=Int(arguments.childPageLen),
                        fields=diffstatFields
                    );
                    if(!isSimpleValue(dsStr) OR !isJSON(dsStr)){
                        break;
                    }
                    var ds = deserializeJson(dsStr);
                    if(!isStruct(ds) OR !structKeyExists(ds, "values") OR !isArray(ds.values) OR arrayLen(ds.values) EQ 0){
                        break;
                    }

                    for(var v in ds.values){
                        arrayAppend(diffValues, v);
                        if(arrayLen(diffValues) GTE Int(arguments.maxFilesPerPR)){
                            break;
                        }
                    }
                    if(!structKeyExists(ds, "next")){
                        break;
                    }
                    dsPage++;
                }

                var prStats = {
                    files_changed = arrayLen(diffValues),
                    lines_added = 0,
                    lines_removed = 0,
                    top_level_paths = {},
                    sample_paths = []
                };

                for(var dv in diffValues){
                    if(structKeyExists(dv, "lines_added")){
                        prStats.lines_added += Int(dv.lines_added);
                    }
                    if(structKeyExists(dv, "lines_removed")){
                        prStats.lines_removed += Int(dv.lines_removed);
                    }

                    var p = dv.new?.path ?: dv.old?.path ?: "";
                    if(Len(p)){
                        if(arrayLen(prStats.sample_paths) LT 50){
                            arrayAppend(prStats.sample_paths, p);
                        }
                        var top = listFirst(p, "/");
                        prStats.top_level_paths[top] = (prStats.top_level_paths[top] ?: 0) + 1;
                    }
                }

                prCtx.diffstat = prStats;
                totals.files_changed += prStats.files_changed;
                totals.lines_added += prStats.lines_added;
                totals.lines_removed += prStats.lines_removed;

                for(var k in prStats.top_level_paths){
                    totals.top_level_paths[k] = (totals.top_level_paths[k] ?: 0) + prStats.top_level_paths[k];
                }
            }

            if(shouldIncludeCommits){
                var commitValues = [];
                var cPage = 1;

                while(arrayLen(commitValues) LT Int(arguments.maxCommitsPerPR)){
                    var cStr = bb.listPullRequestCommits(
                        pullRequestId=pr.id,
                        page=cPage,
                        pagelen=Int(arguments.childPageLen),
                        fields=commitFields
                    );
                    if(!isSimpleValue(cStr) OR !isJSON(cStr)){
                        break;
                    }
                    var cs = deserializeJson(cStr);
                    if(!isStruct(cs) OR !structKeyExists(cs, "values") OR !isArray(cs.values) OR arrayLen(cs.values) EQ 0){
                        break;
                    }

                    for(var cv in cs.values){
                        arrayAppend(commitValues, {
                            hash = cv.hash ?: "",
                            date = cv.date ?: "",
                            message = cv.message ?: "",
                            author = cv.author?.user?.display_name ?: cv.author?.raw ?: ""
                        });
                        if(arrayLen(commitValues) GTE Int(arguments.maxCommitsPerPR)){
                            break;
                        }
                    }

                    if(!structKeyExists(cs, "next")){
                        break;
                    }
                    cPage++;
                }

                prCtx.commits = commitValues;
                prCtx.commit_count = arrayLen(commitValues);
            }

            arrayAppend(prContexts, prCtx);
        }

        var result = {
            workspace = Len(arguments.workspace) ? arguments.workspace : getEnv("BITBUCKET_WORKSPACE", ""),
            repoSlug = Len(arguments.repoSlug) ? arguments.repoSlug : getEnv("BITBUCKET_REPO_SLUG", ""),
            branch = arguments.branch,
            since = arguments.sinceISO,
            until = arguments.untilISO,
            mode = modeNorm,
            base = baseSha,
            head = headSha,
            totals = {
                pr_count = totals.pr_count,
                author_count = structCount(totals.unique_authors),
                files_changed = totals.files_changed,
                lines_added = totals.lines_added,
                lines_removed = totals.lines_removed,
                top_level_paths = totals.top_level_paths
            },
            pullrequests = prContexts
        };

        if(lCase(arguments.format) EQ "json-compact"){
            return serializeJson(result, true);
        }
        return serializeJson(result, false);
    }

    /**
     * List default reviewers.
     * Maps to GET /repositories/{workspace}/{repo_slug}/default-reviewers
     */
    public any function pullrequests_default_reviewers(
        numeric page=0,
        numeric pagelen=0,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .listDefaultReviewers(
                page=arguments.page,
                pagelen=arguments.pagelen
            );
    }


    /**
     * Returns the Diff text of a pull request
     *
     * @pullRequestId The id of the pull request
     */
    public any function getPullRequestDiff(
        numeric pullRequestId = 0,
        string outputPath="",
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        // For this function we need a pull request id
        var prId = arguments.pullRequestId ?: getEnv("BITBUCKET_PR_ID", "");

        var diffContent = createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken)
            .getPullRequestDiff(
                pullRequestId = prId
            );

        if(Len(arguments.outputPath)){
            var absOutputPath = getAbsolutePath(variables.cwd, arguments.outputPath);
            if(isStruct(diffContent) OR isArray(diffContent)){
                fileWrite(absOutputPath, serializeJson(diffContent));
            }
            else{
                fileWrite(absOutputPath, diffContent);
            }
        }

        return diffContent;
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
        
        var foundAnnotations = []
        
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
        if(Len(arguments.outputPath)){
                // Save to file
                var absOutputPath = getAbsolutePath(variables.cwd, outputPath);
                fileWrite(absOutputPath, serializeJson(foundAnnotations));
                return foundAnnotations;
        }

        return foundAnnotations;
    }



    public any function downloadPRFiles(
        numeric pullRequestId = 0,
        string downloadPath="",
        string workspace="",
        string repoSlug="",
        string authToken=""
    ) {
        var prId = arguments.pullRequestId ?: getEnv("BITBUCKET_PR_ID", "");
        var bb = createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken);

        var prFiles = bb.getPullRequestDiffStat(
            pullRequestId = prId,
            page = 1,
            pagelen = 100
        );

        // When BitbucketClient returns "bare JSON" (string), we need to deserialize
        // here because this helper iterates the diffstat response.
        if(isSimpleValue(prFiles) AND isJSON(prFiles)){
            prFiles = deserializeJson(prFiles);
        }

        if(!isStruct(prFiles) OR !structKeyExists(prFiles, "values") OR !isArray(prFiles.values)){
            throw("Unexpected diffstat response; expected JSON object with a 'values' array.");
        }

        var absDownloadPath = getAbsolutePath(variables.cwd, arguments.downloadPath);
       
        // Create download path if it doesn't exist
        if(!directoryExists(absDownloadPath)){
            directoryCreate(absDownloadPath, true);
        }

        var result = {
            downloaded = [],
            skipped = [],
            errors = []
        };

        for(var fileInfo in prFiles.values){

            var fileURL = fileInfo.new?.links?.self?.href;
            var filePath =  fileInfo?.new?.path;

            if(fileInfo.status EQ "removed"){
                arrayAppend(result.skipped, {
                    reason = "removed",
                    file = filePath,
                    url = fileURL
                });
                continue;
            }

            if(!Len(fileURL) OR !Len(filePath)){
                arrayAppend(result.skipped, {
                    reason = "missing url or path",
                    file = filePath,
                    url = fileURL,
                    info = fileInfo
                });
                continue;
            }
          
            try{
                bb.downloadFile(
                    fileURL = fileURL,
                    destinationPath = absDownloadPath & "/" & filePath
                );

                arrayAppend(result.downloaded, {
                    file = filePath,
                    url = fileURL,
                    path = absDownloadPath & "/" & filePath
                });
                
            }
            catch (any ex) {
                arrayAppend(result.errors, {
                    file = filePath,
                    url = fileURL,
                    message = ex.message
                });
            }
            
        }

        result.summary = "Downloaded " & arrayLen(result.downloaded) & " files to " & absDownloadPath;
        return result;
    }


    /**
     * posts a report to bitbuclet from a report formatted json file
     *
     * @commit the commit
     * @reportPath the path to the bitbucket report json file
     * @reportTitle the title of the report (optional) If not provided, will use the title from the report file
     */
    public any function postReport(
        required string commit, 
        required string reportPath, 
        required string reportID, 
        string title="",
        string details="",
        string workspace="",
        string repoSlug="",
        string authToken=""
    ) {
        var bb = createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken);

        var absReportPath = getAbsolutePath(variables.cwd, arguments.reportPath);
        var reportData = deserializeJson(fileRead(absReportPath));
        if(Len(title)){
            reportData.title = title;
        }
        if(Len(details)){
            reportData.details = details;
        }

        var response = bb.createReport(
            reportData = reportData,
            commit = commit,
            reportID = reportID
        );

        return response;

    }
   
    /**
     * adds annotations to a report
     *
     * @commit the commit
     * @annotationFile the path to the annotation file with a JSON array of annotations
     * @reportTitle the title of the report to add the annotations to
     */

    public any function postReportAnnotations(
        required string commit,
        required string annotationFile,
        required string reportId,
        string workspace="",
        string repoSlug="",
        string authToken=""
    ) {
        var bb = createClient(workspace=arguments.workspace, repoSlug=arguments.repoSlug, authToken=arguments.authToken);

        var absAnnotationPath = getAbsolutePath(variables.cwd, arguments.annotationFile);
        var annotations = deserializeJson(fileRead(absAnnotationPath));

        if(!annotations.len()){
            throw("No annotations found in file: #annotationFile#");
        }
        var annotationResponse = bb.createAnnotations(
            annotations = annotations,
            commit = commit,
            reportId = reportId
        );

        return annotationResponse;
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
