const std = @import("std");
const builtin = @import("builtin");
/// This allows users to get the "native" version of Box2D, which is just an @cImport of Box2Ds headers.
pub const native = @import("box2dnative.zig");

// TODO: Instead of translating these types, translate the functions they are related to and remove these types entirely.
// The translated functions should use proxy functions to avoid the calling convention restriction and allow context generics
pub const CastResultFn = fn (shape: ShapeId, pos: Vec2, normal: Vec2, fraction: f32, context: ?*anyopaque) callconv(.C) f32;
pub const PreSolveFn = fn (shapeIdA: ShapeId, shapeIdB: ShapeId, manifold: *Manifold, context: ?*anyopaque) callconv(.C) bool;
pub const TreeQueryCallbackFn = fn (proxyId: i32, userData: i32, context: ?*anyopaque) callconv(.C) bool;
pub const TreeRayCastCallbackFn = fn (*const RayCastInput, i32, i32, ?*anyopaque) callconv(.C) f32;
pub const TreeShapeCastCallbackFn = fn (*const ShapeCastInput, i32, i32, ?*anyopaque) callconv(.C) f32;
pub const OverlapResultFn = fn (shape: ShapeId, context: ?*anyopaque) callconv(.C) bool;
pub const AllocFn = fn (size: c_uint, alignment: c_int) callconv(.C) *anyopaque;
pub const FreeFn = fn (mem: *anyopaque) callconv(.C) void;
pub const AssertFn = fn (condition: [*:0]const u8, fileName: [*:0]const u8, lineNumber: c_int) callconv(.C) c_int;
pub const TaskCallback = fn (i32, i32, u32, ?*anyopaque) callconv(.C) void;

pub const defaultCategoryBits = native.b2_defaultCategoryBits;
pub const defaultMaskBits = native.b2_defaultMaskBits;
pub const maxPolygonVertices = native.b2_maxPolygonVertices;

// these have been translated

// general types

pub const Counters = extern struct {
    staticBodyCount: i32,
	bodyCount: i32,
	shapeCount: i32,
	contactCount: i32,
	jointCount: i32,
	islandCount: i32,
	stackUsed: i32,
	staticTreeHeight: i32,
	treeHeight: i32,
	byteCount: i32,
	taskCount: i32,
	colorCounts: [12]i32,
};

pub const MassData = extern struct {
    mass: f32,
    center: Vec2,
    rotationalInertia: f32
};

pub const ContactData = extern struct {
    shapeIdA: ShapeId,
    shapeIdB: ShapeId,
    manifold: Manifold,
};

pub const Segment = extern struct {
    point1: Vec2,
    point2: Vec2,

    pub inline fn computeAABB(shape: Segment, transform: Transform) AABB {
        return @bitCast(native.b2ComputeSegmentAABB(@ptrCast(&shape), @bitCast(transform)));
    }
};

pub const ChainSegment = extern struct {
    ghost1: Vec2,
    segment: Segment,
    ghost2: Vec2,
    chainId: i32,
};


/// Profiling data. Times are in milliseconds.
pub const Profile = extern struct {
    step: f32,
    pairs: f32,
    collide: f32,
    solve: f32,
    buildIslands: f32,
    solveConstraints: f32,
    prepareTasks: f32,
    solverTasks: f32,
    prepareConstraints: f32,
    integrateVelocities: f32,
    warmStart: f32,
    solveVelocities: f32,
    integratePositions: f32,
    relaxVelocities: f32,
    applyRestitution: f32,
    storeImpulses: f32,
    finalizeBodies: f32,
    splitIslands: f32,
    sleepIslands: f32,
    hitEvents: f32,
    broadphase: f32,
    continuous: f32,
};

pub const Version = extern struct {
    major: c_int,
    mionor: c_int,
    revision: c_int,
};

pub const Rot = extern struct {

    pub inline fn fromRadians(angle: f32) Rot {
        return @bitCast(native.b2MakeRot(angle));
    }

    pub inline fn normalize(q: Rot) Rot {
        const mag: f32 = @sqrt((q.s * q.s) + (q.c * q.c));
        const invMag: f32 = if (mag > 0.0) 1.0 / mag else 0.0;
        const qn: Rot = Rot{
            .c = q.c * invMag,
            .s = q.s * invMag,
        };
        return qn;
    }

    pub inline fn isNormalized(q: Rot) bool {
        const qq: f32 = (q.s * q.s) + (q.c * q.c);
        // larger tolerance due to failure on mingw 32-bit
        return ((1.0 - 0.0006) < qq) and (qq < (1.0 + 0.0006));
    }

    pub inline fn nLerp(q1: Rot, q2: Rot, t: f32) Rot {
        const omt: f32 = 1.0 - t;
        const q: Rot = Rot{
            .c = (omt * q1.c) + (t * q2.c),
            .s = (omt * q1.s) + (t * q2.s),
        };
        return q.normalize();
    }

    pub inline fn integrateRotation(q1: Rot, deltaAngle: f32) Rot {
        const q2: Rot = Rot{
            .c = q1.c - (deltaAngle * q1.s),
            .s = q1.s + (deltaAngle * q1.c),
        };
        const mag: f32 = @sqrt((q2.s * q2.s) + (q2.c * q2.c));
        const invMag: f32 = if (mag > 0.0) 1.0 / mag else 0.0;
        const qn: Rot = Rot{
            .c = q2.c * invMag,
            .s = q2.s * invMag,
        };
        return qn;
    }

    pub inline fn computeAngularVelocity(q1: Rot, q2: Rot, inv_h: f32) f32 {
        const omega: f32 = inv_h * ((q2.s * q1.c) - (q2.c * q1.s));
        return omega;
    }

    pub inline fn toRadians(q: Rot) f32 {
        return atan2(q.s, q.c);
    }

    pub inline fn getXAxis(q: Rot) Vec2 {
        const v: Vec2 = Vec2{
            .x = q.c,
            .y = q.s,
        };
        return v;
    }

    pub inline fn getYAxis(q: Rot) Vec2 {
        const v: Vec2 = Vec2{
            .x = -q.s,
            .y = q.c,
        };
        return v;
    }

    pub inline fn mul(q: Rot, r: Rot) Rot {
        // [qc -qs] * [rc -rs] = [qc*rc-qs*rs -qc*rs-qs*rc]
        // [qs  qc]   [rs  rc]   [qs*rc+qc*rs -qs*rs+qc*rc]
        // s(q + r) = qs * rc + qc * rs
        // c(q + r) = qc * rc - qs * rs
        var qr: Rot = undefined;
        qr.s = (q.s * r.c) + (q.c * r.s);
        qr.c = (q.c * r.c) - (q.s * r.s);
        return qr;
    }

    pub inline fn invMul(q: Rot, r: Rot) Rot {
        // [ qc qs] * [rc -rs] = [qc*rc+qs*rs -qc*rs+qs*rc]
        // [-qs qc]   [rs  rc]   [-qs*rc+qc*rs qs*rs+qc*rc]
        // s(q - r) = qc * rs - qs * rc
        // c(q - r) = qc * rc + qs * rs
        var qr: Rot = undefined;
        qr.s = (q.c * r.s) - (q.s * r.c);
        qr.c = (q.c * r.c) + (q.s * r.s);
        return qr;
    }

    pub inline fn relativeAngle(b: Rot, a: Rot) f32 {
        const s: f32 = (b.s * a.c) - (b.c * a.s);
        const c: f32 = (b.c * a.c) + (b.s * a.s);
        return atan2(s, c);
    }

    pub inline fn rotateVector(q: Rot, v: Vec2) Vec2 {
        return Vec2{
            .x = (q.c * v.x) - (q.s * v.y),
            .y = (q.s * v.x) + (q.c * v.y),
        };
    }

    pub inline fn invRotateVector(q: Rot, v: Vec2) Vec2 {
        return Vec2{
            .x = (q.c * v.x) + (q.s * v.y),
            .y = (-q.s * v.x) + (q.c * v.y),
        };
    }

    pub inline fn isValid(q: Rot) bool {
        return native.b2Rot_IsValid(q);
    }

    /// Cosine component
    c: f32,
    /// Sine component
    s: f32,
};

pub const Transform = extern struct {
    pub inline fn transformPoint(t: Transform, p: Vec2) Vec2 {
        return Vec2{
            .x = ((t.q.c * p.x) - (t.q.s * p.y)) + t.p.x,
            .y = ((t.q.s * p.x) + (t.q.c * p.y)) + t.p.y,
        };
    }

    pub inline fn invTransformPoint(t: Transform, p: Vec2) Vec2 {
        const vx: f32 = p.x - t.p.x;
        const vy: f32 = p.y - t.p.y;
        return Vec2{
            .x = (t.q.c * vx) + (t.q.s * vy),
            .y = (-t.q.s * vx) + (t.q.c * vy),
        };
    }

    pub inline fn mul(A: Transform, B: Transform) Transform {
        return Transform{
            .q = A.q.mul(B.q),
            .p = A.q.rotateVector(B.p).add(A.p),
        };
    }

    pub inline fn invMul(A: Transform, B: Transform) Transform {
        return Transform{
            .q = A.q.invMul(B.q),
            .p = A.q.invRotateVector(B.p.sub(A.p)),
        };
    }
    p: Vec2,
    q: Rot,
};

pub const Vec2 = extern struct {
    pub inline fn dot(a: Vec2, b: Vec2) f32 {
        return (a.x * b.x) + (a.y * b.y);
    }

    pub inline fn cross(a: Vec2, b: Vec2) f32 {
        return (a.x * b.y) - (a.y * b.x);
    }

    pub inline fn crossVS(v: Vec2, s: f32) Vec2 {
        return Vec2{
            .x = s * v.y,
            .y = -s * v.x,
        };
    }

    pub inline fn crossSV(s: f32, v: Vec2) Vec2 {
        return Vec2{
            .x = -s * v.y,
            .y = s * v.x,
        };
    }

    pub inline fn leftPerp(v: Vec2) Vec2 {
        return Vec2{
            .x = -v.y,
            .y = v.x,
        };
    }

    pub inline fn rightPerp(v: Vec2) Vec2 {
        return Vec2{
            .x = v.y,
            .y = -v.x,
        };
    }

    pub inline fn add(a: Vec2, b: Vec2) Vec2 {
        return Vec2{
            .x = a.x + b.x,
            .y = a.y + b.y,
        };
    }

    pub inline fn sub(a: Vec2, b: Vec2) Vec2 {
        return Vec2{
            .x = a.x - b.x,
            .y = a.y - b.y,
        };
    }

    pub inline fn neg(a: Vec2) Vec2 {
        return Vec2{
            .x = -a.x,
            .y = -a.y,
        };
    }

    pub inline fn lerp(a: Vec2, b: Vec2, t: f32) Vec2 {
        return Vec2{
            .x = ((1.0 - t) * a.x) + (t * b.x),
            .y = ((1.0 - t) * a.y) + (t * b.y),
        };
    }

    pub inline fn mul(a: Vec2, b: Vec2) Vec2 {
        return Vec2{
            .x = a.x * b.x,
            .y = a.y * b.y,
        };
    }

    pub inline fn mulSV(s: f32, v: Vec2) Vec2 {
        return Vec2{
            .x = s * v.x,
            .y = s * v.y,
        };
    }

    pub inline fn mulAdd(a: Vec2, s: f32, b: Vec2) Vec2 {
        return Vec2{
            .x = a.x + (s * b.x),
            .y = a.y + (s * b.y),
        };
    }

    pub inline fn mulSub(a: Vec2, s: f32, b: Vec2) Vec2 {
        return Vec2{
            .x = a.x - (s * b.x),
            .y = a.y - (s * b.y),
        };
    }

    pub inline fn abs(a: Vec2) Vec2 {
        return Vec2{
            .x = @abs(a.x),
            .y = @abs(a.y),
        };
    }

    pub inline fn min(a: Vec2, b: Vec2) Vec2 {
        return Vec2{
            .x = @min(a.x, b.x),
            .y = @min(a.y, b.y),
        };
    }

    pub inline fn max(a: Vec2, b: Vec2) Vec2 {
        return Vec2{
            .x = @max(a.x, b.x),
            .y = @max(a.y, b.y),
        };
    }

    pub inline fn clamp(v: Vec2, lower: Vec2, upper: Vec2) Vec2 {
        return Vec2{
            .x = std.math.clamp(v.x, lower.x, upper.x),
            .y = std.math.clamp(v.y, lower.y, upper.y),
        };
    }

    pub inline fn length(v: Vec2) f32 {
        return @sqrt((v.x * v.x) + (v.y * v.y));
    }

    pub inline fn lengthSquared(v: Vec2) f32 {
        return (v.x * v.x) + (v.y * v.y);
    }

    pub inline fn distance(a: Vec2, b: Vec2) f32 {
        const dx: f32 = b.x - a.x;
        const dy: f32 = b.y - a.y;
        return @sqrt((dx * dx) + (dy * dy));
    }

    pub inline fn distanceSquared(a: Vec2, b: Vec2) f32 {
        const dx: f32 = b.x - a.x;
        const dy: f32 = b.y - a.y;
        return (dx * dx) + (dy * dy);
    }

    pub inline fn isValid(v: Vec2) bool {
        return native.b2Vec2_IsValid(@bitCast(v));
    }

    pub inline fn normalize(v: Vec2) Vec2 {
        const _length = v.length();
        if(_length < std.math.floatEps(f32)) {
            return Vec2{.x = 0, .y = 0};
        }
        const invLength = 1.0 / _length;
        return Vec2{.x = invLength * v.x, .y = invLength * v.y};
    }

    pub inline fn getLengthAndNormalize(len: *f32, v: Vec2) Vec2 {
        len.* = v.length();
        if(len.* < std.math.floatEps(f32)) {
            return Vec2{.x = 0, .y = 0};
        }
        const invLength = 1.0 / len.*;
        return Vec2{.x = invLength * v.x, .y = invLength * v.y};
    }

    x: f32,
    y: f32,
};

pub const BodyType = enum(c_uint) {
    static = 0,
    kinematic = 1,
    dynamic = 2,
};

pub const ShapeType = enum(c_uint) {
    circle = 0,
    capsule = 1,
    segment = 2,
    polygon = 3,
    chainSegment = 4,
    // TODO: do we need this?
    shapeTypeCount = 5,
};

pub const JointType = enum(c_uint) {
    distance,
    motor,
    mouse,
    prismatic,
    revolute,
    weld,
    wheel,
};

// TODO: I don't think using an actual enum here is particularily appropriate.
pub const HexColor = enum(c_int) {
    pub const aliceBlue = 0xf0f8ff;
    pub const antiqueWhite = 0xfaebd7;
    pub const aquamarine = 0x7fffd4;
    pub const azure = 0xf0ffff;
    pub const beige = 0xf5f5dc;
    pub const bisque = 0xffe4c4;
    pub const black = 0x000000;
    pub const blanchedAlmond = 0xffebcd;
    pub const blue = 0x0000ff;
    pub const blueViolet = 0x8a2be2;
    pub const brown = 0xa52a2a;
    pub const burlywood = 0xdeb887;
    pub const cadetBlue = 0x5f9ea0;
    pub const chartreuse = 0x7fff00;
    pub const chocolate = 0xd2691e;
    pub const coral = 0xff7f50;
    pub const cornflowerBlue = 0x6495ed;
    pub const cornsilk = 0xfff8dc;
    pub const crimson = 0xdc143c;
    pub const cyan = 0x00ffff;
    pub const darkBlue = 0x00008b;
    pub const darkCyan = 0x008b8b;
    pub const darkGoldenrod = 0xb8860b;
    pub const darkGray = 0xa9a9a9;
    pub const darkGreen = 0x006400;
    pub const darkKhaki = 0xbdb76b;
    pub const darkMagenta = 0x8b008b;
    pub const darkOliveGreen = 0x556b2f;
    pub const darkOrange = 0xff8c00;
    pub const darkOrchid = 0x9932cc;
    pub const darkRed = 0x8b0000;
    pub const darkSalmon = 0xe9967a;
    pub const darkSeaGreen = 0x8fbc8f;
    pub const darkSlateBlue = 0x483d8b;
    pub const darkSlateGray = 0x2f4f4f;
    pub const darkTurquoise = 0x00ced1;
    pub const darkViolet = 0x9400d3;
    pub const deepPink = 0xff1493;
    pub const deepSkyBlue = 0x00bfff;
    pub const dimGray = 0x696969;
    pub const dodgerBlue = 0x1e90ff;
    pub const firebrick = 0xb22222;
    pub const floralWhite = 0xfffaf0;
    pub const forestGreen = 0x228b22;
    pub const gainsboro = 0xdcdcdc;
    pub const ghostWhite = 0xf8f8ff;
    pub const gold = 0xffd700;
    pub const goldenrod = 0xdaa520;
    pub const gray = 0xbebebe;
    pub const gray1 = 0x1a1a1a;
    pub const gray2 = 0x333333;
    pub const gray3 = 0x4d4d4d;
    pub const gray4 = 0x666666;
    pub const gray5 = 0x7f7f7f;
    pub const gray6 = 0x999999;
    pub const gray7 = 0xb3b3b3;
    pub const gray8 = 0xcccccc;
    pub const gray9 = 0xe5e5e5;
    pub const green = 0x00ff00;
    pub const greenYellow = 0xadff2f;
    pub const honeydew = 0xf0fff0;
    pub const hotPink = 0xff69b4;
    pub const indianRed = 0xcd5c5c;
    pub const indigo = 0x4b0082;
    pub const ivory = 0xfffff0;
    pub const khaki = 0xf0e68c;
    pub const lavender = 0xe6e6fa;
    pub const lavenderBlush = 0xfff0f5;
    pub const lawnGreen = 0x7cfc00;
    pub const lemonChiffon = 0xfffacd;
    pub const lightBlue = 0xadd8e6;
    pub const lightCoral = 0xf08080;
    pub const lightCyan = 0xe0ffff;
    pub const lightGoldenrod = 0xeedd82;
    pub const lightGoldenrodYellow = 0xfafad2;
    pub const lightGray = 0xd3d3d3;
    pub const lightGreen = 0x90ee90;
    pub const lightPink = 0xffb6c1;
    pub const lightSalmon = 0xffa07a;
    pub const lightSeaGreen = 0x20b2aa;
    pub const lightSkyBlue = 0x87cefa;
    pub const lightSlateBlue = 0x8470ff;
    pub const lightSlateGray = 0x778899;
    pub const lightSteelBlue = 0xb0c4de;
    pub const lightYellow = 0xffffe0;
    pub const limeGreen = 0x32cd32;
    pub const linen = 0xfaf0e6;
    pub const magenta = 0xff00ff;
    pub const maroon = 0xb03060;
    pub const mediumAquamarine = 0x66cdaa;
    pub const mediumBlue = 0x0000cd;
    pub const mediumOrchid = 0xba55d3;
    pub const mediumPurple = 0x9370db;
    pub const mediumSeaGreen = 0x3cb371;
    pub const mediumSlateBlue = 0x7b68ee;
    pub const mediumSpringGreen = 0x00fa9a;
    pub const mediumTurquoise = 0x48d1cc;
    pub const mediumVioletRed = 0xc71585;
    pub const midnightBlue = 0x191970;
    pub const mintCream = 0xf5fffa;
    pub const mistyRose = 0xffe4e1;
    pub const moccasin = 0xffe4b5;
    pub const navajoWhite = 0xffdead;
    pub const navyBlue = 0x000080;
    pub const oldLace = 0xfdf5e6;
    pub const olive = 0x808000;
    pub const oliveDrab = 0x6b8e23;
    pub const orange = 0xffa500;
    pub const orangeRed = 0xff4500;
    pub const orchid = 0xda70d6;
    pub const paleGoldenrod = 0xeee8aa;
    pub const paleGreen = 0x98fb98;
    pub const paleTurquoise = 0xafeeee;
    pub const paleVioletRed = 0xdb7093;
    pub const papayaWhip = 0xffefd5;
    pub const peachPuff = 0xffdab9;
    pub const peru = 0xcd853f;
    pub const pink = 0xffc0cb;
    pub const plum = 0xdda0dd;
    pub const powderBlue = 0xb0e0e6;
    pub const purple = 0xa020f0;
    pub const rebeccaPurple = 0x663399;
    pub const red = 0xff0000;
    pub const RosyBrown = 0xbc8f8f;
    pub const RoyalBlue = 0x4169e1;
    pub const saddleBrown = 0x8b4513;
    pub const salmon = 0xfa8072;
    pub const sandyBrown = 0xf4a460;
    pub const seaGreen = 0x2e8b57;
    pub const seashell = 0xfff5ee;
    pub const sienna = 0xa0522d;
    pub const silver = 0xc0c0c0;
    pub const skyBlue = 0x87ceeb;
    pub const slateBlue = 0x6a5acd;
    pub const slateGray = 0x708090;
    pub const snow = 0xfffafa;
    pub const springGreen = 0x00ff7f;
    pub const steelBlue = 0x4682b4;
    pub const tan = 0xd2b48c;
    pub const teal = 0x008080;
    pub const thistle = 0xd8bfd8;
    pub const tomato = 0xff6347;
    pub const turquoise = 0x40e0d0;
    pub const violet = 0xee82ee;
    pub const violetRed = 0xd02090;
    pub const wheat = 0xf5deb3;
    pub const white = 0xffffff;
    pub const whiteSmoke = 0xf5f5f5;
    pub const yellow = 0xffff00;
    pub const yellowGreen = 0x9acd32;
    pub const box2DRed = 0xdc3132;
    pub const box2DBlue = 0x30aebf;
    pub const box2DGreen = 0x8cc924;
    pub const box2DYellow = 0xffee8c;
    // this is only an "enum" so we can have a type that behaves exactly like an int, but has declarations.
    _
};

// TODO: create a wrapper around DebugDraw so users of Box2D don't need to worry about the context type or calling convention
pub const DebugDraw = extern struct {
    pub inline fn default() DebugDraw {
        return @bitCast(native.b2DefaultDebugDraw());
    }
    DrawPolygon: *const fn ([*c]const Vec2, c_int, HexColor, ?*anyopaque) callconv(.C) void,
    DrawSolidPolygon: *const fn (Transform, [*c]const Vec2, c_int, f32, HexColor, ?*anyopaque) callconv(.C) void,
    DrawCircle: *const fn (Vec2, f32, HexColor, ?*anyopaque) callconv(.C) void,
    DrawSolidCircle: *const fn (Transform, f32, HexColor, ?*anyopaque) callconv(.C) void,
    DrawCapsule: *const fn (Vec2, Vec2, f32, HexColor, ?*anyopaque) callconv(.C) void,
    DrawSolidCapsule: *const fn (Vec2, Vec2, f32, HexColor, ?*anyopaque) callconv(.C) void,
    DrawSegment: *const fn (Vec2, Vec2, HexColor, ?*anyopaque) callconv(.C) void,
    DrawTransform: *const fn (Transform, ?*anyopaque) callconv(.C) void,
    DrawPoint: *const fn (Vec2, f32, HexColor, ?*anyopaque) callconv(.C) void,
    DrawString: *const fn (Vec2, [*c]const u8, ?*anyopaque) callconv(.C) void,
    drawingBounds: AABB,
    useDrawingBounds: bool,
    drawShapes: bool,
    drawJoints: bool,
    drawJointExtras: bool,
    drawAABBs: bool,
    drawMass: bool,
    drawContacts: bool,
    drawGraphColors: bool,
    drawContactNormals: bool,
    drawContactImpulses: bool,
    drawFrictionImpulses: bool,
    context: ?*anyopaque,
};

// defs

pub const ShapeDef = extern struct {
    userData: ?*anyopaque,
    friction: f32,
    restitution: f32,
    density: f32,
    filter: Filter,
    customColor: u32,
    isSensor: bool,
    enableSensorEvents: bool,
    enableContactEvents: bool,
    enableHitEvents: bool,
    enablePreSolveEvents: bool,
    forceContactCreation: bool,
    internalValue: i32,

    pub inline fn default() ShapeDef {
        return @bitCast(native.b2DefaultShapeDef());
    }
};

pub const ChainDef = extern struct {
    userData: ?*anyopaque,
    points: [*]const Vec2,
    count: i32,
    friction: f32,
    restitution: f32,
    filter: Filter,
    isLoop: bool,
    internalValue: i32,

    pub inline fn default() ChainDef {
        return @bitCast(native.b2DefaultChainDef());
    }
};

pub const DistanceJointDef = extern struct {
    bodyIdA: BodyId,
    bodyIdB: BodyId,
    localAnchorA: Vec2,
    localAnchorB: Vec2,
    length: f32,
    enableSpring: bool,
    hertz: f32,
    dampingRatio: f32,
    enableLimit: bool,
    minLength: f32,
    maxLength: f32,
    enableMotor: bool,
    maxMotorForce: f32,
    motorSpeed: f32,
    collideConnected: bool,
    userData: ?*anyopaque,
    internalValue: i32,

    pub inline fn default() DistanceJointDef {
        return @bitCast(native.b2DefaultDistanceJointDef());
    }
};

pub const MotorJointDef = extern struct {
    bodyIdA: BodyId,
    bodyIdB: BodyId,
    linearOffset: Vec2,
    angularOffset: f32,
    maxForce: f32,
    maxTorque: f32,
    correctionFactor: f32,
    collideConnected: bool,
    userData: ?*anyopaque,
    internalValue: i32,

    pub inline fn default() MotorJointDef {
        return @bitCast(native.b2DefaultMotorJointDef());
    }
};

pub const MouseJointDef = extern struct {
    bodyIdA: BodyId,
    bodyIdB: BodyId,
    target: Vec2,
    hertz: f32,
    dampingRatio: f32,
    maxForce: f32,
    collideConnected: bool,
    userData: ?*anyopaque,
    internalValue: i32,

    pub inline fn default() MouseJointDef {
        return @bitCast(native.b2DefaultMouseJointDef());
    }
};

pub const PrismaticJointDef = extern struct {
    bodyIdA: BodyId,
    bodyIdB: BodyId,
    localAnchorA: Vec2,
    localAnchorB: Vec2,
    localAxisA: Vec2,
    referenceAngle: f32,
    enableSpring: bool,
    hertz: f32,
    dampingRatio: f32,
    enableLimit: bool,
    lowerTranslation: f32,
    upperTranslation: f32,
    enableMotor: bool,
    maxMotorForce: f32,
    motorSpeed: f32,
    collideConnected: bool,
    userData: ?*anyopaque,
    internalValue: i32,

    pub inline fn default() PrismaticJointDef {
        return @bitCast(native.b2DefaultPrismaticJointDef());
    }
};

pub const RevoluteJointDef = extern struct {
    bodyIdA: BodyId,
    bodyIdB: BodyId,
    localAnchorA: Vec2,
    localAnchorB: Vec2,
    referenceAngle: f32,
    enableSpring: bool,
    hertz: f32,
    dampingRatio: f32,
    enableLimit: bool,
    lowerAngle: f32,
    upperAngle: f32,
    enableMotor: bool,
    maxMotorTorque: f32,
    motorSpeed: f32,
    drawSize: f32,
    collideConnected: bool,
    userData: ?*anyopaque,
    internalValue: i32,

    pub inline fn default() RevoluteJointDef {
        return @bitCast(native.b2DefaultRevoluteJointDef());
    }
};

pub const WeldJointDef = extern struct {
    bodyIdA: BodyId,
    bodyIdB: BodyId,
    localAnchorA: Vec2,
    localAnchorB: Vec2,
    referenceAngle: f32,
    linearHertz: f32,
    angularHertz: f32,
    linearDampingRatio: f32,
    angularDampingRatio: f32,
    collideConnected: bool,
    userData: ?*anyopaque,
    internalValue: i32,

    pub inline fn default() WeldJointDef {
        return @bitCast(native.b2DefaultWeldJointDef());
    }
};

pub const WheelJointDef = extern struct {
    bodyIdA: BodyId,
    bodyIdB: BodyId,
    localAnchorA: Vec2,
    localAnchorB: Vec2,
    localAxisA: Vec2,
    enableSpring: bool,
    hertz: f32,
    dampingRatio: f32,
    enableLimit: bool,
    lowerTranslation: f32,
    upperTranslation: f32,
    enableMotor: bool,
    maxMotorTorque: f32,
    motorSpeed: f32,
    collideConnecte: bool,
    userData: ?*anyopaque,
    internalValue: i32,

    pub inline fn default() WheelJointDef {
        return @bitCast(native.b2DefaultWheelJointDef());
    }
};

pub const BodyDef = extern struct {
    type: BodyType,
    position: Vec2,
    rotation: Rot,
    linearVelocity: Vec2,
    angularVelocity: f32,
    linearDamping: f32,
    angularDamping: f32,
    gravityScale: f32,
    sleepThreshold: f32,
    userData: ?*anyopaque,
    enableSleep: bool,
    isAwake: bool,
    fixedRotation: bool,
    isBullet: bool,
    isEnabled: bool,
    automaticMass: bool,
    allowFastRotation: bool,
    internalValue: i32,

    pub inline fn default() BodyDef {
        return @bitCast(native.b2DefaultBodyDef());
    }
};

pub const WorldDef = extern struct {
    gravity: Vec2,
    restitutionThreshold: f32,
    contactPushoutVelocity: f32,
    hitEventThreshold: f32,
    contactHertz: f32,
    contactDampingRatio: f32,
    jointHertz: f32,
    jointDampingRatio: f32,
    maximumLinearVelocity: f32,
    enableSleep: bool,
    enableContinuous: bool,
    workerCount: i32,
    // TODO: convert these callbacks manually & maybe make a wrapper?
    enqueueTask: ?*const native.b2EnqueueTaskCallback,
    finishTask: ?*const native.b2FinishTaskCallback,
    userTaskContext: ?*anyopaque,
    internalValue: i32,

    pub inline fn default() WorldDef {
        return @bitCast(native.b2DefaultWorldDef());
    }
};

// ids

pub const WorldId = extern struct {
    pub inline fn create(def: WorldDef) WorldId {
        return @bitCast(native.b2CreateWorld(@ptrCast(&def)));
    }

    pub inline fn destroy(worldId: WorldId) void {
        native.b2DestroyWorld(@bitCast(worldId));
    }

    pub inline fn isValid(id: WorldId) bool {
        return @bitCast(native.b2World_IsValid(@bitCast(id)));
    }

    pub inline fn step(worldId: WorldId, timeStep: f32, subStepCount: u32) void {
        native.b2World_Step(@bitCast(worldId), timeStep, @intCast(subStepCount));
    }

    pub inline fn draw(worldId: WorldId, dbgDraw: *DebugDraw) void {
        native.b2World_Draw(@bitCast(worldId), @ptrCast(dbgDraw));
    }

    pub inline fn getBodyEvents(worldId: WorldId) BodyEvents {
        return @bitCast(native.b2World_GetBodyEvents(@bitCast(worldId)));
    }

    pub inline fn getSensorEvents(worldId: WorldId) SensorEvents {
        return @bitCast(native.b2World_GetSensorEvents(@bitCast(worldId)));
    }

    pub inline fn getContactEvents(worldId: WorldId) ContactEvents {
        return @bitCast(native.b2World_GetContactEvents(@bitCast(worldId)));
    }

    pub inline fn overlapAABB(worldId: WorldId, aabb: AABB, filter: QueryFilter, overlapFn: *OverlapResultFn, context: ?*anyopaque) void {
        native.b2World_OverlapAABB(@bitCast(worldId), @bitCast(aabb), @bitCast(filter), @ptrCast(overlapFn), @ptrCast(context));
    }

    pub inline fn overlapCircle(worldId: WorldId, circle: Circle, transform: Transform, filter: QueryFilter, overlapFn: *OverlapResultFn, context: ?*anyopaque) void {
        native.b2World_OverlapCircle(@bitCast(worldId), @ptrCast(&circle), @bitCast(transform), @bitCast(filter), @ptrCast(overlapFn), @ptrCast(context));
    }

    pub inline fn overlapCapsule(worldId: WorldId, capsule: Capsule, transform: Transform, filter: QueryFilter, overlapFn: *OverlapResultFn, context: ?*anyopaque) void {
        native.b2World_OverlapCapsule(@bitCast(worldId), @ptrCast(&capsule), @bitCast(transform), @bitCast(filter), @ptrCast(overlapFn), @ptrCast(context));
    }

    pub inline fn overlapPolygon(worldId: WorldId, polygon: Polygon, transform: Transform, filter: QueryFilter, overlapFn: *OverlapResultFn, context: ?*anyopaque) void {
        native.b2World_OverlapPolygon(@bitCast(worldId), @ptrCast(&polygon), @bitCast(transform), @bitCast(filter), @ptrCast(overlapFn), @ptrCast(context));
    }

    pub inline fn castRay(worldId: WorldId, origin: Vec2, translation: Vec2, filter: QueryFilter, castFn: *CastResultFn, context: ?*anyopaque) void {
        native.b2World_CastRay(@bitCast(worldId), @bitCast(origin), @bitCast(translation), @bitCast(filter), @ptrCast(castFn), @ptrCast(context));
    }

    pub inline fn rayCastClosest(worldId: WorldId, origin: Vec2, translation: Vec2, filter: QueryFilter) RayResult {
        return @bitCast(native.b2World_RayCastClosest(@bitCast(worldId), @bitCast(origin), @bitCast(translation), @bitCast(filter)));
    }

    pub inline fn castCircle(worldId: WorldId, circle: Circle, originTransform: Transform, translation: Vec2, filter: QueryFilter, castFn: *CastResultFn, context: ?*anyopaque) void {
        native.b2World_CastCircle(@bitCast(worldId), @ptrCast(&circle), @bitCast(originTransform), @bitCast(translation), @bitCast(filter), @ptrCast(castFn), @ptrCast(context));
    }

    pub inline fn castCapsule(worldId: WorldId, capsule: Capsule, originTransform: Transform, translation: Vec2, filter: QueryFilter, castFn: *CastResultFn, context: ?*anyopaque) void {
        native.b2World_CastCapsule(@bitCast(worldId), @ptrCast(&capsule), @bitCast(originTransform), @bitCast(translation), @bitCast(filter), @ptrCast(castFn), @ptrCast(context));
    }

    pub inline fn castPolygon(worldId: WorldId, polygon: Polygon, originTransform: Transform, translation: Vec2, filter: QueryFilter, castFn: *CastResultFn, context: ?*anyopaque) void {
        native.b2World_CastPolygon(@bitCast(worldId), @ptrCast(&polygon), @bitCast(originTransform), @bitCast(translation), @bitCast(filter), @ptrCast(castFn), @ptrCast(context));
    }

    pub inline fn enableSleeping(worldId: WorldId, flag: bool) void {
        native.b2World_EnableSleeping(@bitCast(worldId), flag);
    }

    pub inline fn enableWarmStarting(worldId: WorldId, flag: bool) void {
        native.b2World_EnableWarmStarting(@bitCast(worldId), flag);
    }

    pub inline fn enableContinuous(worldId: WorldId, flag: bool) void {
        native.b2World_EnableContinuous(@bitCast(worldId), flag);
    }

    pub inline fn setRestitutionThreshold(worldId: WorldId, value: f32) void {
        native.b2World_SetRestitutionThreshold(@bitCast(worldId), value);
    }

    pub inline fn setHitEventThreshold(worldId: WorldId, value: f32) void {
        native.b2World_SetHitEventThreshold(@bitCast(worldId), value);
    }

    pub inline fn setPreSolveCallback(worldId: WorldId, preSolveFn: ?*PreSolveFn, context: ?*anyopaque) void {
        native.b2World_SetPreSolveCallback(@bitCast(worldId), @ptrCast(preSolveFn), @ptrCast(context));
    }

    pub inline fn setGravity(worldId: WorldId, gravity: Vec2) void {
        native.b2World_SetGravity(@bitCast(worldId), @bitCast(gravity));
    }

    pub inline fn getGravity(worldId: WorldId) Vec2 {
        return @bitCast(native.b2World_GetGravity(@bitCast(worldId)));
    }

    pub inline fn explode(worldId: WorldId, position: Vec2, radius: f32, impulse: f32) void {
        native.b2World_Explode(@bitCast(worldId), @bitCast(position), radius, impulse);
    }

    pub inline fn setContactTuning(worldId: WorldId, hertz: f32, dampingRatio: f32, pushVelocity: f32) void {
        native.b2World_SetContactTuning(@bitCast(worldId), hertz, dampingRatio, pushVelocity);
    }

    pub inline fn getProfile(worldId: WorldId) Profile {
        return @bitCast(native.b2World_GetProfile(@bitCast(worldId)));
    }

    pub inline fn getCounters(worldId: WorldId) Counters {
        return @bitCast(native.b2World_GetCounters(@bitCast(worldId)));
    }

    pub inline fn dumpMemoryStats(worldId: WorldId) void {
        native.b2World_DumpMemoryStats(@bitCast(worldId));
    }

    index1: u16,
    revision: u16,
};

pub const JointId = extern struct {
    index1: i32,
    world0: u16,
    revision: u16,

    pub inline fn createDistanceJoint(worldId: WorldId, def: DistanceJointDef) JointId {
        return @bitCast(native.b2CreateDistanceJoint(@bitCast(worldId), @ptrCast(&def)));
    }

    pub inline fn createMotorJoint(worldId: WorldId, def: MotorJointDef) JointId {
        return @bitCast(native.b2CreateMotorJoint(@bitCast(worldId), @ptrCast(&def)));
    }

    pub inline fn createMouseJoint(worldId: WorldId, def: MouseJointDef) JointId {
        return @bitCast(native.b2CreateMouseJoint(@bitCast(worldId), @ptrCast(&def)));
    }

    pub inline fn createPrismaticJoint(worldId: WorldId, def: PrismaticJointDef) JointId {
        return @bitCast(native.b2CreatePrismaticJoint(@bitCast(worldId), @ptrCast(&def)));
    }

    pub inline fn createRevoluteJoint(worldId: WorldId, def: RevoluteJointDef) JointId {
        return @bitCast(native.b2CreateRevoluteJoint(@bitCast(worldId), @ptrCast(&def)));
    }

    pub inline fn createWeldJoint(worldId: WorldId, def: WeldJointDef) JointId {
        return @bitCast(native.b2CreateWeldJoint(@bitCast(worldId), @ptrCast(&def)));
    }

    pub inline fn createWheelJoint(worldId: WorldId, def: WheelJointDef) JointId {
        return @bitCast(native.b2CreateWheelJoint(@bitCast(worldId), @ptrCast(&def)));
    }

    // The rename from destroy to deinit is to follow general zig patterns
    pub inline fn deinit(jointId: JointId) void {
        return native.b2DestroyJoint(@bitCast(jointId));
    }

    pub inline fn isValid(id: JointId) bool {
        return native.b2Joint_IsValid(@bitCast(id));
    }

    pub inline fn getType(jointId: JointId) JointType {
        return @bitCast(native.b2Joint_GetType(@bitCast(jointId)));
    }

    pub inline fn getBodyA(jointId: JointId) BodyId {
        return @bitCast(native.b2Joint_GetBodyA(@bitCast(jointId)));
    }

    pub inline fn getBodyB(jointId: JointId) BodyId {
        return @bitCast(native.b2Joint_GetBodyB(@bitCast(jointId)));
    }

    pub inline fn getLocalAnchorA(jointId: JointId) Vec2 {
        return @bitCast(native.b2Joint_GetLocalAnchorA(@bitCast(jointId)));
    }

    pub inline fn getLocalAnchorB(jointId: JointId) Vec2 {
        return @bitCast(native.b2Joint_GetLocalAnchorB(@bitCast(jointId)));
    }

    pub inline fn setCollideConnected(jointId: JointId, shouldCollide: bool) void {
        native.b2Joint_SetCollideConnected(@bitCast(jointId), shouldCollide);
    }

    pub inline fn getCollideConnected(jointId: JointId) bool {
        return native.b2Joint_GetCollideConnected(@bitCast(jointId));
    }

    pub inline fn setUserData(jointId: JointId, userData: ?*anyopaque) void {
        native.b2Joint_SetUserData(@bitCast(jointId), @ptrCast(userData));
    }

    pub inline fn getUserData(jointId: JointId) ?*anyopaque {
        return @ptrCast(native.b2Joint_GetUserData(@bitCast(jointId)));
    }

    pub inline fn wakeBodies(jointId: JointId) void {
        native.b2Joint_WakeBodies(@bitCast(jointId));
    }

    pub inline fn getConstraintForce(jointId: JointId) void {
        native.b2Joint_GetConstraintForce(@bitCast(jointId));
    }

    pub inline fn getConstraintTorque(jointId: JointId) void {
        native.b2Joint_GetConstraintTorque(@bitCast(jointId));
    }

    // TODO: merge common functions (ex: enableLimit) by switching in the type.
    pub inline fn distanceJointSetLength(jointId: JointId, length: f32) void {
        return native.b2DistanceJoint_SetLength(@bitCast(jointId), length);
    }

    pub inline fn distanceJointGetLength(jointId: JointId) f32 {
        return distanceJointGetLength(@bitCast(jointId));
    }

    pub inline fn distanceJointEnableSpring(jointId: JointId, enableSpring: bool) void {
        native.b2DistanceJoint_EnableSpring(@bitCast(jointId), enableSpring);
    }

    pub inline fn distanceJointIsSpringEnabled(jointId: JointId) bool {
        return native.b2DistanceJoint_IsSpringEnabled(@bitCast(jointId));
    }

    pub inline fn distanceJointSetSpringHertz(jointId: JointId, hertz: f32) void {
        native.b2DistanceJoint_SetSpringHertz(@bitCast(jointId), hertz);
    }

    pub inline fn distanceJointSetSpringDampingRatio(jointId: JointId, dampingRatio: f32) void {
        native.b2DistanceJoint_SetSpringDampingRatio(@bitCast(jointId), dampingRatio);
    }

    pub inline fn distanceJointGetSpringHertz(jointId: JointId) f32 {
        return native.b2DistanceJoint_GetSpringHertz(@bitCast(jointId));
    }

    pub inline fn distanceJointGetSpringDampingRatio(jointId: JointId) f32 {
        return native.b2DistanceJoint_GetSpringDampingRatio(@bitCast(jointId));
    }

    pub inline fn distanceJointEnableLimit(jointId: JointId, enableLimit: bool) void {
        return native.b2DistanceJoint_EnableLimit(@bitCast(jointId), enableLimit);
    }

    pub inline fn distanceJointIsLimitEnabled(jointId: JointId) bool {
        return native.b2DistanceJoint_IsLimitEnabled(@bitCast(jointId));
    }

    pub inline fn distanceJointSetLengthRange(jointId: JointId, minLength: f32, maxLength: f32) void {
        native.b2DistanceJoint_SetLengthRange(@bitCast(jointId), minLength, maxLength);
    }

    pub inline fn distanceJointGetMinLength(jointId: JointId) f32 {
        return native.b2DistanceJoint_GetMinLength(@bitCast(jointId));
    }

    pub inline fn distanceJointGetMaxLength(jointId: JointId) f32 {
        return native.b2DistanceJoint_GetMaxLength(@bitCast(jointId));
    }

    pub inline fn distanceJointGetCurrentLength(jointId: JointId) f32 {
        return native.b2DistanceJoint_GetCurrentLength(@bitCast(jointId));
    }

    pub inline fn distanceJointEnableMotor(jointId: JointId, enableMotor: bool) void {
        native.b2DistanceJoint_EnableMotor(@bitCast(jointId), enableMotor);
    }

    pub inline fn distanceJointIsMotorEnabled(jointId: JointId) bool {
        return native.b2DistanceJoint_IsMotorEnabled(@bitCast(jointId));
    }

    pub inline fn distanceJointSetMotorSpeed(jointId: JointId, motorSpeed: f32) void {
        native.b2DistanceJoint_SetMotorSpeed(@bitCast(jointId), motorSpeed);
    }

    pub inline fn distanceJointGetMotorSpeed(jointId: JointId) f32 {
        return native.b2DistanceJoint_GetMotorSpeed(@bitCast(jointId));
    }

    pub inline fn distanceJointGetMotorForce(jointId: JointId) f32 {
        return native.b2DistanceJoint_GetMotorForce(@bitCast(jointId));
    }

    pub inline fn distanceJointSetMaxMotorForce(jointId: JointId, force: f32) void {
        native.b2DistanceJoint_SetMaxMotorForce(@bitCast(jointId), force);
    }

    pub inline fn distanceJointGetMaxMotorForce(jointId: JointId) f32 {
        return native.b2DistanceJoint_GetMaxMotorForce(@bitCast(jointId));
    }

    pub inline fn motorJointSetLinearOffset(jointId: JointId, linearOffset: Vec2) void {
        native.b2MotorJoint_SetLinearOffset(@bitCast(jointId), linearOffset);
    }

    pub inline fn motorJointGetLinearOffset(jointId: JointId) Vec2 {
        return @bitCast(native.b2MotorJoint_GetLinearOffset(@bitCast(jointId)));
    }

    pub inline fn motorJointSetAngularOffset(jointId: JointId, angularOffset: f32) void {
        native.b2MotorJoint_SetAngularOffset(@bitCast(jointId), angularOffset);
    }

    pub inline fn motorJointGetAngularOffset(jointId: JointId) f32 {
        return native.b2MotorJoint_GetAngularOffset(@bitCast(jointId));
    }

    pub inline fn motorJointSetMaxForce(jointId: JointId, maxForce: f32) void {
        native.b2MotorJoint_SetMaxForce(@bitCast(jointId), maxForce);
    }

    pub inline fn motorJointGetMaxForce(jointId: JointId) f32 {
        return native.b2MotorJoint_GetMaxForce(@bitCast(jointId));
    }

    pub inline fn motorJointSetMaxTorque(jointId: JointId, maxTorque: f32) void {
        native.b2MotorJoint_SetMaxTorque(@bitCast(jointId), maxTorque);
    }

    pub inline fn motorJointGetMaxTorque(jointId: JointId) f32 {
        return native.b2MotorJoint_GetMaxTorque(@bitCast(jointId));
    }

    pub inline fn motorJointSetCorrectionFactor(jointId: JointId, correctionFactor: f32) void {
        native.b2MotorJoint_SetCorrectionFactor(@bitCast(jointId), correctionFactor);
    }

    pub inline fn motorJointGetCorrectionFactor(jointId: JointId) f32 {
        return native.b2MotorJoint_GetCorrectionFactor(@bitCast(jointId));
    }

    pub inline fn mouseJointSetTarget(jointId: JointId, target: Vec2) void {
        native.b2MouseJoint_SetTarget(@bitCast(jointId), @bitCast(target));
    }

    pub inline fn mouseJointGetTarget(jointId: JointId) Vec2 {
        return @bitCast(native.b2MouseJoint_GetTarget(@bitCast(jointId)));
    }

    pub inline fn mouseJointSetSpringHertz(jointId: JointId, hertz: f32) void {
        native.b2MouseJoint_SetSpringHertz(@bitCast(jointId), hertz);
    }

    pub inline fn mouseJointGetSpringHertz(jointId: JointId) f32 {
        return native.b2MouseJoint_GetSpringHertz(@bitCast(jointId));
    }

    pub inline fn mouseJointSetMaxForce(jointId: JointId, maxForce: f32) void {
        native.b2MouseJoint_SetMaxForce(@bitCast(jointId), maxForce);
    }

    pub inline fn mouseJointGetMaxForce(jointId: JointId) f32 {
        return native.b2MouseJoint_GetMaxForce(@bitCast(jointId));
    }

    pub inline fn mouseJointSetSpringDampingRatio(jointId: JointId, dampingRatio: f32) void {
        native.b2MouseJoint_SetSpringDampingRatio(@bitCast(jointId), dampingRatio);
    }

    pub inline fn mouseJointGetSpringDampingRatio(jointId: JointId) f32 {
        return native.b2MouseJoint_GetSpringDampingRatio(@bitCast(jointId));
    }

    pub inline fn prismaticJointEnableSpring(jointId: JointId, enableSpring: bool) void {
        native.b2PrismaticJoint_EnableSpring(@bitCast(jointId), enableSpring);
    }

    pub inline fn prismaticJointIsSpringEnabled(jointId: JointId) bool {
        return native.b2PrismaticJoint_IsSpringEnabled(@bitCast(jointId));
    }

    pub inline fn prismaticJointSetSpringHertz(jointId: JointId, hertz: f32) void {
        native.b2PrismaticJoint_SetSpringHertz(@bitCast(jointId), hertz);
    }

    pub inline fn prismaticJointGetSpringHertz(jointId: JointId) f32 {
        return native.b2PrismaticJoint_GetSpringHertz(@bitCast(jointId));
    }

    pub inline fn prismaticJointSetSpringDampingRatio(jointId: JointId, dampingRatio: f32) void {
        native.b2PrismaticJoint_SetSpringDampingRatio(@bitCast(jointId), dampingRatio);
    }

    pub inline fn prismaticJointGetSpringDampingRatio(jointId: JointId) f32 {
        return native.b2PrismaticJoint_GetSpringDampingRatio(@bitCast(jointId));
    }

    pub inline fn prismaticJointEnableLimit(jointId: JointId, enableLimit: bool) void {
        native.b2PrismaticJoint_EnableLimit(@bitCast(jointId), enableLimit);
    }

    pub inline fn prismaticJointIsLimitEnabled(jointId: JointId) bool {
        return native.b2PrismaticJoint_IsLimitEnabled(@bitCast(jointId));
    }

    pub inline fn prismaticJointGetLowerLimit(jointId: JointId) f32 {
        return native.b2PrismaticJoint_GetLowerLimit(@bitCast(jointId));
    }

    pub inline fn prismaticJointGetUpperLimit(jointId: JointId) f32 {
        return native.b2PrismaticJoint_GetUpperLimit(@bitCast(jointId));
    }

    pub inline fn prismaticJointSetLimits(jointId: JointId, lower: f32, upper: f32) void {
        native.b2PrismaticJoint_SetLimits(@bitCast(jointId), lower, upper);
    }

    pub inline fn prismaticJointEnableMotor(jointId: JointId, enableMotor: bool) void {
        native.b2PrismaticJoint_EnableMotor(@bitCast(jointId), enableMotor);
    }

    pub inline fn prismaticJointIsMotorEnabled(jointId: JointId) bool {
        return native.b2PrismaticJoint_IsMotorEnabled(@bitCast(jointId));
    }

    pub inline fn prismaticJointSetMotorSpeed(jointId: JointId, motorSpeed: f32) void {
        native.b2PrismaticJoint_SetMotorSpeed(@bitCast(jointId), motorSpeed);
    }

    pub inline fn prismaticJointGetMotorSpeed(jointId: JointId) f32 {
        return native.b2PrismaticJoint_GetMotorSpeed(@bitCast(jointId));
    }

    pub inline fn prismaticJointGetMotorForce(jointId: JointId) f32 {
        return native.b2PrismaticJoint_GetMotorForce(@bitCast(jointId));
    }

    pub inline fn prismaticJointSetMaxMotorForce(jointId: JointId, force: f32) void {
        native.b2PrismaticJoint_SetMaxMotorForce(@bitCast(jointId), force);
    }

    pub inline fn prismaticJointGetMaxMotorForce(jointId: JointId) f32 {
        return native.b2PrismaticJoint_GetMaxMotorForce(@bitCast(jointId));
    }

    pub inline fn revoluteJointEnableSpring(jointId: JointId, enableSpring: bool) void {
        native.b2RevoluteJoint_EnableSpring(@bitCast(jointId), enableSpring);
    }

    pub inline fn revoluteJointIsSpringEnabled(jointId: JointId) bool {
        return native.b2RevoluteJoint_IsSpringEnabled(@bitCast(jointId));
    }

    pub inline fn revoluteJointIsLimitEnabled(jointId: JointId) bool {
        return native.b2RevoluteJoint_IsLimitEnabled(@bitCast(jointId));
    }

    pub inline fn revoluteJointSetSpringHertz(jointId: JointId, hertz: f32) void {
        native.b2RevoluteJoint_SetSpringHertz(@bitCast(jointId), hertz);
    }

    pub inline fn revoluteJointGetSpringHertz(jointId: JointId) f32 {
        return native.b2RevoluteJoint_GetSpringHertz(@bitCast(jointId));
    }

    pub inline fn revoluteJointSetSpringDampingRatio(jointId: JointId, dampingRatio: f32) void {
        native.b2RevoluteJoint_SetSpringDampingRatio(@bitCast(jointId), dampingRatio);
    }

    pub inline fn revoluteJointGetSpringDampingRatio(jointId: JointId) f32 {
        return native.b2RevoluteJoint_GetSpringDampingRatio(@bitCast(jointId));
    }

    pub inline fn revoluteJointGetAngle(jointId: JointId) f32 {
        return native.b2RevoluteJoint_GetAngle(@bitCast(jointId));
    }

    pub inline fn revoluteJointEnableLimit(jointId: JointId, enableLimit: bool) void {
        native.b2RevoluteJoint_EnableLimit(@bitCast(jointId), enableLimit);
    }

    pub inline fn revoluteJointGetLowerLimit(jointId: JointId) f32 {
        return native.b2RevoluteJoint_GetLowerLimit(@bitCast(jointId));
    }

    pub inline fn revoluteJointGetUpperLimit(jointId: JointId) f32 {
        return native.b2RevoluteJoint_GetUpperLimit(@bitCast(jointId));
    }

    pub inline fn revoluteJointSetLimits(jointId: JointId, lower: f32, upper: f32) void {
        native.b2RevoluteJoint_SetLimits(@bitCast(jointId), lower, upper);
    }

    pub inline fn revoluteJointEnableMotor(jointId: JointId, enableMotor: bool) void {
        native.b2RevoluteJoint_EnableMotor(@bitCast(jointId), enableMotor);
    }

    pub inline fn revoluteJointIsMotorEnabled(jointId: JointId) bool {
        return native.b2RevoluteJoint_IsMotorEnabled(@bitCast(jointId));
    }

    pub inline fn revoluteJointSetMotorSpeed(jointId: JointId, motorSpeed: f32) void {
        native.b2RevoluteJoint_SetMotorSpeed(@bitCast(jointId), motorSpeed);
    }

    pub inline fn revoluteJointGetMotorSpeed(jointId: JointId) f32 {
        return native.b2RevoluteJoint_GetMotorSpeed(@bitCast(jointId));
    }

    pub inline fn revoluteJointGetMotorTorque(jointId: JointId) f32 {
        return native.b2RevoluteJoint_GetMotorTorque(@bitCast(jointId));
    }

    pub inline fn revoluteJointSetMaxMotorTorque(jointId: JointId, torque: f32) void {
        native.b2RevoluteJoint_SetMaxMotorTorque(@bitCast(jointId), torque);
    }

    pub inline fn revoluteJointGetMaxMotorTorque(jointId: JointId) f32 {
        return native.b2RevoluteJoint_GetMaxMotorTorque(@bitCast(jointId));
    }

    pub inline fn wheelJointEnableSpring(jointId: JointId, enableSpring: bool) void {
        native.b2WheelJoint_EnableSpring(@bitCast(jointId), enableSpring);
    }

    pub inline fn wheelJointIsSpringEnabled(jointId: JointId) bool {
        return native.b2WheelJoint_IsSpringEnabled(@bitCast(jointId));
    }

    pub inline fn wheelJointSetSpringHertz(jointId: JointId, hertz: f32) void {
        return native.b2WheelJoint_SetSpringHertz(@bitCast(jointId), hertz);
    }

    pub inline fn wheelJointGetSpringHertz(jointId: JointId) f32 {
        return native.b2WheelJoint_GetSpringHertz(@bitCast(jointId));
    }

    pub inline fn wheelJointSetSpringDampingRatio(jointId: JointId, dampingRatio: f32) void {
        native.b2WheelJoint_SetSpringDampingRatio(@bitCast(jointId), dampingRatio);
    }

    pub inline fn wheelJointGetSpringDampingRatio(jointId: JointId) f32 {
        return native.b2WheelJoint_GetSpringDampingRatio(@bitCast(jointId));
    }

    pub inline fn wheelJointEnableLimit(jointId: JointId, enableLimit: bool) void {
        native.b2WheelJoint_EnableLimit(@bitCast(jointId), enableLimit);
    }

    pub inline fn wheelJointIsLimitEnabled(jointId: JointId) bool {
        return native.b2WheelJoint_IsLimitEnabled(@bitCast(jointId));
    }

    pub inline fn wheelJointGetLowerLimit(jointId: JointId) f32 {
        return native.b2WheelJoint_GetLowerLimit(@bitCast(jointId));
    }

    pub inline fn wheelJointGetUpperLimit(jointId: JointId) f32 {
        return native.b2WheelJoint_GetUpperLimit(@bitCast(jointId));
    }

    pub inline fn wheelJointSetLimits(jointId: JointId, lower: f32, upper: f32) void {
        native.b2WheelJoint_SetLimits(@bitCast(jointId), lower, upper);
    }

    pub inline fn wheelJointEnableMotor(jointId: JointId, enableMotor: bool) void {
        native.b2WheelJoint_EnableMotor(@bitCast(jointId), enableMotor);
    }

    pub inline fn wheelJointIsMotorEnabled(jointId: JointId) bool {
        return native.b2WheelJoint_IsMotorEnabled(@bitCast(jointId));
    }

    pub inline fn wheelJointSetMotorSpeed(jointId: JointId, motorSpeed: f32) void {
        native.b2WheelJoint_SetMotorSpeed(@bitCast(jointId), motorSpeed);
    }

    pub inline fn wheelJointGetMotorSpeed(jointId: JointId) f32 {
        return native.b2WheelJoint_GetMotorSpeed(@bitCast(jointId));
    }

    pub inline fn wheelJointGetMotorTorque(jointId: JointId) f32 {
        return native.b2WheelJoint_GetMotorTorque(@bitCast(jointId));
    }

    pub inline fn wheelJointSetMaxMotorTorque(jointId: JointId, torque: f32) void {
        native.b2WheelJoint_SetMaxMotorTorque(@bitCast(jointId), torque);
    }

    pub inline fn wheelJointGetMaxMotorTorque(jointId: JointId) f32 {
        return native.b2WheelJoint_GetMaxMotorTorque(@bitCast(jointId));
    }

    pub inline fn weldJointSetLinearHertz(jointId: JointId, hertz: f32) void {
        return native.b2WeldJoint_SetLinearHertz(@bitCast(jointId), hertz);
    }

    pub inline fn weldJointGetLinearHertz(jointId: JointId) f32 {
        return native.b2WeldJoint_GetLinearHertz(@bitCast(jointId));
    }

    pub inline fn weldJointSetLinearDampingRatio(jointId: JointId, dampingRatio: f32) void {
        native.b2WeldJoint_SetLinearDampingRatio(@bitCast(jointId), dampingRatio);
    }

    pub inline fn weldJointGetLinearDampingRatio(jointId: JointId) f32 {
        return native.b2WeldJoint_GetLinearDampingRatio(@bitCast(jointId));
    }

    pub inline fn weldJointSetAngularHertz(jointId: JointId, hertz: f32) void {
        return native.b2WeldJoint_SetAngularHertz(@bitCast(jointId), hertz);
    }

    pub inline fn weldJointGetAngularHertz(jointId: JointId) f32 {
        return native.b2WeldJoint_GetAngularHertz(@bitCast(jointId));
    }

    pub inline fn weldJointSetAngularDampingRatio(jointId: JointId, dampingRatio: f32) void {
        native.b2WeldJoint_SetAngularDampingRatio(@bitCast(jointId), dampingRatio);
    }

    pub inline fn weldJointGetAngularDampingRatio(jointId: JointId) f32 {
        return native.b2WeldJoint_GetAngularDampingRatio(@bitCast(jointId));
    }
};

pub const ChainId = extern struct {
    index: i32,
    world0: u16,
    revision: u16,

    pub inline fn create(bodyId: BodyId, def: ChainDef) ChainId {
        return @bitCast(native.b2CreateChain(@bitCast(bodyId), @ptrCast(&def)));
    }

    // renamed from destroy to deinit to follow zig pattern
    pub inline fn deinit(chainId: ChainId) void {
        native.b2DestroyChain(@bitCast(chainId));
    }

    pub inline fn setFriction(chainId: ChainId, friction: f32) void {
        native.b2Chain_SetFriction(@bitCast(chainId), friction);
    }

    pub inline fn setRestitution(chainId: ChainId, restitution: f32) void {
        native.b2Chain_SetRestitution(@bitCast(chainId), restitution);
    }

    pub inline fn isValid(id: ChainId) bool {
        return native.b2Chain_IsValid(@bitCast(id));
    }
};

pub const ShapeId = extern struct {
    index1: i32,
    world0: u16,
    revision: u16,

    pub inline fn createCircleShape(bodyId: BodyId, def: ShapeDef, circle: Circle) ShapeId {
        return @bitCast(native.b2CreateCircleShape(@bitCast(bodyId), @ptrCast(&def), @ptrCast(&circle)));
    }

    pub inline fn createSegmentShape(bodyId: BodyId, def: ShapeDef, segment: Segment) ShapeId {
        return @bitCast(native.b2CreateSegmentShape(@bitCast(bodyId), @ptrCast(&def), @ptrCast(&segment)));
    }

    pub inline fn createCapsuleShape(bodyId: BodyId, def: ShapeDef, capsule: Capsule) ShapeId {
        return @bitCast(native.b2CreateCapsuleShape(@bitCast(bodyId), @ptrCast(&def), @ptrCast(&capsule)));
    }

    pub inline fn createPolygonShape(bodyId: BodyId, def: ShapeDef, polygon: Polygon) ShapeId {
        return @bitCast(native.b2CreatePolygonShape(@bitCast(bodyId), @ptrCast(&def), @ptrCast(&polygon)));
    }

    // renamed forom destroy to deinit to follow zig patterns
    pub inline fn deinit(shapeId: ShapeId) void {
        native.b2DestroyShape(@bitCast(shapeId));
    }

    pub inline fn isValid(id: ShapeId) bool {
        return native.b2Shape_IsValid(@bitCast(id));
    }

    pub inline fn getType(shapeId: ShapeId) ShapeType {
        return @bitCast(native.b2Shape_GetType(@bitCast(shapeId)));
    }

    pub inline fn getBody(shapeId: ShapeId) BodyId {
        return @bitCast(native.b2Shape_GetBody(@bitCast(shapeId)));
    }

    pub inline fn isSensor(shapeId: ShapeId) bool {
        return native.b2Shape_IsSensor(@bitCast(shapeId));
    }

    pub inline fn setUserData(shapeId: ShapeId, userData: ?*anyopaque) void {
        native.b2Shape_SetUserData(@bitCast(shapeId), @ptrCast(userData));
    }

    pub inline fn getUserData(shapeId: ShapeId) ?*anyopaque {
        return @ptrCast(native.b2Shape_GetUserData(@bitCast(shapeId)));
    }

    pub inline fn setDensity(shapeId: ShapeId, density: f32) void {
        native.b2Shape_SetDensity(@bitCast(shapeId), density);
    }

    pub inline fn getDensity(shapeId: ShapeId) f32 {
        return native.b2Shape_GetDensity(@bitCast(shapeId));
    }

    pub inline fn setFriction(shapeId: ShapeId, friction: f32) void {
        native.b2Shape_SetFriction(@bitCast(shapeId), friction);
    }

    pub inline fn getFriction(shapeId: ShapeId) f32 {
        return native.b2Shape_GetFriction(@bitCast(shapeId));
    }

    pub inline fn setRestitution(shapeId: ShapeId, restitution: f32) void {
        native.b2Shape_SetRestitution(@bitCast(shapeId), restitution);
    }

    pub inline fn getRestitution(shapeId: ShapeId) f32 {
        return native.b2Shape_GetRestitution(@bitCast(shapeId));
    }

    pub inline fn getFilter(shapeId: ShapeId) Filter {
        return @bitCast(native.b2Shape_GetFilter(@bitCast(shapeId)));
    }

    pub inline fn setFilter(shapeId: ShapeId, filter: Filter) void {
        native.b2Shape_SetFilter(@bitCast(shapeId), @bitCast(filter));
    }

    pub inline fn enableSensorEvents(shapeId: ShapeId, flag: bool) void {
        native.b2Shape_EnableSensorEvents(@bitCast(shapeId), flag);
    }

    pub inline fn areSensorEventsEnabled(shapeId: ShapeId) bool {
        return native.b2Shape_AreSensorEventsEnabled(@bitCast(shapeId));
    }

    pub inline fn enableContactEvents(shapeId: ShapeId, flag: bool) void {
        native.b2Shape_EnableContactEvents(@bitCast(shapeId), flag);
    }

    pub inline fn areContactEventsEnabled(shapeId: ShapeId) bool {
        native.b2Shape_AreContactEventsEnabled(@bitCast(shapeId));
    }

    pub inline fn enablePreSolveEvents(shapeId: ShapeId, flag: bool) void {
        native.b2Shape_EnablePreSolveEvents(@bitCast(shapeId), flag);
    }

    pub inline fn arePreSolveEventsEnabled(shapeId: ShapeId) bool {
        return native.b2Shape_ArePreSolveEventsEnabled(@bitCast(shapeId));
    }

    pub inline fn enableHitEvents(shapeId: ShapeId, flag: bool) void {
        native.b2Shape_EnableContactEvents(@bitCast(shapeId), flag);
    }

    pub inline fn areHitEventsEnabled(shapeId: ShapeId) bool {
        return native.b2Shape_AreHitEventsEnabled(@bitCast(shapeId));
    }

    pub inline fn testPoint(shapeId: ShapeId, point: Vec2) bool {
        return native.b2Shape_TestPoint(@bitCast(shapeId), @bitCast(point));
    }

    pub inline fn rayCast(shapeId: ShapeId, input: RayCastInput) CastOutput {
        return @bitCast(native.b2Shape_RayCast(@bitCast(shapeId), @ptrCast(&input)));
    }

    pub inline fn getCircle(shapeId: ShapeId) Circle {
        return @bitCast(native.b2Shape_GetCircle(@bitCast(shapeId)));
    }

    pub inline fn getSegment(shapeId: ShapeId) Segment {
        return @bitCast(native.b2Shape_GetSegment(@bitCast(shapeId)));
    }

    pub inline fn getChainSegment(shapeId: ShapeId) ChainSegment {
        return @bitCast(native.b2Shape_GetChainSegment(@bitCast(shapeId)));
    }

    pub inline fn getCapsule(shapeId: ShapeId) Capsule {
        return @bitCast(native.b2Shape_GetCapsule(@bitCast(shapeId)));
    }

    pub inline fn getPolygon(shapeId: ShapeId) Polygon {
        return @bitCast(native.b2Shape_GetPolygon(@bitCast(shapeId)));
    }

    pub inline fn setCircle(shapeId: ShapeId, circle: Circle) void {
        native.b2Shape_SetCircle(@bitCast(shapeId), @bitCast(circle));
    }

    pub inline fn setCapsule(shapeId: ShapeId, capsule: Capsule) void {
        native.b2Shape_SetCapsule(@bitCast(shapeId), @bitCast(capsule));
    }

    pub inline fn setSegment(shapeId: ShapeId, segment: Segment) void {
        native.b2Shape_SetSegment(@bitCast(shapeId), @bitCast(segment));
    }

    pub inline fn setPolygon(shapeId: ShapeId, polygon: Polygon) void {
        native.b2Shape_SetPolygon(@bitCast(shapeId), @bitCast(polygon));
    }

    pub inline fn getParentChain(shapeId: ShapeId) ChainId {
        return @bitCast(native.b2Shape_GetParentChain(@bitCast(shapeId)));
    }

    pub inline fn getContactCapacity(shapeId: ShapeId) usize {
        return @intCast(native.b2Shape_GetContactCapacity(@bitCast(shapeId)));
    }

    pub inline fn getContactData(shapeId: ShapeId, contacts: []ContactData) usize {
        return @intCast(native.b2Shape_GetContactData(@bitCast(shapeId), @ptrCast(contacts.ptr), @intCast(contacts.len)));
    }

    pub inline fn getAABB(shapeId: ShapeId) AABB {
        return @bitCast(native.b2Shape_GetAABB(@bitCast(shapeId)));
    }

    pub inline fn getClosestPoint(shapeId: ShapeId, target: Vec2) Vec2 {
        return @bitCast(native.b2Shape_GetClosestPoint(@bitCast(shapeId), @bitCast(target)));
    }
};

pub const BodyId = extern struct {
    pub inline fn create(worldId: WorldId, def: BodyDef) BodyId {
        return @bitCast(native.b2CreateBody(@bitCast(worldId), @ptrCast(&def)));
    }

    pub inline fn destroy(bodyId: BodyId) void {
        return native.b2DestroyBody(@bitCast(bodyId));
    }

    pub inline fn isValid(id: BodyId) bool {
        return native.b2Body_IsValid(@bitCast(id));
    }

    pub inline fn getType(bodyId: BodyId) BodyType {
        return @bitCast(native.b2Body_GetType(@bitCast(bodyId)));
    }

    pub inline fn setType(bodyId: BodyId, @"type": BodyType) void {
        native.b2Body_SetType(@bitCast(bodyId), @bitCast(@"type"));
    }

    pub inline fn setUserData(bodyId: BodyId, userData: ?*anyopaque) void {
        native.b2Body_SetUserData(@bitCast(bodyId), @ptrCast(userData));
    }

    pub inline fn getUserData(bodyId: BodyId) ?*anyopaque {
        return @ptrCast(native.b2Body_GetUserData(@bitCast(bodyId)));
    }

    pub inline fn getPosition(bodyId: BodyId) Vec2 {
        return @bitCast(native.b2Body_GetPosition(@bitCast(bodyId)));
    }

    pub inline fn getRotation(bodyId: BodyId) Rot {
        return @bitCast(native.b2Body_GetRotation(@bitCast(bodyId)));
    }

    pub inline fn getAngle(bodyId: BodyId) f32 {
        return native.b2Body_GetAngle(@bitCast(bodyId));
    }

    pub inline fn getTransform(bodyId: BodyId) Transform {
        return @bitCast(native.b2Body_GetTransform(@bitCast(bodyId)));
    }

    pub inline fn setTransform(bodyId: BodyId, position: Vec2, angle: f32) void {
        native.b2Body_SetTransform(@bitCast(bodyId), @bitCast(position), angle);
    }

    pub inline fn getLocalPoint(bodyId: BodyId, worldPoint: Vec2) Vec2 {
        return @bitCast(native.b2Body_GetLocalPoint(@bitCast(bodyId), @bitCast(worldPoint)));
    }

    pub inline fn getWorldPoint(bodyId: BodyId, localPoint: Vec2) Vec2 {
        return @bitCast(native.b2Body_GetWorldPoint(@bitCast(bodyId), @bitCast(localPoint)));
    }

    pub inline fn getLocalVector(bodyId: BodyId, worldVector: Vec2) Vec2 {
        return @bitCast(native.b2Body_GetLocalVector(@bitCast(bodyId), @bitCast(worldVector)));
    }

    pub inline fn getWorldVector(bodyId: BodyId, localVector: Vec2) Vec2 {
        return @bitCast(native.b2Body_GetWorldVector(@bitCast(bodyId), @bitCast(localVector)));
    }

    pub inline fn getLinearVelocity(bodyId: BodyId) Vec2 {
        return @bitCast(native.b2Body_GetLinearVelocity(@bitCast(bodyId)));
    }

    pub inline fn getAngularVelocity(bodyId: BodyId) f32 {
        return native.b2Body_GetAngularVelocity(@bitCast(bodyId));
    }

    pub inline fn setLinearVelocity(bodyId: BodyId, linearVelocity: Vec2) void {
        native.b2Body_SetLinearVelocity(@bitCast(bodyId), @bitCast(linearVelocity));
    }

    pub inline fn setAngularVelocity(bodyId: BodyId, angularVelocity: f32) void {
        native.b2Body_SetAngularVelocity(@bitCast(bodyId), @bitCast(angularVelocity));
    }

    pub inline fn applyForce(bodyId: BodyId, force: Vec2, point: Vec2, wake: bool) void {
        native.b2Body_ApplyForce(@bitCast(bodyId), @bitCast(force), @bitCast(point), wake);
    }

    pub inline fn applyForceToCenter(bodyId: BodyId, force: Vec2, wake: bool) void {
        native.b2Body_ApplyForceToCenter(@bitCast(bodyId), @bitCast(force), wake);
    }

    pub inline fn applyTorque(bodyId: BodyId, torque: f32, wake: bool) void {
        native.b2Body_ApplyTorque(@bitCast(bodyId), @bitCast(torque), @bitCast(wake));
    }

    pub inline fn applyLinearImpulse(bodyId: BodyId, impulse: Vec2, point: Vec2, wake: bool) void {
        native.b2Body_ApplyLinearImpulse(@bitCast(bodyId), @bitCast(impulse), @bitCast(point), @bitCast(wake));
    }

    pub inline fn applyLinearImpulseToCenter(bodyId: BodyId, impulse: Vec2, wake: bool) void {
        native.b2Body_ApplyLinearImpulseToCenter(@bitCast(bodyId), @bitCast(impulse), wake);
    }

    pub inline fn applyAngularImpulse(bodyId: BodyId, impulse: f32, wake: bool) void {
        native.b2Body_ApplyAngularImpulse(@bitCast(bodyId), @bitCast(impulse), wake);
    }

    pub inline fn getMass(bodyId: BodyId) f32 {
        return native.b2Body_GetMass(@bitCast(bodyId));
    }

    pub inline fn getRotationalInertia(bodyId: BodyId) f32 {
        return native.b2Body_GetRotationalIntertia(@bitCast(bodyId));
    }

    pub inline fn getLocalCenterOfMass(bodyId: BodyId) Vec2 {
        return @bitCast(native.b2Body_GetLocalCenterOfMass(@bitCast(bodyId)));
    }

    pub inline fn getWorldCenterOfMass(bodyId: BodyId) Vec2 {
        return @bitCast(native.b2Body_GetWorldCenterOfMass(@bitCast(bodyId)));
    }

    pub inline fn setMassData(bodyId: BodyId, massData: MassData) void {
        native.b2Body_SetMassData(@bitCast(bodyId), @bitCast(massData));
    }

    pub inline fn getMassData(bodyId: BodyId) MassData {
        return @bitCast(native.b2Body_GetMassData(@bitCast(bodyId)));
    }

    pub inline fn applyMassFromShapes(bodyId: BodyId) void {
        native.b2Body_ApplyMassFromShapes(@bitCast(bodyId));
    }

    pub inline fn setAutomaticMass(bodyId: BodyId, automaticMass: bool) void {
        native.b2Body_SetAutomaticMass(@bitCast(bodyId), automaticMass);
    }

    pub inline fn getAutomaticMass(bodyId: BodyId) bool {
        return native.b2Body_GetAutomaticMass(@bitCast(bodyId));
    }

    pub inline fn setLinearDamping(bodyId: BodyId, linearDamping: f32) void {
        native.b2Body_SetLinearDamping(@bitCast(bodyId), linearDamping);
    }

    pub inline fn getLinearDamping(bodyId: BodyId) f32 {
        return native.b2Body_GetLinearDamping(@bitCast(bodyId));
    }

    pub inline fn setAngularDamping(bodyId: BodyId, angularDamping: f32) void {
        native.b2Body_SetAngularDamping(@bitCast(bodyId), angularDamping);
    }

    pub inline fn getAngularDamping(bodyId: BodyId) f32 {
        return native.b2Body_GetAngularDamping(@bitCast(bodyId));
    }

    pub inline fn setGravityScale(bodyId: BodyId, gravityScale: f32) void {
        native.b2Body_SetGravityScale(@bitCast(bodyId), gravityScale);
    }

    pub inline fn getGravityScale(bodyId: BodyId) f32 {
        return native.b2Body_GetGravityScale(@bitCast(bodyId));
    }

    pub inline fn isAwake(bodyId: BodyId) bool {
        return native.b2Body_IsAwake(@bitCast(bodyId));
    }

    pub inline fn setAwake(bodyId: BodyId, awake: bool) void {
        native.b2Body_SetAwake(@bitCast(bodyId), awake);
    }

    pub inline fn enableSleep(bodyId: BodyId, _enableSleep: bool) void {
        native.b2Body_EnableSleep(@bitCast(bodyId), _enableSleep);
    }

    pub inline fn isSleepEnabled(bodyId: BodyId) bool {
        return native.b2Body_IsSleepEnabled(@bitCast(bodyId));
    }

    pub inline fn setSleepThreshold(bodyId: BodyId, sleepThreshold: f32) void {
        native.b2Body_SetSleepThreshold(@bitCast(bodyId), sleepThreshold);
    }

    pub inline fn getSleepThreshold(bodyId: BodyId) f32 {
        return native.b2Body_GetSleepThreshold(@bitCast(bodyId));
    }

    pub inline fn isEnabled(bodyId: BodyId) bool {
        return native.b2Body_IsEnabled(@bitCast(bodyId));
    }

    pub inline fn disable(bodyId: BodyId) void {
        native.b2Body_Disable(@bitCast(bodyId));
    }

    pub inline fn enable(bodyId: BodyId) void {
        native.b2Body_Enable(@bitCast(bodyId));
    }

    pub inline fn setFixedRotation(bodyId: BodyId, flag: bool) void {
        native.b2Body_SetFixedRotation(@bitCast(bodyId), flag);
    }

    pub inline fn isFixedRotation(bodyId: BodyId) bool {
        return native.b2Body_IsFixedRotation(@bitCast(bodyId));
    }

    pub inline fn setBullet(bodyId: BodyId, flag: bool) void {
        native.b2Body_SetBullet(@bitCast(bodyId), flag);
    }

    pub inline fn isBullet(bodyId: BodyId) bool {
        return native.b2Body_IsBullet(@bitCast(bodyId));
    }

    pub inline fn enableHitEvents(bodyId: BodyId, _enableHitEvents: bool) void {
        native.b2Body_EnableHitEvents(@bitCast(bodyId), _enableHitEvents);
    }

    pub inline fn getShapeCount(bodyId: BodyId) usize {
        return @intCast(native.b2Body_GetShapeCount(@bitCast(bodyId)));
    }

    pub inline fn getShapes(bodyId: BodyId, shapes: []ShapeId) usize {
        return @intCast(native.b2Body_GetShapes(@bitCast(bodyId), @ptrCast(shapes.ptr), @intCast(shapes.len)));
    }

    pub inline fn getJointCount(bodyId: BodyId) usize {
        return @intCast(native.b2Body_GetJointCount(bodyId));
    }

    pub inline fn getJoints(bodyId: BodyId, joints: []JointId) usize {
        return @intCast(native.b2Body_GetJoints(@bitCast(bodyId), @ptrCast(joints.ptr), @intCast(joints.len)));
    }

    pub inline fn getContactCapacity(bodyId: BodyId) usize {
        return @intCast(native.b2Body_GetContactCapacity(@bitCast(bodyId)));
    }

    pub inline fn getContactData(bodyId: BodyId, contacts: []ContactData) usize {
        return @intCast(native.b2Body_GetContactData(@bitCast(bodyId), @ptrCast(contacts.ptr), @intCast(contacts.len)));
    }

    pub inline fn computeAABB(bodyId: BodyId) AABB {
        return @bitCast(native.b2Body_ComputeAABB(@bitCast(bodyId)));
    }

    index1: i32,
    world0: u16,
    revision: u16,
};

// shapes

pub const Hull = extern struct {
    points: [8]Vec2,
    count: i32,

    pub inline fn makePolygon(hull: Hull, radius: f32) Polygon {
        return @bitCast(native.b2MakePolygon(@ptrCast(&hull), radius));
    }

    pub inline fn makeOffsetPolygon(hull: Hull, radius: f32, transform: Transform) Polygon {
        return @bitCast(native.b2MakeOffsetPolygon(@ptrCast(&hull), radius, @bitCast(transform)));
    }

    pub inline fn compute(points: []const Vec2) Hull {
        return @bitCast(native.b2ComputeHull(@ptrCast(points.ptr), @intCast(points.len)));
    }

    pub inline fn validate(hull: Hull) bool {
        return native.b2ValidateHull(@ptrCast(&hull));
    }
};

pub const Capsule = extern struct {
    center1: Vec2,
    center2: Vec2,
    radius: f32,

    pub inline fn containsPoint(shape: Capsule, point: Vec2) bool {
        return native.b2PointInCapsule(@bitCast(point), @ptrCast(&shape));
    }

    pub inline fn computeAABB(shape: Capsule, transform: Transform) AABB {
        return @bitCast(native.b2ComputeCapsuleAABB(@ptrCast(&shape), @bitCast(transform)));
    }

    pub inline fn computeMass(shape: Capsule, density: f32) MassData {
        return @bitCast(native.b2ComputeCapsuleMass(@ptrCast(&shape), density));
    }
};

pub const Polygon = extern struct {
    vertices: [maxPolygonVertices]Vec2,
    normals: [maxPolygonVertices]Vec2,
    centroid: Vec2,
    radius: f32,
    count: i32,

    pub inline fn containsPoint(shape: Polygon, point: Vec2) bool {
        return native.b2PointInPolygon(@bitCast(point), @ptrCast(&shape));
    }

    pub inline fn computeAABB(shape: Polygon, _transform: Transform) AABB {
        return @bitCast(native.b2ComputePolygonAABB(@ptrCast(&shape), @bitCast(_transform)));
    }

    pub inline fn computeMass(shape: Polygon, density: f32) MassData {
        return @bitCast(native.b2ComputePolygonMass(@ptrCast(&shape), density));
    }

    pub inline fn transform(polygon: Polygon, _transform: Transform) Polygon {
        return @bitCast(native.b2TransformPolygon(@bitCast(_transform), @ptrCast(&polygon)));
    }

    // TODO: do these make* functions belong here?
    pub inline fn makeSquare(h: f32) Polygon {
        return @bitCast(native.b2MakeSquare(h));
    }

    pub inline fn makeBox(hx: f32, hy: f32) Polygon {
        return @bitCast(native.b2MakeBox(hx, hy));
    }

    pub inline fn makeRoundedBox(hx: f32, hy: f32, radius: f32) Polygon {
        return @bitCast(native.b2MakeRoundedBox(hx, hy, radius));
    }

    pub inline fn makeOffsetBox(hx: f32, hy: f32, center: Vec2, rotation: Rot) Polygon {
        return @bitCast(native.b2MakeOffsetBox(hx, hy, center, @bitCast(rotation)));
    }
};

// Collision

pub const CastOutput = extern struct {
    normal: Vec2,
    point: Vec2,
    fraction: f32,
    iterations: i32,
    hit: bool,
};

pub const SegmentDistanceResult = extern struct {
    closest1: Vec2,
    closest2: Vec2,
    fraction1: f32,
    fraction2: f32,
    distanceSquared: f32,
};

pub const DistanceCache = extern struct {
    count: u16,
    indexA: [3]u8,
    indexB: [3]u8,

    // TODO: does this really belong here?
    pub inline fn shapeDistanceDebug(cache: *DistanceCache, input: DistanceInput, simplexes: ?*Simplex, simplexCapacity: usize) DistanceOutput {
        return @bitCast(native.b2ShapeDistance(@ptrCast(cache), @ptrCast(&input), simplexes, @intCast(simplexCapacity)));
    }

    // TODO: does this really belong here?
    // This non-debug version is for normal people who don't need the one with the GJK debug output
    pub inline fn shapeDistance(cache: *DistanceCache, input: DistanceInput) DistanceOutput {
        return @bitCast(native.b2ShapeDistance(@ptrCast(cache), @ptrCast(&input), null, 0));
    }
};

pub const DistanceInput = extern struct {
    proxyA: DistanceProxy,
    proxyB: DistanceProxy,
    transformA: Transform,
    transformB: Transform,
    useRadii: bool,
};

pub const DistanceOutput = extern struct {
    pointA: Vec2,
    pointB: Vec2,
    distance: f32,
    iterations: i32,
    simplexCount: i32,
};

pub const ShapeCastPairInput = extern struct {
    proxyA: DistanceProxy,
    proxyB: DistanceProxy,
    transformA: Transform,
    transformB: Transform,
    translationB: Vec2,
    maxFraction: f32,

    // TODO: does this really belong here?
    pub inline fn cast(input: ShapeCastPairInput) CastOutput {
        return @bitCast(native.b2ShapeCast(@ptrCast(&input)));
    }
};

pub const DistanceProxy = extern struct {
    points: [maxPolygonVertices]Vec2,
    count: i32,
    radius: f32,

    pub inline fn make(vertices: []const Vec2, radius: f32) DistanceProxy {
        return @bitCast(native.b2MakeProxy(@ptrCast(vertices.ptr), @intCast(vertices.len), radius));
    }
};

pub const Sweep = extern struct {
    localCenter: Vec2,
    c1: Vec2,
    c2: Vec2,
    q1: Rot,
    q2: Rot,

    pub inline fn getTransform(sweep: Sweep, time: f32) Transform {
        return @bitCast(native.b2GetSweepTransform(@ptrCast(&sweep), time));
    }
};

pub const RayCastInput = extern struct {
    origin: Vec2,
    translation: Vec2,
    maxFraction: f32,

    // TODO: should these actually be in the individual shape structs?
    pub inline fn circle(input: RayCastInput, shape: Circle) CastOutput {
        return @bitCast(native.b2RayCastCircle(@ptrCast(&input), @ptrCast(&shape)));
    }

    pub inline fn capsule(input: RayCastInput, shape: Capsule) CastOutput {
        return @bitCast(native.b2RayCastCapsule(@ptrCast(&input), @ptrCast(&shape)));
    }

    pub inline fn segment(input: RayCastInput, shape: Segment, oneSided: bool) CastOutput {
        return @bitCast(native.b2RayCastSegment(@ptrCast(&input), @ptrCast(&shape), oneSided));
    }

    pub inline fn polygon(input: RayCastInput, shape: Polygon) CastOutput {
        return @bitCast(native.b2RayCastPolygon(@ptrCast(&input), @ptrCast(&shape)));
    }

    pub inline fn isValid(input: RayCastInput) bool {
        return native.b2IsValidRay(@ptrCast(&input));
    }
};

pub const ShapeCastInput = extern struct {
    points: [maxPolygonVertices]Vec2,
    count: i32,
    radius: f32,
    translation: Vec2,
    maxFraction: f32,
    
    // TODO: should these actually be in the individual shape structs?
    pub inline fn circle(input: ShapeCastInput, shape: Circle) CastOutput {
        return @bitCast(native.b2ShapeCastCircle(@ptrCast(&input), @ptrCast(&shape)));
    }

    pub inline fn capsule(input: ShapeCastInput, shape: Capsule) CastOutput {
        return @bitCast(native.b2ShapeCastCapsule(@ptrCast(&input), @ptrCast(&shape)));
    }

    pub inline fn segment(input: ShapeCastInput, shape: Segment) CastOutput {
        return @bitCast(native.b2ShapeCastSegment(@ptrCast(&input), @ptrCast(&shape)));
    }

    pub inline fn polygon(input: ShapeCastInput, shape: Polygon) CastOutput {
        return @bitCast(native.b2ShapeCastPolygon(@ptrCast(&input), @ptrCast(&shape)));
    }
};

pub const BodyMoveEvent = extern struct {
    transform: Transform,
    bodyId: BodyId,
    userData: ?*anyopaque,
    fellAsleep: bool,
};

pub const BodyEvents = extern struct {
    moveEvents: [*]BodyMoveEvent,
    moveCount: i32,
};

pub const SensorEndTouchEvent = extern struct {
    sensorShapeId: ShapeId,
    visitorShapeId: ShapeId,
};

pub const SensorBeginTouchEvent = extern struct {
    sensorShapeId: ShapeId,
    visitorShapeId: ShapeId,
};

pub const SensorEvents = extern struct {
    beginEvents: [*]SensorBeginTouchEvent,
    endEvents: [*]SensorEndTouchEvent,
    beginCount: i32,
    endCount: i32,
};

pub const ContactBeginTouchEvent = extern struct {
    shapeIdA: ShapeId,
    shapeIdB: ShapeId,
};

pub const ContactEndTouchEvent = extern struct {
    shapeIdA: ShapeId,
    shapeIdB: ShapeId,
};

pub const ContactHitEvent = extern struct {
    shapeIdA: ShapeId,
    shapeIdB: ShapeId,
    point: Vec2,
    normal: Vec2,
    approachSpeed: f32,
};

pub const ContactEvents = extern struct {
    beginEvents: [*]ContactBeginTouchEvent,
    endEvents: [*]ContactEndTouchEvent,
    hitEvents: [*]ContactHitEvent,
    beginCount: i32,
    endCount: i32,
    hitCount: i32,
};

pub const TOIInput = extern struct {
    proxyA: DistanceProxy,
    proxyB: DistanceProxy,
    sweepA: Sweep,
    sweepB: Sweep,
    tMax: f32,

    // TODO: maybe rename to something like "process" or "calculate"?
    pub inline fn timeOfImpact(input: TOIInput) TOIOutput {
        return native.b2TimeOfImpact(@ptrCast(&input));
    }
};

pub const TOIOutput = extern struct {
    state: TOIState,
    t: f32,
};

pub const TOIState = enum(c_int) {
    unknown,
    failed,
    overlapped,
    hit,
    separated,
};

pub const TreeNode = extern struct {

    pub const Union0 = extern union {
        parent: i32,
        next: i32,
    };

    aabb: AABB,
    categoryBits: u64,
    // TODO: better name for this
    union0: Union0,
    child1: i32,
    child2: i32,
    userData: i32,
    height: i16,
    enlarged: bool,
    pad: [5]u8,
};

// TODO: why are SimplexVertex and Simplex public?
pub const SimplexVertex = extern struct {
    wA: Vec2,
    wB: Vec2,
    w: Vec2,
    a: f32,
    indexA: i32,
    indexB: i32,
};

pub const Simplex = extern struct {
    v1: SimplexVertex,
    v2: SimplexVertex,
    v3: SimplexVertex,
    coint: i32,
};

pub const ManifoldPoint = extern struct {
    point: Vec2,
    anchorA: Vec2,
    anchorB: Vec2,
    separation: f32,
    normalImpulse: f32,
    tangentImpulse: f32,
    maxNormalImpulse: f32,
    normalVelocitu: f32,
    id: u16,
    persisted: bool,
};

pub const Manifold = extern struct {
    points: [2]ManifoldPoint,
    normal: Vec2,
    pointCount: i32,
};

pub const RayResult = extern struct {
    shapeId: ShapeId,
    point: Vec2,
    normal: Vec2,
    fraction: f32,
    hit: bool,
};


pub const Circle = extern struct {
    center: Vec2,
    radius: f32,

    pub inline fn containsPoint(shape: Circle, point: Vec2) bool {
        return native.b2PointInCircle(@bitCast(point), @ptrCast(&shape));
    }

    pub inline fn computeAABB(shape: Circle, transform: Transform) AABB {
        return @bitCast(native.b2ComputeCircleAABB(@ptrCast(&shape), @bitCast(transform)));
    }

    pub inline fn computeMass(shape: Circle, density: f32) MassData {
        return @bitCast(native.b2ComputeCircleMass(@ptrCast(&shape), density));
    }
};

pub const Filter = extern struct {
    categoryBits: u64,
    maskBits: u64,
    groupIndex: i32,

    pub inline fn default() Filter {
        return @bitCast(native.b2DefaultFilter());
    }
};

pub const DynamicTree = extern struct {
    nodes: [*]TreeNode,
    root: i32,
    nodeCount: i32,
    nodeCapacity: i32,
    freeList: i32,
    proxyCount: i32,
    leafIndices: [*]i32,
    leafBoxes: [*]AABB,
    leafCenters: [*]Vec2,
    binIndices: [*]i32,
    rebuildCapacity: i32,

    pub inline fn create() DynamicTree {
        return @bitCast(native.b2DynamicTree_Create());
    }

    pub inline fn destroy(tree: *DynamicTree) void {
        native.b2DynamicTree_Destroy(@ptrCast(tree));
    }

    pub inline fn createProxy(tree: *DynamicTree, aabb: AABB, categoryBits: u64, userData: i32) i32 {
        return native.b2DynamicTree_CreateProxy(@ptrCast(tree), @bitCast(aabb), categoryBits, userData);
    }

    pub inline fn destroyProxy(tree: *DynamicTree, proxyId: i32) void {
        native.b2DynamicTree_DestroyProxy(@ptrCast(tree), proxyId);
    }

    pub inline fn clone(outTree: *DynamicTree, inTree: *const DynamicTree) void {
        native.b2DynamicTree_Clone(@ptrCast(outTree), @ptrCast(inTree));
    }

    pub inline fn moveProxy(tree: *DynamicTree, proxyId: i32, aabb: AABB) void {
        native.b2DynamicTree_MoveProxy(@ptrCast(tree), proxyId, @bitCast(aabb));
    }

    pub inline fn enlargeProxy(tree: *DynamicTree, proxyId: i32, aabb: AABB) void {
        native.b2DynamicTree_EnlargeProxy(@ptrCast(tree), proxyId, @bitCast(aabb));
    }

    // TODO: replace raw C callbacks with something more Zig friendly
    pub inline fn query(tree: DynamicTree, aabb: AABB, maskBits: u64, callback: ?*const TreeQueryCallbackFn, context: ?*anyopaque) void {
        native.b2DynamicTree_Query(@ptrCast(&tree), @bitCast(aabb), maskBits, @ptrCast(callback), @ptrCast(context));
    }

    pub inline fn rayCast(tree: DynamicTree, input: RayCastInput, maskBits: u64, callback: *const TreeRayCastCallbackFn, context: ?*anyopaque) void {
        native.b2DynamicTree_RayCast(@ptrCast(&tree), @bitCast(&input), maskBits, @ptrCast(callback), @ptrCast(context));
    }

    pub inline fn shapeCast(tree: DynamicTree, input: ShapeCastInput, maskBits: u64, callback: *const TreeShapeCastCallbackFn, context: ?*anyopaque) void {
        native.b2DynamicTree_ShapeCast(@ptrCast(&tree), @ptrCast(&input), maskBits, @ptrCast(callback), @ptrCast(context));
    }

    pub inline fn validate(tree: DynamicTree) void {
        native.b2DynamicTree_Validate(@ptrCast(&tree));
    }

    pub inline fn getHeight(tree: DynamicTree) i32 {
        return native.b2DynamicTree_GetHeight(@ptrCast(&tree));
    }

    pub inline fn getMaxBalance(tree: DynamicTree) i32 {
        return native.b2DynamicTree_GetMaxBalance(@ptrCast(&tree));
    }

    pub inline fn getAreaRatio(tree: DynamicTree) f32 {
        return native.b2DynamicTree_GetAreaRatio(@ptrCast(&tree));
    }

    pub inline fn rebuildBottomUp(tree: *DynamicTree) void {
        native.b2DynamicTree_RebuildBottomUp(@ptrCast(tree));
    }

    pub inline fn getProxyCount(tree: DynamicTree) i32 {
        return native.b2DynamicTree_GetProxyCount(@ptrCast(&tree));
    }

    pub inline fn rebuild(tree: *DynamicTree, fullBuild: bool) i32 {
        return native.b2DynamicTree_Rebuild(@ptrCast(tree), fullBuild);
    }

    pub inline fn shiftOrigin(tree: *DynamicTree, newOrigin: Vec2) void {
        native.b2DynamicTree_ShiftOrigin(@ptrCast(tree), @bitCast(newOrigin));
    }

    pub inline fn getByteCount(tree: DynamicTree) usize {
        return @intCast(native.b2DynamicTree_GetByteCount(@ptrCast(&tree)));
    }

    pub inline fn getUserData(tree: DynamicTree, proxyId: i32) i32 {
        return tree.nodes[proxyId].userData;
    }

    pub inline fn getAABB(tree: DynamicTree, proxyId: i32) AABB {
        return tree.nodes[proxyId].aabb;
    }
};

pub const AABB = extern struct {
    lowerBound: Vec2,
    upperBound: Vec2,

    pub inline fn contains(a: AABB, b: AABB) bool {
        var s: bool = true;
        s = s and (a.lowerBound.x <= b.lowerBound.x);
        s = s and (a.lowerBound.y <= b.lowerBound.y);
        s = s and (b.upperBound.x <= a.upperBound.x);
        s = s and (b.upperBound.y <= a.upperBound.y);
        return s;
    }

    pub inline fn center(a: AABB) Vec2 {
        const b = Vec2{
            .x = 0.5 * (a.lowerBound.x + a.upperBound.x),
            .y = 0.5 * (a.lowerBound.y + a.upperBound.y),
        };
        return b;
    }

    pub inline fn extents(a: AABB) Vec2 {
        const b = Vec2{
            .x = 0.5 * (a.upperBound.x - a.lowerBound.x),
            .y = 0.5 * (a.upperBound.y - a.lowerBound.y),
        };
        return b;
    }

    /// Renamed from `union` due to a conflict with the union keyword
    pub inline fn add(a: AABB, b: AABB) AABB {
        var c: AABB = undefined;
        c.lowerBound.x = @min(a.lowerBound.x, b.lowerBound.x);
        c.lowerBound.y = @min(a.lowerBound.y, b.lowerBound.y);
        c.upperBound.x = @max(a.upperBound.x, b.upperBound.x);
        c.upperBound.y = @max(a.upperBound.y, b.upperBound.y);
        return c;
    }

    pub inline fn isValid(aabb: AABB) bool {
        return native.b2AABB_IsValid(@bitCast(aabb));
    }
};

pub const QueryFilter = extern struct {
    categoryBits: u64,
    maskBits: u64,

    pub inline fn default() QueryFilter {
        return @bitCast(native.b2DefaultQueryFilter());
    }
};

// These functions don't fit into any of the structs.

pub inline fn getByteCount() usize {
    return @intCast(native.b2GetByteCount());
}

pub inline fn setLengthUnitsPerMeter(lengthUnits: f32) void {
    native.b2SetLengthUnitsPerMeter(lengthUnits);
}

pub inline fn getLengthUnitsPerMeter() f32 {
    return native.b2GetLengthUnitsPerMeter();
}

pub inline fn getVersion() Version {
    return @bitCast(native.b2GetVersion());
}

// TODO: replace to take Zig allocator.
// The free function does not have a length argument while Zig allocators require that.
// probably just add a usize worth of extra bytes per allocation to store the length.
pub inline fn setAllocator(alloc: *AllocFn, free: *FreeFn) void {
    native.b2SetAllocator(@ptrCast(&alloc), @ptrCast(&free));
}

pub inline fn setAssertFn(assertFn: *AssertFn) void {
    native.b2SetAssertFcn(@ptrCast(assertFn));
}

// "mathy" functions

pub inline fn unwindAngle(angle: f32) f32 {
    if (angle < -std.math.pi) {
        return angle + (2.0 * std.math.pi);
    } else if (angle > std.math.pi) {
        return angle - (2.0 * std.math.pi);
    }
    return angle;
}

pub inline fn unwindLargeAngle(angle: f32) f32 {
    var realAngle = angle;
    while(realAngle > std.math.pi) {
        realAngle -= 2.0 * std.path.pi;
    }

    while(realAngle < -std.math.pi) {
        realAngle += 2.0 * std.path.pi;
    }

    return realAngle;
}

// These may seem redundant, but they make use of Box2D's determinism

pub inline fn atan2(y: f32, x: f32) f32 {
    return native.b2Atan2(y, x);
}

pub inline fn segmentDistance(p1: Vec2, q1: Vec2, p2: Vec2, q2: Vec2) SegmentDistanceResult {
    return @bitCast(native.b2SegmentDistance(@bitCast(p1), @bitCast(q1), @bitCast(p2), @bitCast(q2)));
}

// Collision functions

// TODO: For the collision functions, it will require re-duplicating since the user should be able to to do circle.collideCapsule(capsule) as well as capsule.collideCircle(circle)

pub inline fn collideCircles(circleA: Circle, xfA: Transform, circleB: Circle, xfB: Transform) Manifold {
    return @bitCast(native.b2CollideCircles(@ptrCast(&circleA), @bitCast(xfA), @ptrCast(&circleB), @bitCast(xfB)));
}

pub inline fn collideCapsuleAndCircle(capsuleA: Capsule, xfA: Transform, circleB: Circle, xfB: Transform) Manifold {
    return @bitCast(native.b2CollideCapsuleAndCircle(@ptrCast(&capsuleA), @bitCast(xfA), @ptrCast(&circleB), @bitCast(xfB)));
}

pub inline fn collideSegmentAndCircle(segmentA: Segment, xfA: Transform, circleB: Circle, xfB: Transform) Manifold {
    return @bitCast(native.b2CollideSegmentAndCircle(@ptrCast(&segmentA), @bitCast(xfA), @ptrCast(&circleB), @bitCast(xfB)));
}

pub inline fn collidePolygonAndCircle(polygonA: Polygon, xfA: Transform, circleB: Circle, xfB: Transform) Manifold {
    return @bitCast(native.b2CollidePolygonAndCircle(@ptrCast(&polygonA), @bitCast(xfA), @ptrCast(&circleB), @bitCast(xfB)));
}

pub inline fn collideCapsules(capsuleA: Capsule, xfA: Transform, capsuleB: Capsule, xfB: Transform, cache: *DistanceCache) Manifold {
    return @bitCast(native.b2CollideCapsules(@ptrCast(&capsuleA), @bitCast(xfA), @ptrCast(&capsuleB), @bitCast(xfB), @ptrCast(cache)));
}

pub inline fn collideSegmentAndCapsule(segmentA: Segment, xfA: Transform, capsuleB: Capsule, xfB: Transform, cache: *DistanceCache) Manifold {
    return @bitCast(native.b2CollideSegmentAndCapsule(@ptrCast(&segmentA), @bitCast(xfA), @ptrCast(&capsuleB), @bitCast(xfB), @ptrCast(cache)));
}

pub inline fn collidePolygonAndCapsule(polygonA: Polygon, xfA: Transform, capsuleB: Capsule, xfB: Transform, cache: *DistanceCache) Manifold {
    return @bitCast(native.b2CollidePolygonAndCapsule(@ptrCast(&polygonA), @bitCast(xfA), @ptrCast(&capsuleB), @bitCast(xfB), @ptrCast(cache)));
}

pub inline fn collidePolygons(polyA: Polygon, xfA: Transform, polyB: Polygon, xfB: Transform, cache: *DistanceCache) Manifold {
    return @bitCast(native.b2CollidePolygons(@ptrCast(&polyA), @bitCast(xfA), @ptrCast(&polyB), @bitCast(xfB), @ptrCast(cache)));
}

pub inline fn collideSegmentAndPolygon(segmentA: Segment, xfA: Transform, polygonB: Polygon, xfB: Transform, cache: *DistanceCache) Manifold {
    return @bitCast(native.b2CollideSegmentAndPolygon(@ptrCast(&segmentA), @bitCast(xfA), @ptrCast(&polygonB), @bitCast(xfB), @ptrCast(cache)));
}

pub inline fn collideChainSegmentAndCircle(chainSegmentA: ChainSegment, xfA: Transform, circleB: Circle, xfB: Transform) Manifold {
    return @bitCast(native.b2CollideChainSegmentAndCircle(@ptrCast(&chainSegmentA), @bitCast(xfA), @ptrCast(&circleB), @bitCast(xfB)));
}

pub inline fn collideChainSegmentAndCapsule(chainSegmentA: ChainSegment, xfA: Transform, capsuleB: Capsule, xfB: Transform, cache: *DistanceCache) Manifold {
    return @bitCast(native.b2CollideChainSegmentAndCapsule(@ptrCast(&chainSegmentA), @bitCast(xfA), @ptrCast(&capsuleB), @bitCast(xfB), @ptrCast(cache)));
}

pub inline fn collideChainSegmentAndPolygon(chainSegmentA: ChainSegment, xfA: Transform, polygonB: Polygon, xfB: Transform, cache: *DistanceCache) Manifold {
    return @bitCast(native.b2CollideChainSegmentAndPolygon(@ptrCast(&chainSegmentA), @bitCast(xfA), @ptrCast(&polygonB), @bitCast(xfB), @ptrCast(cache)));
}

// This is required since native is a raw translate-c, and translate-c creates compile errors when certain declarations are referenced.
fn recursivelyRefAllDeclsExceptNative(T: type) void {
    @setEvalBranchQuota(10000);
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
}

// The only point of this test is to make sure Box2D is linked correctly.
// TODO: fully translate all of Box2D's tests
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

// This test invokes ABI compatibility checks, so ABI incompatibilities are caught before they cause memory errors.
test "abiCompat" {
    recursivelyRefAllDeclsExceptNative(@This());
    // Things that need to be verified here: structs, function pointers, enums
    // Everything else will be automatically verified by the compiler
    // Here are the structs
    try std.testing.expect(structsAreABICompatible(WorldId, native.b2WorldId));
    try std.testing.expect(structsAreABICompatible(WorldDef, native.b2WorldDef));
    try std.testing.expect(structsAreABICompatible(DebugDraw, native.b2DebugDraw));
    try std.testing.expect(structsAreABICompatible(BodyEvents, native.b2BodyEvents));
    try std.testing.expect(structsAreABICompatible(SensorEvents, native.b2SensorEvents));
    try std.testing.expect(structsAreABICompatible(ContactEvents, native.b2ContactEvents));
    try std.testing.expect(structsAreABICompatible(AABB, native.b2AABB));
    try std.testing.expect(structsAreABICompatible(QueryFilter, native.b2QueryFilter));
    try std.testing.expect(structsAreABICompatible(ShapeId, native.b2ShapeId));
    try std.testing.expect(structsAreABICompatible(Circle, native.b2Circle));
    try std.testing.expect(structsAreABICompatible(Transform, native.b2Transform));
    try std.testing.expect(structsAreABICompatible(Capsule, native.b2Capsule));
    try std.testing.expect(structsAreABICompatible(Polygon, native.b2Polygon));
    try std.testing.expect(structsAreABICompatible(Vec2, native.b2Vec2));
    try std.testing.expect(structsAreABICompatible(RayResult, native.b2RayResult));
    try std.testing.expect(structsAreABICompatible(Manifold, native.b2Manifold));
    try std.testing.expect(structsAreABICompatible(Profile, native.b2Profile));
    try std.testing.expect(structsAreABICompatible(Counters, native.b2Counters));
    try std.testing.expect(structsAreABICompatible(BodyDef, native.b2BodyDef));
    try std.testing.expect(structsAreABICompatible(BodyId, native.b2BodyId));
    try std.testing.expect(structsAreABICompatible(Rot, native.b2Rot));
    try std.testing.expect(structsAreABICompatible(MassData, native.b2MassData));
    try std.testing.expect(structsAreABICompatible(JointId, native.b2JointId));
    try std.testing.expect(structsAreABICompatible(ContactData, native.b2ContactData));
    try std.testing.expect(structsAreABICompatible(ShapeDef, native.b2ShapeDef));
    try std.testing.expect(structsAreABICompatible(Segment, native.b2Segment));
    try std.testing.expect(structsAreABICompatible(Filter, native.b2Filter));
    try std.testing.expect(structsAreABICompatible(CastOutput, native.b2CastOutput));
    try std.testing.expect(structsAreABICompatible(ChainSegment, native.b2ChainSegment));
    try std.testing.expect(structsAreABICompatible(ChainId, native.b2ChainId));
    try std.testing.expect(structsAreABICompatible(ChainDef, native.b2ChainDef));
    try std.testing.expect(structsAreABICompatible(DistanceJointDef, native.b2DistanceJointDef));
    try std.testing.expect(structsAreABICompatible(MotorJointDef, native.b2MotorJointDef));
    try std.testing.expect(structsAreABICompatible(MouseJointDef, native.b2MouseJointDef));
    try std.testing.expect(structsAreABICompatible(PrismaticJointDef, native.b2PrismaticJointDef));
    try std.testing.expect(structsAreABICompatible(RevoluteJointDef, native.b2RevoluteJointDef));
    try std.testing.expect(structsAreABICompatible(WeldJointDef, native.b2WeldJointDef));
    try std.testing.expect(structsAreABICompatible(WheelJointDef, native.b2WheelJointDef));
    try std.testing.expect(structsAreABICompatible(SegmentDistanceResult, native.b2SegmentDistanceResult));
    try std.testing.expect(structsAreABICompatible(DistanceCache, native.b2DistanceCache));
    try std.testing.expect(structsAreABICompatible(DistanceInput, native.b2DistanceInput));
    try std.testing.expect(structsAreABICompatible(DistanceOutput, native.b2DistanceOutput));
    try std.testing.expect(structsAreABICompatible(ShapeCastPairInput, native.b2ShapeCastPairInput));
    try std.testing.expect(structsAreABICompatible(DistanceProxy, native.b2DistanceProxy));
    try std.testing.expect(structsAreABICompatible(Sweep, native.b2Sweep));
    try std.testing.expect(structsAreABICompatible(DynamicTree, native.b2DynamicTree));
    try std.testing.expect(structsAreABICompatible(RayCastInput, native.b2RayCastInput));
    try std.testing.expect(structsAreABICompatible(ShapeCastInput, native.b2ShapeCastInput));
    try std.testing.expect(structsAreABICompatible(Hull, native.b2Hull));
    try std.testing.expect(structsAreABICompatible(TOIInput, native.b2TOIInput));
    try std.testing.expect(structsAreABICompatible(TOIOutput, native.b2TOIOutput));
    try std.testing.expect(structsAreABICompatible(SimplexVertex, native.b2SimplexVertex));
    try std.testing.expect(structsAreABICompatible(Simplex, native.b2Simplex));
    try std.testing.expect(structsAreABICompatible(ContactBeginTouchEvent, native.b2ContactBeginTouchEvent));
    try std.testing.expect(structsAreABICompatible(ContactEndTouchEvent, native.b2ContactEndTouchEvent));
    try std.testing.expect(structsAreABICompatible(ContactHitEvent, native.b2ContactHitEvent));
    try std.testing.expect(structsAreABICompatible(TreeNode, native.b2TreeNode));
    try std.testing.expect(structsAreABICompatible(ManifoldPoint, native.b2ManifoldPoint));
    try std.testing.expect(structsAreABICompatible(SensorEndTouchEvent, native.b2SensorEndTouchEvent));
    try std.testing.expect(structsAreABICompatible(SensorBeginTouchEvent, native.b2SensorBeginTouchEvent));
    try std.testing.expect(structsAreABICompatible(BodyMoveEvent, native.b2BodyMoveEvent));
    // TODO: the function pointers
    // TODO: the function pointers in DebugDraw
    // TODO: the enums
    // TODO: check for added types
    // TODO: check for added functions. Can be done by scanning recursively for which box2D functions have alternatives, and erroring if there are functions without alternatives
}

fn structsAreABICompatible(comptime A: type, comptime B: type) bool {
    const aInfo = @typeInfo(A);
    const bInfo = @typeInfo(B);
    // Lol who cares about things that aren't structs
    if (aInfo != .Struct) return false;
    if (bInfo != .Struct) return false;
    // Make sure they have the same layout and that layout is ABI stable
    if (aInfo.Struct.layout == .auto) return false;
    if (aInfo.Struct.layout != bInfo.Struct.layout) return false;

    if (aInfo.Struct.fields.len != bInfo.Struct.fields.len) return false;
    inline for (aInfo.Struct.fields, 0..) |aField, i| {
        // Assume their indices match. I'm 99% certain the compiler has reliable order on extern/packed structs, however I have not dug into it.
        const bField = bInfo.Struct.fields[i];
        // this *could* do a recursive ABI check on the fields.
        // However, that would be a lot of work, so just check that the sizes match and call it a day
        if (@sizeOf(aField.type) != @sizeOf(bField.type)) return false;
    }
    // None of the checks failed, so assume they are compatible at this point
    return true;
}
