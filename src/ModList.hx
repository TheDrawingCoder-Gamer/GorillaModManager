package;

import haxe.ui.containers.ScrollView;
import ModData;
using StringTools;
@:keep
@:build(haxe.ui.ComponentBuilder.build("assets/mod-list.xml"))
class ModList extends haxe.ui.containers.ScrollView {
    
    public function new() {
        super();
    }
    public function addMod(mod:ModData) {
        var unborkedName = ModDataTools.mangleName(mod.group);
        var group:Null<ModGroup> = this.groups.findComponent(unborkedName, ModGroup, false);
        if (group == null) {
            group = new ModGroup(unborkedName);
            this.groups.addComponent(group);
            trace(this.groups.childComponents);
        }
        group.addMod(mod);
    }
}