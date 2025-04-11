const map = @import("../map/world.zig").Map;
const Context = @import("../Context.zig");
const Player = @import("../player/player.zig");

pub fn render3D(ctx: *Context) !void {
    map.draw(ctx);
    try Player.Render.shadow(ctx.player);
    try Player.Render.model(ctx.player);
}

pub fn render2D(ctx: *Context) !void {
    try Player.Render.ui(ctx.player, ctx);
}
