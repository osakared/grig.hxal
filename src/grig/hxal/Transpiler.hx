package grig.hxal;

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
        var classMetadata = localClass.get().meta.get();
        for (metadataEntry in classMetadata) {
            trace(metadataEntry.name);
        }
        var fields:Array<Field> = Context.getBuildFields();
        for (field in fields) {
            trace(field.kind);
            trace(field.meta);
        }
        // File.saveContent('tst.c', '#include <stdio.h>\n\nint main() {\nprintf("hello, world\\n");\nreturn 0;}\n');
        return fields; // return modified fields back for haxe pathway, nothing for translation pathway and hooks for calling into, e.g., dll for split code mode
    }
    #end
}