package grig.hxal;

import grig.hxal.Node;

@name("Sine Synth", 'en')
@name("サインシンセサイザー", 'jp')
@version("0.0.1")
class Sine extends Node
{
    @parameter @name("OSC1 Frequency", 'en') var frequency1:Float;
    @parameter @name("OSC2 Frequency", 'en') var frequency2:Float;
    @parameter var approximate:Bool;

    var phase:Float;

    var gain:Array<Sample, 2>;

    final const:Float = phase;

    // var multiplier:Array<Int16, 2>;

    // public function onNoteOn():Void
    // {

    // }

    function onAudioFrame():Array<Sample>
    {
        var data:Int = 0;
        phase += 0.1;
        return 0.0;
    }
}