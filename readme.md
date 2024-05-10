# Box2d.zig

Box2D v3 for the Zig programming language.

This does not provide bindings, only an easier way to link Box2D to your project. It more or less simply reimplements Box2D's cmake files into a `build.zig`.

It is tested on zig stable (currently 0.12.0) and master (0.13.0-dev.xyz). See the commit history for which version of zig master was last tested.

## TODO
- Compare performance between compiling with cmake+clang and zig (in theory it should be identical, since they are both ultimately LLVM+clang)
