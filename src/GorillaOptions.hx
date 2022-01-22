package;

import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;

typedef GorillaOptionData = {
    var enableBetas:Bool;
    var darkMode:Bool;
};
class GorillaOptions {
    private static var cache:GorillaOptionData = { enableBetas: false, darkMode: false};
    private static var updatedCache = false;
    public static var enableBetas(get, set):Bool;
    public static var darkMode(get, set):Bool;
    private static function updateCache() {
        if (FileSystem.exists(Path.join([GorillaPath.assetsPath, "options.json"]))) {
            cache = haxe.Json.parse(File.getContent(Path.join([GorillaPath.assetsPath, "options.json"])));
        } else {
            cache = {
                enableBetas : false,
                darkMode: false
            };
        }
        updatedCache = true;
    }
    private static function flush() {
        File.saveContent(Path.join([GorillaPath.assetsPath, "options.json"]), haxe.Json.stringify(cache));
    }

    public static function get_enableBetas() {
        if (!updatedCache)
            updateCache();
        return cache.enableBetas;
    }
    public static function set_enableBetas(value:Bool) {
        cache.enableBetas = value;
        flush();
        return value;
    }
    public static function get_darkMode() {
        if (!updatedCache)
            updateCache();
        return cache.darkMode;
    }
    public static function set_darkMode(value:Bool) {
        cache.darkMode = value;
        flush();
        return value;
    }
    
}