package components;

import haxe.ui.events.MouseEvent;
@:build(haxe.ui.ComponentBuilder.build("assets/mod-item.xml"))
@:keep
class ModItem extends haxe.ui.containers.HBox {
    public var mod(default, null):ModData;
    var temp = 0;
    public function new(modData:ModData) {
        super();
        this.name.text = modData.name;
        this.version.text = modData.version;
        this.author.text = modData.author;
        this.mod = modData;
        this.enabled.onChange = (_) -> MainView.instance.modlist.updateMods();
    }
    @:bind(this, MouseEvent.DBL_CLICK)
    private function doShowSource(me:MouseEvent) {
        if (mod.git_path == null)
            return;
        me.bubble = false;
        switch (Sys.systemName()) {
            case "Windows": 
                Sys.command("start", ['https://github.com/${mod.git_path}']);
            case "Mac": 
                Sys.command("open", ['https://github.com/${mod.git_path}']);
            case "Linux": 
                Sys.command("xdg-open", ['https://github.com/${mod.git_path}']);
        }
    }
}