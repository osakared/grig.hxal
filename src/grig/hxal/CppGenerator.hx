package grig.hxal;

import grig.hxal.NodeDescriptor.NodeVar;
import grig.hxal.NodeDescriptor.VarType;
import haxe.macro.Context;

using grig.hxal.CodeStringTools;

typedef CppType = {
    var name:String;
    var ?subscript:Int;
}

interface Serializable
{
    public function serialize():String;
}

class CppInclude implements Serializable
{
    public var descriptor:Dynamic;

    public function new(_descriptor:{name:String, ?useQuotes:Bool})
    {
        descriptor = _descriptor;
    }

    private function getOpening():String
    {
        return if (descriptor.useQuotes) {
            '"';
        } else {
            '<';
        }
    }

    private function getClosing():String
    {
        return if (descriptor.useQuotes) {
            '"';
        } else {
            '>';
        }
    }

    public function serialize():String
    {
        return '#include ${getOpening()}${descriptor.name}${getClosing()}';
    }
}

class CppArgument implements Serializable
{
    public var descriptor:Dynamic;

    public function new(_descriptor:{type:String, ?isConst:Bool, name:String})
    {
        descriptor = _descriptor;
    }

    public function serialize():String
    {
        return '${if (descriptor.isConst == true) 'const ' else ''}${descriptor.type} ${descriptor.name}';
    }
}

class CppBinaryOperator implements Serializable
{
    public var left:Serializable;
    public var right:Serializable;
    public var op:String;

    public function new(_left:Serializable, _right:Serializable, _op:String)
    {
        left = _left;
        right = _right;
        op = _op;
    }

    public function serialize():String
    {
        return '${left.serialize()} $op ${right.serialize()}';
    }
}

class CppDeclaration implements Serializable
{
    public var descriptor:Dynamic;

    public function new(_descriptor:{type:CppType, ?isConst:Bool, name:String})
    {
        descriptor = _descriptor;
    }

    public function serialize():String
    {
        return '${if (descriptor.isConst == true) 'const ' else ''}${descriptor.type.name} ${descriptor.name}${if(descriptor.type.subscript != null) '[${descriptor.type.subscript}]' else ''};';
    }
}

class CppCase implements Serializable
{
    public var name:String;

    public var children = new Array<Serializable>();

    public function new(_name:String)
    {
        name = _name;
    }

    public function serialize():String
    {
        var s = '$name:\n';

        for (child in children) {
            s += child.serialize().prependLines(CppGenerator.TAB);
        }

        return s;
    }
}

class CppStatement implements Serializable
{
    public var name:String;

    public function new(_name:String)
    {
        name = _name;
    }

    public function serialize():String
    {
        return name + ';';
    }
}

class CppLine implements Serializable
{
    public var contents:Serializable;

    public function new(_contents:Serializable)
    {
        contents = _contents;
    }

    public function serialize():String
    {
        return contents.serialize() + ';';
    }
}

class CppFunctionCall implements Serializable
{
    public var name:String;
    public var object:Null<Serializable> = null;

    public var arguments = new Array<Serializable>();

    public function new(_name:String)
    {
        name = _name;
    }

    public function serialize():String
    {
        var args = [];
        for (argument in arguments) {
            args.push(argument.serialize());
        }
        return '${if (object != null) object.serialize() + '.' else ''}$name(${args.join(', ')})';
    }
}

class CppFunctionDeclaration implements Serializable
{
    public var descriptor:Dynamic;

    public var children = new Array<Serializable>();
    public var arguments = new Array<Serializable>();

    public function new(_descriptor:{returnType:String, name:String, ?isConst:Bool, ?isStatic:Bool})
    {
        descriptor = _descriptor;
    }

    public function serialize():String
    {
        var s = '${if (descriptor.isStatic) 'static ' else ''}${descriptor.returnType} ${descriptor.name}(';
        var argumentStrings = new Array<String>();
        for (argument in arguments) {
            argumentStrings.push(argument.serialize());
        }
        s += argumentStrings.join(', ');
        s += ')\n{\n';
        for (child in children) {
            s += child.serialize().prependLines(CppGenerator.TAB);
        }
        s += '\n}';
        return s;
    }
}

class CppControl implements Serializable
{
    public var name:String;

    public var children = new Array<Serializable>();
    public var conditions = new Array<Serializable>();

    public function new(_name:String)
    {
        name = _name;
    }

    public function serialize():String
    {
        var s = '$name (';
        var conditionStrings = new Array<String>();
        for (condition in conditions) {
            conditionStrings.push(condition.serialize());
        }
        s += conditionStrings.join('; ');
        s += ') {\n';
        for (child in children) {
            s += child.serialize().prependLines(CppGenerator.TAB);
        }
        s += '}';
        return s;
    }
}

class CppClass implements Serializable
{
    public var descriptor:Dynamic;

    public var children = new Array<Serializable>();

    public function new(_descriptor:{name:String})
    {
        descriptor = _descriptor;
    }

    public function serialize():String
    {
        var s = 'class ${descriptor.name}\n{\n';
        for (child in children) {
            s += child.serialize().prependLines(CppGenerator.TAB);
        }
        s += '\n};';

        return s;
    }

}

class CppArbitrary implements Serializable
{
    public var text:String;

    public function new(_text:String)
    {
        text = _text;
    }

    public function serialize():String
    {
        return text;
    }
}

class CppFile implements Serializable
{
    public var children = new Array<Serializable>();
    
    public function new()
    {
    }

    public function serialize():String
    {
        var s = '';
        for (child in children) {
            s += child.serialize() + '\n';
        }
        return s;
    }
}

typedef NeededTypeHeaders = {
    var needStdInt:Bool;
    var needStdBool:Bool;
}

class CppGenerator
{
    public static inline var TAB = '    ';
    public static var BREAK = new CppArbitrary('');

    public static function toCstdIntType(type:VarType, neededTypeHeaders:NeededTypeHeaders, sampleType:VarType = TFloat):CppType
    {
        if (sampleType == TSample) {
            throw 'Cannot tautologically set sample type to be itself';
        }

        neededTypeHeaders.needStdBool = false;
        neededTypeHeaders.needStdInt = true;
        
        var outputType = {name: '', subscript: null};
        outputType.name = switch type {
            case TInt:
                neededTypeHeaders.needStdInt = false;
                'int';
            case TUInt:
                neededTypeHeaders.needStdInt = false;
                'unsigned int';
            case TInt8:
                'int8_t';
            case TUInt8:
                'uint8_t';
            case TInt16:
                'int16_t';
            case TUInt16:
                'uint16_t';
            case TInt32:
                'int32_t';
            case TUInt32:
                'uint32_t';
            case TInt64:
                'int64_t';
            case TUInt64:
                'uint64_t';
            case TFloat:
                neededTypeHeaders.needStdInt = false;
                'float';
            case TFloat32:
                neededTypeHeaders.needStdInt = false;
                'float';
            case TFloat64:
                neededTypeHeaders.needStdInt = false;
                'double';
            case TSample:
                return toCstdIntType(sampleType, neededTypeHeaders, sampleType);
            case TArray(subType, length):
                outputType.subscript = length;
                toCstdIntType(subType, neededTypeHeaders, sampleType).name;
            case TBool:
                neededTypeHeaders.needStdBool = true;
                neededTypeHeaders.needStdInt = false;
                'bool';
        }
        return outputType;
    }

    #if macro
    public static function generatePlainCpp(nodeDescriptor:NodeDescriptor):String
    {
        var cppFile = new CppFile();
        var needCTypes = false;
        var cppClass = new CppClass({name: nodeDescriptor.className});
        for (classVar in nodeDescriptor.classVars) {
            var isConst = !classVar.mutable && classVar.category == CClass;
            var neededTypeHeaders = {needStdInt: false, needStdBool: false};
            var type = toCstdIntType(classVar.type, neededTypeHeaders);
            needCTypes = needCTypes || neededTypeHeaders.needStdInt;
            var cppDecl = new CppDeclaration({type: type, isConst: isConst, name: classVar.name});
            cppClass.children.push(cppDecl);
        }
        if (needCTypes) {
            cppFile.children.push(new CppInclude({name: 'cstdint'}));
        }
        cppFile.children.push(cppClass);
        return cppFile.serialize();
    }

    // Helper function
    private static function createIntParamAssign(name:String, assign:String):Serializable
    {
        return new CppLine(new CppBinaryOperator(new CppArbitrary(name), new CppArbitrary(assign), '='));
    }

    private static function createFloatParamAssign(name:String, assign:String):Serializable
    {
        var functionCall = new CppFunctionCall('param_val_to_f32');
        functionCall.arguments.push(new CppArbitrary(assign));
        return new CppLine(new CppBinaryOperator(new CppArbitrary(name), functionCall, '='));
    }

    public static inline var LOGUE_SAMPLE_TYPE = TFloat32;

    /**
     * Generates files needed for making a korg logue sdk plugin
     * @param nodeDescriptor descriptor to morph into logue sdk c code
     * @return String
     */
    public static function generateLogueProject(nodeDescriptor:NodeDescriptor):String
    {
        var cFile = new CppFile();
        cFile.children.push(new CppInclude({name: 'userosc.h', useQuotes: true}));
        cFile.children.push(BREAK);

        var params = new Array<NodeVar>();
        // Globally declaring the vars
        var needStdBool = false;
        for (classVar in nodeDescriptor.classVars) {
            var isConst = !classVar.mutable && classVar.category == CClass;
            var neededTypeHeaders = {needStdInt: false, needStdBool: false};
            var type = toCstdIntType(classVar.type, neededTypeHeaders, LOGUE_SAMPLE_TYPE);
            needStdBool = needStdBool || neededTypeHeaders.needStdBool;
            var cppDecl = new CppDeclaration({type: type, isConst: isConst, name: classVar.name});
            cFile.children.push(cppDecl);
            if (classVar.category == CParameter) {
                params.push(classVar);
            }
        }
        if (needStdBool) {
            cFile.children.insert(0, new CppInclude({name: 'stdbool.h'}));
            cFile.children.push(BREAK);
        }
        cFile.children.push(BREAK);

        // Making the function to edit the parameters
        var oscParamFn = new CppFunctionDeclaration({returnType: 'void', name: 'OSC_PARAM'});
        var valueLabel = 'value';
        oscParamFn.arguments.push(new CppArgument({type: 'uint16_t', name: 'index'}));
        oscParamFn.arguments.push(new CppArgument({type: 'uint16_t', name: valueLabel}));

        var oscParamSwitch = new CppControl('switch');
        oscParamSwitch.conditions.push(new CppArbitrary('index'));
        for (i in 0...params.length) {
            var paramCase = new CppCase('k_osc_param_id${i+1}');

            var paramType = params[i].type;
            if (paramType == TSample) {
                paramType = LOGUE_SAMPLE_TYPE;
            }
            var paramAssign = switch (paramType) {
                case TInt:
                    createIntParamAssign(params[i].name, valueLabel);
                case TUInt:
                    createIntParamAssign(params[i].name, valueLabel);
                case TInt8:
                    createIntParamAssign(params[i].name, valueLabel);
                case TUInt8:
                    createIntParamAssign(params[i].name, valueLabel);
                case TInt16:
                    createIntParamAssign(params[i].name, valueLabel);
                case TUInt16:
                    createIntParamAssign(params[i].name, valueLabel);
                case TInt32:
                    createIntParamAssign(params[i].name, valueLabel);
                case TUInt32:
                    createIntParamAssign(params[i].name, valueLabel);
                case TInt64:
                    createIntParamAssign(params[i].name, valueLabel);
                case TUInt64:
                    createIntParamAssign(params[i].name, valueLabel);
                case TFloat:
                    createFloatParamAssign(params[i].name, valueLabel);
                case TFloat32:
                    createFloatParamAssign(params[i].name, valueLabel);
                case TFloat64:
                    createFloatParamAssign(params[i].name, valueLabel);
                case TSample:
                    throw 'Unexpected TSample';
                case TArray(type, length):
                    Context.error('hxal: ${params[i].name}: array params not supported for logue', Context.currentPos());
                case TBool:
                    new CppLine(new CppBinaryOperator(new CppArbitrary(params[i].name), new CppBinaryOperator(new CppArbitrary(valueLabel), new CppArbitrary('0'), '!='), '='));
            }

            paramCase.children.push(paramAssign);
            paramCase.children.push(new CppStatement('break'));
            oscParamSwitch.children.push(paramCase);
        }
        oscParamFn.children.push(oscParamSwitch);

        cFile.children.push(oscParamFn);

        return cFile.serialize();
    }
    #end
}