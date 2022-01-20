package components;

import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.Dialog;
@:build(haxe.ui.ComponentBuilder.build("assets/text-dialog.xml"))
class DialogTextField extends HBox {
    public function new() {
        super();
    }
    @:bind(openFileDialog, MouseEvent.CLICK)
    public function openDialog(_:MouseEvent) {
        // Now only works on cpp!
        trace("showing dialog");
        
        Dialogs.selectFile(function(button, files) {
            switch (button) {
                case DialogButton.CANCEL:
                    trace("file selection cancelled");
                case DialogButton.OK:
                    trace("file(s) selected - " + files.length);
                    
            }
        }, {multiple: false});
    }
 }