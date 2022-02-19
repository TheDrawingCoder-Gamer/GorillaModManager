package;

import haxe.macro.Context;

class Defines {
    public static macro function getDefines() : haxe.macro.Expr {
        var defines : Map<String, String> = Context.getDefines();
        var map:Array<haxe.macro.Expr> = [];
        for (key in defines.keys()) {
            map.push(macro $v{key} => $v{Std.string(defines.get(key))});
        }
        return macro $a{map};
    }
}