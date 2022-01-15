package components;

import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
import haxe.io.Path;
#if USING_OPENFL
import openfl.net.FileFilter;

#end 
@:build(haxe.ui.ComponentBuilder.build("assets/text-dialog.xml"))
class DialogTextField extends HBox {
    public function new() {
        super();
    }
    @:bind(openFileDialog, MouseEvent.CLICK)
    public function openDialog(_:MouseEvent) {
        #if USING_OPENFL
        var fileR = new openfl.net.FileReference();
        var finished = false;
        fileR.addEventListener("select", (_) -> { finished = true; monkePath.text = Path.directory(fileR.name); });
        fileR.browse([new FileFilter("Executables (*.exe)", "*.exe")]);
        while (!finished) {
            
        }
        trace("closed?");
        #else
        var dialog = new hx.widgets.DirDialog(haxe.ui.ToolkitAssets.instance.options.frame, "Pick a directory", this.monkePath.text);
        dialog.showModal();
        this.monkePath.text = dialog.path != "" ? dialog.path : this.monkePath.text;
        dialog.destroy();
        #end
        
    }
 }