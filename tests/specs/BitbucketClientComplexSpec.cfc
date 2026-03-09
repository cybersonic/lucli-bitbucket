component extends="testbox.system.BaseSpec" {

    function run(){
        describe("BitbucketClient complex behavior", function(){
            beforeEach(function(){
                variables.bb = new tests.helpers.FakeBitbucketClient(
                    workspace = "workspaceA",
                    repoSlug = "repoA",
                    authToken = "tokenA"
                );
                variables.tmpDir = getTempDirectory() & "bitbucket-client-tests-" & replace(createUUID(), "-", "", "all");
                directoryCreate(variables.tmpDir, true);
            });

            afterEach(function(){
                if(directoryExists(variables.tmpDir)){
                    directoryDelete(variables.tmpDir, true);
                }
            });

            it("createAnnotations truncates long summaries and generates external_id values", function(){
                var annotations = [
                    { summary = repeatString("a", 500), path = "src/a.cfm", line = 10 },
                    { summary = "short", path = "src/b.cfm", line = 11 }
                ];

                variables.bb.createAnnotations(
                    annotations = annotations,
                    commit = "abc123",
                    reportId = "lint"
                );

                var call = variables.bb.getLastCall();

                expect(call.path).toBe("repositories/workspaceA/repoA/commit/abc123/reports/lint/annotations");
                expect(call.method).toBe("POST");
                expect(len(call.data[1].summary)).toBe(450);
                expect(right(call.data[1].summary, 3)).toBe("...");
                expect(call.data[1].external_id).toBe("lint_001");
                expect(call.data[2].external_id).toBe("lint_002");
            });

            it("createAnnotations preserves explicit external_id values", function(){
                var annotations = [
                    { summary = "short", path = "src/a.cfm", line = 10, external_id = "explicit-123" }
                ];

                variables.bb.createAnnotations(
                    annotations = annotations,
                    commit = "abc123",
                    reportId = "lint"
                );

                var call = variables.bb.getLastCall();
                expect(call.data[1].external_id).toBe("explicit-123");
            });

            it("createReport derives reportId from title when omitted", function(){
                variables.bb.createReport(
                    reportData = { title = "My Report Name", details = "details" },
                    commit = "abc123"
                );

                var call = variables.bb.getLastCall();
                expect(call.path).toBe("repositories/workspaceA/repoA/commit/abc123/reports/my_report_name");
                expect(call.method).toBe("PUT");
                expect(call.data.title).toBe("My Report Name");
            });

            it("createReport throws when reportId is omitted and title is empty", function(){
                expect(function(){
                    variables.bb.createReport(
                        reportData = {},
                        commit = "abc123"
                    );
                }).toThrow();
            });

            it("downloadFile requests raw content and writes destination path", function(){
                var destinationPath = variables.tmpDir & "/nested/path/file.json";

                var result = variables.bb.downloadFile(
                    fileURL = "https://example.com/raw/file.json",
                    destinationPath = destinationPath
                );

                var call = variables.bb.getLastCall();
                expect(call.path).toBe("https://example.com/raw/file.json");
                expect(call.overrideURL).toBeTrue();
                expect(call.parseResponse).toBeFalse();
                expect(fileExists(destinationPath)).toBeTrue();
                expect(fileRead(destinationPath)).toBe(result);
            });
        });
    }
}
