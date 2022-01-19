package components;

import hx.widgets.EventType;
import haxe.ui.events.MouseEvent;
@:build(haxe.ui.ComponentBuilder.build("assets/mod-item.xml"))
@:keep
class ModItem extends haxe.ui.containers.HBox {
    public var mod(default, null):ModData;
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
        helpers.Util.openURL('https://github.com/${mod.git_path}');

    }
}