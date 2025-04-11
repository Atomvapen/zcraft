const map = @import("../map/world.zig").Map;
const Context = @import("../Context.zig");
const Player = @import("../player/player.zig");
const rl = @import("raylib");
const shader = @import("shader.zig");

pub fn render3D(ctx: *Context) !void {
    map.draw(ctx);
    try Player.Render.shadow(ctx.player);
    try Player.Render.model(ctx.player);
}

pub fn render2D(ctx: *Context) !void {
    try Player.Render.ui(ctx.player, ctx);
}

pub fn renderGame(ctx: *Context) !void {
    ctx.generated = true;

    ctx.setCursorVisibility();

    try shader.drawShadow(ctx);
    rl.beginMode3D(ctx.player.camera);
    try render3D(ctx);
    rl.endMode3D();
    try render2D(ctx);
}

pub fn drawDebug() void {
    rl.drawFPS(100, 100);
}
