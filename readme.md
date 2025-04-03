# Box2d.zig

Box2D v3 for the Zig programming language. Can also be used to make cross-compiling Box2D easier.

Quick note: waiting for 3.1 for the first proper release - until then, your best bet is to import the C library directly

Tested on zig stable (currently 0.13.0) and master (0.14.0-dev.xyz). See the commit history for which version of zig master was last tested. It also probably works with the Mach nominated version of Zig, however it is not explicitly tested with that.

It's not too hard to @cImport Box2D's headers, but a binding is certainly nice. Plus integrating Cmake projects into Zig can be rather annoying.

## How to use

If all you want to do is compile box2d into a static or shared library, simply clone the repository, init the `box2d` git submodule, and use `zig build static` or `zig build shared` to make a static or shared library respectively.

Of course, you're probably here to use Box2D with Zig. Right now, it's a bit of a mess. This is not a fault of Zig, but a fault of this project. We will have proper Zig packages available soon.

For now, use a git submodule or equivalent (such as cloning the repo into a subfolder of your project). Make sure the `box2d` submodule in this repository is initialized. Then, add this code to your `build.zig`:

```
// You can find-replace "Box2D.zig" with the path to the folder with this repository
const box2d = @import("Box2d.zig/build.zig");

// This calls b.addModule, with the name as "box2d" and uses the binding for the source file
// It then adds all of Box2Ds source files and the include directory to that module
const box2dModule = box2d.addModule(b, "Box2D.zig", .{});
exe.root_module.addImport("box2d", box2dModule);
```

## Other notes

The binding is under heavy work, but it's nearly there. All that's missing are:
- add enforced type safety for userData and context pointers
    - userData type validation will be done at runtime, since it's just an opaque pointer that gets eaten and regurgitated
    - Not sure the best way to go about this, so leaving it as-is
- copy documentation over (with minor modifications to fit the binding better)
- there are a number of TODOs

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
- package this into various places
    - Zig's package manager

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
