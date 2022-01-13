package;

import haxe.ui.core.Screen;
import haxe.io.BytesInput;
import haxe.zip.Uncompress;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import haxe.ui.events.UIEvent;
import haxe.ui.containers.dialogs.Dialogs;
using StringTools;

@:build(haxe.ui.ComponentBuilder.build("assets/main-view.xml"))
class MainView extends VBox {
	public static var instance:MainView = null;
	public static var gorillaPath:String = null;
	public static var assetsPath:String = null;
	public static var existsZipCommand:Bool = false;
	public static var existsWget:Bool = false;
	public function new() {
		super();
		instance = this;
		this.monkePathDialog.monkePath.text = gorillaPath;
		var mods:Array<ModData> = [];
		for (source in File.getContent('$assetsPath/assets/sources.txt').split('\n')) {
			if (source.startsWith("local:")) {
				var file = Path.join([assetsPath, source.substr(6)]);
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
	}
	@:bind(installMods, MouseEvent.CLICK)
	public function doInstallMods(e:MouseEvent) {
		var goodMods = [];
		try {
			for (modItem in this.modlist.modItems()) {
				if (modItem.enabled.selected && (!VersionSaver.isLatestVersion(modItem.mod) || this.overwrite.selected))
					if (!doInstallMod(modItem.mod)) {
						trace("Failed to install mod: " + modItem.mod.name);
					} else {
						goodMods.push(modItem.mod);
					}
			}
		} catch (e) {
			trace(e);
		}
		VersionSaver.serialize(goodMods);
		
	}
	public function doInstallMod(mod:ModData):Bool {
		if (mod.download_url.startsWith("internal-runner:")) {
			var runner = mod.download_url.substr(16);
			switch (runner) {
				case "linux-bepinex":
					// Basically do what fixed my issues on Endeavour
					// 1. Install normal bepinex
					var failed = false;
					if (!doInstallMod({
						"name": "BepInEx",
						"author": "BepInEx Team",
						"version": "5.4.18",
						"group": "Core",
						"download_url": "https://github.com/BepInEx/BepInEx/releases/download/v5.4.18/BepInEx_x64_5.4.18.0.zip"
					  }))
					  return false;
					// 2. Download and overwrite with the magic files
					tink.http.Client.fetch('https://github.com/BepInEx/BepInEx/files/7323852/winhttp.zip').all().handle((o) -> {
						switch (o) {
							case Success(d): 
								unpackZip(d.body.toBytes());
							case Failure(e): 
								trace(e);
								failed = true;
						}
					});
					if (failed)
						return false;
					tink.http.Client.fetch('https://github.com/BepInEx/BepInEx/files/7357827/bepin4.zip').all().handle((o) -> {
						switch (o) {
							case Success(d): 
								unpackZip(d.body.toBytes());
							case Failure(e): 
								trace(e);
								failed = true;
						}
					});
					if (failed)
						return false;
					return true;
				case "wine-config": 
					if (Sys.systemName() == "Windows") {
						Dialogs.messageBox("Windows doesn't require wine configuration",'Info', 'info');
						return true;
					}
					if (Sys.command('which', ["protontricks"]) != 0) {
						Dialogs.messageBox("Protontricks must be installed", 'Error', 'error');
						return false;
					}	
					Dialogs.messageBox("Automated setup is not fully complete; you must add the winhttp proxy.\n In the new window switch to the libraries tab and type winhttp in the text field and click Add.\n Click OK to save the data.", 'Info', 'info');
					Sys.command('protontricks', ["1533390", "winecfg"]);
					
					return true;
				default:

					return false;
			}
		} else {
			try {
				downloadAndUnpack(mod);
			} catch (e) {
				return false;
			}
			return true;
		}
		return false;
		
	} 
	public static function unpackZip(zipFile:haxe.io.Bytes, ?installPath:String = ".") {
		if (!existsZipCommand) {
			for (entry in haxe.zip.Reader.readZip(new BytesInput(zipFile))) {
				if ((entry.data == null || entry.dataSize == 0 ) ) {
					// git in to it
					// ignore folders with no contents because fuck you
				} else {
					// Overwrite
					createPath(Path.directory(Path.join([gorillaPath, installPath, entry.fileName])));
					File.saveBytes(Path.join([gorillaPath, installPath, entry.fileName]), haxe.zip.Reader.unzip(entry));
				}
				
			}
		} else {
			var oldCwd = Sys.getCwd();
			File.saveBytes(Path.join([gorillaPath, installPath, "temp.zip"]), zipFile);
			Sys.setCwd(gorillaPath);
			Sys.command("unzip", ["-o", Path.join([gorillaPath, installPath, "temp.zip"])]);
			FileSystem.deleteFile(Path.join([gorillaPath, installPath, "temp.zip"]));
			Sys.setCwd(oldCwd);
		}
		
	}
	private static function downloadAndUnpack(mod:ModData) {
		if (existsWget && existsZipCommand) {
			var oldCwd = Sys.getCwd();
			Sys.setCwd(Path.join([gorillaPath, mod.install_location]));
			Sys.command("wget", [mod.download_url]);
			// good enough for C# good enough for me
			trace(Path.withoutDirectory(mod.download_url));
			Sys.command("unzip", ["-o", Path.withoutDirectory(mod.download_url)]);
			FileSystem.deleteFile(Path.withoutDirectory(mod.download_url));
			Sys.setCwd(oldCwd);
		} else {
			tink.http.Client.fetch(mod.download_url).all().handle((o) -> {
				switch (o) {
					case Success(d): 
						unpackZip(d.body.toBytes(), mod.install_location);
					case Failure(e): 
						throw e;
				}
			});
		}
		
	}
	private static function createPath(path:String) {
		if (!FileSystem.exists(Path.join([path, ".."]))) {
			createPath(Path.join([path, ".."]));
		}
		if (!FileSystem.exists(path)) {
			FileSystem.createDirectory(path);
		}
		
	}
	@:bind(monkePathDialog.monkePath, UIEvent.CHANGE)
	private function updatePath(_:UIEvent) {
		gorillaPath = this.monkePathDialog.monkePath.text;
	}
}
