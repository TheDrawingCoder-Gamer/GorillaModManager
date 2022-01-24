package;

class GorillaPath {
    public static var gorillaPath(get, set):String;
    public static var assetsPath:String = "";
    static function get_gorillaPath() {
        return GorillaOptions.path;
    }
    static function set_gorillaPath(value:String) {
        return GorillaOptions.path = value;
    }
}