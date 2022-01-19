package helpers;

import sys.FileSystem;
import haxe.io.Path;
import sys.io.File;
import haxe.io.Bytes;
import sys.io.FileInput;
enum FileFetcher {
    FFWget;
    FFCurl;
    FFHaxe;
    FFUnknown;
}

enum Unzipper {
    UZUnzip;
    UZHaxe;
    UZUnknown;
}
class Util {
    public static var fetcher:FileFetcher = FFUnknown;
    public static var unzipper:Unzipper = UZUnknown;
    public static function openURL(url:String) {
        #if windows
            Sys.command("start", [url]);
        #elseif mac
            Sys.command("open", [url]);
        #else 
            Sys.command("xdg-open", [url]);
        #end
    }
    public static function unzipFile(file:String) {
        if (unzipper == UZUnknown) {
            if (existsCommand("unzip"))
                unzipper = UZUnzip;
            else 
                unzipper = UZHaxe;
        }
        switch (unzipper) {
            case UZUnzip:
                var oldCwd = Sys.getCwd();
                Sys.setCwd(Path.directory(file));
                var success = Sys.command("unzip", ["-o", file]) == 0;
                Sys.setCwd(oldCwd);
                return success;
            case UZHaxe:
                try {
                    var dir = Path.directory(file);
                    for (entry in haxe.zip.Reader.readZip(sys.io.File.read(file))) {
                        if ((entry.data == null || entry.dataSize == 0 ) ) {
                            // :sob:
                        } else {
                            // Overwrite
                            createPath(Path.directory(Path.join([dir, entry.fileName])));
                            File.saveBytes(Path.join([dir, entry.fileName]), haxe.zip.Reader.unzip(entry));
                        }
                        
                    }
                    return true;
                } catch (e) {
                    trace(e);
                    return false;
                }
               
            default: 
                return false;
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
    public static function downloadAndSave(url:String, dest:String) {
        switch (fetcher) {
            case FFUnknown: 
                if (existsCommand("wget"))
                    fetcher = FFWget;
                else if (existsCommand("curl"))
                    fetcher = FFCurl;
                else 
                    fetcher = FFHaxe;
            default: 
        }
        switch (fetcher) {
            case FFWget: 
                return Sys.command("wget", ["-O", dest, url]) == 0;
            case FFCurl: 
                return Sys.command("curl", ["-L", "-o", dest, url]) == 0;
            case FFHaxe: 
                try {
                    nativeDownloadFile(url, dest);
                    return true;
                } catch (e) {
                    trace(e);
                    return false;
                }
            default: 
                return false;
        }
    }
    // https://github.com/ianharrigan/hvm/blob/main/hvm/HVM.hx#L822-L861
	private static function nativeDownloadFile(srcUrl:String, dstFile:String, isRedirect:Bool = false) {
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
                    nativeDownloadFile(location, dstFile, true);
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
                nativeDownloadFile( StringTools.replace(srcUrl, "https", "http"), dstFile);
            } else {
                throw "    Problem downloading file: " + error;
            }
        }
        http.request();
    }
    private static function existsCommand(cmd:String) {
        #if windows 
        return Sys.command("WHERE", [cmd]) == 0;
        #else 
        return Sys.command("which", [cmd]) == 0;
        #end
    }
}