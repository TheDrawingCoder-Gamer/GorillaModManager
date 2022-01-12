package;

using StringTools;
typedef ModData = {
    var name:String;
    var author:String;
    var version:String;
    var downloadURL:String;
    var group:String;
}

class ModDataTools {
    public static function mangleName(name:String) { 
        return name.toLowerCase().trim().replace(" ", "-");
    }
}