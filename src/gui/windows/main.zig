const rl = @import("raylib");
const root = @import("root");
const gui = @import("../gui.zig");
const Component = gui.Component;
const DrawBuffer = gui.DrawBuffer;

pub fn render() !void {
    const screenWidth: i32 = rl.getScreenWidth();
    const screenHeight = rl.getScreenHeight();
    const centerX = @as(f32, @floatFromInt(screenWidth - 400)) / 2;

    if (DrawBuffer.count() == 0) {
        rl.enableCursor();
        try drawBackground();
        try drawTitle();
        DrawBuffer.append(try Component.create(.gradiant, .{ .pos = .{ .x = 0, .y = 0, .width = @floatFromInt(screenWidth), .height = @floatFromInt(screenHeight) }, .topColor = rl.Color{ .r = 0, .g = 0, .b = 0, .a = 0 }, .botColor = rl.Color{ .r = 0, .g = 0, .b = 0, .a = 200 } }));
        DrawBuffer.append(try Component.create(.button, .{ .text = "Play", .fontSize = 20, .alignment = .center, .pos = .{ .x = centerX, .y = 250, .width = 400, .height = 50 }, .action = .play }));
        DrawBuffer.append(try Component.create(.button, .{ .text = "Settings", .fontSize = 20, .alignment = .center, .pos = .{ .x = centerX, .y = 320, .width = (400 - 40) / 2, .height = 50 }, .action = .settings }));
        DrawBuffer.append(try Component.create(.button, .{ .text = "Exit", .fontSize = 20, .alignment = .center, .pos = .{ .x = centerX + 20 + 400 / 2, .y = 320, .width = (400 - 40) / 2, .height = 50 }, .action = .exit }));
        DrawBuffer.append(try Component.create(.label, .{ .text = "zcraft 0.1.0", .fontSize = 12, .alignment = .left, .pos = .{ .x = 10, .y = @floatFromInt(screenHeight - 20), .width = 0, .height = 0 }, .color = rl.Color.ray_white }));
    }
}

fn drawTitle() !void {
    const screenWidth = rl.getScreenWidth();

    const text: [:0]const u8 = "zcraft";
    const size: i32 = 60;
    const width: i32 = rl.measureText(text, size);
    const pos = rl.Vector2{ .x = @as(f32, @floatFromInt(screenWidth - width)) / 2, .y = 100 };

    for (0..7) |i| {
        DrawBuffer.append(try Component.create(.label, .{ .text = text, .fontSize = size, .alignment = .left, .pos = .{ .x = pos.x + @as(f32, @floatFromInt(i)), .y = pos.y + @as(f32, @floatFromInt(i)), .width = 0, .height = 0 }, .color = rl.Color.dark_gray }));
    }
    DrawBuffer.append(try Component.create(.label, .{ .text = text, .fontSize = size, .alignment = .left, .pos = .{ .x = pos.x, .y = pos.y, .width = 0, .height = 0 }, .color = rl.Color.black }));
}

fn drawBackground() !void {
    const backgroundTexture = gui.Textures.get(.dirtFlat);
    const screenWidth = rl.getScreenWidth();
    const screenHeight = rl.getScreenHeight();

    // Define a desired tile size for the background
    const tileWidth: i32 = 64;
    const tileHeight: i32 = 64;

    // Calculate how many tiles are needed to cover the screen in both directions
    const tilesX: usize = @intCast(@divFloor(screenWidth, tileWidth) + 1);
    const tilesY: usize = @intCast(@divFloor(screenHeight, tileHeight) + 1);

    // Draw the tiled background with the scaled down tile size
    for (0..tilesY) |y| {
        for (0..tilesX) |x| {
            const destRect: rl.Rectangle = rl.Rectangle{
                .x = @as(f32, @floatFromInt(x)) * @as(f32, @floatFromInt(tileWidth)),
                .y = @as(f32, @floatFromInt(y)) * @as(f32, @floatFromInt(tileHeight)),
                .width = @as(f32, @floatFromInt(tileWidth)),
                .height = @as(f32, @floatFromInt(tileHeight)),
            };
            DrawBuffer.append(try Component.create(.image, .{ .pos = destRect, .texture = backgroundTexture }));
        }
    }
}
