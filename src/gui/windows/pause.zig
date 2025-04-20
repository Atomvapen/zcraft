const rl = @import("raylib");
const Context = @import("../../Context.zig");
const gui = @import("../gui.zig");
const Component = gui.Component;
const DrawBuffer = gui.DrawBuffer;

pub fn render(ctx: *Context) !void {
    const screenWidth: i32 = rl.getScreenWidth();
    const screenHeight = rl.getScreenHeight();
    const centerX = @as(f32, @floatFromInt(screenWidth - 400)) / 2;

    if (DrawBuffer.list.items.len == 0) {
        rl.enableCursor();
        try drawBackground();
        DrawBuffer.append(try Component.create(.gradiant, .{ .pos = .{ .x = 0, .y = 0, .width = @floatFromInt(screenWidth), .height = @floatFromInt(screenHeight) }, .topColor = rl.Color{ .r = 0, .g = 0, .b = 0, .a = 0 }, .botColor = rl.Color{ .r = 0, .g = 0, .b = 0, .a = 200 } }));
        DrawBuffer.append(try Component.create(.button, .{ .text = "Back", .fontSize = 20, .alignment = .center, .pos = .{ .x = centerX, .y = 250, .width = 400, .height = 50 }, .action = .play }));
        DrawBuffer.append(try Component.create(.button, .{ .text = "Exit", .fontSize = 20, .alignment = .center, .pos = .{ .x = centerX, .y = 320, .width = 400, .height = 50 }, .action = .exit }));
        DrawBuffer.append(try Component.create(.slider, .{ .pos = .{ .x = (@as(f32, @floatFromInt(rl.getScreenWidth() - 400))) / 2, .y = 390, .width = 400, .height = 50 }, .minValue = 0, .maxValue = 100, .value = &ctx.settings.volume, .thumbWidth = 40, .step = 1 }));
        DrawBuffer.append(try Component.create(.checkBox, .{ .text = "Reverse Scrolling", .fontSize = 20, .pos = .{ .x = centerX, .y = 460, .width = 50, .height = 50 }, .value = &ctx.settings.reverseScrolling }));
        DrawBuffer.append(try Component.create(.slider, .{ .pos = .{ .x = (@as(f32, @floatFromInt(rl.getScreenWidth() - 400))) / 2, .y = 520, .width = 400, .height = 50 }, .minValue = 1, .maxValue = 10, .value = &ctx.settings.renderDistance, .thumbWidth = 40, .step = 1 }));
    }
}

fn drawBackground() !void {
    const backgroundTexture = gui.Textures.grassFlat;
    const screenWidth = rl.getScreenWidth();
    const screenHeight = rl.getScreenHeight();

    // Define a desired tile size for the background
    const tileWidth: i32 = 64; // Adjust as needed (e.g., 64px for a smaller tile)
    const tileHeight: i32 = 64; // Adjust as needed (e.g., 64px for a smaller tile)

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
