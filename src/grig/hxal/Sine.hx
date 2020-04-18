package grig.hxal;

import grig.hxal.Node;

@name("Sine Synth", 'en')
@version("0.0.1")
class Sine extends Node
{
    @input @name("OSC1 Frequency") var frequency1:Float;
    @input @name("OSC2 Frequency") var frequency2:Float;

    @mutable var phase:Float;

    var gain:Array<Sample, 2>;

    // public function onNoteOn():Void
    // {

    // }

    public function onAudioFrame():Array<Sample>
    {
        var data:Int = 0;
        phase += 0.1;
        return 0.0;
    }
}