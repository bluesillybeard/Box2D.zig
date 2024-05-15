const std = @import("std");
const testing = std.testing;
const box2d = @import("box2d");
const box2dnative = box2d.native;

// This is required since native is a raw translate-c, and translate-c creates compile errors when certain declarations are referenced.
fn refAllDeclsExceptNative(T: type) void {
    inline for (comptime std.meta.declarations(T)) |decl| {
        if (!std.mem.eql(u8, decl.name, "native")) {
            _ = &@field(T, decl.name);
        }
    }
}

// The only point of this test is to make sure Box2D is linked correctly.
// It is essentially a copy of test/test_math.c
// Box2D itself is well tested. Seeing as this binding is quite simple, I don't think it needs extensive unit testing beyond this.
test "MathTest" {
    refAllDeclsExceptNative(box2d);
    const zero = box2dnative.b2Vec2_zero;
    const one = box2dnative.b2Vec2{ .x = 1.0, .y = 1.0 };
    const two = box2dnative.b2Vec2{ .x = 2.0, .y = 2.0 };

    var v = box2dnative.b2Add(one, two);
    try testing.expect(v.x == 3.0 and v.y == 3.0);

    v = box2dnative.b2Sub(zero, two);
    try testing.expect(v.x == -2.0 and v.y == -2.0);

    v = box2dnative.b2Add(two, two);
    try testing.expect(v.x != 5.0 and v.y != 5.0);

    const xf1 = box2dnative.b2Transform{ .p = .{ .x = -2.0, .y = 3.0 }, .q = box2dnative.b2MakeRot(1.0) };
    const xf2 = box2dnative.b2Transform{ .p = .{ .x = 1.0, .y = 0.0 }, .q = box2dnative.b2MakeRot(-2.0) };

    const xf = box2dnative.b2MulTransforms(xf2, xf1);

    v = box2dnative.b2TransformPoint(xf2, box2dnative.b2TransformPoint(xf1, two));

    const u = box2dnative.b2TransformPoint(xf, two);

    try testing.expectApproxEqAbs(0, u.y - v.y, 10.0 * std.math.floatEps(f32));

    v = box2dnative.b2TransformPoint(xf1, two);
    v = box2dnative.b2InvTransformPoint(xf1, v);

    try testing.expectApproxEqAbs(0, v.x - two.x, 8.0 * std.math.floatEps(f32));
    try testing.expectApproxEqAbs(0, v.y - two.y, 8.0 * std.math.floatEps(f32));
}
