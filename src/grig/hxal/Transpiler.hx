package grig.hxal;

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
        var descriptor = new NodeDescriptor();
        var classMetadata = localClass.get().meta.get();
        for (metadataEntry in classMetadata) {
            switch metadataEntry.name {
                case 'name':
                    var nodeString = NodeDescriptor.getNodeString('name', metadataEntry);
                    descriptor.name.push(nodeString);
                case 'description':
                    var nodeString = NodeDescriptor.getNodeString('description', metadataEntry);
                    descriptor.description.push(nodeString);
                case 'manufacturer':
                    var manufacturer = NodeDescriptor.getString('manufacturer', metadataEntry);
                    descriptor.manufacturer = manufacturer;
                case 'version':
                    var version = NodeDescriptor.getString('version', metadataEntry);
                    descriptor.version = version;
                    
            }
        }
        var fields:Array<Field> = Context.getBuildFields();
        for (field in fields) {
            switch (field.kind) {
                case FVar(complexType, expr):
                    if (complexType == null) {
                        Context.error("hxal: Unspecified type in declaration not supported", Context.currentPos());
                    }
                    var mutable:Bool = false;
                    var type:VarType = NodeDescriptor.getType(complexType);
                    for (meta in field.meta) {

                    }
                    trace('var');
                case FFun(fun):
                    trace('fun');
                case FProp(_, _):
                    Context.error("hxal: Properties not supported", Context.currentPos());
            }
            // trace(field.kind);
            // trace(field.meta);
        }
        // trace(descriptor.version);
        // File.saveContent('tst.c', '#include <stdio.h>\n\nint main() {\nprintf("hello, world\\n");\nreturn 0;}\n');
        return []; // return modified fields back for haxe pathway, nothing for translation pathway and hooks for calling into, e.g., dll for split code mode
    }
    #end
}