# Box2d.zig

Box2D v3 for the Zig programming language.

It is tested on zig stable (currently 0.12.0) and master (0.13.0-dev.xyz). See the commit history for which version of zig master was last tested.

## How to use

If all you want to do is compile box2d into a static or shared library, simply clone the repository and use `zig build static` or `zig build shared` to make a static or shared library respectively.

Of course, you're probably here to use your project with Zig. I recomend using a git submodule, and doing the following:

In your `build.zig`
```zig
const box2d = @import('Box2D.zig/build.zig);

...

const box2dModule = box2d.addModule("Box2D.zig", .{});
exe.root_module.addImport("box2d", box2dModule);
```

This also probably works using Zig's package `build.zig.zon` thing, however I have not tested it yet.

## Other notes



## TODO
- Compare performance between compiling with cmake+clang and zig (in theory it should be identical, since they are both ultimately LLVM+clang)
- Work on the actual binding
    - Step one: re-declare all types and functions in box2d.zig
    - Step two: zigify things (vague but hopefully clear enough)