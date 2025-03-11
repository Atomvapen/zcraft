// const profiler = @import("../profiler.zig");
const map = @import("../map/map.zig");
const Context = @import("../Context.zig");
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
    renderCrosshair();
    renderHotbar(ctx);
}

// TEMP
fn renderHotbar(ctx: *Context) void {
    // const screenWidth: i32 = rl.getScreenWidth();
    const screenHeight: i32 = rl.getScreenHeight();
    // const centerX: i32 = @divExact(screenWidth, 2);
    // const centerY: i32 = @divExact(screenHeight, 2);
    const size: i32 = 30;
    const color: rl.Color = rl.Color.black;

    for (1..7) |i| {
        const val: [:0]const u8 = if (i == ctx.player.selectedBlock) "[X]" else "[ ]";
        rl.drawText(val, 10 + @as(i32, @intCast(i)) * 50, screenHeight - 30, size, color);
    }
}

fn renderCrosshair() void {
    const screenWidth: i32 = rl.getScreenWidth();
    const screenHeight: i32 = rl.getScreenHeight();
    const centerX: i32 = @divExact(screenWidth, 2);
    const centerY: i32 = @divExact(screenHeight, 2);
    const size: i32 = 10;
    const color: rl.Color = rl.Color.black;

    // Draw vertical and horizontal lines
    rl.drawLine(centerX - size, centerY, centerX + size, centerY, color); // Horizontal
    rl.drawLine(centerX, centerY - size, centerX, centerY + size, color); // Vertical

}
