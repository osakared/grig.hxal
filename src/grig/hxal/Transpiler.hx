package grig.hxal;

import haxe.macro.Context;
import haxe.macro.Expr;
import sys.io.File;

class Transpiler
{
    public static function buildInstrument():Array<haxe.macro.Field>
    {
        var fields = Context.getBuildFields();
        for (field in fields) {
            trace(field.kind);
        }
        File.saveContent('tst.c', '#include <stdio.h>\n\nint main() {\nprintf("hello, world\\n");\nreturn 0;}\n');
        return fields;
    }
}