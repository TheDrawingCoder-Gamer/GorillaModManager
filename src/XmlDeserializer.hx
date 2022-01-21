package;

import tink.core.Error;
import tink.core.Future;
import tink.core.Promise;
import tink.core.Outcome;
import sys.io.File;
import haxe.io.Path;
import helpers.Util;
using Lambda;
enum SourceKind {
    Url(url:String);
    Asset(name:String);
}
enum NodeData {
    Mods(mods:Array<ModData>);
    Groups(groups:Array<Group>);
    NDNone;
}
typedef Group = {
    var name:String;
    var rank:Int;
}
class XmlDeserializer {
    public static function deserialize():Promise<Array<ModData>> {
        return cast Future.irreversible((cb) -> {
            var file = File.getContent('${GorillaPath.assetsPath}/sources.xml');
            var xml:Xml = Xml.parse(file);
            var mods:Array<ModData> = [];
            var groups:Array<Group> = [];
            var promises = Promise.inSequence([for (element in xml.firstElement().elements()) processNode(element)]);
            promises.handle((d) -> {
                switch (d) {
                    case Success(data):
                        for (nodedata in data) {
                            switch (nodedata) {
                                case Mods(nodeMods):
                                    for (mod in nodeMods) {
                                        // Overwrite
                                        mods = mods.filter((it) -> it.name != mod.name);
                                    }
                                    mods = mods.concat(nodeMods);
                                case Groups(nodeGroups):
                                    groups = groups.concat(nodeGroups);
                                case NDNone:
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
                        
                        cb(Success(groupsData.flatMap((it) -> it.mods)));
                    case Failure(failure):
                        cb(Failure(failure));
                }
            });
            
        });
        
    }
    private static function isApplicable(element:Xml) {
        if (element.get("unless") != null) {
            switch (element.get("unless")) {
                case "windows": 
                    #if windows
                        return false;
                    #end
                case "mac": 
                    #if mac 
                        return false;
                    #end
                case "linux": 
                    #if linux
                        return false;
                    #end
            }
        }
        if (element.get("if") != null) {
            switch (element.get("if")) {
                case "windows": 
                    #if windows
                        return false;
                    #end
                case "mac": 
                    #if mac 
                        return false;
                    #end
                case "linux": 
                    #if linux
                        return false;
                    #end
            }
        }
        return true;
    }
    private static function processNode(node:Xml):Promise<NodeData> {
        return cast Future.irreversible((cb) -> {
            switch (node.nodeName) {
                case "url": 
                    Util.requestUrl(node.get("name")).handle((d) -> {
                        switch (d) {
                            case Success(data):
                                var urlMods:Array<ModData> = haxe.Json.parse(data);
                                for (remove in node.elementsNamed("remove")) {
                                    if (!isApplicable(remove))
                                        continue;
                                    urlMods = urlMods.filter((it) -> it.name != remove.get("name"));
                                }
                                if (!GorillaOptions.enableBetas) 
                                    urlMods = urlMods.filter(it -> !it.beta);
                                cb(Success(Mods(urlMods)));
                                
                            case Failure(e ):
                                cb(Failure(e));
                        }
                    });
                case "asset": 
                    try {
                        var assetMods:Array<ModData> = haxe.Json.parse(File.getContent(Path.join([GorillaPath.assetsPath, node.get("name")])));
                        for (remove in node.elementsNamed("remove")) {
                            if (!isApplicable(remove))
                                continue;
                            assetMods = assetMods.filter((it) -> it.name != remove.get("name"));
                        }
                        if (!GorillaOptions.enableBetas) 
                            assetMods = assetMods.filter(it -> !it.beta);
                        cb(Success(Mods(assetMods)));
                    } catch (e) {
                        cb(Failure(Error.asError(e)));
                    }
                case "groupurl":
                    Util.requestUrl(node.get("name")).handle((d) -> {
                        switch (d) {
                            case Success(data):
                                var groups:Array<Group> = haxe.Json.parse(data);
                                cb(Success(Groups(groups)));
                                
                            case Failure(e ):
                                cb(Failure(e));
                        }
                    });
                case "groupasset": 
                    try {
                        var groups:Array<Group> = haxe.Json.parse(File.getContent(Path.join([GorillaPath.assetsPath, node.get("name")])));
                        cb(Success(Groups(groups)));
                    } catch (e) {
                        cb(Failure(Error.asError(e)));
                    }
                default: 
                    cb(Success(NDNone));
            }
        });
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