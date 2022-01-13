package components;

import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
@:build(haxe.ui.ComponentBuilder.build("assets/text-dialog.xml"))
class DialogTextField extends HBox {
    public function new() {
        super();
    }
    @:bind(openFileDialog, MouseEvent.CLICK)
    public function openDialog(_:MouseEvent) {
        // Now only works on cpp!
        trace("showing dialog");
        var dialog = new hx.widgets.DirDialog(haxe.ui.ToolkitAssets.instance.options.frame, "Pick a directory", this.monkePath.text);
        dialog.showModal();
        trace("modal closed?");
        this.monkePath.text = dialog.path != "" ? dialog.path : this.monkePath.text;
        dialog.destroy();
    }
 }