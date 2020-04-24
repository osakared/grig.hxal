package grig.hxal;

import grig.hxal.CppGenerator;
import grig.hxal.NodeDescriptor;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.io.File;

class Transpiler
{
    #if macro
    public static function buildNode():Array<haxe.macro.Field>
    {
        var localClass:Null<Ref<ClassType>> = Context.getLocalClass();
        if (localClass == null) {
            Context.error("Missing local class", Context.currentPos());
        }

        var descriptor = NodeDescriptor.fromClassType(localClass.get());
        var contents = CppGenerator.generateLogueProject(descriptor);
        trace('\n\n$contents\n');

        // File.saveContent('tst.c', contents);
        return []; // return modified fields back for haxe pathway, nothing for translation pathway and hooks for calling into, e.g., dll for split code mode
    }
    #end
}