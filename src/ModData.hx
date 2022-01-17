package;

import haxe.display.Display.Package;
using StringTools;
typedef ModData = {
    var name:String;
    var author:String;
    var version:String;
    var download_url:String;
    var ?git_path:String;
    var group:String;
    var ?dependencies:Array<String>;
    var ?install_location:String;
}

class ModDataTools {
    public static function mangleName(name:String) { 
        return name.toLowerCase().trim().replace(" ", "_");
    }
    public static function fullyMangle(name:String) {
        var mangName = mangleName(name);
        var split = mangName.split("");
        var regexp = ~/[A-Za-z0-9_]/;
        for (i => char in split) {
            if (!regexp.match(char)) {
                split[i] = "_";
            }
        }
        return split.join("");
    }
}