package;

import haxe.macro.Context;
import interp.*;
import haxe.ds.ArraySort;
import tink.core.Error;
import tink.core.Future;
import tink.core.Promise;
import tink.core.Outcome;
import sys.io.File;
import haxe.io.Path;
import helpers.Util;
using Lambda;

enum NodeData {
    Mods(mods:Array<ModData>);
    Groups(groups:Array<Group>);
    Section(data:Array<NodeData>);
    NDNone;
}
typedef Group = {
    var name:String;
    var rank:Int;
}
@:await class XmlDeserializer {
    public static function deserialize():Promise<Array<ModData>> {
        return Future.irreversible((cb) -> {
            var file = File.getContent('${GorillaPath.assetsPath}/sources.xml');
            var xml:Xml = Xml.parse(file);
            var mods:Array<ModData> = [];
            var groups:Array<Group> = [];
            // anonymous functions can't recurse?
            var addData = function addData (daData:NodeData) { 
                switch (daData) {
                    case Mods(nodeMods):
                        for (mod in nodeMods) {
                            // Overwrite
                            mods = mods.filter((it) -> it.name != mod.name);
                        }
                        mods = mods.concat(nodeMods);
                    case Groups(nodeGroups):
                        groups = groups.concat(nodeGroups);
                    case Section(data):
                        for (nodeData in data) {
                            addData(nodeData);
                        }
                    case NDNone:
                }
            }
            var data = Promise.inSequence([for (element in xml.firstElement().elements()) processNode(element)]).handle((d) -> {
                switch (d) {
                    case Success(data):
                        for (nodedata in data) {
                            addData(nodedata);
                        }
                        groups.sort((x, y) -> x.rank - y.rank);
                        var groupsData:Array<{name:String, mods:Array<ModData>}> = [];
                        for (group in groups) {
                            var goodMods = mods.filter((it) -> it.group == group.name);
                            mods = mods.filter((it) -> it.group != group.name);
                            // stable sort because sanity
                            ArraySort.sort(goodMods, (x, y) -> x.name == y.name ? 0 : (x.name > y.name ? 1 : -1));
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
            try {
                var expr = new IfParser(element.get("unless")).parse();
                var eval = new Evaluator(expr);
                for (define => value in Defines.getDefines()) {
                    eval.defines.set(define, value);
                }
                #if windows 
                    eval.defines.set("platform", "windows");
                    eval.defines.set("windows", "1");
                #elseif mac
                    eval.defines.set("platform", "mac");
                    eval.defines.set("mac", "1");
                #elseif linux
                    eval.defines.set("platform", "linux");
                    eval.defines.set("linux", "1");
                #end
                var result =  Evaluator.isTruthy(eval.evaluate());
                if (result)
                    return false;
            } catch (e) {
                trace(e);
            }
        }
        if (element.get("if") != null) {
            try {
                var expr = new IfParser(element.get("if")).parse();
                var eval = new Evaluator(expr);
                for (define => value in Defines.getDefines()) {
                    eval.defines.set(define, value);
                }
                #if windows 
                    eval.defines.set("platform", "windows");
                    eval.defines.set("windows", "1");
                #elseif mac
                    eval.defines.set("platform", "mac");
                    eval.defines.set("mac", "1");
                #elseif linux
                    eval.defines.set("platform", "linux");
                    eval.defines.set("linux", "1");
                #end
                var result =  Evaluator.isTruthy(eval.evaluate());
                if (!result)
                    return false;
            } catch (e) {
                trace(e);
            }
        }
        return true;
    }
    @:async private static function processNode(node:Xml):NodeData {
        if (!isApplicable(node))
            return NDNone;
        switch (node.nodeName) {
            case "url": 
                var data:String = @:await Util.requestUrl(node.get("name"));
                var urlMods:Array<ModData> = haxe.Json.parse(data);
                for (remove in node.elementsNamed("remove")) {
                    if (!isApplicable(remove))
                        continue;
                    urlMods = urlMods.filter((it) -> it.name != remove.get("name"));
                }
                if (!GorillaOptions.enableBetas) 
                    urlMods = urlMods.filter(it -> !it.beta);
                return Mods(urlMods);
            case "asset": 
                var assetMods:Array<ModData> = haxe.Json.parse(File.getContent(Path.join([GorillaPath.assetsPath, node.get("name")])));
                for (remove in node.elementsNamed("remove")) {
                    if (!isApplicable(remove))
                        continue;
                    assetMods = assetMods.filter((it) -> it.name != remove.get("name"));
                }
                if (!GorillaOptions.enableBetas) 
                    assetMods = assetMods.filter(it -> !it.beta);
                return Mods(assetMods);

            case "groupurl":
                var data = @:await Util.requestUrl(node.get("name"));
                var groups:Array<Group> = haxe.Json.parse(data);
                return Groups(groups);

            case "groupasset": 
                var groups:Array<Group> = haxe.Json.parse(File.getContent(Path.join([GorillaPath.assetsPath, node.get("name")])));
                return Groups(groups);
            case "section": 
                var godArr = [];
                for (children in node.elements()) {
                    godArr.push(@:await processNode(children));
                }
                return Section(godArr);
            default: 
                return NDNone;
        }
        
    }
}