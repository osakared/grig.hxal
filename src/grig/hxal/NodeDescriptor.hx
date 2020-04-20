package grig.hxal;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

/**
 * This is all the types allowed in hxal
 */
enum VarType
{
    TInt;
    TUInt;
    TInt8;
    TUInt8;
    TInt16;
    TUInt16;
    TInt32;
    TUInt32;
    TInt64;
    TUInt64;
    TFloat;
    TFloat32;
    TFloat64;
    TSample; // represents the fundamental sample type used in the environment
    TArray(type:VarType, length:Int);
    TBool;
    // TString; // can't be mutable, can only be assigned a string literal at creation
}

enum Category
{
    CInput; // for modular synth modules 
    COutput; // for modular synth modules
    CParameter;
    CClass;
}

typedef NodeString = {
    var text:String;
    var lang:String; // ISO 639-1 language code
}

class NodeVar
{
	public var name:String;
    public var type:VarType;
    public var mutable:Bool = false;
	public var category:Category = CClass;
    public var expr:Null<Expr>;
    public var uiName = new Array<NodeString>();
    public var uiUnit:String;
    // public var uiMin:Null<Float>;
    // public var uiMax:Null<Float>;

    public function new()
    {
    }
}

/**
 * Source tree of a node's functionality, metadata
 */
class NodeDescriptor
{
    private static inline var duplicateCategoryErrorMessage = 'hxal: Only one of the following categories can be specified per variable: input, output, parameter';
    private static inline var notNumericTypeMessage = 'hxal: 1st parameter of Array must be numeric type';
    private static inline var notNumberMessage = 'hxal: 2nd parameter of Array must be positive integer';

    public var className:String;
    public var name = new Array<NodeString>();
    public var description = new Array<NodeString>();
    public var version:String;
    public var manufacturer:String;
    // should I add enum ability? probably
    public var classVars = new Array<NodeVar>();

    private function new()
    {
    }

    #if macro
    private static function verifyNoParams(metadataEntry:MetadataEntry):Void
    {
        if (metadataEntry.params != null && metadataEntry.params.length > 0) {
            Context.error('hxal: Metadata ${metadataEntry.name} doesn\'t support parameters', Context.currentPos());
        }
    }
    
    public static function fromClassType(classType:ClassType):NodeDescriptor
    {
        var descriptor = new NodeDescriptor();
        var classMetadata = classType.meta.get();
        descriptor.className = classType.name;
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
        return descriptor;
    }

    private static function extraneousParamError(typeName:String)
    {
        Context.error('hxal: Type: ${typeName} does not allow parameters', Context.currentPos());
    }

    private static function allowedArrayType(type:VarType):Bool
    {
        return switch type {
            case TInt: true;
            case TUInt: true;
            case TInt8: true;
            case TUInt8: true;
            case TInt16: true;
            case TUInt16: true;
            case TInt32: true;
            case TUInt32: true;
            case TInt64: true;
            case TUInt64: true;
            case TFloat: true;
            case TFloat32: true;
            case TFloat64: true;
            case TSample: true; // represents the fundamental sample type used in the environment
            default: false;
        }
    }

    private static function getTypeFromTypePath(typePath:TypePath):VarType
    {
        var name = typePath.name;
        return switch name {
            case 'Int':
                if (typePath.params != null && typePath.params.length != 0) extraneousParamError(name);
                TInt;
            case 'UInt':
                if (typePath.params != null && typePath.params.length != 0) extraneousParamError(name);
                TUInt;
            case 'Int8':
                if (typePath.params != null && typePath.params.length != 0) extraneousParamError(name);
                TInt8;
            case 'UInt8':
                if (typePath.params != null && typePath.params.length != 0) extraneousParamError(name);
                TUInt8;
            case 'Int16':
                if (typePath.params != null && typePath.params.length != 0) extraneousParamError(name);
                TInt16;
            case 'UInt16':
                if (typePath.params != null && typePath.params.length != 0) extraneousParamError(name);
                TUInt16;
            case 'Int32':
                if (typePath.params != null && typePath.params.length != 0) extraneousParamError(name);
                TInt32;
            case 'UInt32':
                if (typePath.params != null && typePath.params.length != 0) extraneousParamError(name);
                TUInt32;
            case 'Int64':
                if (typePath.params != null && typePath.params.length != 0) extraneousParamError(name);
                TInt64;
            case 'UInt64':
                if (typePath.params != null && typePath.params.length != 0) extraneousParamError(name);
                TUInt64;
            case 'Float':
                if (typePath.params != null && typePath.params.length != 0) extraneousParamError(name);
                TFloat;
            case 'Float32':
                if (typePath.params != null && typePath.params.length != 0) extraneousParamError(name);
                TFloat32;
            case 'Float64':
                if (typePath.params != null && typePath.params.length != 0) extraneousParamError(name);
                TFloat64;
            case 'Sample':
                if (typePath.params != null && typePath.params.length != 0) extraneousParamError(name);
                TSample;
            case 'Array':
                if (typePath.params.length != 2) Context.error("hxal: Array requires two parameters", Context.currentPos());
                var subType = TSample;
                switch (typePath.params[0]) {
                    case TPType(_ => typeName):
                        subType = getType(typeName);
                        if (!allowedArrayType(subType)) {
                            Context.error(notNumericTypeMessage, Context.currentPos());
                        }
                    case TPExpr(_):
                        Context.error(notNumericTypeMessage, Context.currentPos());
                }
                var arrayLength = switch (typePath.params[1]) {
                    case TPType(_):
                        Context.error(notNumberMessage, Context.currentPos());
                    case TPExpr(_ => expr):
                        switch expr.expr {
                            case EConst(CInt(_ => numString)):
                                var num = Std.parseInt(numString);
                                if (num == null || num <= 0) {
                                    Context.error(notNumberMessage, Context.currentPos());
                                }
                                num;
                            default:
                                Context.error(notNumberMessage, Context.currentPos());
                        }
                }
                TArray(subType, arrayLength);
            case 'Bool':
                if (typePath.params != null && typePath.params.length != 0) extraneousParamError(name);
                TBool;
            default:
                Context.error('hxal: Unsupported type: ${name}', Context.currentPos());
                return TSample;
        }
    }

    public static function getNodeString(name:String, metadataEntry:MetadataEntry):NodeString
    {
        if (metadataEntry.params.length != 2) {
            Context.error('hxal: ${name} metadata requires two parameters', Context.currentPos());
        }
        var textExpr = metadataEntry.params[0].expr;
        var text = switch textExpr {
            case EConst(CString(_ => val, _)):
                val;
            default:
                Context.error('hxal: Invalid type for {$name} text: ${textExpr}', Context.currentPos());
        }
        var langExpr = metadataEntry.params[1].expr;
        var lang = switch langExpr {
            case EConst(CString(_ => val, _)):
                val;
            default:
                Context.error('hxal: Invalid type for ${name} lang: ${textExpr}', Context.currentPos());
        }

        return {
            text: text,
            lang: lang
        };
    }

    public static function getString(name:String, metadataEntry:MetadataEntry):String
    {
        if (metadataEntry.params.length != 1) {
            Context.error('hxal: ${name} metadata requires two parameters', Context.currentPos());
        }
        var textExpr = metadataEntry.params[0].expr;
        var text = switch textExpr {
            case EConst(CString(_ => val, _)):
                val;
            default:
                Context.error('hxal: Invalid type for {$name} text: ${textExpr}', Context.currentPos());
        }

        return text;
    }

    public static function getType(complexType:ComplexType):VarType
    {
        return switch complexType {
            case TPath(typePath):
                getTypeFromTypePath(typePath);
            case TFunction(args, ret):
                Context.error("hxal: Functions not yet implemented", Context.currentPos());
            case TAnonymous(fields):
                Context.error("hxal: Anonymous declarations not supported", Context.currentPos());
            case TParent(t):
                Context.error("hxal: Function pointer types not supported", Context.currentPos());
            case TExtend(p, fields):
                Context.error("hxal: Extends not supported", Context.currentPos());
            case TOptional(t):
                Context.error("hxal: Optional types not supported", Context.currentPos());
            case TNamed(n, t):
                Context.error("hxal: Named type not supported", Context.currentPos());
            case TIntersection(tl):
                Context.error("hxal: Intersection not supported", Context.currentPos());
        }
    }
    #end
}