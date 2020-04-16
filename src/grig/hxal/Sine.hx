package grig.hxal;

import grig.hxal.Instrument;

class Sine extends Instrument
{
    @mutable var phase:Blorp;

    public function process()
    {
        var data:Int = 0;
        phase += 0.1;
    }
}