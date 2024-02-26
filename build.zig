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
    // TODO: step to compile to a library (.a and .dll)
}

pub const Box2dOptions = struct {};

/// Links Box2D to a compile step
pub fn link(comptime modulePath: []const u8, c: *std.Build.Step.Compile, options: Box2dOptions) !void {
    _ = options;
    var args = try std.ArrayList([]const u8).initCapacity(c.root_module.owner.allocator, 8);
    try args.append("-I");
    try args.append(modulePath ++ "/include");
    try args.append("-std=c17");
    // Thankfully, simde is entirely header files which makes this pretty easy
    try args.append("-I");
    try args.append(modulePath ++ "/extern/simde");
    // args.append("-I");
    // args.append(modulePath ++ "extern/simde/x86");

    // "Where did all the AVX2 stuff go?"
    // A: That is already handled by Zig's build system automatically.

    // TODO: figure out how this works. It looks like it just generates an extra .h file and defines a macro, however I would like t make sure that's the only result.
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
            modulePath ++ "/src/aabb.c",
            modulePath ++ "/src/allocate.c",
            modulePath ++ "/src/array.c",
            modulePath ++ "/src/bitset.c",
            // TODO: figure out what this does
            //modulePath ++ "/src/bitset.inl",
            modulePath ++ "/src/block_allocator.c",
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
            modulePath ++ "/src/implementation.c",
            modulePath ++ "/src/island.c",
            modulePath ++ "/src/joint.c",
            modulePath ++ "/src/manifold.c",
            modulePath ++ "/src/math.c",
            modulePath ++ "/src/motor_joint.c",
            modulePath ++ "/src/mouse_joint.c",
            modulePath ++ "/src/pool.c",
            modulePath ++ "/src/prismatic_joint.c",
            modulePath ++ "/src/revolute_joint.c",
            modulePath ++ "/src/shape.c",
            modulePath ++ "/src/solver.c",
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
}
