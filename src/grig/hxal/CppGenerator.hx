package grig.hxal;

import grig.hxal.NodeDescriptor.NodeVar;
import grig.hxal.NodeDescriptor.VarType;

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

class CppFunction implements Serializable
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
        s += ') {';
        for (child in children) {
            s += child.serialize().prependLines(CppGenerator.TAB);
        }
        s += '\n}';
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

class CppGenerator
{
    public static inline var TAB = '    ';
    public static var BREAK = new CppArbitrary('');

    public static function cstdIntType(outputType:CppType, type:VarType, sampleType:VarType = TFloat):Bool
    {
        var needCTypes = true;
        outputType.name = switch type {
            case TInt:
                needCTypes = false;
                'int';
            case TUInt:
                needCTypes = false;
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
                needCTypes = false;
                'float';
            case TFloat32:
                needCTypes = false;
                'float';
            case TFloat64:
                needCTypes = false;
                'double';
            case TSample:
                return cstdIntType(outputType, sampleType);
            case TArray(type, length):
                outputType.subscript = length;
                return cstdIntType(outputType, type);
            case TBool:
                needCTypes = false;
                'bool';
        }
        return needCTypes;
    }

    public static function generatePlainCpp(nodeDescriptor:NodeDescriptor):String
    {
        var cppFile = new CppFile();
        var needCTypes = false;
        var cppClass = new CppClass({name: nodeDescriptor.className});
        for (classVar in nodeDescriptor.classVars) {
            var isConst = !classVar.mutable && classVar.category == CClass;
            var type = {name: '', subscript: null};
            needCTypes = cstdIntType(type, classVar.type) || needCTypes;
            var cppDecl = new CppDeclaration({type: type, isConst: isConst, name: classVar.name});
            cppClass.children.push(cppDecl);
        }
        if (needCTypes) {
            cppFile.children.push(new CppInclude({name: 'cstdint'}));
        }
        cppFile.children.push(cppClass);
        return cppFile.serialize();
    }

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
        for (classVar in nodeDescriptor.classVars) {
            var isConst = !classVar.mutable && classVar.category == CClass;
            var type = {name: '', subscript: null};
            cstdIntType(type, classVar.type);
            var cppDecl = new CppDeclaration({type: type, isConst: isConst, name: classVar.name});
            cFile.children.push(cppDecl);
            if (classVar.category == CParameter) {
                params.push(classVar);
            }
        }
        cFile.children.push(BREAK);

        // Making the function to edit the parameters
        var oscParamFn = new CppFunction({returnType: 'void', name: 'OSC_PARAM'});
        oscParamFn.arguments.push(new CppArgument({type: 'uint16_t', name: 'index'}));
        oscParamFn.arguments.push(new CppArgument({type: 'uint16_t', name: 'value'}));

        var oscParamSwitch = new CppControl('switch');
        oscParamSwitch.conditions.push(new CppArbitrary('index'));
        oscParamFn.children.push(oscParamSwitch);

        cFile.children.push(oscParamFn);

        return cFile.serialize();
    }
}