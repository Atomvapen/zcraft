const map = @import("../map/map.zig");
const Context = @import("../Context.zig");
const gui = @import("../gui/gui.zig");
const rl = @import("raylib");

pub fn render3D(ctx: *Context) !void {
    // profiler.time("time");
    map.draw(ctx);
    try ctx.player.render();
    // profiler.time("time");
}

pub fn render2D(ctx: *Context) !void {
    try ctx.player.renderUI();
}
