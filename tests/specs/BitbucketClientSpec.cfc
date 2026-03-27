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

            it("builds listPipelines and runPipeline calls with expected filters and payload", function(){
                variables.bb.listPipelines(
                    creatorUuid = "{user-1}",
                    targetRefType = "branch",
                    targetRefName = "main",
                    targetBranch = "main",
                    targetCommitHash = "abc123",
                    targetSelectorPattern = "default",
                    targetSelectorType = "custom",
                    createdOn = ">=2026-03-01T00:00:00Z",
                    triggerType = "MANUAL",
                    status = "COMPLETED",
                    sort = "-created_on",
                    page = 2,
                    pagelen = 25
                );
                var listCall = variables.bb.getLastCall();
                expect(listCall.path).toBe("repositories/workspaceA/repoA/pipelines");
                expect(listCall.method).toBe("GET");
                expect(listCall.data["creator.uuid"]).toBe("{user-1}");
                expect(listCall.data["target.ref_type"]).toBe("branch");
                expect(listCall.data["target.ref_name"]).toBe("main");
                expect(listCall.data["target.branch"]).toBe("main");
                expect(listCall.data["target.commit.hash"]).toBe("abc123");
                expect(listCall.data["target.selector.pattern"]).toBe("default");
                expect(listCall.data["target.selector.type"]).toBe("custom");
                expect(listCall.data.created_on).toBe(">=2026-03-01T00:00:00Z");
                expect(listCall.data.trigger_type).toBe("MANUAL");
                expect(listCall.data.status).toBe("COMPLETED");
                expect(listCall.data.sort).toBe("-created_on");
                expect(listCall.data.page).toBe(2);
                expect(listCall.data.pagelen).toBe(25);

                variables.bb.runPipeline(
                    pipelineData = {
                        target = {
                            type = "pipeline_ref_target",
                            ref_type = "branch",
                            ref_name = "main"
                        }
                    }
                );
                var runCall = variables.bb.getLastCall();
                expect(runCall.path).toBe("repositories/workspaceA/repoA/pipelines");
                expect(runCall.method).toBe("POST");
                expect(runCall.data.target.ref_name).toBe("main");
            });

            it("builds pipeline detail, step, logs, tests, and stop endpoint paths", function(){
                variables.bb.getPipeline(pipelineUuid = "{pipe-1}");
                var getCall = variables.bb.getLastCall();
                expect(getCall.path).toBe("repositories/workspaceA/repoA/pipelines/{pipe-1}");
                expect(getCall.method).toBe("GET");

                variables.bb.listPipelineSteps(pipelineUuid = "{pipe-1}");
                var stepsCall = variables.bb.getLastCall();
                expect(stepsCall.path).toBe("repositories/workspaceA/repoA/pipelines/{pipe-1}/steps");
                expect(stepsCall.method).toBe("GET");

                variables.bb.getPipelineStep(pipelineUuid = "{pipe-1}", stepUuid = "{step-1}");
                var stepCall = variables.bb.getLastCall();
                expect(stepCall.path).toBe("repositories/workspaceA/repoA/pipelines/{pipe-1}/steps/{step-1}");
                expect(stepCall.method).toBe("GET");

                variables.bb.getPipelineStepLog(pipelineUuid = "{pipe-1}", stepUuid = "{step-1}");
                var logCall = variables.bb.getLastCall();
                expect(logCall.path).toBe("repositories/workspaceA/repoA/pipelines/{pipe-1}/steps/{step-1}/log");
                expect(logCall.method).toBe("GET");

                variables.bb.getPipelineStepLogs(pipelineUuid = "{pipe-1}", stepUuid = "{step-1}", logUuid = "{log-1}");
                var logsCall = variables.bb.getLastCall();
                expect(logsCall.path).toBe("repositories/workspaceA/repoA/pipelines/{pipe-1}/steps/{step-1}/logs/{log-1}");
                expect(logsCall.method).toBe("GET");

                variables.bb.getPipelineStepTestReports(pipelineUuid = "{pipe-1}", stepUuid = "{step-1}");
                var reportsCall = variables.bb.getLastCall();
                expect(reportsCall.path).toBe("repositories/workspaceA/repoA/pipelines/{pipe-1}/steps/{step-1}/test_reports");
                expect(reportsCall.method).toBe("GET");

                variables.bb.getPipelineStepTestCases(pipelineUuid = "{pipe-1}", stepUuid = "{step-1}");
                var casesCall = variables.bb.getLastCall();
                expect(casesCall.path).toBe("repositories/workspaceA/repoA/pipelines/{pipe-1}/steps/{step-1}/test_reports/test_cases");
                expect(casesCall.method).toBe("GET");

                variables.bb.getPipelineStepTestCaseReasons(
                    pipelineUuid = "{pipe-1}",
                    stepUuid = "{step-1}",
                    testCaseUuid = "{case-1}"
                );
                var reasonsCall = variables.bb.getLastCall();
                expect(reasonsCall.path).toBe("repositories/workspaceA/repoA/pipelines/{pipe-1}/steps/{step-1}/test_reports/test_cases/{case-1}/test_case_reasons");
                expect(reasonsCall.method).toBe("GET");

                variables.bb.stopPipeline(pipelineUuid = "{pipe-1}");
                var stopCall = variables.bb.getLastCall();
                expect(stopCall.path).toBe("repositories/workspaceA/repoA/pipelines/{pipe-1}/stopPipeline");
                expect(stopCall.method).toBe("POST");
            });

            it("builds pipeline cache and runner endpoint paths", function(){
                variables.bb.listPipelineCaches();
                var listCachesCall = variables.bb.getLastCall();
                expect(listCachesCall.path).toBe("repositories/workspaceA/repoA/pipelines-config/caches");
                expect(listCachesCall.method).toBe("GET");

                variables.bb.deletePipelineCaches(name = "npm-cache");
                var deleteCachesCall = variables.bb.getLastCall();
                expect(deleteCachesCall.path).toBe("repositories/workspaceA/repoA/pipelines-config/caches");
                expect(deleteCachesCall.method).toBe("DELETE");
                expect(deleteCachesCall.data.name).toBe("npm-cache");

                variables.bb.deletePipelineCache(cacheUuid = "{cache-1}");
                var deleteCacheCall = variables.bb.getLastCall();
                expect(deleteCacheCall.path).toBe("repositories/workspaceA/repoA/pipelines-config/caches/{cache-1}");
                expect(deleteCacheCall.method).toBe("DELETE");

                variables.bb.getPipelineCacheContentUri(cacheUuid = "{cache-1}");
                var cacheUriCall = variables.bb.getLastCall();
                expect(cacheUriCall.path).toBe("repositories/workspaceA/repoA/pipelines-config/caches/{cache-1}/content-uri");
                expect(cacheUriCall.method).toBe("GET");

                variables.bb.listPipelineRunners();
                var listRunnersCall = variables.bb.getLastCall();
                expect(listRunnersCall.path).toBe("repositories/workspaceA/repoA/pipelines-config/runners");
                expect(listRunnersCall.method).toBe("GET");

                variables.bb.createPipelineRunner();
                var createRunnerCall = variables.bb.getLastCall();
                expect(createRunnerCall.path).toBe("repositories/workspaceA/repoA/pipelines-config/runners");
                expect(createRunnerCall.method).toBe("POST");

                variables.bb.getPipelineRunner(runnerUuid = "{runner-1}");
                var getRunnerCall = variables.bb.getLastCall();
                expect(getRunnerCall.path).toBe("repositories/workspaceA/repoA/pipelines-config/runners/{runner-1}");
                expect(getRunnerCall.method).toBe("GET");

                variables.bb.updatePipelineRunner(runnerUuid = "{runner-1}");
                var updateRunnerCall = variables.bb.getLastCall();
                expect(updateRunnerCall.path).toBe("repositories/workspaceA/repoA/pipelines-config/runners/{runner-1}");
                expect(updateRunnerCall.method).toBe("PUT");

                variables.bb.deletePipelineRunner(runnerUuid = "{runner-1}");
                var deleteRunnerCall = variables.bb.getLastCall();
                expect(deleteRunnerCall.path).toBe("repositories/workspaceA/repoA/pipelines-config/runners/{runner-1}");
                expect(deleteRunnerCall.method).toBe("DELETE");
            });

            it("builds pipelines config and schedule endpoint paths", function(){
                variables.bb.getPipelinesConfig();
                var getConfigCall = variables.bb.getLastCall();
                expect(getConfigCall.path).toBe("repositories/workspaceA/repoA/pipelines_config");
                expect(getConfigCall.method).toBe("GET");

                variables.bb.updatePipelinesConfig(configData = { enabled = true });
                var updateConfigCall = variables.bb.getLastCall();
                expect(updateConfigCall.path).toBe("repositories/workspaceA/repoA/pipelines_config");
                expect(updateConfigCall.method).toBe("PUT");
                expect(updateConfigCall.data.enabled).toBeTrue();

                variables.bb.updatePipelinesBuildNumber(buildNumberData = { next = 77 });
                var buildNumberCall = variables.bb.getLastCall();
                expect(buildNumberCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/build_number");
                expect(buildNumberCall.method).toBe("PUT");
                expect(buildNumberCall.data.next).toBe(77);

                variables.bb.listPipelineSchedules();
                var listSchedulesCall = variables.bb.getLastCall();
                expect(listSchedulesCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/schedules");
                expect(listSchedulesCall.method).toBe("GET");

                variables.bb.createPipelineSchedule(scheduleData = { type = "pipeline_schedule" });
                var createScheduleCall = variables.bb.getLastCall();
                expect(createScheduleCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/schedules");
                expect(createScheduleCall.method).toBe("POST");
                expect(createScheduleCall.data.type).toBe("pipeline_schedule");

                variables.bb.getPipelineSchedule(scheduleUuid = "{sched-1}");
                var getScheduleCall = variables.bb.getLastCall();
                expect(getScheduleCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/schedules/{sched-1}");
                expect(getScheduleCall.method).toBe("GET");

                variables.bb.updatePipelineSchedule(scheduleUuid = "{sched-1}", scheduleData = { enabled = true });
                var updateScheduleCall = variables.bb.getLastCall();
                expect(updateScheduleCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/schedules/{sched-1}");
                expect(updateScheduleCall.method).toBe("PUT");
                expect(updateScheduleCall.data.enabled).toBeTrue();

                variables.bb.deletePipelineSchedule(scheduleUuid = "{sched-1}");
                var deleteScheduleCall = variables.bb.getLastCall();
                expect(deleteScheduleCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/schedules/{sched-1}");
                expect(deleteScheduleCall.method).toBe("DELETE");

                variables.bb.listPipelineScheduleExecutions(scheduleUuid = "{sched-1}");
                var executionsCall = variables.bb.getLastCall();
                expect(executionsCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/schedules/{sched-1}/executions");
                expect(executionsCall.method).toBe("GET");
            });

            it("builds pipelines ssh, variables, and environment variables endpoint paths", function(){
                variables.bb.getPipelineSshKeyPair();
                var sshGetCall = variables.bb.getLastCall();
                expect(sshGetCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/ssh/key_pair");
                expect(sshGetCall.method).toBe("GET");

                variables.bb.updatePipelineSshKeyPair(keyPairData = { public_key = "ssh-rsa AAAA..." });
                var sshUpdateCall = variables.bb.getLastCall();
                expect(sshUpdateCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/ssh/key_pair");
                expect(sshUpdateCall.method).toBe("PUT");
                expect(sshUpdateCall.data.public_key).toBe("ssh-rsa AAAA...");

                variables.bb.deletePipelineSshKeyPair();
                var sshDeleteCall = variables.bb.getLastCall();
                expect(sshDeleteCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/ssh/key_pair");
                expect(sshDeleteCall.method).toBe("DELETE");

                variables.bb.listPipelineKnownHosts();
                var listKnownHostsCall = variables.bb.getLastCall();
                expect(listKnownHostsCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/ssh/known_hosts");
                expect(listKnownHostsCall.method).toBe("GET");

                variables.bb.createPipelineKnownHost(knownHostData = { hostname = "github.com", key_type = "rsa" });
                var createKnownHostCall = variables.bb.getLastCall();
                expect(createKnownHostCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/ssh/known_hosts");
                expect(createKnownHostCall.method).toBe("POST");
                expect(createKnownHostCall.data.hostname).toBe("github.com");

                variables.bb.getPipelineKnownHost(knownHostUuid = "{host-1}");
                var getKnownHostCall = variables.bb.getLastCall();
                expect(getKnownHostCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/ssh/known_hosts/{host-1}");
                expect(getKnownHostCall.method).toBe("GET");

                variables.bb.updatePipelineKnownHost(knownHostUuid = "{host-1}", knownHostData = { hostname = "bitbucket.org" });
                var updateKnownHostCall = variables.bb.getLastCall();
                expect(updateKnownHostCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/ssh/known_hosts/{host-1}");
                expect(updateKnownHostCall.method).toBe("PUT");
                expect(updateKnownHostCall.data.hostname).toBe("bitbucket.org");

                variables.bb.deletePipelineKnownHost(knownHostUuid = "{host-1}");
                var deleteKnownHostCall = variables.bb.getLastCall();
                expect(deleteKnownHostCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/ssh/known_hosts/{host-1}");
                expect(deleteKnownHostCall.method).toBe("DELETE");

                variables.bb.listPipelineVariables();
                var listVarsCall = variables.bb.getLastCall();
                expect(listVarsCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/variables");
                expect(listVarsCall.method).toBe("GET");

                variables.bb.createPipelineVariable(variableData = { key = "A", value = "1" });
                var createVarCall = variables.bb.getLastCall();
                expect(createVarCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/variables");
                expect(createVarCall.method).toBe("POST");
                expect(createVarCall.data.key).toBe("A");

                variables.bb.getPipelineVariable(variableUuid = "{var-1}");
                var getVarCall = variables.bb.getLastCall();
                expect(getVarCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/variables/{var-1}");
                expect(getVarCall.method).toBe("GET");

                variables.bb.updatePipelineVariable(variableUuid = "{var-1}", variableData = { value = "2" });
                var updateVarCall = variables.bb.getLastCall();
                expect(updateVarCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/variables/{var-1}");
                expect(updateVarCall.method).toBe("PUT");
                expect(updateVarCall.data.value).toBe("2");

                variables.bb.deletePipelineVariable(variableUuid = "{var-1}");
                var deleteVarCall = variables.bb.getLastCall();
                expect(deleteVarCall.path).toBe("repositories/workspaceA/repoA/pipelines_config/variables/{var-1}");
                expect(deleteVarCall.method).toBe("DELETE");

                variables.bb.listPipelineEnvironmentVariables(environmentUuid = "{env-1}");
                var listEnvVarsCall = variables.bb.getLastCall();
                expect(listEnvVarsCall.path).toBe("repositories/workspaceA/repoA/deployments_config/environments/{env-1}/variables");
                expect(listEnvVarsCall.method).toBe("GET");

                variables.bb.createPipelineEnvironmentVariable(
                    environmentUuid = "{env-1}",
                    variableData = { key = "B", value = "2", secured = false }
                );
                var createEnvVarCall = variables.bb.getLastCall();
                expect(createEnvVarCall.path).toBe("repositories/workspaceA/repoA/deployments_config/environments/{env-1}/variables");
                expect(createEnvVarCall.method).toBe("POST");
                expect(createEnvVarCall.data.key).toBe("B");

                variables.bb.updatePipelineEnvironmentVariable(
                    environmentUuid = "{env-1}",
                    variableUuid = "{envvar-1}",
                    variableData = { value = "3" }
                );
                var updateEnvVarCall = variables.bb.getLastCall();
                expect(updateEnvVarCall.path).toBe("repositories/workspaceA/repoA/deployments_config/environments/{env-1}/variables/{envvar-1}");
                expect(updateEnvVarCall.method).toBe("PUT");
                expect(updateEnvVarCall.data.value).toBe("3");

                variables.bb.deletePipelineEnvironmentVariable(
                    environmentUuid = "{env-1}",
                    variableUuid = "{envvar-1}"
                );
                var deleteEnvVarCall = variables.bb.getLastCall();
                expect(deleteEnvVarCall.path).toBe("repositories/workspaceA/repoA/deployments_config/environments/{env-1}/variables/{envvar-1}");
                expect(deleteEnvVarCall.method).toBe("DELETE");
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
