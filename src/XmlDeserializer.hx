package;

import sys.io.File;

enum SourceKind {
    Url(url:String);
    Asset(name:String);
}
class XmlDeserializer {
    public static function deserialize() {
        var file = File.getContent('${MainView.assetsPath}/assets/sources.xml');
        var xml:Xml = Xml.parse(file);
        var sources:Array<SourceKind> = [];
        sources = sources.concat(modsOfElement(xml.firstChild()));
        return sources;
    }
    private static function modsOfElement(element:Xml) {
        var sources = [];
        for (child in element.elements()) {
            if (child.get("unless") != null) {
                switch (child.get("unless")) {
                    case "windows": 
                        if (Sys.systemName() == "Windows") 
                            continue;
                    case "mac": 
                        if (Sys.systemName() == "Mac") 
                            continue;
                    case "linux": 
                        if (Sys.systemName() == "Linux")
                            continue;
                }
            }
            if (child.get("if") != null) {
                switch (child.get("if")) {
                    case "windows": 
                        if (Sys.systemName() != "Windows") 
                            continue;
                    case "mac": 
                        if (Sys.systemName() != "Mac") 
                            continue;
                    case "linux": 
                        if (Sys.systemName() != "Linux")
                            continue;
                }
            }
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