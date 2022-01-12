package;

import haxe.io.BytesInput;
import haxe.zip.Uncompress;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
using StringTools;

@:build(haxe.ui.ComponentBuilder.build("assets/main-view.xml"))
class MainView extends VBox {
	public static var instance:MainView = null;
	public static var gorillaPath:String = null;
	public static var assetsPath:String = null;
	public function new() {
		super();
		instance = this;
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
        for (mod in mods) {
            this.modlist.addMod(mod);
        }
        trace(this.modlist.groups.childComponents);
		trace(this.modlist.groups.childComponents[0].childComponents[1].childComponents);
	}
	@:bind(installMods, MouseEvent.CLICK)
	public function doInstallMods(e:MouseEvent) {

	}
	public function doInstallMod(mod:ModData):Bool {
		if (mod.downloadURL.startsWith("internal-runner:")) {
			var runner = mod.downloadURL.substr(16);
			switch (runner) {
				case "linux-bepinex":
					// Basically do what fixed my issues on Endeavour
					// 1. Install normal bepinex
					var failed = false;
					var zipFile:haxe.io.Bytes = null;
					tink.http.Client.fetch('https://github.com/BepInEx/BepInEx/releases/download/v5.4.18/BepInEx_x64_5.4.18.0.zip').all().handle((o) -> {
						switch (o) {
							case Success(data):
								zipFile = data.body.toBytes();
							case Failure(e):
								trace(e);
								failed = true;
								
						}
					});
					if (failed)
						return false;
					for (entry in haxe.zip.Reader.readZip(new BytesInput(zipFile))) {
						if (entry.data == null) {
							FileSystem.createDirectory(entry.fileName);
						} else
							File.saveBytes(entry.fileName, haxe.zip.Reader.unzip(entry));
					}
					// 2. Download and overwrite with the magic files

					return true;
				case "wine-config": 
					return true;
				default:

					return false;
			}
		}
		return false;
	} 
}
