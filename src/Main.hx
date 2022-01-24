package ;

import haxe.ui.Toolkit;
import haxe.ui.HaxeUIApp;
import haxe.io.Path;
class Main {
    public static function main() {
        #if DEBUG
            #if heaps 
            GorillaPath.assetsPath = Path.join([Sys.programPath(), "../../../../assets"]);
            #else
            GorillaPath.assetsPath = Path.join([Sys.programPath(), "../../../assets"]);
            #end
        #else 
            #if js
            // Packaged vs. Unpackaged
            // Debug will never be packaged
            GorillaPath.assetsPath = Path.join([Sys.programPath(), "../../../assets"]);
            #else
            GorillaPath.assetsPath = Path.join([Sys.programPath(), "assets"]);
            #end
        #end
        
        #if hxwidgets
        Toolkit.theme = "bulby";
        #else
        Toolkit.theme = "bulbyelectron";
        #end
       VersionSaver.deserialize();
        var app = new HaxeUIApp();
        app.ready(function() {
            app.addComponent(new MainView());

            app.start();
        });
    }
}
