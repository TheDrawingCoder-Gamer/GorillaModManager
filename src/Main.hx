package ;

import haxe.ui.Toolkit;
import haxe.ui.HaxeUIApp;
import haxe.io.Path;
class Main {
    public static function main() {
        #if DEBUG
            #if openfl
            GorillaPath.assetsPath = Path.join([Sys.programPath(), "../../../../../"]);
            #else
            GorillaPath.assetsPath = Path.join([Sys.programPath(), "../../../"]);
            #end
        #else 
            GorillaPath.assetsPath = Path.directory(Sys.programPath());
        #end
        #if windows
            GorillaPath.gorillaPath = "C:\\Program Files\\Steam\\steamapps\\common\\Gorilla Tag";
        #else
            GorillaPath.gorillaPath = Path.join([Sys.getEnv("HOME"), "/.local/share/Steam/steamapps/common/Gorilla Tag/"]);
        #end
        Toolkit.theme = "bulby";
       VersionSaver.deserialize();
        var app = new HaxeUIApp();
        app.ready(function() {
            app.addComponent(new MainView());

            app.start();
        });
    }
}
