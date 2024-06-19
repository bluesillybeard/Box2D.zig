const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const box2dModule = try addModule(b, "./", .{
        .target = target,
        .optimize = optimize,
    });

    // test runner
    const t = b.addTest(.{
        .root_source_file = b.path("src/box2d.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    try link("./", &t.root_module, .{
        .target = target,
        .optimize = optimize,
    });
    const testArtifact = b.addRunArtifact(t);
    const runTest = b.step("test", "Run tests");
    runTest.dependOn(&testArtifact.step);

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
    const installHeadersStep = addInstallHeaders(b, "./");
    staticLibStep.dependOn(installHeadersStep);
    sharedLibStep.dependOn(installHeadersStep);

}

fn addInstallHeaders(b: *std.Build, comptime modulePath: []const u8) *std.Build.Step {
    const step = b.step("headers", "Copy headers to output directory. Automatically done when building static or shared library.");
    step.dependOn(&b.addInstallDirectory(.{
        .install_dir = .header,
        .source_dir = b.path(modulePath ++ "/box2c/include/"),
        .install_subdir = "",
    }).step);
    // step.dependOn(&b.addInstallHeaderFile(b.path(modulePath ++ "/box2c/include/box2d/api.h"), "api.h").step);
    return step;
}

pub const Box2dOptions = struct {
    target: ?std.Build.ResolvedTarget = null,
    optimize: ?std.builtin.OptimizeMode = null,
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
    _ = options;
    var args = try std.ArrayList([]const u8).initCapacity(c.owner.allocator, 8);
    try args.append("-I");
    try args.append(modulePath ++ "/box2c/include");
    try args.append("-std=gnu17");
    // Thankfully, simde is entirely header files which makes this pretty easy
    try args.append("-I");
    try args.append(modulePath ++ "/box2c/extern/simde");

    // "Where did all the AVX2 stuff go?"
    // A: I believe that stuff is already handled by Zig's build system automatically. I may be wrong about that though.

    // TODO: figure out how this works. It looks like it just generates an extra .h file and defines a macro, however I would like to make sure that's the only result.
    // option(BOX2D_USER_CONSTANTS "Generate user_constants.h" OFF)
    // if (BOX2D_USER_CONSTANTS)
    // 	set(BOX2D_LENGTH_UNIT_PER_METER "1.0" CACHE STRING "Length units per meter")
    // 	set(BOX2D_MAX_POLYGON_VERTICES "8" CACHE STRING "Maximum number of polygon vertices (affects performance)")
    // endif()
    // if (BOX2D_USER_CONSTANTS)
    // 	# this file allows users to override constants
    // 	configure_file(user_constants.h.in user_constants.h)
    // 	target_compile_definitions(box2d PUBLIC BOX2D_USER_CONSTANTS)
    // endif()
    c.addCSourceFiles(.{
        .files = &[_][]const u8{
            modulePath ++ "/box2c/src/aabb.c",
            modulePath ++ "/box2c/src/allocate.c",
            modulePath ++ "/box2c/src/array.c",
            modulePath ++ "/box2c/src/bitset.c",
            modulePath ++ "/box2c/src/block_allocator.c",
            modulePath ++ "/box2c/src/block_array.c",
            modulePath ++ "/box2c/src/body.c",
            modulePath ++ "/box2c/src/broad_phase.c",
            modulePath ++ "/box2c/src/constraint_graph.c",
            modulePath ++ "/box2c/src/contact.c",
            modulePath ++ "/box2c/src/contact_solver.c",
            modulePath ++ "/box2c/src/core.c",
            modulePath ++ "/box2c/src/distance.c",
            modulePath ++ "/box2c/src/distance_joint.c",
            modulePath ++ "/box2c/src/dynamic_tree.c",
            modulePath ++ "/box2c/src/geometry.c",
            modulePath ++ "/box2c/src/hull.c",
            modulePath ++ "/box2c/src/id_pool.c",
            modulePath ++ "/box2c/src/implementation.c",
            modulePath ++ "/box2c/src/island.c",
            modulePath ++ "/box2c/src/joint.c",
            modulePath ++ "/box2c/src/manifold.c",
            modulePath ++ "/box2c/src/math_functions.c",
            modulePath ++ "/box2c/src/motor_joint.c",
            modulePath ++ "/box2c/src/mouse_joint.c",
            modulePath ++ "/box2c/src/prismatic_joint.c",
            modulePath ++ "/box2c/src/revolute_joint.c",
            modulePath ++ "/box2c/src/shape.c",
            modulePath ++ "/box2c/src/solver.c",
            modulePath ++ "/box2c/src/solver_set.c",
            modulePath ++ "/box2c/src/stack_allocator.c",
            modulePath ++ "/box2c/src/table.c",
            modulePath ++ "/box2c/src/timer.c",
            modulePath ++ "/box2c/src/types.c",
            modulePath ++ "/box2c/src/weld_joint.c",
            modulePath ++ "/box2c/src/wheel_joint.c",
            modulePath ++ "/box2c/src/world.c",
        },
        .flags = try args.toOwnedSlice(),
    });
    c.addIncludePath(c.owner.path(modulePath ++ "/box2c/include/"));
    c.link_libc = true;
}
