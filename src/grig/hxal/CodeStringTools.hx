package grig.hxal;

class CodeStringTools
{
    public static function prependLines(s:String, prefix:String):String
    {
        var newS = '';
        for (line in s.split('\n')) {
            newS += prefix + line + '\n';
        }
        return newS;
    }
}