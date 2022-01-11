package;

import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import sys.io.File;
import sys.FileSystem;

using StringTools;

@:build(haxe.ui.ComponentBuilder.build("assets/main-view.xml"))
class MainView extends VBox {
	public function new() {
		super();
		var mods:Array<ModData> = [];
		for (source in File.getContent('assets/sources.txt').split('\n')) {
			if (source.startsWith("local:")) {
				var file = source.substr(6);
				if (!FileSystem.exists(file)) {
					trace("Ignoring invalid source directive");
					continue;
				}
				mods = mods.concat(haxe.Json.parse(File.getContent(file)));
			} else {
				// Web URL
                tink.http.Client.fetch(source).all().handle((o) -> {
                    switch (o) {
                        case Success(data):
                            var theJson:Array<ModData> = haxe.Json.parse(data.body.toString());
                            mods = mods.concat(theJson);
                        case Failure(failure):
                            trace(failure);
                    }
                });
			}
		}
        trace(mods);
        for (mod in mods) {
            this.modlist.addMod(mod);
        }
	}
}
