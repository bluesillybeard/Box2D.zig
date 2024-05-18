// In C, you would only import the headers you need.
// This is a binding, so ALL of the headers are included
const c = @cImport({
    // Many of these are unnessesary. They are all here since it was easiest to just
    // add all of them without thinking about which ones are actually needed
    @cInclude("box2d/api.h");
    @cInclude("box2d/box2d.h");
    @cInclude("box2d/callbacks.h");
    @cInclude("box2d/color.h");
    @cInclude("box2d/constants.h");
    @cInclude("box2d/debug_draw.h");
    @cInclude("box2d/distance.h");
    @cInclude("box2d/dynamic_tree.h");
    @cInclude("box2d/event_types.h");
    @cInclude("box2d/geometry.h");
    @cInclude("box2d/hull.h");
    @cInclude("box2d/id.h");
    @cInclude("box2d/joint_types.h");
    @cInclude("box2d/manifold.h");
    @cInclude("box2d/math_functions.h");
    @cInclude("box2d/math_types.h");
    @cInclude("box2d/timer.h");
    @cInclude("box2d/types.h");
});
pub usingnamespace c;
