package;

#if js
import electron.main.BrowserWindow;
import js.Node;

class ElectronApp {
    static var window:BrowserWindow;

    static function createWindow() {
        window = new BrowserWindow({
            show: false,
            webPreferences: {
                nodeIntegration: true,
                contextIsolation: false
            }
        });
        window.setMenu(null);
        window.on(closed, function() {
            window = null;
        });
        window.loadFile('index.html');
        //window.maximize();
        #if DEBUG
        window.webContents.openDevTools();
        #end
        window.show();
        window.focus();
        window.focusOnWebView();

        window.setMenuBarVisibility(false);
    }

    static function main() {
        electron.CrashReporter.start({
            companyName: 'Main',
            submitURL : "https://haxeui.org"
        });

        electron.main.App.on('ready', function(e) {
            createWindow();
        });

        electron.main.App.on('window_all_closed', function(e) {
            if (Node.process.platform != 'darwin') {
                electron.main.App.quit();
            }
        });
    }
}
#end