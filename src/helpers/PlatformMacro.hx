package helpers;

import haxe.macro.Compiler;
#if macro
class PlatformMacro {
    public static function definePlatform() {
        switch (Sys.systemName()) {
            case "Windows": 
                Compiler.define("windows");
            case "Mac":
                Compiler.define("mac");
            case "Linux" | "BSD": 
                Compiler.define("linux");
        }
    }
}
#end