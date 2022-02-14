package components;

import haxe.ui.events.MouseEvent;
@:build(haxe.ui.ComponentBuilder.build("assets/mod-item.xml"))
@:keep
class ModItem extends haxe.ui.containers.HBox {
    public var mod(default, null):ModData;
    public function new(modData:ModData) {
        super();
        this.modName.text = modData.name;
        this.modVersion.text = modData.version;
        this.modAuthor.text = modData.author;
        this.mod = modData;
        this.modEnabled.onChange = (_) -> MainView.instance.modlist.updateMods();
    }
    @:bind(this, MouseEvent.DBL_CLICK)
    private function doShowSource(me:MouseEvent) {
        
        me.bubble = false;
        showSource();

    }
    public function showSource() {
        if (mod.git_path == null)
            return;
        helpers.Util.openURL('https://github.com/${mod.git_path}');
    }
    public function updateRecency(status:UpdateStatus) {
        this.modVersion.removeClass("outdated");
        this.modVersion.removeClass("updated");
        switch (status) {
            case NotInstalled: 

            case LatestVersion: 
                this.modVersion.addClass("updated");
            case Outdated: 
                this.modVersion.addClass("outdated");
        }
    }
}