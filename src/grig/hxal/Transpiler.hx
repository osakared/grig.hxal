package grig.hxal;

import haxe.macro.Context;
import haxe.macro.Expr;
import sys.io.File;

class Transpiler
{
    public static function buildInstrument():Array<haxe.macro.Field>
    {
        var fields:Array<Field> = Context.getBuildFields();
        for (field in fields) {
            trace(field.kind);
            trace(field.meta);
        }
        // File.saveContent('tst.c', '#include <stdio.h>\n\nint main() {\nprintf("hello, world\\n");\nreturn 0;}\n');
        return []; // return modified fields back for haxe pathway, nothing for translation pathway and hooks for calling into, e.g., dll for split code mode
    }
}