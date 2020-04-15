# hxal

[Haxe](https://haxe.org/) Audio Language. A haxe-based DSL for real-time audio applications built using haxe's macro system. Part of [grig](https://haxe.org/).

EARLY STAGE OF DEVELOPMENT. Ignore if you are expecting something you can use right away. Other parts of grig can be used now (grig.midi, grig.audio) but not this.

## Design Goals

* Look and behave like haxe
* Lightweight and simple
* Facilitates two different compilation pathways:
  * Straightforward compilation as haxe code with minimal modification by the macro aside from swapping hxal types for grig types
  * Transpilation straight to non-garbage-colleged targets. Planned:
    * [soul](https://soul.dev/)
    * rust
    * c/c++
      * lv2 plugins
      * vst plugins
      * ...
* Allows declaration of variables, assignments, arithmetic but prevents allocations and frees, ensuring that the code is suitable for realtime even on gc targets.
* Facilitates concurrency and safety with immutable by default (rustian haxe) and other use of decorators to give hxal and target environments information it can use to optimize. _Unsure about this... discuss!_
* Meant to be easy to port legacy c++ code to, rather than being a radically different paradigm like faust
* Err on the side of simple and works, rather than being clever
* Designed to build atop other's work, in keeping with the general philosophy of haxe.