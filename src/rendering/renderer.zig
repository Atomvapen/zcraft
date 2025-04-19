const map = @import("../map/world.zig").Map;
const Context = @import("../Context.zig");
const Player = @import("../player/player.zig").Player;
const rl = @import("raylib");
const shader = @import("shader.zig");
const gui = @import("../gui/gui.zig");

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
}

pub fn setCursorVisibility(ctx: *Context) void {
    if (ctx.player.inventory.open != ctx.player.cursorEnabled) {
        ctx.player.cursorEnabled = ctx.player.inventory.open;
        if (ctx.player.inventory.open) rl.enableCursor() else rl.disableCursor();
    }
}

pub fn renderGame(ctx: *Context) !void {
    if (map.created != true) map.created = true;
    setCursorVisibility(ctx);

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

pub fn renderUI(self: *Player, ctx: *Context) !void {
    const Component = gui.Component;
    if (gui.DrawBuffer.list.items.len == 0) { // Refactor out of player?
        gui.DrawBuffer.append(Component{ .hotbar = try .create(&self.inventory.hotbar.selection, ctx) });
        gui.DrawBuffer.append(Component{ .crosshair = try .create(10) });
        gui.DrawBuffer.append(Component{ .inventory = try .create(ctx) });
    }
    if (ctx.settings.debug) rl.drawFPS(100, 100);
}
