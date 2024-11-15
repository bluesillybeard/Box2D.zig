# Box2d.zig

Box2D v3 for the Zig programming language. Can also be used to make cross-compiling Box2D easier.

Tested on zig stable (currently 0.13.0) and master (0.14.0-dev.xyz). See the commit history for which version of zig master was last tested. It also probably works with the Mach nominated version of Zig, however it is not explicitly tested with that.

It's not too hard to @cImport Box2D's headers, but a binding is certainly nice. Plus integrating Cmake projects into Zig can be rather annoying.

## How to use

If all you want to do is compile box2d into a static or shared library, simply clone the repository and use `zig build static` or `zig build shared` to make a static or shared library respectively.

Of course, you're probably here to use Box2D with Zig. I recomend using a git submodule, and doing the following:

In your `build.zig`
```zig
const box2d = @import("Box2D.zig/build.zig");

...

// This calls b.addModule, with the name as "box2d" and uses the binding for the source file
// It then adds all of Box2Ds source files and the include directory to that module
const box2dModule = box2d.addModule(b, "Box2D.zig", .{});
exe.root_module.addImport("box2d", box2dModule);
```

This also probably works using Zigs package `build.zig.zon` thing, however I have not tested it yet as I don't use that system for any of my own projects.

## Other notes

The binding is under heavy work, but it's nearly there. All that's missing are:
- move collision functions into shape structs
- add enforced type safety for userData and context pointers
    - userData type validation will be done at runtime, since it's just an opaque pointer that gets eaten and regurgitated
- copy documentation over (with minor modifications to fit the binding better)
- there are a number of TODOs

I suggest using the native option `@import("box2d").native` for now, however the binding is close enough to ready that it's in a mostly usable state if you are willing to do bits of refactoring as it matures.

## TODO
- Compare performance between compiling with cmake+clang and zig (in theory it should be identical, since they are both ultimately LLVM+clang)
    - translate benchmarks
    - option for BOX2D_ENABLE_SIMD
    - option for BOX2D_AVX2
- add option for b2_maxWorlds
    - This isn't even in Box2D's build system as far as I can tell, need to edit the source code for that?
- Work on the actual binding (see [Other notes](#other-notes))
- Once the actual binding is in a good state, get this added to the Box2D bindings list.
- port all of the unit tests over (except the ones that test internal Box2D functions)
- translate the entire samples app
    - Quite a bit of an undertaking, but I think it wouldn't be too hard.
- there are a lot of TODOs regaurding automatic validation of the binding
- package this into various places
    - build.zig.zon

## Update checklist
When we update the Box2D version, we need to do this set of steps:
- read over ALL changes that were made. Note any:
    - API changes
    - ABI changes
    - Documentation changes
    - build system changes.
- Pull from git and apply the noted changes to the binding.
- I know this is tedious, but we probably won't need to update that often.
- To get all changes: `git diff main...origin/main > diff.diff`, open in vscode
    - search for `diff --git a/.*\.txt` for build system changes
    - search for `diff --git a/include/.*\.h` for API, ABI, and documentation changes
