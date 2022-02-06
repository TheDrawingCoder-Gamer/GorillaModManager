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
		#if !haxeui_hxwidgets
		darkMode.selected = GorillaOptions.darkMode;
		updateTheme();
		#end
		enableBetas.selected = GorillaOptions.enableBetas;
	}
	@:bind(installMods, MouseEvent.CLICK)
	public function doInstallMods(e:MouseEvent) {
		Installer.doInstallMods(this.modlist.modItems().filter(it -> it.modEnabled.selected).map(it -> it.mod));
		
	}
	@:bind(deleteSelectedMods, MouseEvent.CLICK)
	public function doDeleteMods(e:MouseEvent) {
		var dialog = new components.WarningDialog("This will delete selected mods, \nbut will keep any configuration generated. \n\n Is this okay?");
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
		trace("success! deleting mods...");
		var mods:Array<ModData> = this.modlist.modItems().filter(it -> it.modEnabled.selected).map(it -> it.mod);
		for (mod in mods) {
			if (VersionSaver.modStatus(mod) != NotInstalled) {
				Installer.deleteMod(mod);
			}
		}
		this.modlist.updateMods();
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
		if (FileSystem.exists(Path.join([GorillaPath.gorillaPath, "GMM-Version.json"]))) {
			FileSystem.deleteFile(Path.join([GorillaPath.gorillaPath, "GMM-Version.json"]));
		}
		if (FileSystem.exists(Path.join([GorillaPath.gorillaPath, "GMMv2-Version.json"]))) {
			FileSystem.deleteFile(Path.join([GorillaPath.gorillaPath, "GMMv2-Version.json"]));
		}
	}
	#if !haxeui_hxwidgets
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
