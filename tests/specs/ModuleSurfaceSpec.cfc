component extends="testbox.system.BaseSpec" {

    function run(){
        describe("Module command surface", function(){
            beforeEach(function(){
                variables.moduleSource = fileRead(expandPath("/Module.cfc"));
            });

            it("contains pull request command wrappers", function(){
                expect(findNoCase("public any function pullrequests(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function pullrequests_get(", variables.moduleSource) GT 0).toBeTrue();
            });

            it("pullrequests_comments exposes q/sort and forwards them to the client", function(){
                var fnStart = findNoCase("public any function pullrequests_comments(", variables.moduleSource);
                expect(fnStart GT 0).toBeTrue();

                var fnSlice = mid(variables.moduleSource, fnStart, 1200);
                expect(findNoCase("string q=", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("string sort=", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("q=arguments.q", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("sort=arguments.sort", fnSlice) GT 0).toBeTrue();
            });

            it("pullrequests_comments_save supports optional commentId for update-or-create behavior", function(){
                var fnStart = findNoCase("public any function pullrequests_comments_save(", variables.moduleSource);
                expect(fnStart GT 0).toBeTrue();
                var fnSlice = mid(variables.moduleSource, fnStart, 7000);
                expect(findNoCase("numeric commentId=0", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("string marker=", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("numeric scanPageLen=100", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("numeric maxScanPages=20", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("if(Int(arguments.commentId) GT 0)", fnSlice) GT 0).toBeTrue();
                expect(findNoCase(".listPullRequestComments(", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("findNoCase(markerValue", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("var legacyMarkerValue = ", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("findNoCase(legacyMarkerValue", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("compareNoCase(markerValue", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("marker string, not a boolean", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("commentData.content.raw = rawContent", fnSlice) GT 0).toBeTrue();
                expect(findNoCase(".updatePullRequestComment(", fnSlice) GT 0).toBeTrue();
                expect(findNoCase(".createPullRequestComment(", fnSlice) GT 0).toBeTrue();
            });

            it("contains reports list/get/create/delete wrappers", function(){
                expect(findNoCase("public any function reports(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function reports_get(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function reports_create(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function reports_delete(", variables.moduleSource) GT 0).toBeTrue();
            });

            it("contains pipelines command wrappers", function(){
                expect(findNoCase("public any function pipelines(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function pipelines_create(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function pipelines_get(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function pipelines_stop(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function pipelines_steps(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function pipelines_steps_get(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function pipelines_steps_log(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function pipelines_config(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function pipelines_config_caches(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function pipelines_config_runners(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function pipelines_config_schedules(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function pipelines_config_ssh_key_pair(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function pipelines_config_ssh_known_hosts(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function pipelines_config_variables(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function pipelines_environments_variables(", variables.moduleSource) GT 0).toBeTrue();
            });

            it("pipelines exposes filter parameters and forwards them to the client", function(){
                var fnStart = findNoCase("public any function pipelines(", variables.moduleSource);
                expect(fnStart GT 0).toBeTrue();

                var fnSlice = mid(variables.moduleSource, fnStart, 2600);
                expect(findNoCase("string creatorUuid=", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("string targetRefType=", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("string targetRefName=", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("string targetBranch=", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("string targetCommitHash=", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("string targetSelectorPattern=", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("string targetSelectorType=", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("string createdOn=", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("string triggerType=", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("creatorUuid=arguments.creatorUuid", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("targetRefType=arguments.targetRefType", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("targetRefName=arguments.targetRefName", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("targetBranch=arguments.targetBranch", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("targetCommitHash=arguments.targetCommitHash", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("targetSelectorPattern=arguments.targetSelectorPattern", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("targetSelectorType=arguments.targetSelectorType", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("createdOn=arguments.createdOn", fnSlice) GT 0).toBeTrue();
                expect(findNoCase("triggerType=arguments.triggerType", fnSlice) GT 0).toBeTrue();
            });

            it("contains reports annotations list/get/post/create/put/delete wrappers", function(){
                expect(findNoCase("public any function reports_annotations(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function reports_annotations_get(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function reports_annotations_post(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function reports_annotations_create(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function reports_annotations_put(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function reports_annotations_delete(", variables.moduleSource) GT 0).toBeTrue();
            });

            it("keeps backward compatible legacy report wrappers", function(){
                expect(findNoCase("public any function createReport(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function createAnnotations(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function postReport(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function postReportAnnotations(", variables.moduleSource) GT 0).toBeTrue();
            });

            it("keeps backward compatible legacy downloadFile wrapper", function(){
                expect(findNoCase("public any function downloadFile(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("required string fileURL", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("required string destinationPath", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("bb.downloadFile(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("fileURL=arguments.fileURL", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("absDownloadPath = getAbsolutePath(variables.cwd, arguments.destinationPath);", variables.moduleSource) GT 0).toBeTrue();
            });

            it("weeklyReleaseContext keeps full diff optional while preserving diffstat enrichment", function(){
                expect(findNoCase("public any function weeklyReleaseContext(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("boolean includeDiff=false", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("if(shouldIncludeDiff){", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("prCtx.diffstat = prStats;", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("prCtx.diff = bb.getPullRequestDiff(", variables.moduleSource) GT 0).toBeTrue();
            });
        });
    }
}
