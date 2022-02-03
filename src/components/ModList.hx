package components;

import haxe.ui.containers.ScrollView;
import ModData;
using StringTools;
using Lambda;
@:keep
@:build(haxe.ui.ComponentBuilder.build("assets/mod-list.xml"))
class ModList extends haxe.ui.containers.ScrollView {
    public var selectedItem:ModItem = null;
    public function new() {
        super();
    }
    public function addMod(mod:ModData) {
        var unborkedName = ModDataTools.mangleName(mod.group);
        var group:Null<ModGroup> = this.groups.findComponent(unborkedName, ModGroup, false);
        if (group == null) {
            group = new ModGroup(mod.group);
            this.groups.addComponent(group);
        }
        
        var moditem = group.addMod(mod);
        moditem.onClick = (_) -> { for (group in this.findComponents(null, ModGroup)) group.clearSelection(); moditem.addClass("selected"); selectedItem = moditem; onSelectionChanged(); };
    }
    public dynamic function onSelectionChanged() {}
    public function modItems() {
        var modItems = [];
        for (group in this.findComponents(null, ModGroup)) {
            for (modItem in group.mods.findComponents(null, ModItem)) {
                modItems.push(modItem);
            }
        }
        var core = [];
        for (modItem in modItems) {
            if (ModDataTools.mangleName(modItem.mod.group) == "core") {
                core.push(modItem);
            }
        }
        // Ensure core mods are first
        for (coreItem in core) {
            modItems.remove(coreItem);
        }
        modItems = core.concat(modItems);
        return modItems;
    }
    public function mods() {
        return [for (modItem in modItems()) modItem.mod];
    }
    public function refreshModInfo() {

        this.groups.removeAllComponents(true);
        XmlDeserializer.deserialize().handle((data) -> {
            switch (data) {
                case Success(mods): 
                    for (mod in mods) {
                        this.addMod(mod);
                    }
                case Failure(e): 
                    throw e;
            }
        });
        
    }
    public function updateMods() {
        var modItems = this.modItems();
        for (modItem in modItems) {
            modItem.modEnabled.disabled = false;
        }
        __updateMods(modItems);
    }
    private function __updateMods(modItems:Array<ModItem>) {
        for (modItem in modItems) {
            if (modItem.modEnabled.selected) {
                if (modItem.mod.dependencies != null && modItem.mod.dependencies.length != 0) {
                    for (depend in modItem.mod.dependencies) {
                        var dependency = modItems.find((item) -> item.mod.name == depend);
                        if (dependency == null)
                            // crashes otherwise lol
                            continue;
                        if (!dependency.modEnabled.selected) {
                            dependency.modEnabled.selected = true;
                            dependency.modEnabled.disabled = true;
                            __updateMods(modItems);
                            // Stop this cycle and redo everything
                            break;
                        }
                        if (!dependency.modEnabled.disabled) {
                            dependency.modEnabled.disabled = true;
                        }
                        
                    }
                }
            }
            
        }
    }
}