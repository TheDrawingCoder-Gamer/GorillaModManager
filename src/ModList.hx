package;

import haxe.ui.containers.ScrollView;

@:keep
class ModList extends haxe.ui.containers.ScrollView {
    
    public function new() {
        super();
        this.percentWidth = 100;
    }
    public function addMod(mod:ModData) {
        trace(mod);
        var group:Null<ModGroup> = this.findComponent(mod.group, ModGroup);
        trace(group);
        if (group == null) {
            group = new ModGroup(mod.group);
            this.addComponent(group);
        }
        trace(group);
        group.addMod(mod);
    }
}