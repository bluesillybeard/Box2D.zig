const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const box2dModule = try addModule(b, "./", .{
        .target = target,
        .optimize = optimize,
    });

    // test runner
    {
        const t = b.addTest(.{
            .root_source_file = b.path("src/test.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        const cflags: []const []const u8 = blk: {
            switch (target.result.os.tag) {
                .macos, .ios, .tvos, .visionos, .watchos => {
                    // determinism options
                    // TODO: does this actually work? I have no apple hardware to test on
                    // note: requires translating the determinism tests over (or adding the C files directly from box2D)
                    break :blk &[_][]const u8{"-ffp-contract=off"};
                },
                else => {
                    break :blk &[_][]const u8{};
                },
            }
        };
        // TODO: remove when 0.14 becomes stable
        if (comptime std.mem.eql(u8, builtin.zig_version_string, "0.13.0")) {
            try link("./", &t.root_module, .{
                .target = target,
                .optimize = optimize,
                .cflags = cflags,
            });
        } else {
            try link("./", t.root_module, .{
                .target = target,
                .optimize = optimize,
                .cflags = cflags,
            });
        }

        const testArtifact = b.addRunArtifact(t);
        const runTest = b.step("test", "Run tests");
        runTest.dependOn(&testArtifact.step);
    }

    const installHeadersStep = addInstallHeaders(b, "./");
    // build static lib
    {
        const staticLib = b.addStaticLibrary(.{
            .name = "box2d",
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        staticLib.root_module.addImport("box2d", box2dModule);
        const staticLibArtifact = b.addInstallArtifact(staticLib, .{});
        const staticLibStep = b.step("static", "Build a static library of box2d");
        staticLibStep.dependOn(&staticLibArtifact.step);
        staticLibStep.dependOn(installHeadersStep);
    }

    // build shared lib
    {
        const sharedLib = b.addSharedLibrary(.{
            .name = "box2d",
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        sharedLib.root_module.addImport("box2d", box2dModule);
        const sharedLibArtifact = b.addInstallArtifact(sharedLib, .{});
        const sharedLibStep = b.step("shared", "Build a shared library of box2d");
        sharedLibStep.dependOn(&sharedLibArtifact.step);
        sharedLibStep.dependOn(installHeadersStep);
    }

    // build samples app
    {
        const samplesExe = b.addExecutable(.{
            .name = "samples",
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        samplesExe.linkLibCpp();
        // Link directly instead of using a module so we get the include dirs.
        const additionalCFlags: []const []const u8 = blk: {
            switch (target.result.os.tag) {
                else => {
                    break :blk &[_][]const u8{};
                },
            }
        };
        if (comptime std.mem.eql(u8, builtin.zig_version_string, "0.13.0")) {
            try link("./", &samplesExe.root_module, .{
                .target = target,
                .optimize = optimize,
                .cflags = additionalCFlags,
            });
        } else {
            try link("./", samplesExe.root_module, .{
                .target = target,
                .optimize = optimize,
                .cflags = additionalCFlags,
            });
        }
        // the samples app uses GLAD. Instead of making a library, just add the sources.
        samplesExe.addCSourceFile(.{ .file = b.path("box2d/extern/glad/src/glad.c") });
        samplesExe.addIncludePath(b.path("box2d/extern/glad/include"));
        // Note: the cmake for the samples app does a bit more work to find GLFW nicely.
        // We just do the equivalent of '-l glfw'
        samplesExe.root_module.linkSystemLibrary("glfw", .{});
        // Imgui, as well as the backends needed for use GLFW and OpenGL
        // Zig could use something like cmake's fetch content... For now, we just have Imgui as a git submodule
        // TODO: does imgui have a zig build system integration yet?
        samplesExe.addCSourceFiles(.{ .files = &[_][]const u8{
            "imgui/imgui.cpp",
            "imgui/imgui_draw.cpp",
            "imgui/imgui_demo.cpp",
            "imgui/imgui_tables.cpp",
            "imgui/imgui_widgets.cpp",
            "imgui/backends/imgui_impl_glfw.cpp",
            "imgui/backends/imgui_impl_opengl3.cpp",
        }, .flags = &[_][]const u8{
            "-std=c++17",
            "-DIMGUI_DISABLE_OBSOLETE_FUNCTIONS",
        } });
        samplesExe.addIncludePath(b.path("imgui"));
        samplesExe.addIncludePath(b.path("imgui/backends"));
        // jsmn for json
        samplesExe.addIncludePath(b.path("box2d/extern/jsmn/"));
        // add the source files for the samples app
        samplesExe.addCSourceFiles(.{
            .files = &[_][]const u8{
                "box2d/samples/car.cpp",
                "box2d/samples/donut.cpp",
                "box2d/samples/doohickey.cpp",
                "box2d/samples/draw.cpp",
                "box2d/samples/human.cpp",
                "box2d/samples/main.cpp",
                "box2d/samples/sample.cpp",
                "box2d/samples/sample_benchmark.cpp",
                "box2d/samples/sample_bodies.cpp",
                "box2d/samples/sample_collision.cpp",
                "box2d/samples/sample_continuous.cpp",
                "box2d/samples/sample_events.cpp",
                "box2d/samples/sample_geometry.cpp",
                "box2d/samples/sample_joints.cpp",
                "box2d/samples/sample_robustness.cpp",
                "box2d/samples/sample_shapes.cpp",
                "box2d/samples/sample_stacking.cpp",
                "box2d/samples/sample_world.cpp",
                "box2d/samples/sample_determinism.cpp",
                "box2d/samples/settings.cpp",
                "box2d/samples/shader.cpp",
            },
            .flags = &[_][]const u8{
                //TODO: does this need the additional C flags from earlier?
                "-std=c++17",
            },
        });
        // enable determinism

        samplesExe.addIncludePath(b.path("box2d/samples"));
        // We also need enkiTS
        // Like with Imgui, it's a submodule...
        samplesExe.addCSourceFile(.{
            .file = b.path("enkiTS/src/TaskScheduler.cpp"),
            .flags = &[_][]const u8{},
        });
        samplesExe.addIncludePath(b.path("enkiTS/src"));
        // step to copy the resources for the samples app
        const copyFilesStep = b.addInstallDirectory(.{
            .source_dir = b.path("box2d/samples/data"),
            // TODO: probably incorrect
            .install_dir = .{ .bin = void{} },
            .install_subdir = "data",
        });

        const samplesExeArtifact = b.addInstallArtifact(samplesExe, .{});
        const samplesExeStep = b.step("samples", "Build the samples app");
        samplesExeStep.dependOn(&copyFilesStep.step);
        samplesExeStep.dependOn(&samplesExeArtifact.step);
    }

    // build test exe
    {
        const t = b.addExecutable(.{
            .root_source_file = b.path("src/test.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .name = "testexe",
        });
        const cflags: []const []const u8 = blk: {
            switch (target.result.os.tag) {
                .macos, .ios, .tvos, .visionos, .watchos => {
                    // determinism options
                    // TODO: does this actually work? I have no apple hardware to test on
                    // note: requires translating the determinism tests over (or adding the C files directly from box2D)
                    break :blk &[_][]const u8{"-ffp-contract=off"};
                },
                else => {
                    break :blk &[_][]const u8{};
                },
            }
        };
        // TODO: remove when 0.14 becomes stable
        if (comptime std.mem.eql(u8, builtin.zig_version_string, "0.13.0")) {
            try link("./", &t.root_module, .{
                .target = target,
                .optimize = optimize,
                .cflags = cflags,
            });
        } else {
            try link("./", t.root_module, .{
                .target = target,
                .optimize = optimize,
                .cflags = cflags,
            });
        }

        const testArtifact = b.addInstallArtifact(t, .{});
        const runTest = b.step("testexe", "Built tests as an exe that can be debugged in a regular debugger");
        runTest.dependOn(&testArtifact.step);
    }
}

fn addInstallHeaders(b: *std.Build, comptime modulePath: []const u8) *std.Build.Step {
    const step = b.step("headers", "Copy headers to output directory. Automatically done when building static or shared library.");
    step.dependOn(&b.addInstallDirectory(.{
        .install_dir = .header,
        .source_dir = b.path(modulePath ++ "/box2d/include/"),
        .install_subdir = "",
    }).step);
    return step;
}

pub const Box2dOptions = struct {
    target: ?std.Build.ResolvedTarget = null,
    optimize: ?std.builtin.OptimizeMode = null,
    cflags: ?[]const []const u8 = null,
};

/// Adds the box2d module and returns it.
pub fn addModule(b: *std.Build, comptime modulePath: []const u8, options: Box2dOptions) !*std.Build.Module {
    const module = b.addModule("box2d", .{
        .root_source_file = b.path(modulePath ++ "/src/box2d.zig"),
        .target = options.target,
        .optimize = options.optimize,
    });
    try link(modulePath, module, options);
    return module;
}

fn link(comptime modulePath: []const u8, c: *std.Build.Module, options: Box2dOptions) !void {
    var args = try std.ArrayList([]const u8).initCapacity(c.owner.allocator, 8);
    try args.append("-I");
    try args.append(modulePath ++ "/box2d/include");
    try args.append("-std=gnu17");
    const target = options.target.?.result;
    // determinism options: https://box2d.org/posts/2024/08/determinism/
    // TODO: does this actually work? Should probably set up CI the same way original Box2D has.
    // note: requires translating the determinism tests over (or adding the C files directly from box2D)
    // MINGW OR APPLE OR UNIX
    // TODO: more comprehsneive way to test for unix systems
    if (target.isMinGW() or target.isDarwin() or target.isGnu() or target.isBSD() or target.isAndroid() or target.isMusl()) {
        try args.append("-ffp-contract=off");
    }

    // TODO: original build system checks for EMSCRIPTEN, is that strictly only emscripten or meant for wasm?
    // Also, is this required? If not, might it be best to leave this for users to determine? Zig, as far as I can tell, enthusiastically enables SIMD.
    // Other platforms have this too, but I've heard on certain versions of IOS it actually crashes without simd.
    if (target.isWasm()) {
        try args.append("-msimd128");
        try args.append("-msse2");
    }

    if (options.cflags) |cflags| {
        try args.appendSlice(cflags);
    }

    // "Where did all the AVX2 stuff go?"
    // A: I believe that stuff is already handled by Zig's build system automatically. I may be wrong about that though.

    c.addCSourceFiles(.{
        .root = c.owner.path(modulePath ++ "/box2d/src/"),
        .files = &[_][]const u8{
            "aabb.c",
            "array.c",
            "bitset.c",
            "body.c",
            "broad_phase.c",
            "constraint_graph.c",
            "contact.c",
            "contact_solver.c",
            "core.c",
            "distance.c",
            "distance_joint.c",
            "dynamic_tree.c",
            "geometry.c",
            "hull.c",
            "id_pool.c",
            "island.c",
            "joint.c",
            "manifold.c",
            "math_functions.c",
            "motor_joint.c",
            "mouse_joint.c",
            "prismatic_joint.c",
            "revolute_joint.c",
            "shape.c",
            "solver.c",
            "solver_set.c",
            "stack_allocator.c",
            "table.c",
            "timer.c",
            "types.c",
            "weld_joint.c",
            "wheel_joint.c",
            "world.c",
        },
        .flags = try args.toOwnedSlice(),
    });
    c.addIncludePath(c.owner.path(modulePath ++ "/box2d/include/"));
    c.link_libc = true;
}
