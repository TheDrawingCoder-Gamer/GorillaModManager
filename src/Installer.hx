package; 

import tink.core.Future;
import tink.core.Promise;
import ModData.ModDataTools;
import sys.FileSystem;
import helpers.Util;
import haxe.ui.containers.dialogs.Dialogs;
using haxe.io.Path;
import VersionSaver;
using StringTools;
using tink.CoreApi;
typedef ModInstallInfo = {
	var success:Bool;
	var mod:ModData;
	var ?structure:Array<String>;
}
class Installer {

    public static function doInstallMods(mods:Array<ModData>):Promise<Noise> {
		return Future.irreversible((cb) -> {
			Promise.inSequence([for (mod in mods) doInstallMod(mod)]).handle((d) -> {
				switch (d) {
					case Success(data): 
						var infos:Array<ModInfo> = [];
						for (modInfo in data) {
							if (!modInfo.success) {
								trace("Failed to install mod: "+ modInfo.mod.name);
							} else {
								var info:ModInfo = {version: modInfo.mod.version, structure: modInfo.structure, name: modInfo.mod.name};
								infos.push(info);
							}
						}
						VersionSaver.serialize(infos);
						cb(Success(Noise));
					case Failure(error): 
						cb(Failure(error));
				}
			});
		});
		
    }
	public static function deleteMod(mod:ModData):Bool {
		var entries = VersionSaver.entries(mod.name);
		if (entries == null) 
			return false;
		// if I do it backwards then it's more likely to be in correct order
		entries.reverse();
		// Don't delete directorys that have files as we are only deleting the zip file
		VersionSaver.removeMod(mod);
		for (bentry in entries) {
			var entry = Path.join([GorillaPath.gorillaPath, bentry]);
			if (FileSystem.isDirectory(entry)) {
				if (FileSystem.readDirectory(entry).length == 0) {
					FileSystem.deleteDirectory(entry);
				}
			} else {
				try {
					FileSystem.deleteFile(entry);
				} catch (e) {
					trace(e);
				}
				
			}
		} 
		VersionSaver.flush();
		return true;

	}
    private static function doInstallMod(mod:ModData):Promise<ModInstallInfo> {
		return Future.irreversible((cb:Outcome<ModInstallInfo, Error> -> Void) -> {
			if (VersionSaver.modStatus(mod) != NotInstalled) {
				deleteMod(mod);
			}
			if (mod.download_url.startsWith("internal-runner:")) {
				var runner = mod.download_url.substr(16);
				switch (runner) {
					case "linux-bepinex":
						// Basically do what fixed my issues on Endeavour
						// 1. Install normal bepinex
						var structure = [];
						var bepinexInfo = doInstallMod({
							"name": "BepInEx",
							"author": "BepInEx Team",
							"version": "5.4.18",
							"group": "Core",
							"download_url": "https://github.com/BepInEx/BepInEx/releases/download/v5.4.18/BepInEx_x64_5.4.18.0.zip"
						  });
						bepinexInfo.handle((d) -> {
							switch (d) {
								case Success(data): 
									if (!data.success) {
										cb(Success(data));
										return;
									}
									else 
										structure = structure.concat(data.structure);
									// 2. Download and overwrite with the magic files
									try {
										var winHttp = downloadAndUnpack('https://github.com/BepInEx/BepInEx/files/7323852/winhttp.zip');
										var bepin4 = downloadAndUnpack('https://github.com/BepInEx/BepInEx/files/7357827/bepin4.zip');
										Promise.inParallel([winHttp, bepin4]).handle((d) -> {
											switch (d) {
												case Success(data):
													for (res in data) {
														structure = structure.concat(res);
														cb(Success({success: true, structure : structure, mod: mod}));
													}
												case Failure(failure):
													cb(Failure(failure));
											}
										});
										
									} catch (e) {
										trace(e);
										cb(Success({ success: false, mod: mod}));
									}
								case Failure(failure):
									cb(Failure(failure));
							}	
							
										
						});
						
						
					case "wine-config": 
						#if windows
							Dialogs.messageBox("Windows doesn't require wine configuration",'Info', 'info');
							cb(Success({success: true, mod: mod}));
						#else
						if (Sys.command('which', ["protontricks"]) != 0) {
							Dialogs.messageBox("Protontricks must be installed", 'Error', 'error');
							cb(Success({success: true, mod: mod}));
						}	
						Dialogs.messageBox("Automated setup is not fully complete; you must add the winhttp proxy.\n In the new window switch to the libraries tab and type winhttp in the text field and click Add.\n Click OK to save the data.", 'Info', 'info');
						Sys.command('protontricks', ["1533390", "winecfg"]);
						
						cb(Success({success: true, mod: mod}));
						#end
					default:
	
						cb(Success({success: false, mod: mod}));
				}
			} else {
				try {
					if (mod.download_url.extension() == "zip")
						downloadAndUnpack(mod.download_url, mod.install_location).handle((d) -> {
							switch (d) {
								case Success(data): 
									cb(Success({success: true, structure: data, mod: mod}));
								case Failure(error): 
									cb(Failure(error));
							}
						});
					else 
						download(mod.download_url, Path.join([GorillaPath.gorillaPath, mod.install_location])).handle(d -> {
							switch (d) {
								case Success(data): 
									cb(Success({success: true, structure: [Path.join([mod.install_location, mod.download_url.withoutDirectory()])], mod: mod}));
								case Failure(error): 
									cb(Failure(error));
							}
						});
						
				} catch (e) {
					trace(e);
					cb(Failure(Error.asError(e)));
				}
			}
		});
        
    }
    private static function downloadAndUnpack(url:String, install_location:String = ".") {
		return Future.irreversible((cb) -> {
			download(url, Path.join([GorillaPath.gorillaPath, install_location])).handle((d) -> {
				switch (d) {
					case Success(data):
						Util.unzipFile(Path.join([GorillaPath.gorillaPath, install_location, url.withoutDirectory()]));
						var fileData = getEntries(Path.join([GorillaPath.gorillaPath, install_location, url.withoutDirectory()]), install_location);
						FileSystem.deleteFile(Path.join([GorillaPath.gorillaPath, install_location, url.withoutDirectory()]));
						cb(Success(fileData));
					case Failure(failure):
						failure.throwSelf();
				}
			});
		});
		
		
	
	}
	private static function getEntries(zip:String, install_path:String) {
		return [for (entry in haxe.zip.Reader.readZip(sys.io.File.read(zip))) Path.join([install_path, entry.fileName])];
	}

	private static function download(url:String, ?installPath:String = null) {
		if (installPath == null)
			installPath = GorillaPath.gorillaPath;
		return Util.downloadAndSave(url, Path.join([installPath, url.withoutDirectory()]));
		
	}
}