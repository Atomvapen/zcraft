const Context = @import("Context.zig");
const rl = @import("raylib");

pub fn drawSettings(ctx: *Context) void {
    const exitButton = rl.Rectangle{ .x = 300, .y = 320, .width = 200, .height = 50 };
    const mousePos = rl.getMousePosition();

    rl.clearBackground(rl.Color.ray_white);
    drawButton(mousePos, exitButton, "Exit", 20);
    if (rl.checkCollisionPointRec(mousePos, exitButton) and rl.isMouseButtonPressed(.left)) ctx.quit = true;
}

pub fn drawMain(ctx: *Context) void {
    const playButton = rl.Rectangle{ .x = 300, .y = 250, .width = 200, .height = 50 };
    const exitButton = rl.Rectangle{ .x = 300, .y = 320, .width = 200, .height = 50 };
    const settButton = rl.Rectangle{ .x = 300, .y = 390, .width = 200, .height = 50 };
    const mousePos = rl.getMousePosition();

    rl.clearBackground(rl.Color.ray_white);
    rl.drawText("zcraft", 250, 100, 40, rl.Color.dark_gray);

    // Draw buttons
    drawButton(mousePos, playButton, "Play", 20);
    drawButton(mousePos, exitButton, "Exit", 20);
    drawButton(mousePos, settButton, "Settings", 20);

    // Check mouse click
    if (rl.checkCollisionPointRec(mousePos, settButton) and rl.isMouseButtonPressed(.left)) ctx.state = .Settings;
    if (rl.checkCollisionPointRec(mousePos, playButton) and rl.isMouseButtonPressed(.left)) ctx.state = .Playing;
    if (rl.checkCollisionPointRec(mousePos, exitButton) and rl.isMouseButtonPressed(.left)) ctx.quit = true;
}

fn drawButton(mousePos: rl.Vector2, pos: rl.Rectangle, text: [:0]const u8, fontSize: i32) void {
    const textWidth: f32 = @as(f32, @floatFromInt(rl.measureText(text, fontSize)));
    const textX: f32 = pos.x + (pos.width - textWidth) / 2;
    const textY: f32 = pos.y + (pos.height - @as(f32, @floatFromInt(fontSize))) / 2;

    rl.drawRectangleRec(pos, if (rl.checkCollisionPointRec(mousePos, pos)) rl.Color.gray else rl.Color.light_gray);
    rl.drawText(text, @intFromFloat(textX), @intFromFloat(textY), fontSize, rl.Color.black);
}
