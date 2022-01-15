package components;

import haxe.ui.containers.dialogs.Dialog;

@:build(haxe.ui.ComponentBuilder.build("assets/warning-dialog.xml"))
class WarningDialog extends Dialog {
    public function new(message:String) {
        super();
        title = "Confirm";
        buttons = DialogButton.CANCEL | DialogButton.OK;
        warningText.text = message;
    }
}