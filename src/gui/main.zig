const rl = @import("raylib");
const Context = @import("../Context.zig");
const gui = @import("gui.zig");
const Component = gui.Component;

fn drawTitle() void {
    const screenWidth = rl.getScreenWidth();

    const text: [:0]const u8 = "zcraft";
    const size: i32 = 60;
    const width: i32 = rl.measureText(text, size);
    const pos = rl.Vector2{ .x = @as(f32, @floatFromInt(screenWidth - width)) / 2, .y = 100 };

    rl.drawText(text, @intFromFloat(pos.x), @intFromFloat(pos.y), size, rl.Color.dark_gray);

    for (0..6) |i| {
        rl.drawText(text, @as(i32, @intFromFloat(pos.x)) + @as(i32, @intCast(i)), @as(i32, @intFromFloat(pos.y)) + @as(i32, @intCast(i)), size, rl.Color.dark_gray);
    }

    rl.drawText(text, @as(i32, @intFromFloat(pos.x)), @as(i32, @intFromFloat(pos.y)), size, rl.Color.black);
}

fn drawVersion() void {
    const screenHeight = rl.getScreenHeight();
    rl.drawText("zcraft 0.1.0", 10, screenHeight - 20, 20, rl.Color.gray);
}

fn drawBackground() void {
    const screenWidth = rl.getScreenWidth();
    const screenHeight = rl.getScreenHeight();

    const tilesX: usize = @intCast(@divFloor(screenWidth, gui.Textures.backgroundTexture.width) + 2);
    const tilesY: usize = @intCast(@divFloor(screenHeight, gui.Textures.backgroundTexture.height) + 2);

    // Resize the texture to be smaller (scaled down)
    const newWidth: f32 = @as(f32, @floatFromInt(@divFloor(screenWidth, @as(i32, @intCast(tilesX)))));
    const newHeight: f32 = @as(f32, @floatFromInt(@divFloor(screenHeight, @as(i32, @intCast(tilesY)))));

    for (0..tilesY) |y| {
        for (0..tilesX) |x| {
            rl.drawTexturePro(
                gui.Textures.backgroundTexture,
                rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(gui.Textures.backgroundTexture.width), .height = @floatFromInt(gui.Textures.backgroundTexture.height) },
                rl.Rectangle{ .x = @as(f32, @floatFromInt(x)) * newWidth, .y = @as(f32, @floatFromInt(y)) * newHeight, .width = newWidth, .height = newHeight },
                rl.Vector2{ .x = 0, .y = 0 },
                0.0,
                rl.Color.white,
            );
        }
    }

    { // Fade
        // Create the colors for the gradient
        const topColor: rl.Color = rl.Color{ .r = 0, .g = 0, .b = 0, .a = 0 }; // Transparent black at the top
        const bottomColor: rl.Color = rl.Color{ .r = 0, .g = 0, .b = 0, .a = 200 }; // Opaque black at the bottom

        // Draw a single large rectangle with a vertical gradient
        rl.drawRectangleGradientV(0, 0, screenWidth, screenHeight, topColor, bottomColor);
    }
}

pub fn render(ctx: *Context) !void {
    const screenWidth: i32 = rl.getScreenWidth();

    drawBackground();
    drawTitle();
    drawVersion();

    if (gui.list.items.len == 0) {
        try gui.list.append(Component{ .button = try .init(ctx.allocator, "Play", 20, .{ .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2, .y = 250, .width = 400, .height = 50 }, .play) });
        try gui.list.append(Component{ .button = try .init(ctx.allocator, "Settings", 20, .{ .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2, .y = 320, .width = (400 - 40) / 2, .height = 50 }, .settings) });
        try gui.list.append(Component{ .button = try .init(ctx.allocator, "Exit", 20, .{ .x = ((@as(f32, @floatFromInt(screenWidth - 400))) / 2) + 20 + 400 / 2, .y = 320, .width = (400 - 40) / 2, .height = 50 }, .exit) });
    }
}
