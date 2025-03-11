const std = @import("std");
const shader = @import("rendering/shader.zig");
const profiler = @import("profiler.zig");
const mapGen = @import("map/generation.zig");
const renderer = @import("rendering/renderer.zig");
const Context = @import("Context.zig");
const rl = @import("raylib");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator: std.mem.Allocator = gpa.allocator();
    // const allocator: std.mem.Allocator = std.heap.c_allocator;

    var ctx: *Context = try Context.create(allocator);
    defer ctx.destroy(allocator);

    rl.initWindow(1280, 720, "zcraft");
    defer rl.closeWindow();

    //ray.SetTargetFPS(120);
    rl.disableCursor();
    rl.setExitKey(.escape);

    shader.init();
    defer shader.deinit();
    shader.setShadowColor(rl.Color.white);

    try mapGen.init();

    while (!rl.windowShouldClose()) {
        ctx.update();

        rl.beginDrawing();

        shader.drawShadow(ctx);
        rl.clearBackground(rl.Color.gray);

        profiler.clear();

        rl.beginMode3D(ctx.player.camera);
        try renderer.render3D(ctx);
        rl.endMode3D();

        try renderer.render2D(ctx);

        profiler.clear();

        rl.drawFPS(100, 100);
        rl.endDrawing();
    }
}
