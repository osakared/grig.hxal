package grig.hxal;

import grig.hxal.Instrument;

@:build(grig.hxal.Transpiler.buildInstrument())
class Sine implements Instrument
{
    @mutable var phase:Float;

    public function process()
    {
        var data:Int = 0;
    }

    public function new()
    {
    }
}