package ;

import haxe.ui.HaxeUIApp;
import haxe.io.Path;
class Main {
    public static function main() {
        #if DEBUG
            MainView.assetsPath = Path.join([Sys.programPath(), "../../"]);
        #else 
            MainView.assetsPath = Sys.programPath();
        #end
        var app = new HaxeUIApp();
        app.ready(function() {
            app.addComponent(new MainView());

            app.start();
        });
    }
}
