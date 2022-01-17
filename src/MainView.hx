package;

import haxe.ui.containers.dialogs.Dialog;
import haxe.io.Bytes;
import haxe.ui.core.Screen;
import haxe.io.BytesInput;
import haxe.zip.Uncompress;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import sys.io.File;
import sys.FileSystem;
using haxe.io.Path;
import haxe.ui.events.UIEvent;
import haxe.ui.containers.dialogs.Dialogs;
using StringTools;

@:build(haxe.ui.ComponentBuilder.build("assets/main-view.xml"))
class MainView extends VBox {
	public static var instance:MainView = null;
	public static var existsZipCommand:Bool = false;
	public static var existsWget:Bool = false;
	public function new() {
		super();
		instance = this;
		this.monkePathDialog.monkePath.text = GorillaPath.gorillaPath;
		var mods:Array<ModData> = XmlDeserializer.deserialize();
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
					if (!doInstallMod({
						"name": "BepInEx",
						"author": "BepInEx Team",
						"version": "5.4.18",
						"group": "Core",
						"download_url": "https://github.com/BepInEx/BepInEx/releases/download/v5.4.18/BepInEx_x64_5.4.18.0.zip"
					  }))
					  return false;
					// 2. Download and overwrite with the magic files
					try {
						downloadAndUnpack('https://github.com/BepInEx/BepInEx/files/7323852/winhttp.zip');
						downloadAndUnpack('https://github.com/BepInEx/BepInEx/files/7357827/bepin4.zip');
					} catch (e) {
						trace(e);
						return false;
					}
					
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
				downloadAndUnpack(mod.download_url, mod.install_location);
			} catch (e) {
				trace(e);
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
					createPath(Path.directory(Path.join([GorillaPath.gorillaPath, installPath, entry.fileName])));
					File.saveBytes(Path.join([GorillaPath.gorillaPath, installPath, entry.fileName]), haxe.zip.Reader.unzip(entry));
				}
				
			}
		} else {
			var oldCwd = Sys.getCwd();
			File.saveBytes(Path.join([GorillaPath.gorillaPath, installPath, "temp.zip"]), zipFile);
			Sys.setCwd(GorillaPath.gorillaPath);
			Sys.command("unzip", ["-o", Path.join([GorillaPath.gorillaPath, installPath, "temp.zip"])]);
			FileSystem.deleteFile(Path.join([GorillaPath.gorillaPath, installPath, "temp.zip"]));
			Sys.setCwd(oldCwd);
		}
		
	}
	private static function downloadAndUnpack(url:String, install_location:String = ".") {
		download(url, Path.join([GorillaPath.gorillaPath, install_location]));
		var bytes = File.getBytes(Path.join([GorillaPath.gorillaPath, install_location, url.withoutDirectory()]));
		unpackZip(bytes, install_location);
		FileSystem.deleteFile(Path.join([GorillaPath.gorillaPath, install_location, url.withoutDirectory()]));
		
	}
	private static function download(url:String, ?installPath:String = null) {
		if (installPath == null)
			installPath = GorillaPath.gorillaPath;
		if (existsWget) {
			Sys.command("wget", ["-O", Path.join([installPath, url.withoutDirectory()]), url]);
		} else {
			trace(Path.join([installPath, url.withoutDirectory()]));
			downloadFile(url, Path.join([installPath, url.withoutDirectory()]));
			
		}
		
		
	}
	// https://github.com/ianharrigan/hvm/blob/main/hvm/HVM.hx#L822-L861
	private static function downloadFile(srcUrl:String, dstFile:String, isRedirect:Bool = false) {
        if (isRedirect == false) {
            trace("    " + srcUrl);
        }
        
        var http = new sys.Http(srcUrl);
        var httpsFailed:Bool = false;
        var httpStatus:Int = -1;
        http.onStatus = function(status:Int) {
            httpStatus = status;
            if (status == 302) { // follow redirects
                var location = http.responseHeaders.get("location");
                if (location == null) {
                    location = http.responseHeaders.get("Location");
                }
                if (location != null) {
                    downloadFile(location, dstFile, true);
                } else {
                    throw "302 (redirect) encountered but no 'location' header found";
                }
            }
        }
        http.onBytes = function(bytes:Bytes) {
            if (httpStatus == 200) {
                trace("    Download complete");
                File.saveBytes(dstFile, bytes);
            }
        }
        http.onError = function(error) {
            if (!httpsFailed && srcUrl.indexOf("https:") > -1) {
                httpsFailed = true;
                trace("Problem downloading file using http secure: " + error);
                trace("Trying again with http insecure...");
                downloadFile( StringTools.replace(srcUrl, "https", "http"), dstFile);
            } else {
                throw "    Problem downloading file: " + error;
            }
        }
        http.request();
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
		GorillaPath.gorillaPath = this.monkePathDialog.monkePath.text;
	}
	@:bind(deleteMods, MouseEvent.CLICK) 
	private function deleteModsAction(_:MouseEvent) {
		var dialog = new components.WarningDialog("This will delete ALL MODS AND ALL OF THEIR CONFIGURATION. \n\nIs this ok?");
		var success = false;
		dialog.onDialogClosed = (b:DialogEvent) -> {
			if (b.button == DialogButton.OK) {
				success = true;
			}
		};
		dialog.showDialog();
		trace("closed?");
		if (!success)
			return;
		trace("accepted!");
		deleteDirRecursively(Path.join([GorillaPath.gorillaPath, "BepInEx"]));
	}
	// https://ashes999.github.io/learnhaxe/recursively-delete-a-directory-in-haxe.html
	private static function deleteDirRecursively(path:String) : Void
	{
		if (sys.FileSystem.exists(path) && sys.FileSystem.isDirectory(path))
		{
		var entries = sys.FileSystem.readDirectory(path);
		for (entry in entries) {
			if (sys.FileSystem.isDirectory(path + '/' + entry)) {
			deleteDirRecursively(path + '/' + entry);
			sys.FileSystem.deleteDirectory(path + '/' + entry);
			} else {
			sys.FileSystem.deleteFile(path + '/' + entry);
			}
		}
		}
	}
}
