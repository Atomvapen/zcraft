const rl = @import("raylib");
const Context = @import("../../Context.zig");
const gui = @import("../gui.zig");
const Component = gui.Component;

pub fn render(ctx: *Context) !void {
    const screenWidth: i32 = rl.getScreenWidth();
    const screenHeight = rl.getScreenHeight();

    if (gui.DrawBuffer.list.items.len == 0) {
        rl.enableCursor();
        try drawBackground(ctx);
        gui.DrawBuffer.append(Component{ .gradiant = try .create(ctx.allocator, .{ .x = 0, .y = 0, .width = @floatFromInt(screenWidth), .height = @floatFromInt(screenHeight) }, rl.Color{ .r = 0, .g = 0, .b = 0, .a = 0 }, rl.Color{ .r = 0, .g = 0, .b = 0, .a = 200 }) });
        gui.DrawBuffer.append(Component{ .button = try .create(ctx.allocator, "Back", 20, .center, .{ .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2, .y = 250, .width = 400, .height = 50 }, .back) });
        gui.DrawBuffer.append(Component{ .button = try .create(ctx.allocator, "Exit", 20, .center, .{ .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2, .y = 320, .width = 400, .height = 50 }, .exit) });
        gui.DrawBuffer.append(Component{ .slider = try .create(ctx.allocator, .{ .x = (@as(f32, @floatFromInt(rl.getScreenWidth() - 400))) / 2, .y = 390, .width = 400, .height = 50 }, 0, 100, &ctx.settings.volume, 40) });
        gui.DrawBuffer.append(Component{ .checkBox = try .create(ctx.allocator, "Safe", 20, .{ .x = (@as(f32, @floatFromInt(rl.getScreenWidth() - 400))) / 2, .y = 460, .width = 50, .height = 50 }, &ctx.settings.reverseScrolling) });
        gui.DrawBuffer.append(Component{ .slider = try .create(ctx.allocator, .{ .x = (@as(f32, @floatFromInt(rl.getScreenWidth() - 400))) / 2, .y = 520, .width = 400, .height = 50 }, 1, 10, &ctx.settings.renderDistance, 40) });
    }
}

fn drawBackground(ctx: *Context) !void {
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

            gui.DrawBuffer.append(.{ .image = try .create(ctx.allocator, destRect, backgroundTexture) });
        }
    }
}
