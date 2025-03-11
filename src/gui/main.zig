const rl = @import("raylib");
const Button = @import("components/Button.zig");
const Context = @import("../Context.zig");
const gui = @import("gui.zig");

// var backgroundTexture: rl.Texture = gui.backgroundTexture;
// var backgroundImage: rl.Image = gui.backgroundImage;

fn drawMainTitle() void {
    const screenWidth = rl.getScreenWidth();

    const menuTitleText = "zcraft";
    const menuTitleSize: i32 = 60;
    const menuTitleWidth: i32 = rl.measureText(menuTitleText, menuTitleSize);
    const menuTitlePos = rl.Vector2{ .x = @as(f32, @floatFromInt(screenWidth - menuTitleWidth)) / 2, .y = 100 };
    rl.drawText(menuTitleText, @intFromFloat(menuTitlePos.x), @intFromFloat(menuTitlePos.y), menuTitleSize, rl.Color.dark_gray);

    for (0..6) |i| {
        rl.drawText(menuTitleText, @as(i32, @intFromFloat(menuTitlePos.x)) + @as(i32, @intCast(i)), @as(i32, @intFromFloat(menuTitlePos.y)) + @as(i32, @intCast(i)), menuTitleSize, rl.Color.dark_gray);
    }

    rl.drawText(menuTitleText, @as(i32, @intFromFloat(menuTitlePos.x)), @as(i32, @intFromFloat(menuTitlePos.y)), menuTitleSize, rl.Color.black);
}

fn drawVersionText() void {
    const screenHeight = rl.getScreenHeight();
    rl.drawText("zcraft 0.1.0", 10, screenHeight - 20, 20, rl.Color.gray);
}

fn drawBackground() void {
    const screenWidth = rl.getScreenWidth();
    const screenHeight = rl.getScreenHeight();

    const tilesX: usize = @intCast(@divFloor(screenWidth, gui.backgroundTexture.width) + 2);
    const tilesY: usize = @intCast(@divFloor(screenHeight, gui.backgroundTexture.height) + 2);

    // Resize the texture to be smaller (scaled down)
    const newWidth: f32 = @as(f32, @floatFromInt(@divFloor(screenWidth, @as(i32, @intCast(tilesX)))));
    const newHeight: f32 = @as(f32, @floatFromInt(@divFloor(screenHeight, @as(i32, @intCast(tilesY)))));

    for (0..tilesY) |y| {
        for (0..tilesX) |x| {
            rl.drawTexturePro(
                gui.backgroundTexture,
                rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(gui.backgroundTexture.width), .height = @floatFromInt(gui.backgroundTexture.height) },
                rl.Rectangle{ .x = @as(f32, @floatFromInt(x)) * newWidth, .y = @as(f32, @floatFromInt(y)) * newHeight, .width = newWidth, .height = newHeight },
                rl.Vector2{ .x = 0, .y = 0 },
                0.0,
                rl.Color.white,
            );
        }
    }
    drawBackgroundFade();
}

fn drawBackgroundFade() void {
    const screenWidth: i32 = rl.getScreenWidth();
    const screenHeight: i32 = rl.getScreenHeight();

    // Create the colors for the gradient
    const topColor: rl.Color = rl.Color{ .r = 0, .g = 0, .b = 0, .a = 0 }; // Transparent black at the top
    const bottomColor: rl.Color = rl.Color{ .r = 0, .g = 0, .b = 0, .a = 200 }; // Opaque black at the bottom

    // Draw a single large rectangle with a vertical gradient
    rl.drawRectangleGradientV(0, 0, screenWidth, screenHeight, topColor, bottomColor);
}

pub fn draw(ctx: *Context) !void {
    const screenWidth: i32 = rl.getScreenWidth();

    rl.clearBackground(rl.Color.ray_white);

    drawBackground();
    drawMainTitle();
    drawVersionText();

    const playButton = Button.init(
        "Play",
        20,
        .{
            .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2,
            .y = 250,
            .width = 400,
            .height = 50,
        },
    );
    playButton.draw();
    if (playButton.isPressed()) ctx.state = .Playing;

    const settButton = Button.init(
        "Settings",
        20,
        .{
            .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2,
            .y = 320,
            .width = (400 - 40) / 2,
            .height = 50,
        },
    );
    settButton.draw();
    if (settButton.isPressed()) ctx.state = .Settings;

    const exitButton = Button.init(
        "Exit",
        20,
        .{
            .x = settButton.pos.x + 20 + 400 / 2,
            .y = 320,
            .width = (400 - 40) / 2,
            .height = 50,
        },
    );
    exitButton.draw();
    if (exitButton.isPressed()) ctx.quit = true;
}
