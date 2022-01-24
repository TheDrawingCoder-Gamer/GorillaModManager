package helpers;

import tink.core.Error;
import tink.core.Noise;
import tink.core.Promise;
import tink.core.Future;
import tink.core.Outcome;
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
@await class Util {
    public static var fetcher:FileFetcher = #if disable_command_dl FFHaxe #else FFUnknown #end;
    public static var unzipper:Unzipper = #if disable_command_unzip UZHaxe #else UZUnknown #end;
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
    @:async public static function downloadAndSave(url:String, dest:String) {
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
                    @:await nativeDownloadFile(url, dest);
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
	private static function nativeDownloadFile(srcUrl:String, dstFile:String):Promise<Noise> {
        return Future.irreversible((cb) -> {
            trace("    " + srcUrl);
            
            var http = #if nodejs new helpers.Http(srcUrl) #else new haxe.Http(srcUrl) #end;
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
                        nativeDownloadFile(location, dstFile).handle((d) -> {
                            trace(d);
                            cb(d);
                        });
                        return;
                    } else {
                        cb(Failure(Error.asError("302 (redirect) encountered but no 'location' header found")));
                        return;
                    }
                }
            }
            http.onBytes = function(bytes:Bytes) {
                trace(httpStatus);
                if (httpStatus == 200) {
                    trace("    Download complete");
                    try {
                        trace(FileSystem.exists(Path.directory(dstFile)));
                        File.saveBytes(dstFile, bytes);
                    } catch (e) {
                        cb(Failure(Error.asError(e)));
                        return;
                    }
                   
                    cb(Success(null));
                    return;
                }
                
            }
            http.onError = function(error) {
                trace(httpStatus);
                if (!httpsFailed && srcUrl.indexOf("https:") > -1) {
                    httpsFailed = true;
                    trace("Problem downloading file using http secure: " + error);
                    trace("Trying again with http insecure...");
                    nativeDownloadFile( StringTools.replace(srcUrl, "https", "http"), dstFile).handle((d) -> {
                        cb(d);
                    });
                    return;
                } else {
                    trace(":frown:");
                    cb(Failure(Error.asError("    Problem downloading file: " + error)));
                }
            }
            try {
                http.request();
            } catch (e) {
                trace(e); 
                cb(Failure(Error.asError(e)));
            }
            
        });
        
    }
    private static function getHeaders(data:String) {
    
        var responseHeaders:Map<String, String> = [];
        trace(data);
        var headers = data.split("\r\n");
        headers.shift();
        headers.pop();
        headers.pop();

        var size = null;
        var chunked = false;
        for (hline in headers) {
            var a = hline.split(": ");
			var hname = a.shift();
			var hval = if (a.length == 1) a[0] else a.join(": ");
			hval = StringTools.ltrim(StringTools.rtrim(hval));
			responseHeaders.set(hname, hval);
			switch (hname.toLowerCase()) {
				case "content-length":
					size = Std.parseInt(hval);
				case "transfer-encoding":
					chunked = (hval.toLowerCase() == "chunked");
			}
        }
        return responseHeaders;

    }
    public static function requestUrl(url:String):Promise<String> {
        return cast Future.irreversible((cb) -> {
            var h = new haxe.Http(url);

            h.onData = function (d) {
                cb(Success(d));
            }
            h.onError = function (e) {
                cb(Failure(e));
            }
            h.request(false);
        });
    }
    private static function existsCommand(cmd:String) {
        #if windows 
        return Sys.command("WHERE", [cmd]) == 0;
        #else 
        return Sys.command("which", [cmd]) == 0;
        #end
    }
    // https://ashes999.github.io/learnhaxe/recursively-delete-a-directory-in-haxe.html
	public static function deleteDirRecursively(path:String) : Void
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