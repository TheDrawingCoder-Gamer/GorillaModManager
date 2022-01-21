package ;

import haxe.ui.Toolkit;
import haxe.ui.HaxeUIApp;
import haxe.io.Path;
class Main {
    public static function main() {
        #if DEBUG
            GorillaPath.assetsPath = Path.join([Sys.programPath(), "../../../assets"]);
        #else 
            GorillaPath.assetsPath = Path.directory(Path.join([Sys.programPath(), "assets"]));
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
