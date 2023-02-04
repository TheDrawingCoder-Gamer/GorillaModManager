package components;

import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.Dialog;
import haxe.io.Path;
@:build(haxe.ui.ComponentBuilder.build("assets/text-dialog.xml"))
class DialogTextField extends HBox {
    public function new() {
        super();
    }
    @:bind(openFileDialog, MouseEvent.CLICK)
    public function openDialog(_:MouseEvent) {
        Dialogs.openFile((button, files) -> {
            switch (button) {
                case DialogButton.CANCEL: 
                    trace("File Selection Cancelled");
                case DialogButton.OK: 
                    trace("File selected");
                    this.monkePath.text = Path.directory(files[0].fullPath);
            }
        });
    }
 }
