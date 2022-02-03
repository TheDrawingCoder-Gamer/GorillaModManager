package; 

import sys.FileSystem;
import helpers.Util;
import haxe.ui.containers.dialogs.Dialogs;
using haxe.io.Path;
using StringTools;
class Installer {

    public static function doInstallMods(mods:Array<ModData>) {
        var goodMods = [];
        try {
            for (mod in mods) {
                if (!doInstallMod(mod)) {
                    trace("Failed to install mod: "+ mod.name);
                } else {
                    goodMods.push(mod);
                }
            } 
        } catch (e) {
            trace(e);
        }
        VersionSaver.serialize(goodMods);
    }
    private static function doInstallMod(mod:ModData) {
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
					#if windows
						Dialogs.messageBox("Windows doesn't require wine configuration",'Info', 'info');
						return true;
					#else
					if (Sys.command('which', ["protontricks"]) != 0) {
						Dialogs.messageBox("Protontricks must be installed", 'Error', 'error');
						return false;
					}	
					Dialogs.messageBox("Automated setup is not fully complete; you must add the winhttp proxy.\n In the new window switch to the libraries tab and type winhttp in the text field and click Add.\n Click OK to save the data.", 'Info', 'info');
					Sys.command('protontricks', ["1533390", "winecfg"]);
					
					return true;
					#end
				default:

					return false;
			}
        } else {
            try {
				if (mod.download_url.extension() == "zip")
					downloadAndUnpack(mod.download_url, mod.install_location);
				else 
					download(mod.download_url, Path.join([GorillaPath.gorillaPath, mod.install_location]));
			} catch (e) {
				trace(e);
				return false;
			}
			return true;
        }
        return false;
    }
    private static function downloadAndUnpack(url:String, install_location:String = ".") {
		download(url, Path.join([GorillaPath.gorillaPath, install_location]));
		Util.unzipFile(Path.join([GorillaPath.gorillaPath, install_location, url.withoutDirectory()]));
		FileSystem.deleteFile(Path.join([GorillaPath.gorillaPath, install_location, url.withoutDirectory()]));
	}
	private static function download(url:String, ?installPath:String = null) {
		if (installPath == null)
			installPath = GorillaPath.gorillaPath;
		Util.downloadAndSave(url, Path.join([installPath, url.withoutDirectory()]));
		
	}
}