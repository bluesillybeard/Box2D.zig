# Box2d.zig

Box2D v3 for the Zig programming language.

Tested on zig stable (currently 0.12.0) and master (0.13.0-dev.xyz). See the commit history for which version of zig master was last tested. It also probably works with the Mach nominated version of Zig, however it is not explicitly tested with that.

It's not too hard to @cImport Box2D's headers, but a binding is certainly nice. Plus integrating Cmake projects into Zig can be rather annoying.

## How to use

If all you want to do is compile box2d into a static or shared library, simply clone the repository and use `zig build static` or `zig build shared` to make a static or shared library respectively.

Of course, you're probably here to use your project with Zig. I recomend using a git submodule, and doing the following:

In your `build.zig`
```zig
const box2d = @import('Box2D.zig/build.zig);

...

// This calls b.addModule, with the name as "box2d" and uses the binding for the source file
const box2dModule = box2d.addModule(b, "Box2D.zig", .{});
exe.root_module.addImport("box2d", box2dModule);
```

This also probably works using Zigs package `build.zig.zon` thing, however I have not tested it yet.

## Other notes

The binding does not significantly change the API. The biggest notable change is that things are slightly renamed to follow style guidlines:
```
b2WorldId -> WorldId
b2CreateWorld() -> createWorld()
b2World_IsValid() -> worldIsValid()

// This one is an exception - it caused a name conflict which will be removed in stage 3.
// This is temporary and will hopefully be fixed soon.
b2Length() -> vec2Length()
```

Eventually, the binding will sort everything into namespace structs and use the "OOP-like" syntax (`b2World_IsValid(world)` -> `world.isValid()`)

## TODO
- Compare performance between compiling with cmake+clang and zig (in theory it should be identical, since they are both ultimately LLVM+clang)
- Work on the actual binding
    - Move structs out of native and convert functions like `worldIsValid` to use the Zig "OOP-like" syntax: `world.isValid` (Stage 3)
    - add generics and stuff where reasonable (Stage 4)
        - Since box2d can't do comptime verification stuff directly, and adding comptime type checking would be annoying and limiting, maybe wrap the context types in a special box that checks to make sure it matches at runtime.
    - Copy and tweak inline documentation from Box2D
        - This is done last since the documentation is a work in progress
