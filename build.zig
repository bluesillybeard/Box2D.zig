const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // test runner
    const t = b.addTest(.{
        .root_source_file = .{ .path = "tests/tests.zig" },
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    try link("box2c", t, .{});
    const runStep = b.step("test", "Run tests");
    runStep.dependOn(&t.step);

    const staticLib = b.addStaticLibrary(.{
        .name = "box2d",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    try link("box2c", staticLib, .{});
    b.installArtifact(staticLib);
    const staticLibArtifact = b.addInstallArtifact(staticLib, .{});
    const staticLibStep = b.step("static", "Build a static library of box2d");
    staticLibStep.dependOn(&staticLibArtifact.step);

    const sharedLib = b.addSharedLibrary(.{
        .name = "box2d",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    try link("box2c", sharedLib, .{});
    b.installArtifact(sharedLib);
    const sharedLibArtifact = b.addInstallArtifact(sharedLib, .{});
    const sharedLibStep = b.step("shared", "Build a shared library of box2d");
    sharedLibStep.dependOn(&sharedLibArtifact.step);
}

pub const Box2dOptions = struct {};

/// Links Box2D to a compile step
pub fn link(comptime modulePath: []const u8, c: *std.Build.Step.Compile, options: Box2dOptions) !void {
    _ = options;
    var args = try std.ArrayList([]const u8).initCapacity(c.root_module.owner.allocator, 8);
    try args.append("-I");
    try args.append(modulePath ++ "/include");
    try args.append("-std=gnu17");
    // Thankfully, simde is entirely header files which makes this pretty easy
    try args.append("-I");
    try args.append(modulePath ++ "/extern/simde");

    // "Where did all the AVX2 stuff go?"
    // A: That is already handled by Zig's build system automatically.

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
        .files = &[_][]const u8 {
            modulePath ++ "/src/aabb.c",
            modulePath ++ "/src/allocate.c",
            modulePath ++ "/src/array.c",
            modulePath ++ "/src/bitset.c",
            modulePath ++ "/src/block_allocator.c",
            modulePath ++ "/src/block_array.c",
            modulePath ++ "/src/body.c",
            modulePath ++ "/src/broad_phase.c",
            modulePath ++ "/src/constraint_graph.c",
            modulePath ++ "/src/contact.c",
            modulePath ++ "/src/contact_solver.c",
            modulePath ++ "/src/core.c",
            modulePath ++ "/src/distance.c",
            modulePath ++ "/src/distance_joint.c",
            modulePath ++ "/src/dynamic_tree.c",
            modulePath ++ "/src/geometry.c",
            modulePath ++ "/src/hull.c",
            modulePath ++ "/src/id_pool.c",
            modulePath ++ "/src/implementation.c",
            modulePath ++ "/src/island.c",
            modulePath ++ "/src/joint.c",
            modulePath ++ "/src/manifold.c",
            modulePath ++ "/src/math_functions.c",
            modulePath ++ "/src/motor_joint.c",
            modulePath ++ "/src/mouse_joint.c",
            modulePath ++ "/src/prismatic_joint.c",
            modulePath ++ "/src/revolute_joint.c",
            modulePath ++ "/src/shape.c",
            modulePath ++ "/src/solver.c",
            modulePath ++ "/src/solver_set.c",
            modulePath ++ "/src/stack_allocator.c",
            modulePath ++ "/src/table.c",
            modulePath ++ "/src/timer.c",
            modulePath ++ "/src/types.c",
            modulePath ++ "/src/weld_joint.c",
            modulePath ++ "/src/wheel_joint.c",
            modulePath ++ "/src/world.c",
        },
        .flags = try args.toOwnedSlice(),
    });
    c.addIncludePath(.{ .path = modulePath ++ "/include/" });
    c.linkLibC();
}
