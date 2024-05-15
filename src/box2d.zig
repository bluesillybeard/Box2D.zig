const std = @import("std");
/// This allows users to get the "native" version of Box2D, which is just an @cImport of Box2Ds headers.
pub const native = @import("box2dnative.zig");

// TODO: add function that just takes a Zig allocator object.
// That may be quite dificult to do, seeing as the free function does not have a length argument while Zig allocators require that.

pub const AllocFn = fn(size: c_uint, alignment: c_int) callconv(.C) *anyopaque;

pub const FreeFn = fn(mem: *anyopaque) callconv(.C) void;

pub const AssertFn = fn(condition: [*:0]const u8, fileName: [*:0]const u8, lineNumber: c_int) callconv(.C) c_int;

pub inline fn SetAllocator(alloc: *AllocFn, free: *FreeFn) void {
    native.b2SetAllocator(&alloc, &free);
}

pub inline fn GetByteCount() u32 {
    return @intCast(native.b2GetByteCount());
}

pub inline fn SetAssertFn(assertFn: *AssertFn) void {
    native.b2SetAssertFcn(assertFn);
}

pub const WorldId = native.b2WorldId;
pub const WorldDef = native.b2WorldDef;
pub const DebugDraw = native.b2DebugDraw;
pub const BodyEvents = native.b2BodyEvents;
pub const SensorEvents = native.b2SensorEvents;
pub const ContactEvents = native.b2ContactEvents;
pub const AABB = native.b2AABB;
pub const QueryFilter = native.b2QueryFilter;
pub const ShapeId = native.b2ShapeId;
pub const OverlapResultFn = fn (shape: ShapeId, context: ?*anyopaque) callconv(.C) bool;
pub const Circle = native.b2Circle;
pub const Transform = native.b2Transform;
pub const Capsule = native.b2Capsule;
pub const Polygon = native.b2Polygon;
pub const Vec2 = native.b2Vec2;
pub const CastResultFn = fn (shape: ShapeId, pos: Vec2, normal: Vec2, fraction: f32, context: ?*anyopaque) callconv(.C) f32;
pub const RayResult = native.b2RayResult;
pub const Manifold = native.b2Manifold;
pub const PreSolveFn = fn (shapeIdA: ShapeId, shapeIdB: ShapeId, manifold: *Manifold, context: ?*anyopaque) callconv(.C) bool;
pub const Profile = native.b2Profile;
pub const Counters = native.b2Counters;
pub const BodyDef = native.b2BodyDef;
pub const BodyId = native.b2BodyId;
pub const BodyType =  enum (c_uint) {
    static = 0,
    kinematic = 1,
    dynamic = 2,
};
pub const Rot = native.b2Rot;
pub const MassData = native.b2MassData;
pub const JointId = native.b2JointId;
pub const ContactData = native.b2ContactData;
pub const ShapeDef = native.b2ShapeDef;
pub const Segment = native.b2Segment;
pub const ShapeType = enum (c_uint) {
    circle = 0,
	capsule = 1,
	segment = 2,
	polygon = 3,
	smoothSegment = 4,
    // Yeetis Beatis Bonkis Donkis
	shapeTypeCount = 5,
};
pub const Filter = native.b2Filter;
pub const CastOutput = native.b2CastOutput;
pub const SmoothSegment = native.b2SmoothSegment;
pub const ChainId = native.b2ChainId;
pub const ChainDef = native.b2ChainDef;
pub const DistanceJointDef = native.b2DistanceJointDef;
pub const MotorJointDef = native.b2MotorJointDef;
pub const MouseJointDef = native.b2MouseJointDef;
pub const PrismaticJointDef = native.b2PrismaticJointDef;
pub const RevoluteJointDef = native.b2RevoluteJointDef;
pub const WeldJointDef = native.b2WeldJointDef;
pub const WheelJointDef = native.b2WheelJointDef;
pub const JointType = enum(c_uint) {
    distance,
    motor,
    mouse,
    prismatic,
    revolute,
    weld,
    wheel,
};
pub const Color = native.b2Color;

pub inline fn createWorld(def: *const WorldDef) WorldId {
    return native.b2CreateWorld(def);
}

pub inline fn cestroyWorld(worldId: WorldId) void {
    native.b2DestroyWorld(worldId);
}

pub inline fn worldIsValid(id: WorldId) bool {
    return native.b2World_IsValid(id);
}

pub inline fn worldStep(worldId: WorldId, timeStep: f32, subStepCount: u32) void {
    native.b2World_Step(worldId, timeStep, @intCast(subStepCount));
}

pub inline fn worldDraw(worldId: WorldId, draw: *DebugDraw) void {
    native.b2World_Draw(worldId, draw);
}

pub inline fn worldGetBodyEvents(worldId: WorldId) BodyEvents {
    return native.b2World_GetBodyEvents(worldId);
}

pub inline fn worldGetSensorEvents(worldId: WorldId) SensorEvents {
    return native.b2World_GetSensorEvents(worldId);
}

pub inline fn worldGetContactEvents(worldId: WorldId) ContactEvents {
    return native.b2World_GetContactEvents(worldId);
}

pub inline fn worldOverlapAABB(worldId: WorldId, aabb: AABB, filter: QueryFilter, overlapFn: *OverlapResultFn, context: ?*anyopaque) void {
    native.b2World_OverlapAABB(worldId, aabb, filter, overlapFn, context);
}

pub inline fn worldOverlapCircle(worldId: WorldId, circle: Circle, transform: Transform, filter: QueryFilter, overlapFn: *OverlapResultFn, context: ?*anyopaque) void {
    native.b2World_OverlapCircle(worldId, &circle, transform, filter, overlapFn, context);
}

pub inline fn worldOverlapCapsule(worldId: WorldId, capsule: Capsule, transform: Transform, filter: QueryFilter, overlapFn: *OverlapResultFn, context: ?*anyopaque) void {
    native.b2World_OverlapCapsule(worldId, &capsule, transform, filter, overlapFn, context);
}

pub inline fn worldOverlapPolygon(worldId: WorldId, polygon: Polygon, transform: Transform, filter: QueryFilter, overlapFn: *OverlapResultFn, context: ?*anyopaque) void {
    native.b2World_OverlapPolygon(worldId, &polygon, transform, filter, overlapFn, context);
}

pub inline fn worldRayCast(worldId: WorldId, origin: Vec2, translation: Vec2, filter: QueryFilter, castFn: *CastResultFn, context: ?*anyopaque) void {
    native.b2World_RayCast(worldId, origin, translation, filter, castFn, context);
}

pub inline fn worldRayCastClosest(worldId: WorldId, origin: Vec2, translation: Vec2, filter: QueryFilter) RayResult {
    return native.b2World_RayCastClosest(worldId, origin, translation, filter);
}

pub inline fn worldCircleCast(worldId: WorldId, circle: Circle, originTransform: Transform, translation: Vec2, filter: QueryFilter, castFn: *CastResultFn, context: ?*anyopaque) void {
    native.b2World_CircleCast(worldId, &circle, originTransform, translation, filter, castFn, context);
}

pub inline fn worldCapsuleCast(worldId: WorldId, capsule: Capsule, originTransform: Transform, translation: Vec2, filter: QueryFilter, castFn: *CastResultFn, context: ?*anyopaque) void {
    native.b2World_CapsuleCast(worldId, &capsule, originTransform, translation, filter, castFn, context);
}

pub inline fn worldPolygonCast(worldId: WorldId, polygon: Polygon, originTransform: Transform, translation: Vec2, filter: QueryFilter, castFn: *CastResultFn, context: ?*anyopaque) void {
    native.b2World_PolygonCast(worldId, &polygon, originTransform, translation, filter, castFn, context);
}

// TODO: would it make sense to rename this to 'set' instead of 'enable'?
pub inline fn worldEnableSleeping(worldId: WorldId, flag: bool) void {
    native.b2World_EnableSleeping(worldId, flag);
}

pub inline fn worldEnableWarmStarting(worldId: WorldId, flag: bool) void {
    native.b2World_EnableWarmStarting(worldId, flag);
}

pub inline fn worldEnableContinuous(worldId: WorldId, flag: bool) void {
    native.b2World_EnableContinuous(worldId, flag);
}

pub inline fn worldSetRestitutionThreshold(worldId: WorldId, value: f32) void {
    native.b2World_SetRestitutionThreshold(worldId, value);
}

pub inline fn worldSetHitEventThreshold(worldId: WorldId, value: f32) void {
    native.b2World_SetHitEventThreshold(worldId, value);
}

pub inline fn worldSetPreSolveCallback(worldId: WorldId, preSolveFn: ?*PreSolveFn, context: ?*anyopaque) void {
    native.b2World_SetPreSolveCallback(worldId, preSolveFn, context);
}

pub inline fn worldSetGravity(worldId: WorldId, gravity: Vec2) void {
    native.b2World_SetGravity(worldId, gravity);
}

pub inline fn worldGetGravity(worldId: WorldId) Vec2 {
    return native.b2World_GetGravity(worldId);
}

pub inline fn worldExplode(worldId: WorldId, position: Vec2, radius: f32, impulse: f32) void {
    native.b2World_Explode(worldId, position, radius, impulse);
}
pub inline fn worldSetContactTuning(worldId: WorldId, hertz: f32, dampingRatio: f32, pushVelocity: f32) void {
    native.b2World_SetContactTuning(worldId, hertz, dampingRatio, pushVelocity);
}
pub inline fn worldGetProfile(worldId: WorldId) Profile {
    return native.b2World_GetProfile(worldId);
}

pub inline fn worldGetCounters(worldId: WorldId) Counters {
    return native.b2World_GetCounters(worldId);
}

pub inline fn worldDumpMemoryStats(worldId: WorldId) void {
    native.b2World_DumpMemoryStats(worldId);
}

pub inline fn createBody(worldId: WorldId, def: *const BodyDef) BodyId {
    return native.b2CreateBody(worldId, def);
}

pub inline fn destroyBody(bodyId: BodyId) void {
    return native.b2DestroyBody(bodyId);
}

pub inline fn bodyIsValid(id: BodyId) bool {
    return native.b2Body_IsValid(id);
}

pub inline fn bodyGetType(bodyId: BodyId) BodyType {
    return native.b2Body_GetType(bodyId);
}

pub inline fn bodySetType(bodyId: BodyId, @"type": BodyType) void {
    native.b2Body_SetType(bodyId, @"type");
}

pub inline fn bodySetUserData(bodyId: BodyId, userData: ?*anyopaque) void {
    native.b2Body_SetUserData(bodyId, userData);
}

pub inline fn bodyGetUserData(bodyId: BodyId) ?*anyopaque {
    return native.b2Body_GetUserData(bodyId);
}

pub inline fn bodyGetPosition(bodyId: BodyId) Vec2 {
    return native.b2Body_GetPosition(bodyId);
}

pub inline fn bodyGetRotation(bodyId: BodyId) Rot {
    return native.b2Body_GetRotation(bodyId);
}

pub inline fn bodyGetAngle(bodyId: BodyId) f32 {
    return native.b2Body_GetAngle(bodyId);
}

pub inline fn bodyGetTransform(bodyId: BodyId) Transform {
    return native.b2Body_GetTransform(bodyId);
}

pub inline fn bodySetTransform(bodyId: BodyId, position: Vec2, angle: f32) void {
    native.b2Body_SetTransform(bodyId, position, angle);
}

pub inline fn bodyGetLocalPoint(bodyId: BodyId, worldPoint: Vec2) Vec2 {
    return native.b2Body_GetLocalPoint(bodyId, worldPoint);
}

pub inline fn bodyGetWorldPoint(bodyId: BodyId, localPoint: Vec2) Vec2 {
    return native.b2Body_GetWorldPoint(bodyId, localPoint);
}

pub inline fn bodyGetLocalVector(bodyId: BodyId, worldVector: Vec2) Vec2 {
    return native.b2Body_GetLocalVector(bodyId, worldVector);
}

pub inline fn bodyGetWorldVector(bodyId: BodyId, localVector: Vec2) Vec2 {
    return native.b2Body_GetWorldVector(bodyId, localVector);
}

pub inline fn bodyGetLinearVelocity(bodyId: BodyId) Vec2 {
    return native.b2Body_GetLinearVelocity(bodyId);
}

pub inline fn bodyGetAngularVelocity(bodyId: BodyId) f32 {
    return native.b2Body_GetAngularVelocity(bodyId);
}

pub inline fn bodySetLinearVelocity(bodyId: BodyId, linearVelocity: Vec2) void {
    native.b2Body_SetLinearVelocity(bodyId, linearVelocity);
}

pub inline fn bodySetAngularVelocity(bodyId: BodyId, angularVelocity: f32) void {
    native.b2Body_SetAngularVelocity(bodyId, angularVelocity);
}

pub inline fn bodyApplyForce(bodyId: BodyId, force: Vec2, point: Vec2, wake: bool) void {
    native.b2Body_ApplyForce(bodyId, force, point, wake);
}

pub inline fn bodyApplyForceToCenter(bodyId: BodyId, force: Vec2, wake: bool) void {
    native.b2Body_ApplyForceToCenter(bodyId, force, wake);
}

pub inline fn bodyApplyTorque(bodyId: BodyId, torque: f32, wake: bool) void {
    native.b2Body_ApplyTorque(bodyId, torque, wake);
}

pub inline fn bodyApplyLinearImpulse(bodyId: BodyId, impulse: Vec2, point: Vec2, wake: bool) void {
    native.b2Body_ApplyLinearImpulse(bodyId, impulse, point, wake);
}

pub inline fn bodyApplyLinearImpulseToCenter(bodyId: BodyId, impulse: Vec2, wake: bool) void {
    native.b2Body_ApplyLinearImpulseToCenter(bodyId, impulse, wake);
}

pub inline fn bodyApplyAngularImpulse(bodyId: BodyId, impulse: f32, wake: bool) void {
    native.b2Body_ApplyAngularImpulse(bodyId, impulse, wake);
}

pub inline fn bodyGetMass(bodyId: BodyId) f32 {
    return native.b2Body_GetMass(bodyId);
}

pub inline fn bodyGetInertiaTensor(bodyId: BodyId) f32 {
    return native.b2Body_GetInertiaTensor(bodyId);
}

pub inline fn bodyGetLocalCenterOfMass(bodyId: BodyId) Vec2 {
    return native.b2Body_GetLocalCenterOfMass(bodyId);
}

pub inline fn bodyGetWorldCenterOfMass(bodyId: BodyId) Vec2 {
    return native.b2Body_GetWorldCenterOfMass(bodyId);
}

pub inline fn bodySetMassData(bodyId: BodyId, massData: MassData) void {
    native.b2Body_SetMassData(bodyId, massData);
}

pub inline fn bodyGetMassData(bodyId: BodyId) MassData {
    return native.b2Body_GetMassData(bodyId);
}

pub inline fn bodyApplyMassFromShapes(bodyId: BodyId) void {
    native.b2Body_ApplyMassFromShapes(bodyId);
}

pub inline fn bodySetAutomaticMass(bodyId: BodyId, automaticMass: bool) void {
    native.b2Body_SetAutomaticMass(bodyId, automaticMass);
}

pub inline fn bodyGetAutomaticMass(bodyId: BodyId) bool {
    return native.b2Body_GetAutomaticMass(bodyId);
}

pub inline fn bodySetLinearDamping(bodyId: BodyId, linearDamping: f32) void {
    native.b2Body_SetLinearDamping(bodyId, linearDamping);
}

pub inline fn bodyGetLinearDamping(bodyId: BodyId) f32 {
    return native.b2Body_GetLinearDamping(bodyId);
}

pub inline fn bodySetAngularDamping(bodyId: BodyId, angularDamping: f32) void {
    native.b2Body_SetAngularDamping(bodyId, angularDamping);
}

pub inline fn bodyGetAngularDamping(bodyId: BodyId) f32 {
    return native.b2Body_GetAngularDamping(bodyId);
}

pub inline fn bodySetGravityScale(bodyId: BodyId, gravityScale: f32) void {
    native.b2Body_SetGravityScale(bodyId, gravityScale);
}

pub inline fn bodyGetGravityScale(bodyId: BodyId) f32 {
    return native.b2Body_GetGravityScale(bodyId);
}

pub inline fn bodyIsAwake(bodyId: BodyId) bool {
    return native.b2Body_IsAwake(bodyId);
}

pub inline fn bodySetAwake(bodyId: BodyId, awake: bool) void {
    native.b2Body_SetAwake(bodyId, awake);
}

pub inline fn bodyEnableSleep(bodyId: BodyId, enableSleep: bool) void {
    native.b2Body_EnableSleep(bodyId, enableSleep);
}

pub inline fn bodyIsSleepEnabled(bodyId: BodyId) bool {
    return native.b2Body_IsSleepEnabled(bodyId);
}

pub inline fn bodySetSleepThreshold(bodyId: BodyId, sleepVelocity: f32) void {
    native.b2Body_SetSleepThreshold(bodyId, sleepVelocity);
}

pub inline fn bodyGetSleepThreshold(bodyId: BodyId) f32 {
    return native.b2Body_GetSleepThreshold(bodyId);
}

pub inline fn bodyIsEnabled(bodyId: BodyId) bool {
    return native.b2Body_IsEnabled(bodyId);
}

pub inline fn bodyDisable(bodyId: BodyId) void {
    native.b2Body_Disable(bodyId);
}

pub inline fn bodyEnable(bodyId: BodyId) void {
    native.b2Body_Enable(bodyId);
}

pub inline fn bodySetFixedRotation(bodyId: BodyId, flag: bool) void {
    native.b2Body_SetFixedRotation(bodyId, flag);
}

pub inline fn bodyIsFixedRotation(bodyId: BodyId) bool {
    return native.b2Body_IsFixedRotation(bodyId);
}

pub inline fn bodySetBullet(bodyId: BodyId, flag: bool) void {
    native.b2Body_SetBullet(bodyId, flag);
}

pub inline fn bodyIsBullet(bodyId: BodyId) bool {
    return native.b2Body_IsBullet(bodyId);
}

pub inline fn bodyEnableHitEvents(bodyId: BodyId, enableHitEvents: bool) void {
    native.b2Body_EnableHitEvents(bodyId, enableHitEvents);
}

pub inline fn bodyGetShapeCount(bodyId: BodyId) usize {
    return @intCast(native.b2Body_GetShapeCount(bodyId));
}

pub inline fn bodyGetShapes(bodyId: BodyId, shapes: []ShapeId) usize {
    return @intCast(native.b2Body_GetShapes(bodyId, shapes.ptr, @intCast(shapes.len)));
}

pub inline fn bodyGetJointCount(bodyId: BodyId) usize {
    return @intCast(native.b2Body_GetJointCount(bodyId));
}

pub inline fn bodyGetJoints(bodyId: BodyId, joints: []JointId) usize {
    return @intCast(native.b2Body_GetJoints(bodyId, joints.ptr, @intCast(joints.len)));
}

pub inline fn bodyGetContactCapacity(bodyId: BodyId) usize {
    return @intCast(native.b2Body_GetContactCapacity(bodyId));
}

pub inline fn bodyGetContactData(bodyId: BodyId, contacts: []ContactData) usize {
    return @intCast(native.b2Body_GetContactData(bodyId, contacts.ptr, @intCast(contacts.len)));
}

pub inline fn bodyComputeAABB(bodyId: BodyId) AABB {
    return native.b2Body_ComputeAABB(bodyId);
}

pub inline fn createCircleShape(bodyId: BodyId, def: ShapeDef, circle: Circle) ShapeId {
    return native.b2CreateCircleShape(bodyId, &def, &circle);
}

pub inline fn createSegmentShape(bodyId: BodyId, def: ShapeDef, segment: Segment) ShapeId {
    return native.b2CreateSegmentShape(bodyId, &def, &segment);
}

pub inline fn createCapsuleShape(bodyId: BodyId, def: ShapeDef, capsule: Capsule) ShapeId {
    return native.b2CreateCapsuleShape(bodyId, &def, &capsule);
}

pub inline fn createPolygonShape(bodyId: BodyId, def: ShapeDef, polygon: Polygon) ShapeId {
    return native.b2CreatePolygonShape(bodyId, &def, &polygon);
}

pub inline fn destroyShape(shapeId: ShapeId) void {
    native.b2DestroyShape(shapeId);
}

pub inline fn shapeIsValid(id: ShapeId) bool {
    return native.b2Shape_IsValid(id);
}

pub inline fn shapeGetType(shapeId: ShapeId) ShapeType {
    return native.b2Shape_GetType(shapeId);
}

pub inline fn shapeGetBody(shapeId: ShapeId) BodyId {
    return native.b2Shape_GetBody(shapeId);
}

pub inline fn shapeIsSensor(shapeId: ShapeId) bool {
    return native.b2Shape_IsSensor(shapeId);
}

pub inline fn shapeSetUserData(shapeId: ShapeId, userData: ?*anyopaque) void {
    native.b2Shape_SetUserData(shapeId, userData);
}

pub inline fn shapeGetUserData(shapeId: ShapeId) ?*anyopaque {
    return native.b2Shape_GetUserData(shapeId);
}

pub inline fn shapeSetDensity(shapeId: ShapeId, density: f32) void {
    native.b2Shape_SetDensity(shapeId, density);
}

pub inline fn shapeGetDensity(shapeId: ShapeId) f32 {
    return native.b2Shape_GetDensity(shapeId);
}

pub inline fn shapeSetFriction(shapeId: ShapeId, friction: f32) void {
    native.b2Shape_SetFriction(shapeId, friction);
}

pub inline fn shapeGetFriction(shapeId: ShapeId) f32 {
    return native.b2Shape_GetFriction(shapeId);
}

pub inline fn shapeSetRestitution(shapeId: ShapeId, restitution: f32) void {
    native.b2Shape_SetRestitution(shapeId, restitution);
}

pub inline fn shapeGetRestitution(shapeId: ShapeId) f32 {
    return native.b2Shape_GetRestitution(shapeId);
}

pub inline fn shapeGetFilter(shapeId: ShapeId) Filter {
    return native.b2Shape_GetFilter(shapeId);
}

pub inline fn shapeSetFilter(shapeId: ShapeId, filter: Filter) void {
    native.b2Shape_SetFilter(shapeId, filter);
}

pub inline fn shapeEnableSensorEvents(shapeId: ShapeId, flag: bool) void {
    native.b2Shape_EnableSensorEvents(shapeId, flag);
}

pub inline fn shapeAreSensorEventsEnabled(shapeId: ShapeId) bool {
    return native.b2Shape_AreSensorEventsEnabled(shapeId);
}

pub inline fn shapeEnableContactEvents(shapeId: ShapeId, flag: bool) void {
    native.b2Shape_EnableContactEvents(shapeId, flag);
}

pub inline fn shapeAreContactEventsEnabled(shapeId: ShapeId) bool {
    native.b2Shape_AreContactEventsEnabled(shapeId);
}

pub inline fn shapeEnablePreSolveEvents(shapeId: ShapeId, flag: bool) void {
    native.b2Shape_EnablePreSolveEvents(shapeId, flag);
}

pub inline fn shapeArePreSolveEventsEnabled(shapeId: ShapeId) bool {
    return native.b2Shape_ArePreSolveEventsEnabled(shapeId);
}

pub inline fn shapeEnableHitEvents(shapeId: ShapeId, flag: bool) void {
    native.b2Shape_EnableContactEvents(shapeId, flag);
}

pub inline fn shapeAreHitEventsEnabled(shapeId: ShapeId) bool {
    return native.b2Shape_AreHitEventsEnabled(shapeId);
}

pub inline fn shapeTestPoint(shapeId: ShapeId, point: Vec2) bool {
    return native.b2Shape_TestPoint(shapeId, point);
}

pub inline fn shapeRayCast(shapeId: ShapeId, origin: Vec2, translation: Vec2) CastOutput {
    return native.b2Shape_RayCast(shapeId, origin, translation);
}

pub inline fn shapeGetCircle(shapeId: ShapeId) Circle {
    return native.b2Shape_GetCircle(shapeId);
}

pub inline fn shapeGetSegment(shapeId: ShapeId) Segment {
    return native.b2Shape_GetSegment(shapeId);
}

pub inline fn shapeGetSmoothSegment(shapeId: ShapeId) SmoothSegment {
    return native.b2Shape_GetSmoothSegment(shapeId);
}

pub inline fn shapeGetCapsule(shapeId: ShapeId) Capsule {
    return native.b2Shape_GetCapsule(shapeId);
}

pub inline fn shapeGetPolygon(shapeId: ShapeId) Polygon {
    return native.b2Shape_GetPolygon(shapeId);
}

pub inline fn shapeSetCircle(shapeId: ShapeId, circle: Circle) void {
    native.b2Shape_SetCircle(shapeId, circle);
}

pub inline fn shapeSetCapsule(shapeId: ShapeId, capsule: Capsule) void {
    native.b2Shape_SetCapsule(shapeId, capsule);
}

pub inline fn shapeSetSegment(shapeId: ShapeId, segment: Segment) void {
    native.b2Shape_SetSegment(shapeId, segment);
}

pub inline fn shapeSetPolygon(shapeId: ShapeId, polygon: Polygon) void {
    native.b2Shape_SetPolygon(shapeId, polygon);
}

pub inline fn shapeGetParentChain(shapeId: ShapeId) ChainId {
    return native.b2Shape_GetParentChain(shapeId);
}

pub inline fn shapeGetContactCapacity(shapeId: ShapeId) usize {
    return @intCast(native.b2Shape_GetContactCapacity(shapeId));
}

pub inline fn shapeGetContactData(shapeId: ShapeId, contacts: []ContactData) usize {
    return @intCast(native.b2Shape_GetContactData(shapeId, contacts.ptr, @intCast(contacts.len)));
}

pub inline fn shapeGetAABB(shapeId: ShapeId) AABB {
    return native.b2Shape_GetAABB(shapeId);
}

pub inline fn shapeGetClosestPoint(shapeId: ShapeId, target: Vec2) Vec2 {
    return native.b2Shape_GetClosestPoint(shapeId, target);
}

pub inline fn createChain(bodyId: BodyId, def: ChainDef) ChainId {
    return native.b2CreateChain(bodyId, &def);
}

pub inline fn destroyChain(chainId: ChainId) void {
    native.b2DestroyChain(chainId);
}

pub inline fn chainSetFriction(chainId: ChainId, friction: f32) void {
    native.b2Chain_SetFriction(chainId, friction);
}

pub inline fn chainSetRestitution(chainId: ChainId, restitution: f32) void {
    native.b2Chain_SetRestitution(chainId, restitution);
}

pub inline fn chainIsValid(id: ChainId) bool {
    return native.b2Chain_IsValid(id);
}

pub inline fn createDistanceJoint(worldId: WorldId, def: DistanceJointDef) JointId {
    return native.b2CreateDistanceJoint(worldId, &def);
}

pub inline fn createMotorJoint(worldId: WorldId, def: MotorJointDef) JointId {
    return native.b2CreateMotorJoint(worldId, &def);
}

pub inline fn createMouseJoint(worldId: WorldId, def: MouseJointDef) JointId {
    return native.b2CreateMouseJoint(worldId, &def);
}

pub inline fn createPrismaticJoint(worldId: WorldId, def: PrismaticJointDef) JointId {
    return native.b2CreatePrismaticJoint(worldId, &def);
}

pub inline fn createRevoluteJoint(worldId: WorldId, def: RevoluteJointDef) JointId {
    return native.b2CreateRevoluteJoint(worldId, &def);
}

pub inline fn createWeldJoint(worldId: WorldId, def: WeldJointDef) JointId {
    return native.b2CreateWeldJoint(worldId, &def);
}

pub inline fn createWheelJoint(worldId: WorldId, def: WheelJointDef) JointId {
    return native.b2CreateWheelJoint(worldId, &def);
}

pub inline fn destroyJoint(jointId: JointId) void {
    return native.b2DestroyJoint(jointId);
}

pub inline fn jointIsValid(id: JointId) bool {
    return native.b2Joint_IsValid(id);
}

pub inline fn jointGetType(jointId: JointId) JointType {
    return native.b2Joint_GetType(jointId);
}

pub inline fn jointGetBodyA(jointId: JointId) BodyId {
    return native.b2Joint_GetBodyA(jointId);
}

pub inline fn jointGetBodyB(jointId: JointId) BodyId {
    return native.b2Joint_GetBodyB(jointId);
}

pub inline fn jointGetLocalAnchorA(jointId: JointId) Vec2 {
    return native.b2Joint_GetLocalAnchorA(jointId);
}

pub inline fn jointGetLocalAnchorB(jointId: JointId) Vec2 {
    return native.b2Joint_GetLocalAnchorB(jointId);
}

pub inline fn jointSetCollideConnected(jointId: JointId, shouldCollide: bool) void {
    native.b2Joint_SetCollideConnected(jointId, shouldCollide);
}

pub inline fn jointGetCollideConnected(jointId: JointId) bool {
    return native.b2Joint_GetCollideConnected(jointId);
}

pub inline fn jointSetUserData(jointId: JointId, userData: ?*anyopaque) void {
    native.b2Joint_SetUserData(jointId, userData);
}

pub inline fn jointGetUserData(jointId: JointId) ?*anyopaque {
    return native.b2Joint_GetUserData(jointId);
}

pub inline fn jointWakeBodies(jointId: JointId) void {
    native.b2Joint_WakeBodies(jointId);
}

pub inline fn distanceJointGetConstraintForce(jointId: JointId, timeStep: f32) f32 {
    return native.b2DistanceJoint_GetConstraintForce(jointId, timeStep);
}

pub inline fn distanceJointSetLength(jointId: JointId, length: f32) void {
    return native.b2DistanceJoint_SetLength(jointId, length);
}

pub inline fn distanceJointGetLength(jointId: JointId) f32 {
    return distanceJointGetLength(jointId);
}

pub inline fn distanceJointEnableSpring(jointId: JointId, enableSpring: bool) void {
    native.b2DistanceJoint_EnableSpring(jointId, enableSpring);
}

pub inline fn distanceJointIsSpringEnabled(jointId: JointId) bool {
    return native.b2DistanceJoint_IsSpringEnabled(jointId);
}

pub inline fn distanceJointSetSpringHertz(jointId: JointId, hertz: f32) void {
    native.b2DistanceJoint_SetSpringHertz(jointId, hertz);
}

pub inline fn distanceJointSetSpringDampingRatio(jointId: JointId, dampingRatio: f32) void {
    native.b2DistanceJoint_SetSpringDampingRatio(jointId, dampingRatio);
}

pub inline fn distanceJointGetHertz(jointId: JointId) f32 {
    return native.b2DistanceJoint_GetHertz(jointId);
}

pub inline fn distanceJointGetDampingRatio(jointId: JointId) f32 {
    return native.b2DistanceJoint_GetDampingRatio(jointId);
}

pub inline fn distanceJointEnableLimit(jointId: JointId, enableLimit: bool) void {
    return native.b2DistanceJoint_EnableLimit(jointId, enableLimit);
}

pub inline fn distanceJointIsLimitEnabled(jointId: JointId) bool {
    return native.b2DistanceJoint_IsLimitEnabled(jointId);
}

pub inline fn distanceJointSetLengthRange(jointId: JointId, minLength: f32, maxLength: f32) void {
    native.b2DistanceJoint_SetLengthRange(jointId, minLength, maxLength);
}

pub inline fn distanceJointGetMinLength(jointId: JointId) f32 {
    return native.b2DistanceJoint_GetMinLength(jointId);
}

pub inline fn distanceJointGetMaxLength(jointId: JointId) f32 {
    return native.b2DistanceJoint_GetMaxLength(jointId);
}

pub inline fn distanceJointGetCurrentLength(jointId: JointId) f32 {
    return native.b2DistanceJoint_GetCurrentLength(jointId);
}

pub inline fn distanceJointEnableMotor(jointId: JointId, enableMotor: bool) void {
    native.b2DistanceJoint_EnableMotor(jointId, enableMotor);
}

pub inline fn distanceJointIsMotorEnabled(jointId: JointId) bool {
    return native.b2DistanceJoint_IsMotorEnabled(jointId);
}

pub inline fn distanceJointSetMotorSpeed(jointId: JointId, motorSpeed: f32) void {
    native.b2DistanceJoint_SetMotorSpeed(jointId, motorSpeed);
}

pub inline fn distanceJointGetMotorSpeed(jointId: JointId) f32 {
    return native.b2DistanceJoint_GetMotorSpeed(jointId);
}

pub inline fn distanceJointGetMotorForce(jointId: JointId) f32 {
    return native.b2DistanceJoint_GetMotorForce(jointId);
}

pub inline fn distanceJointSetMaxMotorForce(jointId: JointId, force: f32) void {
    native.b2DistanceJoint_SetMaxMotorForce(jointId, force);
}

pub inline fn distanceJointGetMaxMotorForce(jointId: JointId) f32 {
    return native.b2DistanceJoint_GetMaxMotorForce(jointId);
}

pub inline fn motorJointSetLinearOffset(jointId: JointId, linearOffset: Vec2) void {
    native.b2MotorJoint_SetLinearOffset(jointId, linearOffset);
}

pub inline fn motorJointGetLinearOffset(jointId: JointId) Vec2 {
    return native.b2MotorJoint_GetLinearOffset(jointId);
}

pub inline fn motorJointSetAngularOffset(jointId: JointId, angularOffset: f32) void {
    native.b2MotorJoint_SetAngularOffset(jointId, angularOffset);
}

pub inline fn motorJointGetAngularOffset(jointId: JointId) f32 {
    return native.b2MotorJoint_GetAngularOffset(jointId);
}

pub inline fn motorJointSetMaxForce(jointId: JointId, maxForce: f32) void {
    native.b2MotorJoint_SetMaxForce(jointId, maxForce);
}

pub inline fn motorJointGetMaxForce(jointId: JointId) f32 {
    return native.b2MotorJoint_GetMaxForce(jointId);
}

pub inline fn motorJointSetMaxTorque(jointId: JointId, maxTorque: f32) void {
    native.b2MotorJoint_SetMaxTorque(jointId, maxTorque);
}

pub inline fn motorJointGetMaxTorque(jointId: JointId) f32 {
    return native.b2MotorJoint_GetMaxTorque(jointId);
}

pub inline fn motorJointSetCorrectionFactor(jointId: JointId, correctionFactor: f32) void {
    native.b2MotorJoint_SetCorrectionFactor(jointId, correctionFactor);
}

pub inline fn motorJointGetCorrectionFactor(jointId: JointId) f32 {
    return native.b2MotorJoint_GetCorrectionFactor(jointId);
}

pub inline fn motorJointGetConstraintForce(jointId: JointId) Vec2 {
    return native.b2MotorJoint_GetConstraintForce(jointId);
}

pub inline fn motorJointGetConstraintTorque(jointId: JointId) f32 {
    return motorJointGetConstraintTorque(jointId);
}

pub inline fn mouseJointSetTarget(jointId: JointId, target: Vec2) void {
    native.b2MouseJoint_SetTarget(jointId, target);
}

pub inline fn mouseJointGetTarget(jointId: JointId) Vec2 {
    return native.b2MouseJoint_GetTarget(jointId);
}

pub inline fn mouseJointSetSpringHertz(jointId: JointId, hertz: f32) void {
    native.b2MouseJoint_SetSpringHertz(jointId, hertz);
}

pub inline fn mouseJointSetSpringDampingRatio(jointId: JointId, dampingRatio: f32) void {
    native.b2MouseJoint_SetSpringDampingRatio(jointId, dampingRatio);
}

pub inline fn mouseJointGetHertz(jointId: JointId) f32 {
    return native.b2MouseJoint_GetHertz(jointId);
}

pub inline fn mouseJointGetDampingRatio(jointId: JointId) f32 {
    return native.b2MouseJoint_GetDampingRatio(jointId);
}

pub inline fn prismaticJointEnableSpring(jointId: JointId, enableSpring: bool) void {
    native.b2PrismaticJoint_EnableSpring(jointId, enableSpring);
}

pub inline fn prismaticJointIsSpringEnabled(jointId: JointId) bool {
    return native.b2PrismaticJoint_IsSpringEnabled(jointId);
}

pub inline fn prismaticJointSetSpringHertz(jointId: JointId, hertz: f32) void {
    native.b2PrismaticJoint_SetSpringHertz(jointId, hertz);
}

pub inline fn prismaticJointGetSpringHertz(jointId: JointId) f32 {
    return native.b2PrismaticJoint_GetSpringHertz(jointId);
}

pub inline fn prismaticJointSetSpringDampingRatio(jointId: JointId, dampingRatio: f32) void {
    native.b2PrismaticJoint_SetSpringDampingRatio(jointId, dampingRatio);
}

pub inline fn prismaticJointGetSpringDampingRatio(jointId: JointId) f32 {
    return native.b2PrismaticJoint_GetSpringDampingRatio(jointId);
}

pub inline fn prismaticJointEnableLimit(jointId: JointId, enableLimit: bool) void {
    native.b2PrismaticJoint_EnableLimit(jointId, enableLimit);
}

pub inline fn prismaticJointIsLimitEnabled(jointId: JointId) bool {
    return native.b2PrismaticJoint_IsLimitEnabled(jointId);
}

pub inline fn prismaticJointGetLowerLimit(jointId: JointId) f32 {
    return native.b2PrismaticJoint_GetLowerLimit(jointId);
}

pub inline fn prismaticJointGetUpperLimit(jointId: JointId) f32 {
    return native.b2PrismaticJoint_GetUpperLimit(jointId);
}

pub inline fn prismaticJointSetLimits(jointId: JointId, lower: f32, upper: f32) void {
    native.b2PrismaticJoint_SetLimits(jointId, lower, upper);
}

pub inline fn prismaticJointEnableMotor(jointId: JointId, enableMotor: bool) void {
    native.b2PrismaticJoint_EnableMotor(jointId, enableMotor);
}

pub inline fn prismaticJointIsMotorEnabled(jointId: JointId) bool {
    return native.b2PrismaticJoint_IsMotorEnabled(jointId);
}

pub inline fn prismaticJointSetMotorSpeed(jointId: JointId, motorSpeed: f32) void {
    native.b2PrismaticJoint_SetMotorSpeed(jointId, motorSpeed);
}

pub inline fn prismaticJointGetMotorSpeed(jointId: JointId) f32 {
    return native.b2PrismaticJoint_GetMotorSpeed(jointId);
}

pub inline fn prismaticJointGetMotorForce(jointId: JointId) f32 {
    return prismaticJointGetMotorForce(jointId);
}

pub inline fn prismaticJointSetMaxMotorForce(jointId: JointId, force: f32) void {
    native.b2PrismaticJoint_SetMaxMotorForce(jointId, force);
}

pub inline fn prismaticJointGetMaxMotorForce(jointId: JointId) f32 {
    return native.b2PrismaticJoint_GetMaxMotorForce(jointId);
}

pub inline fn prismaticJointGetConstraintForce(jointId: JointId) Vec2 {
    return native.b2PrismaticJoint_GetConstraintForce(jointId);
}

pub inline fn prismaticJointGetConstraintTorque(jointId: JointId) f32 {
    return native.b2PrismaticJoint_GetConstraintTorque(jointId);
}

pub inline fn revoluteJointEnableSpring(jointId: JointId, enableSpring: bool) void {
    native.b2RevoluteJoint_EnableSpring(jointId, enableSpring);
}

pub inline fn revoluteJointIsLimitEnabled(jointId: JointId) bool {
    return native.b2RevoluteJoint_IsLimitEnabled(jointId);
}

pub inline fn revoluteJointSetSpringHertz(jointId: JointId, hertz: f32) void {
    native.b2RevoluteJoint_SetSpringHertz(jointId, hertz);
}

pub inline fn revoluteJointGetSpringHertz(jointId: JointId) f32 {
    return native.b2RevoluteJoint_GetSpringHertz(jointId);
}

pub inline fn revoluteJointSetSpringDampingRatio(jointId: JointId, dampingRatio: f32) void {
    native.b2RevoluteJoint_SetSpringDampingRatio(jointId, dampingRatio);
}

pub inline fn revoluteJointGetSpringDampingRatio(jointId: JointId) f32 {
    return native.b2RevoluteJoint_GetSpringDampingRatio(jointId);
}

pub inline fn revoluteJointGetAngle(jointId: JointId) f32 {
    return native.b2RevoluteJoint_GetAngle(jointId);
}

pub inline fn revoluteJointEnableLimit(jointId: JointId, enableLimit: bool) void {
    native.b2RevoluteJoint_EnableLimit(jointId, enableLimit);
}

pub inline fn revoluteJointGetLowerLimit(jointId: JointId) f32 {
    return native.b2RevoluteJoint_GetLowerLimit(jointId);
}

pub inline fn revoluteJointGetUpperLimit(jointId: JointId) f32 {
    return native.b2RevoluteJoint_GetUpperLimit(jointId);
}

pub inline fn revoluteJointSetLimits(jointId: JointId, lower: f32, upper: f32) void {
    native.b2RevoluteJoint_SetLimits(jointId, lower, upper);
}

pub inline fn revoluteJointEnableMotor(jointId: JointId, enableMotor: bool) void {
    native.b2RevoluteJoint_EnableMotor(jointId, enableMotor);
}

pub inline fn revoluteJointIsMotorEnabled(jointId: JointId) bool {
    return native.b2RevoluteJoint_IsMotorEnabled(jointId);
}

pub inline fn revoluteJointSetMotorSpeed(jointId: JointId, motorSpeed: f32) void {
    native.b2RevoluteJoint_SetMotorSpeed(jointId, motorSpeed);
}

pub inline fn revoluteJointGetMotorSpeed(jointId: JointId) f32 {
    return native.b2RevoluteJoint_GetMotorSpeed(jointId);
}

pub inline fn revoluteJointGetMotorTorque(jointId: JointId) f32 {
    return native.b2RevoluteJoint_GetMotorTorque(jointId);
}

pub inline fn revoluteJointSetMaxMotorTorque(jointId: JointId, torque: f32) void {
    native.b2RevoluteJoint_SetMaxMotorTorque(jointId, torque);
}

pub inline fn revoluteJointGetMaxMotorTorque(jointId: JointId) f32 {
    return native.b2RevoluteJoint_GetMaxMotorTorque(jointId);
}

pub inline fn revoluteJointGetConstraintForce(jointId: JointId) Vec2 {
    return native.b2RevoluteJoint_GetConstraintForce(jointId);
}

pub inline fn revoluteJointGetConstraintTorque(jointId: JointId) f32 {
    return native.b2RevoluteJoint_GetConstraintTorque(jointId);
}

pub inline fn wheelJointEnableSpring(jointId: JointId, enableSpring: bool) void {
    native.b2WheelJoint_EnableSpring(jointId, enableSpring);
}

pub inline fn wheelJointIsSpringEnabled(jointId: JointId) bool {
    return native.b2WheelJoint_IsSpringEnabled(jointId);
}

pub inline fn wheelJointSetSpringHertz(jointId: JointId, hertz: f32) void {
    return native.b2WheelJoint_SetSpringHertz(jointId, hertz);
}

pub inline fn wheelJointGetSpringHertz(jointId: JointId) f32 {
    return native.b2WheelJoint_GetSpringHertz(jointId);
}

pub inline fn wheelJointSetSpringDampingRatio(jointId: JointId, dampingRatio: f32) void {
    native.b2WheelJoint_SetSpringDampingRatio(jointId, dampingRatio);
}

pub inline fn wheelJointGetSpringDampingRatio(jointId: JointId) f32 {
    return native.b2WheelJoint_GetSpringDampingRatio(jointId);
}

pub inline fn wheelJointEnableLimit(jointId: JointId, enableLimit: bool) void {
    native.b2WheelJoint_EnableLimit(jointId, enableLimit);
}

pub inline fn wheelJointIsLimitEnabled(jointId: JointId) bool {
    return native.b2WheelJoint_IsLimitEnabled(jointId);
}

pub inline fn wheelJointGetLowerLimit(jointId: JointId) f32 {
    return wheelJointGetLowerLimit(jointId);
}

pub inline fn wheelJointGetUpperLimit(jointId: JointId) f32 {
    return wheelJointGetUpperLimit(jointId);
}

pub inline fn wheelJointSetLimits(jointId: JointId, lower: f32, upper: f32) void {
    native.b2WheelJoint_SetLimits(jointId, lower, upper);
}

pub inline fn wheelJointEnableMotor(jointId: JointId, enableMotor: bool) void {
    native.b2WheelJoint_EnableMotor(jointId, enableMotor);
}

pub inline fn wheelJointIsMotorEnabled(jointId: JointId) bool {
    return native.b2WheelJoint_IsMotorEnabled(jointId);
}

pub inline fn wheelJointSetMotorSpeed(jointId: JointId, motorSpeed: f32) void {
    native.b2WheelJoint_SetMotorSpeed(jointId, motorSpeed);
}

pub inline fn wheelJointGetMotorSpeed(jointId: JointId) f32 {
    return native.b2WheelJoint_GetMotorSpeed(jointId);
}

pub inline fn wheelJointGetMotorTorque(jointId: JointId) f32 {
    return wheelJointGetMotorTorque(jointId);
}

pub inline fn wheelJointSetMaxMotorTorque(jointId: JointId, torque: f32) void {
    native.b2WheelJoint_SetMaxMotorTorque(jointId, torque);
}

pub inline fn wheelJointGetMaxMotorTorque(jointId: JointId) f32 {
    return native.b2WheelJoint_GetMaxMotorTorque(jointId);
}

pub inline fn wheelJointGetConstraintForce(jointId: JointId) Vec2 {
    return wheelJointGetConstraintForce(jointId);
}

pub inline fn wheelJointGetConstraintTorque(jointId: JointId) f32 {
    return native.b2WheelJoint_GetConstraintTorque(jointId);
}

pub inline fn weldJointSetLinearHertz(jointId: JointId, hertz: f32) void {
    return weldJointSetLinearHertz(jointId, hertz);
}

pub inline fn weldJointGetLinearHertz(jointId: JointId) f32 {
    return native.b2WeldJoint_GetLinearHertz(jointId);
}

pub inline fn weldJointSetLinearDampingRatio(jointId: JointId, dampingRatio: f32) void {
    native.b2WeldJoint_SetLinearDampingRatio(jointId, dampingRatio);
}

pub inline fn weldJointGetLinearDampingRatio(jointId: JointId) f32 {
    return native.b2WeldJoint_GetLinearDampingRatio(jointId);
}

pub inline fn weldJointSetAngularHertz(jointId: JointId, hertz: f32) void {
    return native.b2WeldJoint_SetAngularHertz(jointId, hertz);
}

pub inline fn weldJointGetAngularHertz(jointId: JointId) f32 {
    return native.b2WeldJoint_GetAngularHertz(jointId);
}

pub inline fn weldJointSetAngularDampingRatio(jointId: JointId, dampingRatio: f32) void {
    native.b2WeldJoint_SetAngularDampingRatio(jointId, dampingRatio);
}

pub inline fn weldJointGetAngularDampingRatio(jointId: JointId) f32 {
    return native.b2WeldJoint_GetAngularDampingRatio(jointId);
}

// TODO: color hex code enum (well, in Zig an enum would be a bad choice, but you get the idea)
// These functions were actually translated by zig translate-c, however I did some manual modifications afterwards

pub inline fn makeColor(hexCode: u32) Color {
    var color: Color = undefined;
    color.r = @as(f32, @floatFromInt((hexCode >> 16) & 255)) / 255.0;
    color.g = @as(f32, @floatFromInt((hexCode >> 8) & 255)) / 255.0;
    color.b = @as(f32, @floatFromInt(hexCode & 255)) / 255.0;
    color.a = 1.0;
    return color;
}
pub inline fn makeColorAlpha(hexCode: u32, alpha: f32) Color {
    var color: Color = undefined;
    color.r = @as(f32, @floatFromInt((hexCode >> 16) & 255)) / 255.0;
    color.g = @as(f32, @floatFromInt((hexCode >> 8) & 255)) / 255.0;
    color.b = @as(f32, @floatFromInt(hexCode & 255)) / 255.0;
    color.a = alpha;
    return color;
}
