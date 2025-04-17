const std = @import("std");
const shader = @import("rendering/shader.zig");
const renderer = @import("rendering/renderer.zig");
const Context = @import("Context.zig");
const rl = @import("raylib");
const gui = @import("gui/gui.zig");
const blocks = @import("map/blocks.zig");
const map = @import("map/world.zig");

var gpa: std.heap.DebugAllocator(.{}) = std.heap.DebugAllocator(.{}).init;
pub const allocator: std.mem.Allocator = gpa.allocator(); // main game allocator
// pub const allocator: std.mem.Allocator = std.heap.c_allocator;

pub fn main() !void {
    var ctx: *Context = try Context.create(allocator);
    defer ctx.destroy(allocator);

    rl.initWindow(1280, 720, "zcraft");
    defer rl.closeWindow();

    const icon = try rl.loadImage("assets/icon.png");
    defer icon.unload();
    icon.useAsWindowIcon();

    //ray.SetTargetFPS(120);
    rl.setExitKey(.f1);

    shader.init();
    defer shader.deinit();

    try blocks.init();
    defer blocks.deinit();

    try gui.DrawBuffer.init(ctx);
    defer gui.DrawBuffer.deinit();

    map.Map.init();
    defer map.Map.deinit();

    try map.Generate.Structures.init();

    renderer.init();

    { // Debug block
        // ctx.player.hotbar.setRow(.{ 1, 2, 3, 4, 5, 6, 1, 2, 3 });
        // ctx.player.inventory.setRow(.{ 1, 2, 3, 4, 5, 6, 1, 2, 3, 0 }, 0);
        ctx.player.inventory.setRow(.{ 1, 2, 3, 4, 5, 6, 1, 2, 3 }, 0);
    }

    while (!rl.windowShouldClose() and ctx.state.current != .Exiting) {
        try ctx.update();

        if (ctx.state.current != ctx.state.previous) {
            gui.DrawBuffer.clear();
            ctx.state.previous = ctx.state.current;

            switch (ctx.state.current) {
                .Menu, .Settings, .SettingsInGame => rl.enableCursor(),
                .Playing => rl.disableCursor(),
                else => {},
            }
        }

        try renderer.drawFrame(ctx);
    }
}
