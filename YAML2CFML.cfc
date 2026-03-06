
/**
 * Reads a yaml file and returns a lucee structure
 */
component javasettings='{"maven":["org.yaml:snakeyaml:2.4"]}' {

    import org.yaml.snakeyaml.*;

    /**
     * Read a YAML file and return it as a lucee object
     *
     * @filePath 
     */
    public struct function read(filePath) {
        var yaml = new Yaml();
        return yaml.load(fileRead(arguments.filePath));
    }
    
}