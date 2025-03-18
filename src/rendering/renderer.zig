const map = @import("../map/map.zig");
const Context = @import("../Context.zig");
const gui = @import("../gui/gui.zig");
const rl = @import("raylib");

pub fn render3D(ctx: *Context) !void {
    // profiler.time("time");
    map.draw(ctx);
    // ctx.player.render();
    // profiler.time("time");
}

pub fn render2D(ctx: *Context) !void {
    renderUI(ctx);
}

pub fn renderUI(ctx: *Context) void {
    gui.Crosshair.render();
    renderHotbar(ctx) catch {};
}

fn renderHotbar(ctx: *Context) !void {
    const hotbar = try gui.Hotbar.create(ctx.allocator, &ctx.player.selectedBlock);
    hotbar.render(ctx);
    defer hotbar.destroy(ctx.allocator);
}
