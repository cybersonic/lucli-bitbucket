<cfscript>
/**
 * Stamps module.json with a CI-derived version.
 *
 * Environment variables (set by GitHub Actions):
 *   GITHUB_REF        – e.g. refs/tags/v1.2.0 or refs/heads/main
 *   GITHUB_REF_NAME   – e.g. v1.2.0 or main
 *   GITHUB_RUN_NUMBER – incremental build number
 *
 * Tagged builds  → strip leading "v" from tag  (v1.2.0 → 1.2.0)
 * Branch builds  → <base_version>-snapshot.<run_number>
 */

moduleJsonPath = expandPath("/module.json");
data           = deserializeJSON(fileRead(moduleJsonPath));
baseVersion    = data.version ?: "0.0.0";

ref       = server.system.environment.GITHUB_REF       ?: "";
refName   = server.system.environment.GITHUB_REF_NAME   ?: "";
runNumber = server.system.environment.GITHUB_RUN_NUMBER ?: "0";

if (ref.startsWith("refs/tags/")) {
    version = refName.startsWith("v") ? refName.mid(2, refName.len() - 1) : refName;
} else {
    version = "#baseVersion#-snapshot.#runNumber#";
}

data.version = version;
fileWrite(moduleJsonPath, serializeJSON(data));

systemOutput("module.json version set to #version#", true);
</cfscript>
