package;

import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import ModData;
typedef SerializedData = {
    var structure:Array<String>; 
    var version:String;
};
typedef ModInfo = {
    > SerializedData, 
    var name:String;
}
class VersionSaver {
    static var mods:Dynamic<SerializedData> = {};
    public static function addMod(modName:String, modVersion:String, info:Array<String>) {
        Reflect.setField(mods, ModDataTools.fullyMangle(modName), { structure: info, version: modVersion});
    }
    public static function removeMod(mod:ModData) {
        Reflect.deleteField(mods, ModDataTools.fullyMangle(mod.name));
    }
    public static function flush() {
        File.saveContent(Path.join([GorillaPath.gorillaPath, "GMMv2-Version.json"]), haxe.Json.stringify(mods));
    }
    public static function serialize(modInfos:Array<ModInfo>) {
        for (modInfo in modInfos) {
            addMod(modInfo.name, modInfo.version, modInfo.structure);
        }
        flush();
    }
    public static function deserialize() {
        if (FileSystem.exists(Path.join([GorillaPath.gorillaPath, "GMMv2-Version.json"])))
            mods = haxe.Json.parse(File.getContent(Path.join([GorillaPath.gorillaPath, "GMMv2-Version.json"])));
        else 
            mods = {};
    }
    public static function isLatestVersion(mod:ModData) {
        var name = ModDataTools.fullyMangle(mod.name);
        if (!Reflect.hasField(mods, name))
            return false;
        if (Reflect.field(mods, name).version != mod.version) 
            return false;
        return true;
    }
    public static function entries(mod:String):Array<String> {
        var name = ModDataTools.fullyMangle(mod);
        if (!Reflect.hasField(mods, name))
            return null;
        return Reflect.field(mods, name).structure;
    }
}