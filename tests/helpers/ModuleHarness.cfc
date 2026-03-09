component extends="Module" {

    public any function showHelp(){
        return { help = true };
    }

    public any function test_public_action(
        string file="",
        string workspace="",
        string repoSlug="",
        string authToken=""
    ){
        return duplicate(arguments);
    }

    private any function hidden_action(
        string file=""
    ){
        return "hidden";
    }
}
