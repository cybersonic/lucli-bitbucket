component extends="testbox.system.BaseSpec" {

    function run(){
        describe("BitbucketClient endpoint wrappers", function(){
            beforeEach(function(){
                variables.bb = new tests.helpers.FakeBitbucketClient(
                    workspace = "workspaceA",
                    repoSlug = "repoA",
                    authToken = "tokenA"
                );
            });

            it("builds listPullRequests call with expected query parameters", function(){
                variables.bb.listPullRequests(
                    state = "MERGED",
                    q = "destination.branch.name=""main""",
                    sort = "-closed_on",
                    page = 2,
                    pagelen = 50
                );

                var call = variables.bb.getLastCall();
                expect(call.path).toBe("repositories/workspaceA/repoA/pullrequests");
                expect(call.method).toBe("GET");
                expect(call.data.state).toBe("MERGED");
                expect(call.data.q).toBe('destination.branch.name="main"');
                expect(call.data.sort).toBe("-closed_on");
                expect(call.data.page).toBe(2);
                expect(call.data.pagelen).toBe(50);
            });

            it("builds listPullRequestComments call with expected query parameters", function(){
                variables.bb.listPullRequestComments(
                    pullRequestId = 123,
                    q = "deleted=false AND inline.path=""src/main.cfc""",
                    sort = "-created_on",
                    page = 2,
                    pagelen = 30
                );

                var call = variables.bb.getLastCall();
                expect(call.path).toBe("repositories/workspaceA/repoA/pullrequests/123/comments");
                expect(call.method).toBe("GET");
                expect(call.data.q).toBe('deleted=false AND inline.path="src/main.cfc"');
                expect(call.data.sort).toBe("-created_on");
                expect(call.data.page).toBe(2);
                expect(call.data.pagelen).toBe(30);
            });

            it("builds patch endpoint path for pullrequests_patch support", function(){
                variables.bb.getPullRequestPatch(pullRequestId = 42);
                var call = variables.bb.getLastCall();

                expect(call.path).toBe("repositories/workspaceA/repoA/pullrequests/42/patch");
                expect(call.method).toBe("GET");
            });

            it("sends create pull request payload via POST", function(){
                var payload = {
                    title = "Example PR",
                    source = { branch = { name = "feature/testbox" } },
                    destination = { branch = { name = "main" } }
                };

                variables.bb.createPullRequest(pullRequestData = payload);
                var call = variables.bb.getLastCall();

                expect(call.path).toBe("repositories/workspaceA/repoA/pullrequests");
                expect(call.method).toBe("POST");
                expect(call.data.title).toBe("Example PR");
            });
            it("builds reports endpoint paths for list/get/delete", function(){
                variables.bb.listReports(commit = "abc123", page = 2, pagelen = 50);
                var listCall = variables.bb.getLastCall();
                expect(listCall.path).toBe("repositories/workspaceA/repoA/commit/abc123/reports");
                expect(listCall.method).toBe("GET");
                expect(listCall.data.page).toBe(2);
                expect(listCall.data.pagelen).toBe(50);

                variables.bb.getReport(commit = "abc123", reportId = "lint");
                var getCall = variables.bb.getLastCall();
                expect(getCall.path).toBe("repositories/workspaceA/repoA/commit/abc123/reports/lint");
                expect(getCall.method).toBe("GET");

                variables.bb.deleteReport(commit = "abc123", reportId = "lint");
                var deleteCall = variables.bb.getLastCall();
                expect(deleteCall.path).toBe("repositories/workspaceA/repoA/commit/abc123/reports/lint");
                expect(deleteCall.method).toBe("DELETE");
            });

            it("builds report annotation endpoint paths for list/get/put/delete", function(){
                variables.bb.listReportAnnotations(commit = "abc123", reportId = "lint", page = 1, pagelen = 100);
                var listCall = variables.bb.getLastCall();
                expect(listCall.path).toBe("repositories/workspaceA/repoA/commit/abc123/reports/lint/annotations");
                expect(listCall.method).toBe("GET");
                expect(listCall.data.page).toBe(1);
                expect(listCall.data.pagelen).toBe(100);

                variables.bb.getReportAnnotation(commit = "abc123", reportId = "lint", annotationId = "a-1");
                var getCall = variables.bb.getLastCall();
                expect(getCall.path).toBe("repositories/workspaceA/repoA/commit/abc123/reports/lint/annotations/a-1");
                expect(getCall.method).toBe("GET");

                variables.bb.putReportAnnotation(
                    commit = "abc123",
                    reportId = "lint",
                    annotationId = "a-1",
                    annotationData = { severity = "MEDIUM", message = "updated" }
                );
                var putCall = variables.bb.getLastCall();
                expect(putCall.path).toBe("repositories/workspaceA/repoA/commit/abc123/reports/lint/annotations/a-1");
                expect(putCall.method).toBe("PUT");
                expect(putCall.data.severity).toBe("MEDIUM");

                variables.bb.deleteReportAnnotation(commit = "abc123", reportId = "lint", annotationId = "a-1");
                var deleteCall = variables.bb.getLastCall();
                expect(deleteCall.path).toBe("repositories/workspaceA/repoA/commit/abc123/reports/lint/annotations/a-1");
                expect(deleteCall.method).toBe("DELETE");
            });

            it("uses bearer authorization by default when auth user is not provided", function(){
                expect(variables.bb.getAuthMode()).toBe("bearer");
                expect(variables.bb.getAuthorizationHeader()).toBe("Bearer tokenA");
            });

            it("uses basic authorization when auth user is provided", function(){
                var personalClient = new BitbucketClient(
                    workspace = "workspaceA",
                    repoSlug = "repoA",
                    authToken = "tokenA",
                    authUser = "person@example.com"
                );

                expect(personalClient.getAuthMode()).toBe("basic_api_token");
                expect(personalClient.getAuthorizationHeader()).toBe(
                    "Basic " & toBase64("person@example.com:tokenA")
                );
            });

            it("rejects basic auth user values that are not valid emails", function(){
                var personalClient = new BitbucketClient(
                    workspace = "workspaceA",
                    repoSlug = "repoA",
                    authToken = "tokenA",
                    authUser = "person"
                );

                expect(function(){
                    personalClient.getAuthorizationHeader();
                }).toThrow();
            });
        });
    }
}
