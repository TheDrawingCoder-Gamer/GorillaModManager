package;

import sys.io.File;
import haxe.io.Path;
using Lambda;
enum SourceKind {
    Url(url:String);
    Asset(name:String);
}
typedef Group = {
    var name:String;
    var rank:Int;
}
class XmlDeserializer {
    public static function deserialize() {
        var file = File.getContent('${GorillaPath.assetsPath}/assets/sources.xml');
        var xml:Xml = Xml.parse(file);
        var mods:Array<ModData> = [];
        var groups:Array<Group> = [];
        for (element in xml.firstElement().elements()) {
            if (!isApplicable(element))
                continue;
            switch (element.nodeName) {
                case "url": 
                    var urlMods:Array<ModData> = haxe.Json.parse(sys.Http.requestUrl(element.get("name")));
                    for (remove in element.elements()) {
                        if (remove.nodeName != "remove" || !isApplicable(remove))
                            continue;
                        urlMods = urlMods.filter((it) -> it.name != remove.get('name'));
                    }
                    for (mod in urlMods) {
                        // Overwrite
                        mods = mods.filter((it) -> it.name != mod.name);
                    }
                    mods = mods.concat(urlMods);
                case "asset": 
                    var assetMods:Array<ModData> = haxe.Json.parse(File.getContent(Path.join([GorillaPath.assetsPath, "assets", element.get('name')])));
                    for (remove in element.elements()) {
                        if (remove.nodeName != "remove" || !isApplicable(remove))
                            continue;
                        assetMods = assetMods.filter((it) -> it.name != remove.get('name'));
                    }
                    for (mod in assetMods) {
                        // Overwrite
                        mods = mods.filter((it) -> it.name != mod.name);
                    }
                    mods = mods.concat(assetMods);
                case "groupurl": 
                    groups = groups.concat(haxe.Json.parse(sys.Http.requestUrl(element.get("name"))));
                    // to do sorting?
                case "groupasset": 
                    groups = groups.concat(haxe.Json.parse(File.getContent(Path.join([GorillaPath.assetsPath, "assets", element.get("name")]))));
            }
        }
        groups.sort((x, y) -> x.rank - y.rank);
        var groupsData:Array<{name:String, mods:Array<ModData>}> = [];
        for (group in groups) {
            var goodMods = mods.filter((it) -> it.group == group.name);
            mods = mods.filter((it) -> it.group != group.name);
            groupsData.push({name: group.name, mods: goodMods});
        }
        groupsData.push({name: "GMM::Unknown", mods: mods});
        
        return groupsData.flatMap((it) -> it.mods);
    }
    private static function isApplicable(element:Xml) {
        if (element.get("unless") != null) {
            switch (element.get("unless")) {
                case "windows": 
                    if (Sys.systemName() == "Windows") 
                        return false;
                case "mac": 
                    if (Sys.systemName() == "Mac") 
                        return false;
                case "linux": 
                    if (Sys.systemName() == "Linux")
                        return false;
            }
        }
        if (element.get("if") != null) {
            switch (element.get("if")) {
                case "windows": 
                    if (Sys.systemName() != "Windows") 
                        return false;
                case "mac": 
                    if (Sys.systemName() != "Mac") 
                        return false;
                case "linux": 
                    if (Sys.systemName() != "Linux")
                        return false;
            }
        }
        return true;
    }
    private static function modsOfElement(element:Xml) {
        var sources = [];
        for (child in element.elements()) {
            if (!isApplicable(child))
                continue;
            trace(child.nodeName);
            switch (child.nodeName) {
                case "url": 
                    sources.push(Url(child.get("name")));
                case "asset": 
                    sources.push(Asset(child.get("name")));
                default: 
                    trace("WARNING: INVALID XML! Ignoring  :)");
            }
        }
        return sources;
    }
}