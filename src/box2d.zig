const std = @import("std");
/// This allows users to get the "native" version of Box2D, which is just an @cImport of Box2Ds headers.
pub const native = @import("box2dnative.zig");

// -> api.h
// TODO: add function that just takes a Zig allocator object.
// That may be quite dificult to do, seeing as the free function does not have a length argument while Zig allocators require that.

/// Prototype for user allocation function.
/// size: the allocation size in bytes
/// alignment: the required alignment, guaranteed to be a power of 2
pub const AllocFn = fn(size: c_uint, alignment: c_int) callconv(.C) *anyopaque;

/// Prototype for user free function.
///	mem: the memory previously allocated through `b2AllocFcn`
pub const FreeFn = fn(mem: *anyopaque) callconv(.C) void;

/// Prototype for the user assert callback. Return 0 to skip the debugger break.
pub const AssertFn = fn(condition: [*:0]const u8, fileName: [*:0]const u8, lineNumber: c_int) callconv(.C) c_int;

/// This allows the user to override the allocation functions. These should be
///	set during application startup.
pub fn SetAllocator(alloc: *AllocFn, free: *FreeFn) void {
    native.b2SetAllocator(&alloc, &free);
}

/// Total bytes allocated by Box2D
pub fn GetByteCount() u32 {
    return @intCast(native.b2GetByteCount());
}

/// Override the default assert callback.
/// assertFn: a non-null assert callback
pub fn SetAssertFn(assertFn: *AssertFn) void {
    native.b2SetAssertFcn(assertFn);
}

