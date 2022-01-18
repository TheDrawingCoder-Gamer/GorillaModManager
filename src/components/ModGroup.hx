package components;
import ModData;
@:build(haxe.ui.ComponentBuilder.build("assets/mod-group.xml"))
@:keep
class ModGroup extends haxe.ui.containers.VBox {
    public function new(name:String) {
        super();
        this.title.text = name;
        this.id = ModDataTools.mangleName(name);
    }
    public function addMod(mod:ModData) {
        var moditem = new ModItem(mod);
        this.mods.addComponent(moditem);
        
        if (ModDataTools.mangleName(mod.group) != this.id) {
            trace("Mod Group is not the same as the group being added to... Ignoring");
        }
        return moditem;
    }

    public function clearSelection() {
        for (moditem in this.mods.findComponents(null, ModItem)) {
            moditem.removeClass("selected");
        }
    }
}