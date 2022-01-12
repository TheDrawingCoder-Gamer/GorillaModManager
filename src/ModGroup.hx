package;
import ModData;
@:build(haxe.ui.ComponentBuilder.build("assets/mod-group.xml"))
@:keep
class ModGroup extends haxe.ui.containers.VBox {
    public function new(name:String) {
        super();
        this.title.text = name;
        this.id = name;
    }
    public function addMod(mod:ModData) {
        this.mods.addComponent(new ModItem(mod));
        if (ModDataTools.mangleName(mod.group) != this.id) {
            trace("Mod Group is not the same as the group being added to... Ignoring");
        }
    }
}