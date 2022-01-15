package ;

import haxe.ui.HaxeUIApp;
import haxe.io.Path;
class Main {
    public static function main() {
        #if DEBUG
            #if USING_OPENFL
            MainView.assetsPath = Path.join([Sys.programPath(), "../../../../../"]);
            #else 
               MainView.assetsPath = Path.join([Sys.programPath(), "../../../"]);
            #end
        #else 
            MainView.assetsPath = Path.directory(Sys.programPath());
        #end
        if (Sys.systemName() == "Windows") {
            MainView.gorillaPath = "C:\\Program Files\\Steam\\steamapps\\common\\Gorilla Tag";
        } else {
            MainView.gorillaPath = Path.join([Sys.getEnv("HOME"), "/.local/share/Steam/steamapps/common/Gorilla Tag/"]);
            // If there is a command named "unzip"
            #if !DISABLE_WGET_UNZIP
            if (Sys.command("which", ["unzip"]) == 0) {
                // Allow command usage because it's probably more optimized than haxe code
                MainView.existsZipCommand = true;
            }
            if (Sys.command("which", ["wget"]) == 0)
                MainView.existsWget = true;
            #end
        }
       VersionSaver.deserialize();
        var app = new HaxeUIApp();
        app.ready(function() {
            app.addComponent(new MainView());

            app.start();
        });
    }
}
