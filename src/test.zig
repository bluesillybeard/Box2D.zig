const std = @import("std");
const box2d = @import("box2d.zig");
const native = box2d.native;

// The only point of this test is to make sure Box2D is linked correctly.
// TODO: fully translate all of Box2D's tests. Also put the tests in a separate file.
test "MathTest" {
    const zero = native.b2Vec2_zero;
    const one = native.b2Vec2{ .x = 1.0, .y = 1.0 };
    const two = native.b2Vec2{ .x = 2.0, .y = 2.0 };

    var v = native.b2Add(one, two);
    try std.testing.expect(v.x == 3.0 and v.y == 3.0);

    v = native.b2Sub(zero, two);
    try std.testing.expect(v.x == -2.0 and v.y == -2.0);

    v = native.b2Add(two, two);
    try std.testing.expect(v.x != 5.0 and v.y != 5.0);

    const xf1 = native.b2Transform{ .p = .{ .x = -2.0, .y = 3.0 }, .q = native.b2MakeRot(1.0) };
    const xf2 = native.b2Transform{ .p = .{ .x = 1.0, .y = 0.0 }, .q = native.b2MakeRot(-2.0) };

    const xf = native.b2MulTransforms(xf2, xf1);

    v = native.b2TransformPoint(xf2, native.b2TransformPoint(xf1, two));

    const u = native.b2TransformPoint(xf, two);

    try std.testing.expectApproxEqAbs(0, u.y - v.y, 10.0 * std.math.floatEps(f32));

    v = native.b2TransformPoint(xf1, two);
    v = native.b2InvTransformPoint(xf1, v);

    try std.testing.expectApproxEqAbs(0, v.x - two.x, 8.0 * std.math.floatEps(f32));
    try std.testing.expectApproxEqAbs(0, v.y - two.y, 8.0 * std.math.floatEps(f32));
}

// Make sure:
// - our types are compatible with Box2D types
// - we mention all of Box2D functions in case any are added/renamed
// - we don't mention any missing Box2D types or functions for when they are removed/renamed
test "Box2DCompatibilityAndCompletion" {
    // On old versions of zig, do not do the test.
    // They changed the capitalization of all type enums, and doing the ABI test on both would drive me completely insane
    if (comptime @hasField(std.builtin.Type, "Struct")) {
        return;
    }

    // Debugging tests is a nightmare, so we have call into another function.
    // This this is for CI and stuff, but the function has a separate entry point so it can be compiled to a nice binary that can be debugged.
    try box2dCompatibiltyAndCompletionTest(std.testing.allocator);
}

// for debugging
pub fn main() !void {
    var allocatorObj = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = allocatorObj.allocator();
    try box2dCompatibiltyAndCompletionTest(allocator);
}

fn box2dCompatibiltyAndCompletionTest(allocator: std.mem.Allocator) !void {
    // catch those semantic errors for uncalled / unreferenced types.
    // This will not be really nessesary once all of the unit testing is moved over
    // TODO: apparently this does not actually check for errors within functions... sad.
    // Still need to do a unit test where ALL functions are called.
    recursivelyRefAllDeclsExceptNative(box2d);
    // We need to do two things:
    // - Make sure all of our types are compatible with Box2D
    // - Make sure all Box2D types / functions / constants are handled
    // Everything else will be automatically verified by the compiler
    // Use a struct to make things easier

    var check: ApiCompatibilityChecker = blk: {
        var headerThings = std.ArrayList([]const u8).init(allocator);
        defer headerThings.deinit();
        @setEvalBranchQuota(100000);
        inline for (@typeInfo(native).@"struct".decls) |decl| {
            // Only box2d things, not the libc / standard header stuff
            if (std.mem.startsWith(u8, decl.name, "b2") or std.mem.startsWith(u8, decl.name, "B2")) {
                try headerThings.append(decl.name);
            }
        }
        var c: ApiCompatibilityChecker = undefined;
        try c.init(headerThings, allocator);
        break :blk c;
    };

    defer check.deinit();

    // check all of the structs
    try std.testing.expect(check.relateTypes(box2d.WorldId, native.b2WorldId).passes);
    try std.testing.expect(check.relateTypes(box2d.WorldDef, native.b2WorldDef).passes);
    try std.testing.expect(check.relateTypes(box2d.DebugDraw, native.b2DebugDraw).passes);
    try std.testing.expect(check.relateTypes(box2d.BodyEvents, native.b2BodyEvents).passes);
    try std.testing.expect(check.relateTypes(box2d.SensorEvents, native.b2SensorEvents).passes);
    try std.testing.expect(check.relateTypes(box2d.ContactEvents, native.b2ContactEvents).passes);
    try std.testing.expect(check.relateTypes(box2d.AABB, native.b2AABB).passes);
    try std.testing.expect(check.relateTypes(box2d.QueryFilter, native.b2QueryFilter).passes);
    try std.testing.expect(check.relateTypes(box2d.ShapeId, native.b2ShapeId).passes);
    try std.testing.expect(check.relateTypes(box2d.Circle, native.b2Circle).passes);
    try std.testing.expect(check.relateTypes(box2d.Transform, native.b2Transform).passes);
    try std.testing.expect(check.relateTypes(box2d.Capsule, native.b2Capsule).passes);
    try std.testing.expect(check.relateTypes(box2d.Polygon, native.b2Polygon).passes);
    try std.testing.expect(check.relateTypes(box2d.Vec2, native.b2Vec2).passes);
    try std.testing.expect(check.relateTypes(box2d.RayResult, native.b2RayResult).passes);
    try std.testing.expect(check.relateTypes(box2d.Manifold, native.b2Manifold).passes);
    try std.testing.expect(check.relateTypes(box2d.Profile, native.b2Profile).passes);
    try std.testing.expect(check.relateTypes(box2d.Counters, native.b2Counters).passes);
    try std.testing.expect(check.relateTypes(box2d.BodyDef, native.b2BodyDef).passes);
    try std.testing.expect(check.relateTypes(box2d.BodyId, native.b2BodyId).passes);
    try std.testing.expect(check.relateTypes(box2d.Rot, native.b2Rot).passes);
    try std.testing.expect(check.relateTypes(box2d.MassData, native.b2MassData).passes);
    try std.testing.expect(check.relateTypes(box2d.JointId, native.b2JointId).passes);
    try std.testing.expect(check.relateTypes(box2d.ContactData, native.b2ContactData).passes);
    try std.testing.expect(check.relateTypes(box2d.ShapeDef, native.b2ShapeDef).passes);
    try std.testing.expect(check.relateTypes(box2d.Segment, native.b2Segment).passes);
    try std.testing.expect(check.relateTypes(box2d.Filter, native.b2Filter).passes);
    try std.testing.expect(check.relateTypes(box2d.CastOutput, native.b2CastOutput).passes);
    try std.testing.expect(check.relateTypes(box2d.ChainSegment, native.b2ChainSegment).passes);
    try std.testing.expect(check.relateTypes(box2d.ChainId, native.b2ChainId).passes);
    try std.testing.expect(check.relateTypes(box2d.ChainDef, native.b2ChainDef).passes);
    try std.testing.expect(check.relateTypes(box2d.DistanceJointDef, native.b2DistanceJointDef).passes);
    try std.testing.expect(check.relateTypes(box2d.MotorJointDef, native.b2MotorJointDef).passes);
    try std.testing.expect(check.relateTypes(box2d.MouseJointDef, native.b2MouseJointDef).passes);
    try std.testing.expect(check.relateTypes(box2d.PrismaticJointDef, native.b2PrismaticJointDef).passes);
    try std.testing.expect(check.relateTypes(box2d.RevoluteJointDef, native.b2RevoluteJointDef).passes);
    try std.testing.expect(check.relateTypes(box2d.WeldJointDef, native.b2WeldJointDef).passes);
    try std.testing.expect(check.relateTypes(box2d.WheelJointDef, native.b2WheelJointDef).passes);
    try std.testing.expect(check.relateTypes(box2d.SegmentDistanceResult, native.b2SegmentDistanceResult).passes);
    try std.testing.expect(check.relateTypes(box2d.DistanceCache, native.b2DistanceCache).passes);
    try std.testing.expect(check.relateTypes(box2d.DistanceInput, native.b2DistanceInput).passes);
    try std.testing.expect(check.relateTypes(box2d.DistanceOutput, native.b2DistanceOutput).passes);
    try std.testing.expect(check.relateTypes(box2d.ShapeCastPairInput, native.b2ShapeCastPairInput).passes);
    try std.testing.expect(check.relateTypes(box2d.DistanceProxy, native.b2DistanceProxy).passes);
    try std.testing.expect(check.relateTypes(box2d.Sweep, native.b2Sweep).passes);
    try std.testing.expect(check.relateTypes(box2d.DynamicTree, native.b2DynamicTree).passes);
    try std.testing.expect(check.relateTypes(box2d.RayCastInput, native.b2RayCastInput).passes);
    try std.testing.expect(check.relateTypes(box2d.ShapeCastInput, native.b2ShapeCastInput).passes);
    try std.testing.expect(check.relateTypes(box2d.Hull, native.b2Hull).passes);
    try std.testing.expect(check.relateTypes(box2d.TOIInput, native.b2TOIInput).passes);
    try std.testing.expect(check.relateTypes(box2d.TOIOutput, native.b2TOIOutput).passes);
    try std.testing.expect(check.relateTypes(box2d.SimplexVertex, native.b2SimplexVertex).passes);
    try std.testing.expect(check.relateTypes(box2d.Simplex, native.b2Simplex).passes);
    try std.testing.expect(check.relateTypes(box2d.ContactBeginTouchEvent, native.b2ContactBeginTouchEvent).passes);
    try std.testing.expect(check.relateTypes(box2d.ContactEndTouchEvent, native.b2ContactEndTouchEvent).passes);
    try std.testing.expect(check.relateTypes(box2d.ContactHitEvent, native.b2ContactHitEvent).passes);
    try std.testing.expect(check.relateTypes(box2d.TreeNode, native.b2TreeNode).passes);
    try std.testing.expect(check.relateTypes(box2d.ManifoldPoint, native.b2ManifoldPoint).passes);
    try std.testing.expect(check.relateTypes(box2d.SensorEndTouchEvent, native.b2SensorEndTouchEvent).passes);
    try std.testing.expect(check.relateTypes(box2d.SensorBeginTouchEvent, native.b2SensorBeginTouchEvent).passes);
    try std.testing.expect(check.relateTypes(box2d.BodyMoveEvent, native.b2BodyMoveEvent).passes);
    try std.testing.expect(check.relateTypes(box2d.TreeStats, native.b2TreeStats).passes);
    try std.testing.expect(check.relateTypes(box2d.ExplosionDef, native.b2ExplosionDef).passes);
    try std.testing.expect(check.relateTypes(box2d.NullJointDef, native.b2NullJointDef).passes);
    try std.testing.expect(check.relateTypes(box2d.CosSin, native.b2CosSin).passes);
    try std.testing.expect(check.relateTypes(box2d.Version, native.b2Version).passes);

    // constants
    try std.testing.expect(check.relateValues(u64, box2d.defaultCategoryBits, native.B2_DEFAULT_CATEGORY_BITS, "B2_DEFAULT_CATEGORY_BITS").passes);
    try std.testing.expect(check.relateValues(u64, box2d.defaultCategoryBits, @intCast(native.b2_defaultCategoryBits), "b2_defaultCategoryBits").passes);
    try std.testing.expect(check.relateValues(u64, box2d.defaultMaskBits, native.B2_DEFAULT_MASK_BITS, "B2_DEFAULT_MASK_BITS").passes);
    try std.testing.expect(check.relateValues(u64, box2d.defaultMaskBits, native.b2_defaultMaskBits, "b2_defaultMaskBits").passes);
    try std.testing.expect(check.relateValues(usize, box2d.maxPolygonVertices, @intCast(native.b2_maxPolygonVertices), "b2_maxPolygonVertices").passes);
    try std.testing.expect(check.relateValues(box2d.Vec2, box2d.Vec2.zero, @bitCast(native.b2Vec2_zero), "b2Vec2_zero").passes);
    try std.testing.expect(check.relateValues(box2d.Rot, box2d.Rot.identity, @bitCast(native.b2Rot_identity), "b2Rot_identity").passes);
    try std.testing.expect(check.relateValues(box2d.Transform, box2d.Transform.identity, @bitCast(native.b2Transform_identity), "b2Transform_identity").passes);
    try std.testing.expect(check.relateValues(box2d.DistanceCache, box2d.DistanceCache.empty, @bitCast(native.b2_emptyDistanceCache), "b2_emptyDistanceCache").passes);

    // There are A LOT of colors
    try std.testing.expect(check.relateTypesImplName(box2d.HexColor, native.b2HexColor, "b2HexColor").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.aliceBlue, native.b2_colorAliceBlue, "b2_colorAliceBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.antiqueWhite, native.b2_colorAntiqueWhite, "b2_colorAntiqueWhite").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.aquamarine, native.b2_colorAquamarine, "b2_colorAquamarine").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.azure, native.b2_colorAzure, "b2_colorAzure").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.beige, native.b2_colorBeige, "b2_colorBeige").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.bisque, native.b2_colorBisque, "b2_colorBisque").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.black, native.b2_colorBlack, "b2_colorBlack").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.blanchedAlmond, native.b2_colorBlanchedAlmond, "b2_colorBlanchedAlmond").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.blue, native.b2_colorBlue, "b2_colorBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.blueViolet, native.b2_colorBlueViolet, "b2_colorBlueViolet").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.brown, native.b2_colorBrown, "b2_colorBrown").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.burlywood, native.b2_colorBurlywood, "b2_colorBurlywood").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.cadetBlue, native.b2_colorCadetBlue, "b2_colorCadetBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.chartreuse, native.b2_colorChartreuse, "b2_colorChartreuse").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.chocolate, native.b2_colorChocolate, "b2_colorChocolate").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.coral, native.b2_colorCoral, "b2_colorCoral").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.cornflowerBlue, native.b2_colorCornflowerBlue, "b2_colorCornflowerBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.cornsilk, native.b2_colorCornsilk, "b2_colorCornsilk").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.crimson, native.b2_colorCrimson, "b2_colorCrimson").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.cyan, native.b2_colorCyan, "b2_colorCyan").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkBlue, native.b2_colorDarkBlue, "b2_colorDarkBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkCyan, native.b2_colorDarkCyan, "b2_colorDarkCyan").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkGoldenrod, native.b2_colorDarkGoldenrod, "b2_colorDarkGoldenrod").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkGray, native.b2_colorDarkGray, "b2_colorDarkGray").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkGreen, native.b2_colorDarkGreen, "b2_colorDarkGreen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkKhaki, native.b2_colorDarkKhaki, "b2_colorDarkKhaki").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkMagenta, native.b2_colorDarkMagenta, "b2_colorDarkMagenta").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkOliveGreen, native.b2_colorDarkOliveGreen, "b2_colorDarkOliveGreen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkOrange, native.b2_colorDarkOrange, "b2_colorDarkOrange").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkOrchid, native.b2_colorDarkOrchid, "b2_colorDarkOrchid").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkRed, native.b2_colorDarkRed, "b2_colorDarkRed").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkSalmon, native.b2_colorDarkSalmon, "b2_colorDarkSalmon").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkSeaGreen, native.b2_colorDarkSeaGreen, "b2_colorDarkSeaGreen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkSlateBlue, native.b2_colorDarkSlateBlue, "b2_colorDarkSlateBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkSlateGray, native.b2_colorDarkSlateGray, "b2_colorDarkSlateGray").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkTurquoise, native.b2_colorDarkTurquoise, "b2_colorDarkTurquoise").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.darkViolet, native.b2_colorDarkViolet, "b2_colorDarkViolet").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.deepPink, native.b2_colorDeepPink, "b2_colorDeepPink").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.deepSkyBlue, native.b2_colorDeepSkyBlue, "b2_colorDeepSkyBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.dimGray, native.b2_colorDimGray, "b2_colorDimGray").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.dodgerBlue, native.b2_colorDodgerBlue, "b2_colorDodgerBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.firebrick, native.b2_colorFirebrick, "b2_colorFirebrick").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.floralWhite, native.b2_colorFloralWhite, "b2_colorFloralWhite").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.forestGreen, native.b2_colorForestGreen, "b2_colorForestGreen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.gainsboro, native.b2_colorGainsboro, "b2_colorGainsboro").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.ghostWhite, native.b2_colorGhostWhite, "b2_colorGhostWhite").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.gold, native.b2_colorGold, "b2_colorGold").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.goldenrod, native.b2_colorGoldenrod, "b2_colorGoldenrod").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.gray, native.b2_colorGray, "b2_colorGray").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.gray1, native.b2_colorGray1, "b2_colorGray1").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.gray2, native.b2_colorGray2, "b2_colorGray2").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.gray3, native.b2_colorGray3, "b2_colorGray3").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.gray4, native.b2_colorGray4, "b2_colorGray4").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.gray5, native.b2_colorGray5, "b2_colorGray5").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.gray6, native.b2_colorGray6, "b2_colorGray6").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.gray7, native.b2_colorGray7, "b2_colorGray7").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.gray8, native.b2_colorGray8, "b2_colorGray8").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.gray9, native.b2_colorGray9, "b2_colorGray9").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.green, native.b2_colorGreen, "b2_colorGreen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.greenYellow, native.b2_colorGreenYellow, "b2_colorGreenYellow").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.honeydew, native.b2_colorHoneydew, "b2_colorHoneydew").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.hotPink, native.b2_colorHotPink, "b2_colorHotPink").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.indianRed, native.b2_colorIndianRed, "b2_colorIndianRed").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.indigo, native.b2_colorIndigo, "b2_colorIndigo").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.ivory, native.b2_colorIvory, "b2_colorIvory").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.khaki, native.b2_colorKhaki, "b2_colorKhaki").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lavender, native.b2_colorLavender, "b2_colorLavender").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lavenderBlush, native.b2_colorLavenderBlush, "b2_colorLavenderBlush").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lawnGreen, native.b2_colorLawnGreen, "b2_colorLawnGreen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lemonChiffon, native.b2_colorLemonChiffon, "b2_colorLemonChiffon").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lightBlue, native.b2_colorLightBlue, "b2_colorLightBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lightCoral, native.b2_colorLightCoral, "b2_colorLightCoral").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lightCyan, native.b2_colorLightCyan, "b2_colorLightCyan").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lightGoldenrod, native.b2_colorLightGoldenrod, "b2_colorLightGoldenrod").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lightGoldenrodYellow, native.b2_colorLightGoldenrodYellow, "b2_colorLightGoldenrodYellow").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lightGray, native.b2_colorLightGray, "b2_colorLightGray").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lightGreen, native.b2_colorLightGreen, "b2_colorLightGreen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lightPink, native.b2_colorLightPink, "b2_colorLightPink").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lightSalmon, native.b2_colorLightSalmon, "b2_colorLightSalmon").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lightSeaGreen, native.b2_colorLightSeaGreen, "b2_colorLightSeaGreen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lightSkyBlue, native.b2_colorLightSkyBlue, "b2_colorLightSkyBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lightSlateBlue, native.b2_colorLightSlateBlue, "b2_colorLightSlateBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lightSlateGray, native.b2_colorLightSlateGray, "b2_colorLightSlateGray").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lightSteelBlue, native.b2_colorLightSteelBlue, "b2_colorLightSteelBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.lightYellow, native.b2_colorLightYellow, "b2_colorLightYellow").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.limeGreen, native.b2_colorLimeGreen, "b2_colorLimeGreen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.linen, native.b2_colorLinen, "b2_colorLinen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.magenta, native.b2_colorMagenta, "b2_colorMagenta").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.maroon, native.b2_colorMaroon, "b2_colorMaroon").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.mediumAquamarine, native.b2_colorMediumAquamarine, "b2_colorMediumAquamarine").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.mediumBlue, native.b2_colorMediumBlue, "b2_colorMediumBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.mediumOrchid, native.b2_colorMediumOrchid, "b2_colorMediumOrchid").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.mediumPurple, native.b2_colorMediumPurple, "b2_colorMediumPurple").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.mediumSeaGreen, native.b2_colorMediumSeaGreen, "b2_colorMediumSeaGreen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.mediumSlateBlue, native.b2_colorMediumSlateBlue, "b2_colorMediumSlateBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.mediumSpringGreen, native.b2_colorMediumSpringGreen, "b2_colorMediumSpringGreen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.mediumTurquoise, native.b2_colorMediumTurquoise, "b2_colorMediumTurquoise").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.mediumVioletRed, native.b2_colorMediumVioletRed, "b2_colorMediumVioletRed").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.midnightBlue, native.b2_colorMidnightBlue, "b2_colorMidnightBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.mintCream, native.b2_colorMintCream, "b2_colorMintCream").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.mistyRose, native.b2_colorMistyRose, "b2_colorMistyRose").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.moccasin, native.b2_colorMoccasin, "b2_colorMoccasin").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.navajoWhite, native.b2_colorNavajoWhite, "b2_colorNavajoWhite").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.navyBlue, native.b2_colorNavyBlue, "b2_colorNavyBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.oldLace, native.b2_colorOldLace, "b2_colorOldLace").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.olive, native.b2_colorOlive, "b2_colorOlive").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.oliveDrab, native.b2_colorOliveDrab, "b2_colorOliveDrab").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.orange, native.b2_colorOrange, "b2_colorOrange").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.orangeRed, native.b2_colorOrangeRed, "b2_colorOrangeRed").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.orchid, native.b2_colorOrchid, "b2_colorOrchid").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.paleGoldenrod, native.b2_colorPaleGoldenrod, "b2_colorPaleGoldenrod").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.paleGreen, native.b2_colorPaleGreen, "b2_colorPaleGreen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.paleTurquoise, native.b2_colorPaleTurquoise, "b2_colorPaleTurquoise").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.paleVioletRed, native.b2_colorPaleVioletRed, "b2_colorPaleVioletRed").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.papayaWhip, native.b2_colorPapayaWhip, "b2_colorPapayaWhip").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.peachPuff, native.b2_colorPeachPuff, "b2_colorPeachPuff").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.peru, native.b2_colorPeru, "b2_colorPeru").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.pink, native.b2_colorPink, "b2_colorPink").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.plum, native.b2_colorPlum, "b2_colorPlum").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.powderBlue, native.b2_colorPowderBlue, "b2_colorPowderBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.purple, native.b2_colorPurple, "b2_colorPurple").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.rebeccaPurple, native.b2_colorRebeccaPurple, "b2_colorRebeccaPurple").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.red, native.b2_colorRed, "b2_colorRed").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.RosyBrown, native.b2_colorRosyBrown, "b2_colorRosyBrown").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.RoyalBlue, native.b2_colorRoyalBlue, "b2_colorRoyalBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.saddleBrown, native.b2_colorSaddleBrown, "b2_colorSaddleBrown").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.salmon, native.b2_colorSalmon, "b2_colorSalmon").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.sandyBrown, native.b2_colorSandyBrown, "b2_colorSandyBrown").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.seaGreen, native.b2_colorSeaGreen, "b2_colorSeaGreen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.seashell, native.b2_colorSeashell, "b2_colorSeashell").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.sienna, native.b2_colorSienna, "b2_colorSienna").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.silver, native.b2_colorSilver, "b2_colorSilver").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.skyBlue, native.b2_colorSkyBlue, "b2_colorSkyBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.slateBlue, native.b2_colorSlateBlue, "b2_colorSlateBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.slateGray, native.b2_colorSlateGray, "b2_colorSlateGray").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.snow, native.b2_colorSnow, "b2_colorSnow").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.springGreen, native.b2_colorSpringGreen, "b2_colorSpringGreen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.steelBlue, native.b2_colorSteelBlue, "b2_colorSteelBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.tan, native.b2_colorTan, "b2_colorTan").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.teal, native.b2_colorTeal, "b2_colorTeal").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.thistle, native.b2_colorThistle, "b2_colorThistle").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.tomato, native.b2_colorTomato, "b2_colorTomato").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.turquoise, native.b2_colorTurquoise, "b2_colorTurquoise").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.violet, native.b2_colorViolet, "b2_colorViolet").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.violetRed, native.b2_colorVioletRed, "b2_colorVioletRed").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.wheat, native.b2_colorWheat, "b2_colorWheat").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.white, native.b2_colorWhite, "b2_colorWhite").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.whiteSmoke, native.b2_colorWhiteSmoke, "b2_colorWhiteSmoke").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.yellow, native.b2_colorYellow, "b2_colorYellow").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.yellowGreen, native.b2_colorYellowGreen, "b2_colorYellowGreen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.box2DRed, native.b2_colorBox2DRed, "b2_colorBox2DRed").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.box2DBlue, native.b2_colorBox2DBlue, "b2_colorBox2DBlue").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.box2DGreen, native.b2_colorBox2DGreen, "b2_colorBox2DGreen").passes);
    try std.testing.expect(check.relateValues(u32, box2d.HexColors.box2DYellow, native.b2_colorBox2DYellow, "b2_colorBox2DYellow").passes);

    // Enums - colors is kinda an enum, but from here on out are the REAL enums
    try std.testing.expect(check.relateTypesImplName(box2d.TOIState, native.b2TOIState, "b2TOIState").passes);
    try std.testing.expect(check.relateValues(box2d.TOIState, box2d.TOIState.unknown, @enumFromInt(native.b2_toiStateUnknown), "b2_toiStateUnknown").passes);
    try std.testing.expect(check.relateValues(box2d.TOIState, box2d.TOIState.failed, @enumFromInt(native.b2_toiStateFailed), "b2_toiStateFailed").passes);
    try std.testing.expect(check.relateValues(box2d.TOIState, box2d.TOIState.overlapped, @enumFromInt(native.b2_toiStateOverlapped), "b2_toiStateOverlapped").passes);
    try std.testing.expect(check.relateValues(box2d.TOIState, box2d.TOIState.hit, @enumFromInt(native.b2_toiStateHit), "b2_toiStateHit").passes);
    try std.testing.expect(check.relateValues(box2d.TOIState, box2d.TOIState.separated, @enumFromInt(native.b2_toiStateSeparated), "b2_toiStateSeparated").passes);

    try std.testing.expect(check.relateTypesImplName(box2d.MixingRule, native.b2MixingRule, "b2MixingRule").passes);
    try std.testing.expect(check.relateValues(box2d.MixingRule, box2d.MixingRule.average, @enumFromInt(native.b2_mixAverage), "b2_mixAverage").passes);
    try std.testing.expect(check.relateValues(box2d.MixingRule, box2d.MixingRule.geometricMean, @enumFromInt(native.b2_mixGeometricMean), "b2_mixGeometricMean").passes);
    try std.testing.expect(check.relateValues(box2d.MixingRule, box2d.MixingRule.multiply, @enumFromInt(native.b2_mixMultiply), "b2_mixMultiply").passes);
    try std.testing.expect(check.relateValues(box2d.MixingRule, box2d.MixingRule.minimum, @enumFromInt(native.b2_mixMinimum), "b2_mixMinimum").passes);
    try std.testing.expect(check.relateValues(box2d.MixingRule, box2d.MixingRule.maximum, @enumFromInt(native.b2_mixMaximum), "b2_mixMaximum").passes);

    try std.testing.expect(check.relateTypesImplName(box2d.BodyType, native.b2BodyType, "b2BodyType").passes);
    try std.testing.expect(check.relateValues(box2d.BodyType, box2d.BodyType.static, @enumFromInt(native.b2_staticBody), "b2_staticBody").passes);
    try std.testing.expect(check.relateValues(box2d.BodyType, box2d.BodyType.kinematic, @enumFromInt(native.b2_kinematicBody), "b2_kinematicBody").passes);
    try std.testing.expect(check.relateValues(box2d.BodyType, box2d.BodyType.dynamic, @enumFromInt(native.b2_dynamicBody), "b2_dynamicBody").passes);
    try std.testing.expect(check.relateValues(c_uint, 3, native.b2_bodyTypeCount, "b2_bodyTypeCount").passes);

    try std.testing.expect(check.relateTypesImplName(box2d.ShapeType, native.b2ShapeType, "b2ShapeType").passes);
    try std.testing.expect(check.relateValues(box2d.ShapeType, box2d.ShapeType.circle, @enumFromInt(native.b2_circleShape), "b2_circleShape").passes);
    try std.testing.expect(check.relateValues(box2d.ShapeType, box2d.ShapeType.capsule, @enumFromInt(native.b2_capsuleShape), "b2_capsuleShape").passes);
    try std.testing.expect(check.relateValues(box2d.ShapeType, box2d.ShapeType.segment, @enumFromInt(native.b2_segmentShape), "b2_segmentShape").passes);
    try std.testing.expect(check.relateValues(box2d.ShapeType, box2d.ShapeType.polygon, @enumFromInt(native.b2_polygonShape), "b2_polygonShape").passes);
    try std.testing.expect(check.relateValues(box2d.ShapeType, box2d.ShapeType.chainSegment, @enumFromInt(native.b2_chainSegmentShape), "b2_chainSegmentShape").passes);
    try std.testing.expect(check.relateValues(c_uint, 5, native.b2_shapeTypeCount, "b2_shapeTypeCount").passes);

    try std.testing.expect(check.relateTypesImplName(box2d.JointType, native.b2JointType, "b2JointType").passes);
    try std.testing.expect(check.relateValues(box2d.JointType, box2d.JointType.distance, @enumFromInt(native.b2_distanceJoint), "b2_distanceJoint").passes);
    try std.testing.expect(check.relateValues(box2d.JointType, box2d.JointType.motor, @enumFromInt(native.b2_motorJoint), "b2_motorJoint").passes);
    try std.testing.expect(check.relateValues(box2d.JointType, box2d.JointType.mouse, @enumFromInt(native.b2_mouseJoint), "b2_mouseJoint").passes);
    try std.testing.expect(check.relateValues(box2d.JointType, box2d.JointType.null, @enumFromInt(native.b2_nullJoint), "b2_nullJoint").passes);
    try std.testing.expect(check.relateValues(box2d.JointType, box2d.JointType.prismatic, @enumFromInt(native.b2_prismaticJoint), "b2_prismaticJoint").passes);
    try std.testing.expect(check.relateValues(box2d.JointType, box2d.JointType.revolute, @enumFromInt(native.b2_revoluteJoint), "b2_revoluteJoint").passes);
    try std.testing.expect(check.relateValues(box2d.JointType, box2d.JointType.weld, @enumFromInt(native.b2_weldJoint), "b2_weldJoint").passes);
    try std.testing.expect(check.relateValues(box2d.JointType, box2d.JointType.wheel, @enumFromInt(native.b2_wheelJoint), "b2_wheelJoint").passes);
    // Function pointers.

    try std.testing.expect(check.relateTypesImplName(box2d.CastResultFn, native.b2CastResultFcn, "b2CastResultFcn").passes);
    try std.testing.expect(check.relateTypesImplName(box2d.PreSolveFn, native.b2PreSolveFcn, "b2PreSolveFcn").passes);
    try std.testing.expect(check.relateTypesImplName(box2d.TreeQueryCallbackFn, native.b2TreeQueryCallbackFcn, "b2TreeQueryCallbackFcn").passes);
    try std.testing.expect(check.relateTypesImplName(box2d.TreeRayCastCallbackFn, native.b2TreeRayCastCallbackFcn, "b2TreeRayCastCallbackFcn").passes);
    try std.testing.expect(check.relateTypesImplName(box2d.TreeShapeCastCallbackFn, native.b2TreeShapeCastCallbackFcn, "b2TreeShapeCastCallbackFcn").passes);
    try std.testing.expect(check.relateTypesImplName(box2d.OverlapResultFn, native.b2OverlapResultFcn, "b2OverlapResultFcn").passes);
    try std.testing.expect(check.relateTypesImplName(box2d.AllocFn, native.b2AllocFcn, "b2AllocFcn").passes);
    try std.testing.expect(check.relateTypesImplName(box2d.FreeFn, native.b2FreeFcn, "b2FreeFcn").passes);
    try std.testing.expect(check.relateTypesImplName(box2d.AssertFn, native.b2AssertFcn, "b2AssertFcn").passes);
    try std.testing.expect(check.relateTypesImplName(box2d.TaskCallback, native.b2TaskCallback, "b2TaskCallback").passes);
    try std.testing.expect(check.relateTypesImplName(box2d.EnqueueTaskCallback, native.b2EnqueueTaskCallback, "b2EnqueueTaskCallback").passes);
    try std.testing.expect(check.relateTypesImplName(box2d.FinishTaskCallback, native.b2FinishTaskCallback, "b2FinishTaskCallback").passes);
    try std.testing.expect(check.relateTypesImplName(box2d.CustomFilterFn, native.b2CustomFilterFcn, "b2CustomFilterFcn").passes);

    // functions that we have bindings for - this does not validate that they are called correctly.
    // It makes sure that all of them have bindings.

    try std.testing.expect(check.mention("b2ComputeSegmentAABB"));
    try std.testing.expect(check.mention("b2MakeRot"));
    try std.testing.expect(check.mention("b2Rot_IsValid"));
    try std.testing.expect(check.mention("b2Vec2_IsValid"));
    try std.testing.expect(check.mention("b2DefaultDebugDraw"));
    try std.testing.expect(check.mention("b2DefaultShapeDef"));
    try std.testing.expect(check.mention("b2DefaultChainDef"));
    try std.testing.expect(check.mention("b2DefaultDistanceJointDef"));
    try std.testing.expect(check.mention("b2DefaultMotorJointDef"));
    try std.testing.expect(check.mention("b2DefaultMouseJointDef"));
    try std.testing.expect(check.mention("b2DefaultNullJointDef"));
    try std.testing.expect(check.mention("b2DefaultPrismaticJointDef"));
    try std.testing.expect(check.mention("b2DefaultRevoluteJointDef"));
    try std.testing.expect(check.mention("b2DefaultWeldJointDef"));
    try std.testing.expect(check.mention("b2DefaultWheelJointDef"));
    try std.testing.expect(check.mention("b2DefaultExplosionDef"));
    try std.testing.expect(check.mention("b2DefaultBodyDef"));
    try std.testing.expect(check.mention("b2DefaultWorldDef"));
    try std.testing.expect(check.mention("b2CreateWorld"));
    try std.testing.expect(check.mention("b2DestroyWorld"));
    try std.testing.expect(check.mention("b2World_IsValid"));
    try std.testing.expect(check.mention("b2World_Step"));
    try std.testing.expect(check.mention("b2World_Draw"));
    try std.testing.expect(check.mention("b2World_GetBodyEvents"));
    try std.testing.expect(check.mention("b2World_GetSensorEvents"));
    try std.testing.expect(check.mention("b2World_GetContactEvents"));
    try std.testing.expect(check.mention("b2World_OverlapAABB"));
    try std.testing.expect(check.mention("b2World_OverlapCircle"));
    try std.testing.expect(check.mention("b2World_OverlapPoint"));
    try std.testing.expect(check.mention("b2World_OverlapCapsule"));
    try std.testing.expect(check.mention("b2World_OverlapPolygon"));
    try std.testing.expect(check.mention("b2World_CastRay"));
    try std.testing.expect(check.mention("b2World_CastRayClosest"));
    try std.testing.expect(check.mention("b2World_CastCircle"));
    try std.testing.expect(check.mention("b2World_CastCapsule"));
    try std.testing.expect(check.mention("b2World_CastPolygon"));
    try std.testing.expect(check.mention("b2World_EnableSleeping"));
    try std.testing.expect(check.mention("b2World_IsSleepingEnabled"));
    try std.testing.expect(check.mention("b2World_EnableWarmStarting"));
    try std.testing.expect(check.mention("b2World_IsWarmStartingEnabled"));
    try std.testing.expect(check.mention("b2World_EnableContinuous"));
    try std.testing.expect(check.mention("b2World_IsContinuousEnabled"));
    try std.testing.expect(check.mention("b2World_SetRestitutionThreshold"));
    try std.testing.expect(check.mention("b2World_GetRestitutionThreshold"));
    try std.testing.expect(check.mention("b2World_SetHitEventThreshold"));
    try std.testing.expect(check.mention("b2World_GetHitEventThreshold"));
    try std.testing.expect(check.mention("b2World_SetPreSolveCallback"));
    try std.testing.expect(check.mention("b2World_SetGravity"));
    try std.testing.expect(check.mention("b2World_GetGravity"));
    try std.testing.expect(check.mention("b2World_Explode"));
    try std.testing.expect(check.mention("b2World_SetContactTuning"));
    try std.testing.expect(check.mention("b2World_SetJointTuning"));
    try std.testing.expect(check.mention("b2World_SetMaximumLinearVelocity"));
    try std.testing.expect(check.mention("b2World_GetMaximumLinearVelocity"));
    try std.testing.expect(check.mention("b2World_SetUserData"));
    try std.testing.expect(check.mention("b2World_GetUserData"));
    try std.testing.expect(check.mention("b2World_GetProfile"));
    try std.testing.expect(check.mention("b2World_GetCounters"));
    try std.testing.expect(check.mention("b2World_DumpMemoryStats"));
    try std.testing.expect(check.mention("b2World_RebuildStaticTree"));
    try std.testing.expect(check.mention("b2World_SetCustomFilterCallback"));
    try std.testing.expect(check.mention("b2CreateNullJoint"));
    try std.testing.expect(check.mention("b2CreateDistanceJoint"));
    try std.testing.expect(check.mention("b2CreateMotorJoint"));
    try std.testing.expect(check.mention("b2CreateMouseJoint"));
    try std.testing.expect(check.mention("b2CreatePrismaticJoint"));
    try std.testing.expect(check.mention("b2CreateRevoluteJoint"));
    try std.testing.expect(check.mention("b2CreateWeldJoint"));
    try std.testing.expect(check.mention("b2WeldJoint_GetReferenceAngle"));
    try std.testing.expect(check.mention("b2WeldJoint_SetReferenceAngle"));
    try std.testing.expect(check.mention("b2WeldJoint_SetLinearHertz"));
    try std.testing.expect(check.mention("b2WeldJoint_GetLinearHertz"));
    try std.testing.expect(check.mention("b2WeldJoint_SetLinearDampingRatio"));
    try std.testing.expect(check.mention("b2WeldJoint_GetLinearDampingRatio"));
    try std.testing.expect(check.mention("b2WeldJoint_SetAngularHertz"));
    try std.testing.expect(check.mention("b2WeldJoint_GetAngularHertz"));
    try std.testing.expect(check.mention("b2WeldJoint_SetAngularDampingRatio"));
    try std.testing.expect(check.mention("b2WeldJoint_GetAngularDampingRatio"));
    try std.testing.expect(check.mention("b2CreateWheelJoint"));
    try std.testing.expect(check.mention("b2DestroyJoint"));
    try std.testing.expect(check.mention("b2Joint_IsValid"));
    try std.testing.expect(check.mention("b2Joint_GetWorld"));
    try std.testing.expect(check.mention("b2Joint_GetType"));
    try std.testing.expect(check.mention("b2Joint_GetBodyA"));
    try std.testing.expect(check.mention("b2Joint_GetBodyB"));
    try std.testing.expect(check.mention("b2Joint_GetLocalAnchorA"));
    try std.testing.expect(check.mention("b2Joint_GetLocalAnchorB"));
    try std.testing.expect(check.mention("b2Joint_SetCollideConnected"));
    try std.testing.expect(check.mention("b2Joint_GetCollideConnected"));
    try std.testing.expect(check.mention("b2Joint_SetUserData"));
    try std.testing.expect(check.mention("b2Joint_GetUserData"));
    try std.testing.expect(check.mention("b2Joint_WakeBodies"));
    try std.testing.expect(check.mention("b2Joint_GetConstraintForce"));
    try std.testing.expect(check.mention("b2Joint_GetConstraintTorque"));
    try std.testing.expect(check.mention("b2DistanceJoint_SetLength"));
    try std.testing.expect(check.mention("b2DistanceJoint_GetLength"));
    try std.testing.expect(check.mention("b2DistanceJoint_EnableSpring"));
    try std.testing.expect(check.mention("b2DistanceJoint_IsSpringEnabled"));
    try std.testing.expect(check.mention("b2DistanceJoint_SetSpringHertz"));
    try std.testing.expect(check.mention("b2DistanceJoint_SetSpringDampingRatio"));
    try std.testing.expect(check.mention("b2DistanceJoint_GetSpringHertz"));
    try std.testing.expect(check.mention("b2DistanceJoint_GetSpringDampingRatio"));
    try std.testing.expect(check.mention("b2DistanceJoint_EnableLimit"));
    try std.testing.expect(check.mention("b2DistanceJoint_IsLimitEnabled"));
    try std.testing.expect(check.mention("b2DistanceJoint_SetLengthRange"));
    try std.testing.expect(check.mention("b2DistanceJoint_GetMinLength"));
    try std.testing.expect(check.mention("b2DistanceJoint_GetMaxLength"));
    try std.testing.expect(check.mention("b2DistanceJoint_GetCurrentLength"));
    try std.testing.expect(check.mention("b2DistanceJoint_EnableMotor"));
    try std.testing.expect(check.mention("b2DistanceJoint_IsMotorEnabled"));
    try std.testing.expect(check.mention("b2DistanceJoint_SetMotorSpeed"));
    try std.testing.expect(check.mention("b2DistanceJoint_GetMotorSpeed"));
    try std.testing.expect(check.mention("b2DistanceJoint_GetMotorForce"));
    try std.testing.expect(check.mention("b2DistanceJoint_SetMaxMotorForce"));
    try std.testing.expect(check.mention("b2DistanceJoint_GetMaxMotorForce"));
    try std.testing.expect(check.mention("b2MotorJoint_SetLinearOffset"));
    try std.testing.expect(check.mention("b2MotorJoint_GetLinearOffset"));
    try std.testing.expect(check.mention("b2MotorJoint_SetAngularOffset"));
    try std.testing.expect(check.mention("b2MotorJoint_GetAngularOffset"));
    try std.testing.expect(check.mention("b2MotorJoint_SetMaxForce"));
    try std.testing.expect(check.mention("b2MotorJoint_GetMaxForce"));
    try std.testing.expect(check.mention("b2MotorJoint_SetMaxTorque"));
    try std.testing.expect(check.mention("b2MotorJoint_GetMaxTorque"));
    try std.testing.expect(check.mention("b2MotorJoint_SetCorrectionFactor"));
    try std.testing.expect(check.mention("b2MotorJoint_GetCorrectionFactor"));
    try std.testing.expect(check.mention("b2MouseJoint_SetTarget"));
    try std.testing.expect(check.mention("b2MouseJoint_GetTarget"));
    try std.testing.expect(check.mention("b2MouseJoint_SetSpringHertz"));
    try std.testing.expect(check.mention("b2MouseJoint_GetSpringHertz"));
    try std.testing.expect(check.mention("b2MouseJoint_SetMaxForce"));
    try std.testing.expect(check.mention("b2MouseJoint_GetMaxForce"));
    try std.testing.expect(check.mention("b2MouseJoint_SetSpringDampingRatio"));
    try std.testing.expect(check.mention("b2MouseJoint_GetSpringDampingRatio"));
    try std.testing.expect(check.mention("b2PrismaticJoint_EnableSpring"));
    try std.testing.expect(check.mention("b2PrismaticJoint_IsSpringEnabled"));
    try std.testing.expect(check.mention("b2PrismaticJoint_SetSpringHertz"));
    try std.testing.expect(check.mention("b2PrismaticJoint_GetSpringHertz"));
    try std.testing.expect(check.mention("b2PrismaticJoint_SetSpringDampingRatio"));
    try std.testing.expect(check.mention("b2PrismaticJoint_GetSpringDampingRatio"));
    try std.testing.expect(check.mention("b2PrismaticJoint_EnableLimit"));
    try std.testing.expect(check.mention("b2PrismaticJoint_IsLimitEnabled"));
    try std.testing.expect(check.mention("b2PrismaticJoint_GetLowerLimit"));
    try std.testing.expect(check.mention("b2PrismaticJoint_GetUpperLimit"));
    try std.testing.expect(check.mention("b2PrismaticJoint_SetLimits"));
    try std.testing.expect(check.mention("b2PrismaticJoint_EnableMotor"));
    try std.testing.expect(check.mention("b2PrismaticJoint_IsMotorEnabled"));
    try std.testing.expect(check.mention("b2PrismaticJoint_SetMotorSpeed"));
    try std.testing.expect(check.mention("b2PrismaticJoint_GetMotorSpeed"));
    try std.testing.expect(check.mention("b2PrismaticJoint_GetMotorForce"));
    try std.testing.expect(check.mention("b2PrismaticJoint_SetMaxMotorForce"));
    try std.testing.expect(check.mention("b2PrismaticJoint_GetMaxMotorForce"));
    try std.testing.expect(check.mention("b2PrismaticJoint_GetTranslation"));
    try std.testing.expect(check.mention("b2PrismaticJoint_GetSpeed"));
    try std.testing.expect(check.mention("b2RevoluteJoint_EnableSpring"));
    try std.testing.expect(check.mention("b2RevoluteJoint_IsSpringEnabled"));
    try std.testing.expect(check.mention("b2RevoluteJoint_IsLimitEnabled"));
    try std.testing.expect(check.mention("b2RevoluteJoint_SetSpringHertz"));
    try std.testing.expect(check.mention("b2RevoluteJoint_GetSpringHertz"));
    try std.testing.expect(check.mention("b2RevoluteJoint_SetSpringDampingRatio"));
    try std.testing.expect(check.mention("b2RevoluteJoint_GetSpringDampingRatio"));
    try std.testing.expect(check.mention("b2RevoluteJoint_GetAngle"));
    try std.testing.expect(check.mention("b2RevoluteJoint_EnableLimit"));
    try std.testing.expect(check.mention("b2RevoluteJoint_GetLowerLimit"));
    try std.testing.expect(check.mention("b2RevoluteJoint_GetUpperLimit"));
    try std.testing.expect(check.mention("b2RevoluteJoint_SetLimits"));
    try std.testing.expect(check.mention("b2RevoluteJoint_EnableMotor"));
    try std.testing.expect(check.mention("b2RevoluteJoint_IsMotorEnabled"));
    try std.testing.expect(check.mention("b2RevoluteJoint_SetMotorSpeed"));
    try std.testing.expect(check.mention("b2RevoluteJoint_GetMotorSpeed"));
    try std.testing.expect(check.mention("b2RevoluteJoint_GetMotorTorque"));
    try std.testing.expect(check.mention("b2RevoluteJoint_SetMaxMotorTorque"));
    try std.testing.expect(check.mention("b2RevoluteJoint_GetMaxMotorTorque"));
    try std.testing.expect(check.mention("b2WheelJoint_EnableSpring"));
    try std.testing.expect(check.mention("b2WheelJoint_IsSpringEnabled"));
    try std.testing.expect(check.mention("b2WheelJoint_SetSpringHertz"));
    try std.testing.expect(check.mention("b2WheelJoint_GetSpringHertz"));
    try std.testing.expect(check.mention("b2WheelJoint_SetSpringDampingRatio"));
    try std.testing.expect(check.mention("b2WheelJoint_GetSpringDampingRatio"));
    try std.testing.expect(check.mention("b2WheelJoint_EnableLimit"));
    try std.testing.expect(check.mention("b2WheelJoint_IsLimitEnabled"));
    try std.testing.expect(check.mention("b2WheelJoint_GetLowerLimit"));
    try std.testing.expect(check.mention("b2WheelJoint_GetUpperLimit"));
    try std.testing.expect(check.mention("b2WheelJoint_SetLimits"));
    try std.testing.expect(check.mention("b2WheelJoint_EnableMotor"));
    try std.testing.expect(check.mention("b2WheelJoint_IsMotorEnabled"));
    try std.testing.expect(check.mention("b2WheelJoint_SetMotorSpeed"));
    try std.testing.expect(check.mention("b2WheelJoint_GetMotorSpeed"));
    try std.testing.expect(check.mention("b2WheelJoint_GetMotorTorque"));
    try std.testing.expect(check.mention("b2WheelJoint_SetMaxMotorTorque"));
    try std.testing.expect(check.mention("b2WheelJoint_GetMaxMotorTorque"));
    try std.testing.expect(check.mention("b2StoreJointId"));
    try std.testing.expect(check.mention("b2LoadJointId"));
    try std.testing.expect(check.mention("b2CreateChain"));
    try std.testing.expect(check.mention("b2DestroyChain"));
    try std.testing.expect(check.mention("b2Chain_SetFriction"));
    try std.testing.expect(check.mention("b2Chain_SetRestitution"));
    try std.testing.expect(check.mention("b2Chain_GetWorld"));
    try std.testing.expect(check.mention("b2Chain_GetSegmentCount"));
    try std.testing.expect(check.mention("b2Chain_GetSegments"));
    try std.testing.expect(check.mention("b2Chain_IsValid"));
    try std.testing.expect(check.mention("b2StoreChainId"));
    try std.testing.expect(check.mention("b2LoadChainId"));
    try std.testing.expect(check.mention("b2CreateCircleShape"));
    try std.testing.expect(check.mention("b2CreateSegmentShape"));
    try std.testing.expect(check.mention("b2CreateCapsuleShape"));
    try std.testing.expect(check.mention("b2CreatePolygonShape"));
    try std.testing.expect(check.mention("b2DestroyShape"));
    try std.testing.expect(check.mention("b2Shape_IsValid"));
    try std.testing.expect(check.mention("b2Shape_GetType"));
    try std.testing.expect(check.mention("b2Shape_GetBody"));
    try std.testing.expect(check.mention("b2Shape_GetWorld"));
    try std.testing.expect(check.mention("b2Shape_IsSensor"));
    try std.testing.expect(check.mention("b2Shape_SetUserData"));
    try std.testing.expect(check.mention("b2Shape_GetUserData"));
    try std.testing.expect(check.mention("b2Shape_SetDensity"));
    try std.testing.expect(check.mention("b2Shape_GetDensity"));
    try std.testing.expect(check.mention("b2Shape_SetFriction"));
    try std.testing.expect(check.mention("b2Shape_GetFriction"));
    try std.testing.expect(check.mention("b2Shape_SetRestitution"));
    try std.testing.expect(check.mention("b2Shape_GetRestitution"));
    try std.testing.expect(check.mention("b2Shape_GetFilter"));
    try std.testing.expect(check.mention("b2Shape_SetFilter"));
    try std.testing.expect(check.mention("b2Shape_EnableSensorEvents"));
    try std.testing.expect(check.mention("b2Shape_AreSensorEventsEnabled"));
    try std.testing.expect(check.mention("b2Shape_EnableContactEvents"));
    try std.testing.expect(check.mention("b2Shape_AreContactEventsEnabled"));
    try std.testing.expect(check.mention("b2Shape_EnablePreSolveEvents"));
    try std.testing.expect(check.mention("b2Shape_ArePreSolveEventsEnabled"));
    try std.testing.expect(check.mention("b2Shape_EnableHitEvents"));
    try std.testing.expect(check.mention("b2Shape_AreHitEventsEnabled"));
    try std.testing.expect(check.mention("b2Shape_TestPoint"));
    try std.testing.expect(check.mention("b2Shape_RayCast"));
    try std.testing.expect(check.mention("b2Shape_GetCircle"));
    try std.testing.expect(check.mention("b2Shape_GetSegment"));
    try std.testing.expect(check.mention("b2Shape_GetChainSegment"));
    try std.testing.expect(check.mention("b2Shape_GetCapsule"));
    try std.testing.expect(check.mention("b2Shape_GetPolygon"));
    try std.testing.expect(check.mention("b2Shape_SetCircle"));
    try std.testing.expect(check.mention("b2Shape_SetCapsule"));
    try std.testing.expect(check.mention("b2Shape_SetSegment"));
    try std.testing.expect(check.mention("b2Shape_SetPolygon"));
    try std.testing.expect(check.mention("b2Shape_GetParentChain"));
    try std.testing.expect(check.mention("b2Shape_GetContactCapacity"));
    try std.testing.expect(check.mention("b2Shape_GetContactData"));
    try std.testing.expect(check.mention("b2Shape_GetAABB"));
    try std.testing.expect(check.mention("b2Shape_GetClosestPoint"));
    try std.testing.expect(check.mention("b2StoreShapeId"));
    try std.testing.expect(check.mention("b2LoadShapeId"));
    try std.testing.expect(check.mention("b2CreateBody"));
    try std.testing.expect(check.mention("b2DestroyBody"));
    try std.testing.expect(check.mention("b2Body_IsValid"));
    try std.testing.expect(check.mention("b2Body_GetWorld"));
    try std.testing.expect(check.mention("b2Body_GetType"));
    try std.testing.expect(check.mention("b2Body_SetType"));
    try std.testing.expect(check.mention("b2Body_SetUserData"));
    try std.testing.expect(check.mention("b2Body_GetUserData"));
    try std.testing.expect(check.mention("b2Body_GetPosition"));
    try std.testing.expect(check.mention("b2Body_GetRotation"));
    try std.testing.expect(check.mention("b2Body_GetTransform"));
    try std.testing.expect(check.mention("b2Body_SetTransform"));
    try std.testing.expect(check.mention("b2Body_GetLocalPoint"));
    try std.testing.expect(check.mention("b2Body_GetWorldPoint"));
    try std.testing.expect(check.mention("b2Body_GetLocalVector"));
    try std.testing.expect(check.mention("b2Body_GetWorldVector"));
    try std.testing.expect(check.mention("b2Body_GetLinearVelocity"));
    try std.testing.expect(check.mention("b2Body_GetAngularVelocity"));
    try std.testing.expect(check.mention("b2Body_SetLinearVelocity"));
    try std.testing.expect(check.mention("b2Body_SetAngularVelocity"));
    try std.testing.expect(check.mention("b2Body_ApplyForce"));
    try std.testing.expect(check.mention("b2Body_ApplyForceToCenter"));
    try std.testing.expect(check.mention("b2Body_ApplyTorque"));
    try std.testing.expect(check.mention("b2Body_ApplyLinearImpulse"));
    try std.testing.expect(check.mention("b2Body_ApplyLinearImpulseToCenter"));
    try std.testing.expect(check.mention("b2Body_ApplyAngularImpulse"));
    try std.testing.expect(check.mention("b2Body_GetMass"));
    try std.testing.expect(check.mention("b2Body_GetRotationalInertia"));
    try std.testing.expect(check.mention("b2Body_GetLocalCenterOfMass"));
    try std.testing.expect(check.mention("b2Body_GetWorldCenterOfMass"));
    try std.testing.expect(check.mention("b2Body_SetMassData"));
    try std.testing.expect(check.mention("b2Body_GetMassData"));
    try std.testing.expect(check.mention("b2Body_ApplyMassFromShapes"));
    try std.testing.expect(check.mention("b2Body_SetLinearDamping"));
    try std.testing.expect(check.mention("b2Body_GetLinearDamping"));
    try std.testing.expect(check.mention("b2Body_SetAngularDamping"));
    try std.testing.expect(check.mention("b2Body_GetAngularDamping"));
    try std.testing.expect(check.mention("b2Body_SetGravityScale"));
    try std.testing.expect(check.mention("b2Body_GetGravityScale"));
    try std.testing.expect(check.mention("b2Body_IsAwake"));
    try std.testing.expect(check.mention("b2Body_SetAwake"));
    try std.testing.expect(check.mention("b2Body_EnableSleep"));
    try std.testing.expect(check.mention("b2Body_IsSleepEnabled"));
    try std.testing.expect(check.mention("b2Body_SetSleepThreshold"));
    try std.testing.expect(check.mention("b2Body_GetSleepThreshold"));
    try std.testing.expect(check.mention("b2Body_IsEnabled"));
    try std.testing.expect(check.mention("b2Body_Disable"));
    try std.testing.expect(check.mention("b2Body_Enable"));
    try std.testing.expect(check.mention("b2Body_SetFixedRotation"));
    try std.testing.expect(check.mention("b2Body_IsFixedRotation"));
    try std.testing.expect(check.mention("b2Body_SetBullet"));
    try std.testing.expect(check.mention("b2Body_IsBullet"));
    try std.testing.expect(check.mention("b2Body_EnableHitEvents"));
    try std.testing.expect(check.mention("b2Body_GetShapeCount"));
    try std.testing.expect(check.mention("b2Body_GetShapes"));
    try std.testing.expect(check.mention("b2Body_GetJointCount"));
    try std.testing.expect(check.mention("b2Body_GetJoints"));
    try std.testing.expect(check.mention("b2Body_GetContactCapacity"));
    try std.testing.expect(check.mention("b2Body_GetContactData"));
    try std.testing.expect(check.mention("b2Body_ComputeAABB"));
    try std.testing.expect(check.mention("b2StoreBodyId"));
    try std.testing.expect(check.mention("b2LoadBodyId"));
    try std.testing.expect(check.mention("b2MakePolygon"));
    try std.testing.expect(check.mention("b2MakeOffsetPolygon"));
    try std.testing.expect(check.mention("b2MakeOffsetRoundedPolygon"));
    try std.testing.expect(check.mention("b2ComputeHull"));
    try std.testing.expect(check.mention("b2ValidateHull"));
    try std.testing.expect(check.mention("b2PointInCapsule"));
    try std.testing.expect(check.mention("b2ComputeCapsuleAABB"));
    try std.testing.expect(check.mention("b2ComputeCapsuleMass"));
    try std.testing.expect(check.mention("b2PointInPolygon"));
    try std.testing.expect(check.mention("b2ComputePolygonAABB"));
    try std.testing.expect(check.mention("b2ComputePolygonMass"));
    try std.testing.expect(check.mention("b2TransformPolygon"));
    try std.testing.expect(check.mention("b2MakeSquare"));
    try std.testing.expect(check.mention("b2MakeBox"));
    try std.testing.expect(check.mention("b2MakeRoundedBox"));
    try std.testing.expect(check.mention("b2MakeOffsetBox"));
    try std.testing.expect(check.mention("b2MakeOffsetRoundedBox"));
    try std.testing.expect(check.mention("b2ShapeDistance"));
    try std.testing.expect(check.mention("b2ShapeDistance"));
    try std.testing.expect(check.mention("b2ShapeCast"));
    try std.testing.expect(check.mention("b2MakeProxy"));
    try std.testing.expect(check.mention("b2GetSweepTransform"));
    try std.testing.expect(check.mention("b2RayCastCircle"));
    try std.testing.expect(check.mention("b2RayCastCapsule"));
    try std.testing.expect(check.mention("b2RayCastSegment"));
    try std.testing.expect(check.mention("b2RayCastPolygon"));
    try std.testing.expect(check.mention("b2IsValidRay"));
    try std.testing.expect(check.mention("b2ShapeCastCircle"));
    try std.testing.expect(check.mention("b2ShapeCastCapsule"));
    try std.testing.expect(check.mention("b2ShapeCastSegment"));
    try std.testing.expect(check.mention("b2ShapeCastPolygon"));
    try std.testing.expect(check.mention("b2TimeOfImpact"));
    try std.testing.expect(check.mention("b2PointInCircle"));
    try std.testing.expect(check.mention("b2ComputeCircleAABB"));
    try std.testing.expect(check.mention("b2ComputeCircleMass"));
    try std.testing.expect(check.mention("b2DefaultFilter"));
    try std.testing.expect(check.mention("b2DynamicTree_Create"));
    try std.testing.expect(check.mention("b2DynamicTree_Destroy"));
    try std.testing.expect(check.mention("b2DynamicTree_CreateProxy"));
    try std.testing.expect(check.mention("b2DynamicTree_DestroyProxy"));
    try std.testing.expect(check.mention("b2DynamicTree_MoveProxy"));
    try std.testing.expect(check.mention("b2DynamicTree_EnlargeProxy"));
    try std.testing.expect(check.mention("b2DynamicTree_Query"));
    try std.testing.expect(check.mention("b2DynamicTree_RayCast"));
    try std.testing.expect(check.mention("b2DynamicTree_ShapeCast"));
    try std.testing.expect(check.mention("b2DynamicTree_Validate"));
    try std.testing.expect(check.mention("b2DynamicTree_GetHeight"));
    try std.testing.expect(check.mention("b2DynamicTree_GetMaxBalance"));
    try std.testing.expect(check.mention("b2DynamicTree_GetAreaRatio"));
    try std.testing.expect(check.mention("b2DynamicTree_RebuildBottomUp"));
    try std.testing.expect(check.mention("b2DynamicTree_GetProxyCount"));
    try std.testing.expect(check.mention("b2DynamicTree_Rebuild"));
    try std.testing.expect(check.mention("b2DynamicTree_ShiftOrigin"));
    try std.testing.expect(check.mention("b2DynamicTree_GetByteCount"));
    try std.testing.expect(check.mention("b2AABB_IsValid"));
    try std.testing.expect(check.mention("b2DefaultQueryFilter"));
    try std.testing.expect(check.mention("b2GetByteCount"));
    try std.testing.expect(check.mention("b2SetLengthUnitsPerMeter"));
    try std.testing.expect(check.mention("b2GetLengthUnitsPerMeter"));
    try std.testing.expect(check.mention("b2GetVersion"));
    try std.testing.expect(check.mention("b2SetAllocator"));
    try std.testing.expect(check.mention("b2SetAssertFcn"));
    try std.testing.expect(check.mention("b2SegmentDistance"));
    try std.testing.expect(check.mention("b2ComputeRotationBetweenUnitVectors"));
    try std.testing.expect(check.mention("b2Atan2"));
    try std.testing.expect(check.mention("b2ComputeCosSin"));
    try std.testing.expect(check.mention("b2IsValid"));
    try std.testing.expect(check.mention("b2CollideCircles"));
    try std.testing.expect(check.mention("b2CollideCapsuleAndCircle"));
    try std.testing.expect(check.mention("b2CollideSegmentAndCircle"));
    try std.testing.expect(check.mention("b2CollidePolygonAndCircle"));
    try std.testing.expect(check.mention("b2CollideCapsules"));
    try std.testing.expect(check.mention("b2CollideSegmentAndCapsule"));
    try std.testing.expect(check.mention("b2CollidePolygonAndCapsule"));
    try std.testing.expect(check.mention("b2CollidePolygons"));
    try std.testing.expect(check.mention("b2CollideSegmentAndPolygon"));
    try std.testing.expect(check.mention("b2CollideChainSegmentAndCircle"));
    try std.testing.expect(check.mention("b2CollideChainSegmentAndCapsule"));
    try std.testing.expect(check.mention("b2CollideChainSegmentAndPolygon"));

    // Vec2 Functions that are re-implemented
    try std.testing.expect(check.mention("b2Dot"));
    try std.testing.expect(check.mention("b2Cross"));
    try std.testing.expect(check.mention("b2CrossVS"));
    try std.testing.expect(check.mention("b2CrossSV"));
    try std.testing.expect(check.mention("b2LeftPerp"));
    try std.testing.expect(check.mention("b2RightPerp"));
    try std.testing.expect(check.mention("b2Add"));
    try std.testing.expect(check.mention("b2Sub"));
    try std.testing.expect(check.mention("b2Neg"));
    try std.testing.expect(check.mention("b2Lerp"));
    try std.testing.expect(check.mention("b2Mul"));
    try std.testing.expect(check.mention("b2MulSV"));
    try std.testing.expect(check.mention("b2MulAdd"));
    try std.testing.expect(check.mention("b2MulSub"));
    try std.testing.expect(check.mention("b2Abs"));
    try std.testing.expect(check.mention("b2Min"));
    try std.testing.expect(check.mention("b2Max"));
    try std.testing.expect(check.mention("b2Clamp"));
    try std.testing.expect(check.mention("b2Length"));
    try std.testing.expect(check.mention("b2Distance"));
    try std.testing.expect(check.mention("b2Normalize"));
    try std.testing.expect(check.mention("b2GetLengthAndNormalize"));
    try std.testing.expect(check.mention("b2LengthSquared"));
    try std.testing.expect(check.mention("b2DistanceSquared"));

    // Rot functions that are reimplemented
    try std.testing.expect(check.mention("b2NormalizeRot"));
    try std.testing.expect(check.mention("b2IntegrateRotation"));
    try std.testing.expect(check.mention("b2IsNormalized"));
    try std.testing.expect(check.mention("b2NLerp"));
    try std.testing.expect(check.mention("b2ComputeAngularVelocity"));
    try std.testing.expect(check.mention("b2Rot_GetAngle"));
    try std.testing.expect(check.mention("b2Rot_GetXAxis"));
    try std.testing.expect(check.mention("b2Rot_GetYAxis"));
    try std.testing.expect(check.mention("b2MulRot"));
    try std.testing.expect(check.mention("b2InvMulRot"));
    try std.testing.expect(check.mention("b2RelativeAngle"));
    try std.testing.expect(check.mention("b2RotateVector"));
    try std.testing.expect(check.mention("b2InvRotateVector"));

    // Transform functions that are reimplemented
    try std.testing.expect(check.mention("b2TransformPoint"));
    try std.testing.expect(check.mention("b2InvTransformPoint"));
    try std.testing.expect(check.mention("b2MulTransforms"));
    try std.testing.expect(check.mention("b2InvMulTransforms"));

    // AABB functions that are reimplemented
    try std.testing.expect(check.mention("b2AABB_Contains"));
    try std.testing.expect(check.mention("b2AABB_Center"));
    try std.testing.expect(check.mention("b2AABB_Extents"));
    try std.testing.expect(check.mention("b2AABB_Union"));

    // DynamicTree functions that are reimplemented
    try std.testing.expect(check.mention("b2DynamicTree_GetUserData"));
    try std.testing.expect(check.mention("b2DynamicTree_GetAABB"));

    // Math functions that are reimplemented
    try std.testing.expect(check.mention("b2UnwindAngle"));
    try std.testing.expect(check.mention("b2UnwindLargeAngle"));

    // Macros that are translated into proper functions for each type the macro applies to
    try std.testing.expect(check.mention("B2_ID_EQUALS"));
    try std.testing.expect(check.mention("B2_IS_NON_NULL"));
    try std.testing.expect(check.mention("B2_IS_NULL"));

    // null ids
    try std.testing.expect(check.mention("b2_nullWorldId"));
    try std.testing.expect(check.mention("b2_nullBodyId"));
    try std.testing.expect(check.mention("b2_nullShapeId"));
    try std.testing.expect(check.mention("b2_nullChainId"));
    try std.testing.expect(check.mention("b2_nullJointId"));

    // Finally, things we do not care to make a binding for. Reasons include:
    // - Already has a good alternative in Zig standard library (ex: b2Timer)
    // - Does not make sense to have a binding (ex: B2_API, B2_INLINE)

    try std.testing.expect(check.mention("b2Timer"));
    try std.testing.expect(check.mention("b2CreateTimer"));
    try std.testing.expect(check.mention("b2GetMilliseconds"));
    try std.testing.expect(check.mention("b2GetMillisecondsAndReset"));
    try std.testing.expect(check.mention("b2SleepMilliseconds"));
    try std.testing.expect(check.mention("b2Yield"));
    try std.testing.expect(check.mention("b2Hash"));
    try std.testing.expect(check.mention("b2GetTicks"));
    try std.testing.expect(check.mention("b2MinFloat"));
    try std.testing.expect(check.mention("b2MaxFloat"));
    try std.testing.expect(check.mention("b2AbsFloat"));
    try std.testing.expect(check.mention("b2ClampFloat"));
    try std.testing.expect(check.mention("b2MinInt"));
    try std.testing.expect(check.mention("b2MaxInt"));
    try std.testing.expect(check.mention("b2AbsInt"));
    try std.testing.expect(check.mention("b2ClampInt"));
    try std.testing.expect(check.mention("b2_pi"));
    try std.testing.expect(check.mention("B2_HASH_INIT"));
    try std.testing.expect(check.mention("B2_ZERO_INIT"));
    try std.testing.expect(check.mention("B2_LITERAL"));
    try std.testing.expect(check.mention("B2_INLINE"));
    try std.testing.expect(check.mention("B2_API"));
    // TODO: Why is b2Mat22 public to the user? It seems to have no real use outside of Box2D's internal workings.
    try std.testing.expect(check.mention("b2Mat22"));
    try std.testing.expect(check.mention("b2Mat22_zero"));
    try std.testing.expect(check.mention("b2MulMV"));
    try std.testing.expect(check.mention("b2GetInverse22"));
    try std.testing.expect(check.mention("b2Solve22"));

    try std.testing.expect(check.check());
}

/// A struct with functionality to check:
/// - ABI compatibility between types
/// - API implementation completion
/// - API implementation extra types
///
/// It checks the ABI compatibility between the types where applicable.
/// It also makes sure that all of the header things are mentioned / implemented.
const ApiCompatibilityChecker = struct {
    // using a hash dictionary would be faster - who cares, this only runs for `zig test` for this specific project.
    headerThings: std.ArrayList(MentionableString),
    stringArena: std.heap.ArenaAllocator,

    const MentionableString = struct {
        str: []u8,
        mentioned: bool,
    };

    /// initialize an instance of this struct.
    ///
    /// headerThings is a list of names of all of the types that you want to make sure are mentioned. The list is not owned.
    pub fn init(this: *ApiCompatibilityChecker, headerThings: std.ArrayList([]const u8), allocator: std.mem.Allocator) !void {
        this.stringArena = std.heap.ArenaAllocator.init(allocator);
        const arena = this.stringArena.allocator();
        this.headerThings = try std.ArrayList(MentionableString).initCapacity(arena, headerThings.items.len);
        for (headerThings.items) |item| {
            try this.headerThings.append(.{
                .mentioned = false,
                // Cannot assume anything, copy the items
                .str = try arena.dupe(u8, item),
            });
        }
    }

    pub const RelateReturn = struct {
        // True if the mentioned / implemented is within headerThings
        contained: bool,
        // True if the two are compatible
        compatible: bool,
        // True if it fully passes the test
        passes: bool,
    };

    /// relate an implementer and implemented type.
    /// This validates that structs, function pointers, unions, enums are ABI compatible,
    /// and mentions Implemented so that it will not longer cause an error.
    pub fn relateTypes(this: *ApiCompatibilityChecker, comptime Implementer: type, comptime Implemented: type) RelateReturn {
        const contained = this.mention(@typeName(Implemented));
        // Checking ABI compatibiliy is a giant heap of code, so do that somewhere else
        const compatible = typesAreAbiCompatiblePrint(Implementer, Implemented);
        if (!contained or !compatible) {
            std.log.err("implementer {s} and implemented {s}: contained={}, compatible={}", .{ @typeName(Implementer), @typeName(Implemented), contained, compatible });
        }
        return .{
            .contained = contained,
            .compatible = compatible,
            .passes = contained and compatible,
        };
    }

    pub fn relateTypesImplName(this: *ApiCompatibilityChecker, comptime Implementer: type, comptime Implemented: type, implementedName: []const u8) RelateReturn {
        const contained = this.mention(implementedName);
        // Checking ABI compatibiliy is a giant heap of code, so do that somewhere else
        const compatible = typesAreAbiCompatiblePrint(Implementer, Implemented);
        if (!contained or !compatible) {
            std.log.err("implementer {s} and implemented {s}: contained={}, compatible={}", .{ @typeName(Implementer), implementedName, contained, compatible });
        }
        return .{
            .contained = contained,
            .compatible = compatible,
            .passes = contained and compatible,
        };
    }

    pub fn relateValues(this: *ApiCompatibilityChecker, comptime T: type, a: T, b: T, implementedName: []const u8) RelateReturn {
        const contained = this.mention(implementedName);
        var compatible: bool = undefined;
        compatible = std.meta.eql(a, b);
        if (!contained or !compatible) {
            std.log.err("implemented {s}, a={any}, b={any}: contained={} compatible={}", .{ implementedName, a, b, contained, compatible });
        }
        return .{
            .contained = contained,
            .compatible = compatible,
            .passes = contained and compatible,
        };
    }

    // mentions the item named by implemented so it will no longer cause an error.
    // Returns false if the mentioned item is not contained in headerThings.
    pub fn mention(this: *ApiCompatibilityChecker, implemented: []const u8) bool {
        var realImplemented = implemented;
        var found = false;
        // The name may have ended up like "cimport.struct_[name]"
        if (std.mem.startsWith(u8, implemented, "cimport.struct_")) {
            realImplemented = realImplemented["cimport.struct_".len..];
        }
        for (this.headerThings.items) |*item| {
            if (std.mem.eql(u8, realImplemented, item.str)) {
                item.mentioned = true;
                found = true;
            }
        }
        return found;
    }

    // check if all items of HeaderType were mentioned. If they were all mentioned, returns true.
    // If that is not the case, it will print out useful information on stderr and return false.
    pub fn check(this: *ApiCompatibilityChecker) bool {
        var checkPass = true;
        for (this.headerThings.items) |item| {
            if (!item.mentioned) {
                std.log.err("{s} was not mentioned!", .{item.str});
                checkPass = false;
            }
        }
        return checkPass;
    }

    pub fn deinit(this: *ApiCompatibilityChecker) void {
        this.headerThings.deinit();
        this.headerThings = undefined;
        this.stringArena.deinit();
        this.stringArena = undefined;
    }
};

// Returns if the two types are ABI compatible in both directions.
// If so, they can be 100% safely (within reason) casted between each other.
fn typesAreAbiCompatible(comptime A: type, comptime B: type) bool {
    return typesAreAbiCompatibleRecurse(A, B, typesAreAbiCompatible);
}

// Same as typesAreAbiCompatible, but prints an error for types that are incompatible
fn typesAreAbiCompatiblePrint(comptime A: type, comptime B: type) bool {
    const compatible = typesAreAbiCompatibleRecurse(A, B, typesAreAbiCompatiblePrint);
    if (!compatible) {
        std.log.err("Types {s} and {s} are incompatible!", .{ @typeName(A), @typeName(B) });
    }
    return compatible;
}

fn typesAreAbiCompatibleRecurse(comptime A: type, comptime B: type, nextApiCompat: fn (comptime A: type, comptime B: type) bool) bool {
    const aInfo = @typeInfo(A);
    const bInfo = @typeInfo(B);

    switch (aInfo) {
        // type types have no ABI
        .type => return false,
        // void is compatible with other void
        .void => return bInfo == .void,
        // bool is compatible with bool
        // TODO: what about bool -> int, where the int is treated as a bool
        .bool => return bInfo == .bool,
        // noreturn is compatible with other noreturn
        .noreturn => return bInfo == .noreturn,
        .int => |t| {
            if (bInfo == .int) {
                return t.bits == bInfo.int.bits and t.signedness == bInfo.int.signedness;
            } else {
                // other one may be a compatible enum. Swap them and try again.
                return nextApiCompat(B, A);
            }
        },
        .float => |t| {
            if (bInfo == .float) {
                return t.bits == bInfo.float.bits;
            } else return false;
        },
        .pointer => |t| {
            if (bInfo == .pointer) {
                // Give benefit of the doubt, and call 'C' pointers compatible with any size.
                const sizeCompatible = t.size == .C or bInfo.pointer.size == .C or t.size == bInfo.pointer.size;
                // For now, const, volatile, and allowzero do not effect ABI compatibility
                // TODO: should any of these effect ABI compatibility? The only one that might is allowzero.
                const pointerCompatible = sizeCompatible and t.alignment == bInfo.pointer.alignment and t.address_space == bInfo.pointer.address_space;
                // TODO: check sentinel
                // TODO: more detailed investigation of ABI compatibility of address spaces
                return pointerCompatible and nextApiCompat(t.child, bInfo.pointer.child);
            } else return false;
        },
        .array => |t| {
            if (bInfo == .array) {
                // TODO: check sentinel
                return t.len == bInfo.array.len and nextApiCompat(t.child, bInfo.array.child);
            } else return false;
        },
        .@"struct" => {
            if (bInfo != .@"struct") return false;
            // Make sure they have the same layout and that layout is ABI stable
            if (aInfo.@"struct".layout == .auto) return false;
            if (aInfo.@"struct".layout != bInfo.@"struct".layout) return false;

            if (aInfo.@"struct".fields.len != bInfo.@"struct".fields.len) return false;
            inline for (aInfo.@"struct".fields, 0..) |aField, i| {
                // Assume their indices match. I'm 99% certain the compiler has reliable order on extern/packed structs, however I have not dug into it.
                const bField = bInfo.@"struct".fields[i];
                return nextApiCompat(aField.type, bField.type);
            }
            // None of the checks failed, so assume they are compatible at this point
            return true;
        },
        // comptime types have no runtime value, and thus no ABI
        .comptime_float => return false,
        .comptime_int => return false,
        .undefined => return false,
        // I don't even know what a 'null' type is
        // The type of the keyword 'null'?
        .null => return false,
        .optional => |t| {
            if (bInfo == .optional) {
                return nextApiCompat(t.child, bInfo.optional.child);
            } else return false;
        },
        .error_union => |t| {
            if (bInfo == .error_union) {
                return nextApiCompat(t.error_set, bInfo.error_union.error_set) and nextApiCompat(t.payload, bInfo.error_union.payload);
            } else return false;
        },
        .error_set => |t| {
            if (bInfo == .error_set) {
                // TODO: is this right? What causes an error set to be null anyway?
                // if(t == null and bInfo.error_set == null) return true;
                if (t == null) return false;
                if (bInfo.error_set == null) return false;
                const av = t.?;
                const bv = bInfo.error_set.?;
                if (av.len != bv.len) return false;
                for (av, 0..) |avv, avi| {
                    // indices must match
                    const bvv = bv[avi];
                    if (comptime !std.mem.eql(u8, avv.name, bvv.name)) {
                        // If the names are different, the error types are not the same
                        return false;
                    }
                }
                return true;
            } else return false;
        },
        .@"enum" => |t| {
            if (bInfo == .@"enum") {
                // Enums are a complex matter, because their fields can show up in any order,
                // and their names may not match either.
                // What matters is that the meaning stays the same.
                // We can't do a lot to validate their equivalence.
                // For this project, this case never actually occurs anyway, so just do something basic.
                return t.fields.len == bInfo.@"enum".fields.len;
            } else if (bInfo == .int) {
                // other one is an int. If the enum's tag is compatible with B, then the enum is compatible with the int.
                return nextApiCompat(t.tag_type, B);
            } else return false;
        },
        .@"union" => |at| {
            if (bInfo == .@"union") {
                const bt = bInfo.@"union";
                // layout needs to be defined and the same
                if (at.layout == .auto) return false;
                if (bt.layout == .auto) return false;
                if (bt.layout != at.layout) return false;
                // tag types must both be null or neither be null
                if ((at.tag_type == null) != (bt.tag_type == null)) return false;
                // tag types must be compatible
                if (at.tag_type != null and bt.tag_type != null) {
                    if (!nextApiCompat(at.tag_type.?, bt.tag_type.?)) return false;
                }
                // Union fields can show up in any order. So kinda map them between each other.
                // We want to find what field in bt is equivalent to each one in at,
                // and any unmatched fields will cause them to be considered incompatible.
                // A list to keep track of which bt fields have been match to at fields.
                var btfielts = [1]bool{false} ** bt.fields.len;
                for (at.fields) |af| {
                    // Look a bt field that is compatible
                    var foundCompatible = false;
                    for (bt.fields, 0..) |bf, bi| {
                        if (af.alignment == bf.alignment and nextApiCompat(af.type, bf.type)) {
                            // They are compatible, mark the bf one found.
                            foundCompatible = true;
                            btfielts[bi] = true;
                        }
                    }
                    if (!foundCompatible) return false;
                }
                // If any of the fields in B were not found, then they aren't compatible.
                for (btfielts) |bff| {
                    if (!bff) return false;
                }
                // No incompatibilities found.
                return true;
            } else return false;
        },
        .@"fn" => |at| {
            if (bInfo == .@"fn") {
                const bt = bInfo.@"fn";
                // TODO: assuming generic means they take comptime parameters,
                // Zig's Type type has no documentation at all and it's insanely annoying
                // generic functions have no defined ABI
                if (at.is_generic) return false;
                if (bt.is_generic) return false;
                // they must be both var args or neither var args
                if (at.is_var_args != bt.is_var_args) return false;
                // TODO: calling conventions are complicated. Like, REALLY FREAKING CRAZY COMPLICATED.
                // Thus, I have not done any checks on it...

                // TODO: When would the return type ever be null?
                if (at.return_type == null) return false;
                if (bt.return_type == null) return false;
                const atr = at.return_type.?;
                const btr = bt.return_type.?;
                if (!nextApiCompat(atr, btr)) return false;

                // finally, check all of the parameters
                inline for (at.params, 0..) |ap, pi| {
                    const bp = bt.params[pi];
                    if (ap.is_generic) return false;
                    if (bp.is_generic) return false;
                    // Quote from Zig documentation:
                    // "TODO add documentation for noalias"
                    // I thought ALL parameters in zig are marked with the equivalent to 'restrict' by default,
                    // Apparently this is not correct? Or does noalias mean something else?
                    // Anyway, assume they have to be the same for now.
                    if (ap.is_noalias != bp.is_noalias) return false;
                    // TODO: when would the type be null?
                    if (ap.type == null) return false;
                    if (bp.type == null) return false;
                    if (!nextApiCompat(ap.type.?, bp.type.?)) return false;
                }
                // No issues found
                return true;
            } else return false;
        },
        .@"opaque" => {
            if (bInfo == .@"opaque") {
                // assume opaques are compatible
                return true;
            } else return false;
        },
        // TODO: What is a frame
        .frame => return false,
        .@"anyframe" => return false,
        .vector => |t| {
            if (bInfo == .vector) {
                if (t.len != bInfo.vector.len) return false;
                return nextApiCompat(t.child, bInfo.vector.child);
            } else return false;
        },
        .enum_literal => {
            return bInfo == .enum_literal;
        },
        // If new types of types are added... I have no idea.
        // else => return false,
    }
}

// This is required since native is a raw translate-c, and translate-c creates compile errors when certain declarations are referenced.
fn recursivelyRefAllDeclsExceptNative(T: type) void {
    @setEvalBranchQuota(10000);
    // Isn't this the third or fourth time zig devs decided to change the capitalization of enum values?
    // TODO: probably fine to remove once 0.14 is stable
    const useOldEnumCapitalization = comptime @hasField(std.builtin.Type, "Struct");
    if (useOldEnumCapitalization) {
        if (@typeInfo(T) == .Struct) {
            inline for (comptime std.meta.declarations(T)) |decl| {
                // when in doubt, just put 'comptime' in front of literally everything.
                // Because the Zig compiler will annoyingly delay anything it can to runtime, for some reason.
                if (comptime !std.mem.eql(u8, decl.name, "native")) {
                    const d = @field(T, decl.name);
                    _ = &d;
                    if (@TypeOf(d) == type) recursivelyRefAllDeclsExceptNative(d);
                }
            }
        }
    } else {
        if (@typeInfo(T) == .@"struct") {
            inline for (comptime std.meta.declarations(T)) |decl| {
                // when in doubt, just put 'comptime' in front of literally everything.
                // Because the Zig compiler will annoyingly delay anything it can to runtime, for some reason.
                if (comptime !std.mem.eql(u8, decl.name, "native")) {
                    const d = @field(T, decl.name);
                    _ = &d;
                    if (@TypeOf(d) == type) recursivelyRefAllDeclsExceptNative(d);
                }
            }
        }
    }
}
