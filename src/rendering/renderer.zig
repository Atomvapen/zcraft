const map = @import("../map/world.zig").Map;
const Context = @import("../Context.zig");
const Player = @import("../player/player.zig").Player;
const rl = @import("raylib");
const shader = @import("shader.zig");
const gui = @import("../gui/gui.zig");
const DrawBuffer = gui.DrawBuffer;

pub fn init() void {
    rl.gl.rlDisableBackfaceCulling();
}

fn begin() void {
    rl.beginDrawing();
    rl.clearBackground(rl.Color.sky_blue);
}

fn end() void {
    rl.endDrawing();
}

pub fn render(ctx: *Context) !void {
    begin();
    defer end();

    try switch (ctx.state.current) {
        .menu => gui.Window.render(ctx, .main),
        .playing => renderGame(ctx),
        .settings => gui.Window.render(ctx, .settings),
        .pause => gui.Window.render(ctx, .pause),
        else => {},
    };

    gui.DrawBuffer.update();
    gui.DrawBuffer.render();
}

fn renderGame(ctx: *Context) !void {
    if (map.created != true) map.created = true;
    gui.setCursorVisibility(ctx);

    // Clear screen buffers
    rl.gl.rlClearScreenBuffers();

    // 1. Z-Prepass (Depth-only pass)
    rl.gl.rlEnableDepthTest();
    rl.gl.rlEnableDepthMask();
    rl.gl.rlColorMask(false, false, false, false);
    try renderWorld(ctx);

    // 2. Shadow rendering (only depth, no color writes)
    rl.gl.rlColorMask(false, false, false, false);
    try shader.drawShadow(ctx);

    // 3. Main render pass (Full color and depth render)
    rl.gl.rlColorMask(true, true, true, true);
    rl.gl.rlEnableDepthMask();
    rl.beginMode3D(ctx.player.camera);
    try renderWorld(ctx);
    rl.endMode3D();

    // 4. UI Rendering (disable depth test for 2D UI)
    rl.gl.rlDisableDepthTest();
    try renderUI(ctx.player, ctx);
}

pub fn renderWorld(ctx: *Context) !void {
    map.draw(ctx);
    try ctx.player.render();
}

fn renderUI(self: *Player, ctx: *Context) !void {
    const Component = gui.Component;
    if (DrawBuffer.count() == 0) { // Refactor out of player?
        DrawBuffer.append(try Component.create(.hotbar, .{ .ctx = ctx, .pos = .{ .x = 0, .y = 0, .width = 0, .height = 0 }, .selection = &self.inventory.hotbar.selection }));
        DrawBuffer.append(try Component.create(.crosshair, .{ .size = 10, .visible = true }));
        DrawBuffer.append(try Component.create(.inventory, .{ .ctx = ctx, .pos = .{ .x = 0, .y = 0, .width = 0, .height = 0 } }));
    }
    if (ctx.settings.debug) rl.drawFPS(100, 100);
}
