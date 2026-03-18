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

            it("contains reports list/get/create/delete wrappers", function(){
                expect(findNoCase("public any function reports(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function reports_get(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function reports_create(", variables.moduleSource) GT 0).toBeTrue();
                expect(findNoCase("public any function reports_delete(", variables.moduleSource) GT 0).toBeTrue();
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
