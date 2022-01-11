package;

@:build(haxe.ui.ComponentBuilder.build("assets/mod-item.xml"))
@:keep
class ModItem extends haxe.ui.containers.HBox {
    public function new(modData:ModData) {
        super();
        this.name.text = modData.name;
        this.version.text = modData.version;
        this.author.text = modData.author;
    }
}