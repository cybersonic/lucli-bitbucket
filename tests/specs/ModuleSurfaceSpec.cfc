component extends="testbox.system.BaseSpec" {

    function run(){
        describe("Module command surface", function(){
            beforeEach(function(){
                variables.moduleSource = fileRead(expandPath("/Module.cfc"));
            });

            it("contains the pullrequests command wrapper", function(){
                expect(
                    reFindNoCase(
                        "public\s+any\s+function\s+pullrequests\s*\(",
                        variables.moduleSource
                    ) GT 0
                ).toBeTrue();
            });

            it("contains pullrequests_get with workspace/repo/auth overrides", function(){
                expect(
                    reFindNoCase(
                        'public\s+any\s+function\s+pullrequests_get\s*\(\s*required\s+numeric\s+pullRequestId\s*,\s*string\s+workspace\s*=\s*""\s*,\s*string\s+repoSlug\s*=\s*""\s*,\s*string\s+authToken\s*=\s*""',
                        variables.moduleSource
                    ) GT 0
                ).toBeTrue();
            });

            it("keeps backward compatible createReport wrapper as public command", function(){
                expect(
                    reFindNoCase(
                        "public\s+any\s+function\s+createReport\s*\(",
                        variables.moduleSource
                    ) GT 0
                ).toBeTrue();
            });
        });
    }
}
