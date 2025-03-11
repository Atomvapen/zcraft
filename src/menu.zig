const Context = @import("Context.zig");
const rl = @import("raylib");

var buttonTexture: rl.Texture = undefined;
var buttonHoveredTexture: rl.Texture = undefined;

pub fn init() !void {
    buttonTexture = try rl.loadTexture("assets/gui/button.png");
    buttonHoveredTexture = try rl.loadTexture("assets/gui/button_hover.png");
}

pub fn deinit() void {
    rl.unloadTexture(buttonTexture);
    rl.unloadTexture(buttonHoveredTexture);
}

pub fn drawSettings(ctx: *Context) void {
    const screenWidth = rl.getScreenWidth();

    const exitButton = rl.Rectangle{ .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2, .y = 250, .width = 400, .height = 50 };
    const backButton = rl.Rectangle{ .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2, .y = 320, .width = 400, .height = 50 };
    const mousePos = rl.getMousePosition();

    rl.clearBackground(rl.Color.ray_white);
    drawButton(mousePos, exitButton, "Exit", 20);
    drawButton(mousePos, backButton, "Back", 20);
    if (rl.checkCollisionPointRec(mousePos, exitButton) and rl.isMouseButtonPressed(.left)) ctx.quit = true;
    if (rl.checkCollisionPointRec(mousePos, backButton) and rl.isMouseButtonPressed(.left)) ctx.state = .Menu;
}

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

    // Draw main logo text (top layer)
    rl.drawText(menuTitleText, @as(i32, @intFromFloat(menuTitlePos.x)), @as(i32, @intFromFloat(menuTitlePos.y)), menuTitleSize, rl.Color.black);
}

pub fn drawMain(ctx: *Context) !void {
    const screenWidth = rl.getScreenWidth();

    const playButton = rl.Rectangle{ .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2, .y = 250, .width = 400, .height = 50 };
    const exitButton = rl.Rectangle{ .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2, .y = 320, .width = 400, .height = 50 };
    const settButton = rl.Rectangle{ .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2, .y = 390, .width = 400, .height = 50 };
    const mousePos = rl.getMousePosition();

    rl.clearBackground(rl.Color.ray_white);

    drawMainTitle();

    drawButton(mousePos, playButton, "Play", 20);
    drawButton(mousePos, exitButton, "Exit", 20);
    drawButton(mousePos, settButton, "Settings", 20);

    if (rl.checkCollisionPointRec(mousePos, settButton) and rl.isMouseButtonPressed(.left)) ctx.state = .Settings;
    if (rl.checkCollisionPointRec(mousePos, playButton) and rl.isMouseButtonPressed(.left)) ctx.state = .Playing;
    if (rl.checkCollisionPointRec(mousePos, exitButton) and rl.isMouseButtonPressed(.left)) ctx.quit = true;
}

fn drawButton(mousePos: rl.Vector2, pos: rl.Rectangle, text: [:0]const u8, fontSize: i32) void {
    const textWidth: f32 = @as(f32, @floatFromInt(rl.measureText(text, fontSize)));
    const textX: f32 = pos.x + (pos.width - textWidth) / 2;
    const textY: f32 = pos.y + (pos.height - @as(f32, @floatFromInt(fontSize))) / 2;
    const hovering: bool = rl.checkCollisionPointRec(mousePos, pos);
    const srcRect: rl.Rectangle = rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(buttonTexture.width), .height = @floatFromInt(buttonTexture.height) };

    rl.drawTexturePro(if (hovering) buttonHoveredTexture else buttonTexture, srcRect, pos, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.Color.white);
    rl.drawText(text, @intFromFloat(textX), @intFromFloat(textY), fontSize, rl.Color.black);
}
