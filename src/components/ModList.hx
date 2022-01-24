package components;

import haxe.ui.containers.ScrollView;
import ModData;
using StringTools;
using Lambda;
@:keep
@:build(haxe.ui.ComponentBuilder.build("assets/mod-list.xml"))
@await class ModList extends haxe.ui.containers.ScrollView {
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
    @await public function refreshModInfo() {
        this.groups.removeAllComponents(true);
        var mods:Array<ModData> = @await XmlDeserializer.deserialize();
        for (mod in mods) {
            this.addMod(mod);
        }
    }
    public function updateMods() {
        trace("update");
        var modItems = this.modItems();
        for (modItem in modItems) {
            modItem.enabled.disabled = false;
        }
        __updateMods(modItems);
    }
    private function __updateMods(modItems:Array<ModItem>) {
        for (modItem in modItems) {
            if (modItem.enabled.selected) {
                if (modItem.mod.dependencies != null && modItem.mod.dependencies.length != 0) {
                    for (depend in modItem.mod.dependencies) {
                        var dependency = modItems.find((item) -> item.mod.name == depend);
                        if (dependency == null)
                            // crashes otherwise lol
                            continue;
                        if (!dependency.enabled.selected) {
                            dependency.enabled.selected = true;
                            dependency.enabled.disabled = true;
                            __updateMods(modItems);
                            // Stop this cycle and redo everything
                            break;
                        }
                        if (!dependency.enabled.disabled) {
                            dependency.enabled.disabled = true;
                        }
                        
                    }
                }
            }
            
        }
    }
}