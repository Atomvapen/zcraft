const rl = @import("raylib");
const Context = @import("../../Context.zig");
const gui = @import("../gui.zig");
const Component = gui.Component;

pub fn render(ctx: *Context) !void {
    const screenWidth: i32 = rl.getScreenWidth();
    const screenHeight = rl.getScreenHeight();

    if (gui.DrawBuffer.list.items.len == 0) {
        try drawBackground(ctx);
        try drawTitle(ctx);
        gui.DrawBuffer.append(Component{ .gradiant = try .create(ctx.allocator, .{ .x = 0, .y = 0, .width = @floatFromInt(screenWidth), .height = @floatFromInt(screenHeight) }, rl.Color{ .r = 0, .g = 0, .b = 0, .a = 0 }, rl.Color{ .r = 0, .g = 0, .b = 0, .a = 200 }) });
        gui.DrawBuffer.append(Component{ .button = try .create(ctx.allocator, "Play", 20, .center, .{ .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2, .y = 250, .width = 400, .height = 50 }, .play) });
        gui.DrawBuffer.append(Component{ .button = try .create(ctx.allocator, "Settings", 20, .center, .{ .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2, .y = 320, .width = (400 - 40) / 2, .height = 50 }, .settings) });
        gui.DrawBuffer.append(Component{ .button = try .create(ctx.allocator, "Exit", 20, .center, .{ .x = ((@as(f32, @floatFromInt(screenWidth - 400))) / 2) + 20 + 400 / 2, .y = 320, .width = (400 - 40) / 2, .height = 50 }, .exit) });
        gui.DrawBuffer.append(Component{ .label = try .create(ctx.allocator, .{ .x = 10, .y = @floatFromInt(screenHeight - 20), .width = 0, .height = 0 }, "zcraft 0.1.0", 25, .left, rl.Color.ray_white) });
    }
}

fn drawTitle(ctx: *Context) !void {
    const screenWidth = rl.getScreenWidth();

    const text: [:0]const u8 = "zcraft";
    const size: i32 = 60;
    const width: i32 = rl.measureText(text, size);
    const pos = rl.Vector2{ .x = @as(f32, @floatFromInt(screenWidth - width)) / 2, .y = 100 };

    for (0..7) |i| {
        gui.DrawBuffer.append(Component{ .label = try .create(ctx.allocator, .{ .x = pos.x + @as(f32, @floatFromInt(i)), .y = pos.y + @as(f32, @floatFromInt(i)), .width = 0, .height = 0 }, text, size, .left, rl.Color.dark_gray) });
    }

    gui.DrawBuffer.append(Component{ .label = try .create(ctx.allocator, .{ .x = pos.x, .y = pos.y, .width = 0, .height = 0 }, text, size, .left, rl.Color.black) });
}

fn drawBackground(ctx: *Context) !void {
    const backgroundTexture = gui.Textures.dirtFlat;
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

            gui.DrawBuffer.append(.{ .image = try .create(ctx.allocator, destRect, backgroundTexture) });
        }
    }
}
