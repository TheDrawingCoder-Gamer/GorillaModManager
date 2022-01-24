package;

import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;

typedef GorillaOptionData = {
    var enableBetas:Bool;
    var darkMode:Bool;
    var path:String;
};
class GorillaOptions {
    private static var cache:GorillaOptionData = null;
    private static var updatedCache = false;
    public static var enableBetas(get, set):Bool;
    public static var darkMode(get, set):Bool;
    public static var path(get, set):String;
    private static function updateCache() {
        if (FileSystem.exists(Path.join([GorillaPath.assetsPath, "options.json"]))) {
            cache = haxe.Json.parse(File.getContent(Path.join([GorillaPath.assetsPath, "options.json"])));
        } else {
            cache = {
                enableBetas : false,
                darkMode: false,
                path: #if windows "C:\\Program Files\\Steam\\steamapps\\common\\Gorilla Tag"  #else Path.join([Sys.getEnv("HOME"), "/.local/share/Steam/steamapps/common/Gorilla Tag/"]) #end
            };
        }
        updatedCache = true;
    }
    private static function flush() {
        // Flushing the save data shouldn't be make or break
        // So use an async worker thread to save
        asys.io.File.saveContent(Path.join([GorillaPath.assetsPath, "options.json"]), haxe.Json.stringify(cache));
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
    public static function get_path() {
        if (!updatedCache)
            updateCache();
        return cache.path;
    }
    public static function set_path(value:String) {
        cache.path = value;
        flush();
        return value;
    }
    
}