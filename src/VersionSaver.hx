package;

import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import ModData;

class VersionSaver {
    static var mods:Dynamic<String> = {};
    public static function serialize(theMods:Array<ModData>) {
        for (mod in theMods) {
            Reflect.setField(mods, ModDataTools.fullyMangle(mod.name), mod.version);
        }
        File.saveContent(Path.join([GorillaPath.gorillaPath, "GMM-Version.json"]), haxe.Json.stringify(mods));
    }
    public static function deserialize() {
        if (FileSystem.exists(Path.join([GorillaPath.gorillaPath, "GMM-Version.json"])))
            mods = haxe.Json.parse(File.getContent(Path.join([GorillaPath.gorillaPath, "GMM-Version.json"])));
        else 
            mods = {};
    }
    public static function isLatestVersion(mod:ModData) {
        var name = ModDataTools.fullyMangle(mod.name);
        if (!Reflect.hasField(mods, name))
            return false;
        if (Reflect.field(mods, name) != mod.version) 
            return false;
        return true;
    }
}