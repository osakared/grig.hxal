package grig.hxal;

import grig.hxal.NodeDescriptor;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.io.File;

class Transpiler
{
    private static inline var duplicateCategoryErrorMessage = 'hxal: Only one of the following categories can be specified per variable: input, output, parameter';

    #if macro
    private static function verifyNoParams(metadataEntry:MetadataEntry):Void
    {
        if (metadataEntry.params != null && metadataEntry.params.length > 0) {
            Context.error('hxal: Metadata ${metadataEntry.name} doesn\'t support parameters', Context.currentPos());
        }
    }

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
                    var nodeVar = new NodeVar();
                    if (complexType == null) {
                        Context.error("hxal: Unspecified type in declaration not supported", Context.currentPos());
                    }
                    nodeVar.name = field.name;
                    nodeVar.type = NodeDescriptor.getType(complexType);
                    nodeVar.expr = expr;
                    for (meta in field.meta) {
                        switch meta.name {
                            case 'mutable':
                                verifyNoParams(meta);
                                nodeVar.mutable = true;
                            case 'input':
                                verifyNoParams(meta);
                                if (nodeVar.category != CClass) {
                                    Context.error(duplicateCategoryErrorMessage, Context.currentPos());
                                }
                                nodeVar.category = CInput;
                            case 'output':
                                verifyNoParams(meta);
                                if (nodeVar.category != CClass) {
                                    Context.error(duplicateCategoryErrorMessage, Context.currentPos());
                                }
                                nodeVar.category = COutput;
                            case 'parameter':
                                verifyNoParams(meta);
                                if (nodeVar.category != CClass) {
                                    Context.error(duplicateCategoryErrorMessage, Context.currentPos());
                                }
                                nodeVar.category = CParameter;
                            case 'name':
                                var nameString = NodeDescriptor.getNodeString('name', meta);
                                nodeVar.uiName.push(nameString);
                            case 'unit':
                                var unitString = NodeDescriptor.getString('unit', meta);
                                nodeVar.uiUnit = unitString;
                        }
                    }
                    descriptor.classVars.push(nodeVar);
                case FFun(fun):
                    trace('fun');
                case FProp(_, _):
                    Context.error("hxal: Properties not supported", Context.currentPos());
            }
        }
        // trace(descriptor.classVars);
        // File.saveContent('tst.c', '#include <stdio.h>\n\nint main() {\nprintf("hello, world\\n");\nreturn 0;}\n');
        return []; // return modified fields back for haxe pathway, nothing for translation pathway and hooks for calling into, e.g., dll for split code mode
    }
    #end
}