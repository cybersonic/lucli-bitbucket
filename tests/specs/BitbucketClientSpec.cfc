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
        });
    }
}
