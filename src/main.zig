const std = @import("std");
const shader = @import("rendering/shader.zig");
const mapGen = @import("map/generation.zig");
const renderer = @import("rendering/renderer.zig");
const Context = @import("Context.zig");
const rl = @import("raylib");
const gui = @import("gui/gui.zig");
const blocks = @import("map/blocks.zig");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    const allocator: std.mem.Allocator = gpa.allocator();
    // const allocator: std.mem.Allocator = std.heap.c_allocator;

    var ctx: *Context = try Context.create(allocator);
    defer ctx.destroy(allocator);

    rl.initWindow(1280, 720, "zcraft");
    defer rl.closeWindow();

    const icon = try rl.loadImage("assets/icon.png");
    defer icon.unload();
    icon.useAsWindowIcon();

    //ray.SetTargetFPS(120);
    rl.setExitKey(.escape);

    shader.init();
    defer shader.deinit();
    shader.setShadowColor(rl.Color.white);

    try blocks.init(ctx);
    defer blocks.deinit();

    try mapGen.init();

    try gui.DrawBuffer.init(ctx);
    defer gui.DrawBuffer.deinit();

    ctx.player.inventory = .{ 1, 2, 3, 4, 5, 6, 1, 2, 3 };

    while (!rl.windowShouldClose() and !(ctx.state == .Exiting)) {
        ctx.update();

        rl.beginDrawing();
        rl.clearBackground(rl.Color.gray);

        if (ctx.state != ctx.prevState) {
            gui.DrawBuffer.clear(ctx.allocator);
            ctx.prevState = ctx.state;
        }

        switch (ctx.state) {
            .Menu => try gui.Window.main.render(ctx),
            .Playing => renderGame(ctx),
            .Settings => try gui.Window.settings.render(ctx),
            else => {},
        }

        if (ctx.debug) {
            drawDebug();
        }

        gui.DrawBuffer.update();

        rl.endDrawing();
    }
}

fn drawDebug() void {
    rl.drawFPS(100, 100);
}

fn renderGame(ctx: *Context) void {
    rl.disableCursor();
    shader.drawShadow(ctx);
    rl.beginMode3D(ctx.player.camera);
    try renderer.render3D(ctx);
    rl.endMode3D();
    try renderer.render2D(ctx);
}
