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

    c.addCSourceFiles(.{
        .root = c.owner.path(modulePath ++ "/box2c/src/"),
        .files = &[_][]const u8{
            "aabb.c",
            "allocate.c",
            "array.c",
            "bitset.c",
            "block_array.c",
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
    c.addIncludePath(c.owner.path(modulePath ++ "/box2c/include/"));
    c.link_libc = true;
}
