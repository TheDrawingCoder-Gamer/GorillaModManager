package;

import tink.core.Future;
import haxe.ui.containers.dialogs.Dialog;
import haxe.io.Bytes;
import haxe.ui.core.Screen;
import haxe.io.BytesInput;
import haxe.zip.Uncompress;
import haxe.ui.Toolkit;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import sys.io.File;
import sys.FileSystem;
using haxe.io.Path;
import haxe.ui.events.UIEvent;
import haxe.ui.containers.dialogs.Dialogs;
import helpers.Util;
import tink.core.Promise;
using StringTools;

@:build(haxe.ui.ComponentBuilder.build("assets/main-view.xml"))
@:await class MainView extends VBox {
	public static var instance:MainView = null;
	private var requiresUpdate = false;
	private var inProgress = false;
	public function new() {
		super();
		instance = this;
		this.monkePathDialog.monkePath.text = GorillaPath.gorillaPath;
		modlist.refreshModInfo();
		modlist.onSelectionChanged = () -> {
			if (this.modlist.selectedItem == null || this.modlist.selectedItem.mod.git_path == null) {
				modinfo.disabled = true;
			} else {
				modinfo.disabled = false;
	
			}
		};
		#if js
		darkMode.selected = GorillaOptions.darkMode;
		updateTheme();
		#end
		enableBetas.selected = GorillaOptions.enableBetas;
	}
	@:bind(installMods, MouseEvent.CLICK)
	@:await public function doInstallMods(e:MouseEvent) {
		if (inProgress) return;
		inProgress = true;
		var goodMods = [];
		try {
			for (modItem in this.modlist.modItems()) {
				if (modItem.enabled.selected && (!VersionSaver.isLatestVersion(modItem.mod) || this.overwrite.selected))
					if (!@:await doInstallMod(modItem.mod)) {
						trace("Failed to install mod: " + modItem.mod.name);
					} else {
						goodMods.push(modItem.mod);
					}
			}
		} catch (e) {
			trace(e);
		}
		VersionSaver.serialize(goodMods);
		inProgress = false;
		
	}
	public function doInstallMod(mod:ModData):Promise<Bool> {
		if (mod.download_url.startsWith("internal-runner:")) {
			var runner = mod.download_url.substr(16);
			switch (runner) {
				case "linux-bepinex":
					// Basically do what fixed my issues on Endeavour
					// 1. Install normal bepinex
					downloadAndUnpack("https://github.com/BepInEx/BepInEx/releases/download/v5.4.18/BepInEx_x64_5.4.18.0.zip").eager();
					// 2. Download and overwrite with the magic files
					downloadAndUnpack('https://github.com/BepInEx/BepInEx/files/7323852/winhttp.zip').eager();
					downloadAndUnpack('https://github.com/BepInEx/BepInEx/files/7357827/bepin4.zip').eager();
					
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
			return downloadAndUnpack(mod.download_url, mod.install_location);
		}
		return false;
		
	} 
	private static function downloadAndUnpack(url:String, install_location:String = "."):Promise<Bool> {
		return Future.irreversible((cb) -> {
			Util.downloadAndSave(url, Path.join([GorillaPath.gorillaPath, install_location, url.withoutDirectory()])).handle((d) -> {
					switch (d) {
						case Success(data): 
							Util.unzipFile(Path.join([GorillaPath.gorillaPath, install_location, url.withoutDirectory()]));
							FileSystem.deleteFile(Path.join([GorillaPath.gorillaPath, install_location, url.withoutDirectory()]));
							cb(true);
						case Failure(e): 
							cb(false);
					}
				}); 
		});
		
	}
	private static function download(url:String, ?installPath:String = null) {
		if (installPath == null)
			installPath = GorillaPath.gorillaPath;
		trace("download " + url);
		return Util.downloadAndSave(url, Path.join([installPath, url.withoutDirectory()]));
		
	}
	
	@:bind(monkePathDialog.monkePath, UIEvent.CHANGE)
	private function updatePath(_:UIEvent) {
		GorillaPath.gorillaPath = this.monkePathDialog.monkePath.text;
	}
	@:bind(modinfo, MouseEvent.CLICK)
	private function showModInfo(_:MouseEvent) {
		if (modlist.selectedItem != null && modlist.selectedItem.mod.git_path != null) {
			helpers.Util.openURL('https://github.com/${modlist.selectedItem.mod.git_path}');
		}
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
		Util.deleteDirRecursively(Path.join([GorillaPath.gorillaPath, "BepInEx"]));
	}
	#if js
	@:bind(darkMode, UIEvent.CHANGE)
	private function changeDarkMode(_:UIEvent) {
		GorillaOptions.darkMode = darkMode.selected;
		updateTheme();
	}
	
	private function updateTheme() {
		if (GorillaOptions.darkMode) {
			Toolkit.theme = "bulbydark";
		} else {
			Toolkit.theme = "bulbyelectron";
		}
	} 
	#end
	@:bind(enableBetas, UIEvent.CHANGE) 
	private function changeEnableBetas(_:UIEvent) {
		GorillaOptions.enableBetas = enableBetas.selected;
		// TODO: Lazy update
		// requiresUpdate = true;
		modlist.refreshModInfo();
	}
	
}
