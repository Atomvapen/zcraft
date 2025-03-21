const map = @import("../map/map.zig").Map;
const Context = @import("../Context.zig");
const gui = @import("../gui/gui.zig");
const rl = @import("raylib");

pub fn render3D(ctx: *Context) !void {
    map.draw(ctx);
    try ctx.player.render3D();
}

pub fn render2D(ctx: *Context) !void {
    try ctx.player.render2D(ctx);
}
