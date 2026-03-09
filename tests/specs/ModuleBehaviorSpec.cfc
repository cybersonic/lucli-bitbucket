component extends="testbox.system.BaseSpec" {

    function run(){
        describe("Module behavior", function(){
            beforeEach(function(){
                variables.mod = new tests.helpers.ModuleHarness();
                variables.tmpDir = getTempDirectory() & "bitbucket-module-tests-" & replace(createUUID(), "-", "", "all");
                directoryCreate(variables.tmpDir, true);
            });

            afterEach(function(){
                if(directoryExists(variables.tmpDir)){
                    directoryDelete(variables.tmpDir, true);
                }
            });

            it("main dispatches only accepted arguments to the target public function", function(){
                var result = variables.mod.main(
                    action = "test_public_action",
                    file = "report.json",
                    reportId = "should-not-pass",
                    workspace = "workspace-a",
                    repoSlug = "repo-a",
                    authToken = "token-a"
                );

                expect(result.file).toBe("report.json");
                expect(result.workspace).toBe("workspace-a");
                expect(result.repoSlug).toBe("repo-a");
                expect(result.authToken).toBe("token-a");
                expect(structKeyExists(result, "reportId")).toBeFalse();
            });

            it("main rejects unknown and non-public actions", function(){
                expect(function(){
                    variables.mod.main(action = "does_not_exist");
                }).toThrow();

                expect(function(){
                    variables.mod.main(action = "hidden_action");
                }).toThrow();
            });

            it("main returns help when no action is provided", function(){
                var result = variables.mod.main();
                expect(result.help).toBeTrue();
            });

            it("main resolves public actions case-insensitively", function(){
                var result = variables.mod.main(
                    action = "TEST_PUBLIC_ACTION",
                    file = "case-insensitive.json"
                );

                expect(result.file).toBe("case-insensitive.json");
            });

            it("filterAnnotationsInDiff keeps only changed annotations and writes output", function(){
                var reportPath = variables.tmpDir & "/report.json";
                var diffPath = variables.tmpDir & "/changes.diff";
                var outputPath = variables.tmpDir & "/filtered.json";

                var reportData = {
                    annotations = [
                        {path = "/repo/src/a.cfm", line = 10, summary = "line10"},
                        {path = "/repo/src/a.cfm", line = 20, summary = "line20"},
                        {path = "/repo/src/a.cfm", line = 11, end_line = 12, summary = "range11to12"}
                    ]
                };

                fileWrite(reportPath, serializeJson(reportData));

                var diffLines = [
                    "diff --git a/src/a.cfm b/src/a.cfm",
                    "index 1111111..2222222 100644",
                    "--- a/src/a.cfm",
                    "+++ b/src/a.cfm",
                    "@@ -10,1 +10,2 @@",
                    "-old line",
                    "+new line",
                    "+another line"
                ];
                fileWrite(diffPath, arrayToList(diffLines, chr(10)));

                var filtered = variables.mod.filterAnnotationsInDiff(
                    reportPath = reportPath,
                    diffFilePath = diffPath,
                    rootPath = "/repo/",
                    outputPath = outputPath
                );

                expect(arrayLen(filtered)).toBe(2);
                expect(fileExists(outputPath)).toBeTrue();

                var summaries = filtered.map(function(item){
                    return item.summary;
                });

                expect(arrayContains(summaries, "line10")).toBeTrue();
                expect(arrayContains(summaries, "range11to12")).toBeTrue();
                expect(arrayContains(summaries, "line20")).toBeFalse();
            });

            it("filterAnnotationsInDiff supports multi-file diffs and removed lines", function(){
                var reportPath = variables.tmpDir & "/report-multi.json";
                var diffPath = variables.tmpDir & "/multi.diff";

                var reportData = {
                    annotations = [
                        { path = "/repo/src/a.cfm", line = 30, summary = "removedA" },
                        { path = "/repo/src/b.cfm", line = 5, summary = "addedB" },
                        { path = "/repo/src/c.cfm", line = 99, summary = "unrelatedC" }
                    ]
                };
                fileWrite(reportPath, serializeJson(reportData));

                var diffLines = [
                    "diff --git a/src/a.cfm b/src/a.cfm",
                    "index 1111111..2222222 100644",
                    "--- a/src/a.cfm",
                    "+++ b/src/a.cfm",
                    "@@ -30,1 +30,0 @@",
                    "-old line removed",
                    "diff --git a/src/b.cfm b/src/b.cfm",
                    "index 3333333..4444444 100644",
                    "--- a/src/b.cfm",
                    "+++ b/src/b.cfm",
                    "@@ -5,0 +5,1 @@",
                    "+new line added"
                ];
                fileWrite(diffPath, arrayToList(diffLines, chr(10)));

                var filtered = variables.mod.filterAnnotationsInDiff(
                    reportPath = reportPath,
                    diffFilePath = diffPath,
                    rootPath = "/repo/"
                );

                expect(arrayLen(filtered)).toBe(2);

                var summaries = filtered.map(function(item){
                    return item.summary;
                });

                expect(arrayContains(summaries, "removedA")).toBeTrue();
                expect(arrayContains(summaries, "addedB")).toBeTrue();
                expect(arrayContains(summaries, "unrelatedC")).toBeFalse();
            });
        });
    }
}
