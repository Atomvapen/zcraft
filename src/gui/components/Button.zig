const rl = @import("raylib");
const gui = @import("../gui.zig");

const Button = @This();

// pub const Button = struct {
pos: rl.Rectangle,
text: [:0]const u8,
fontSize: i32,

pub fn init(text: [:0]const u8, fontSize: i32, pos: rl.Rectangle) Button {
    return .{
        .pos = pos,
        .text = text,
        .fontSize = fontSize,
    };
}

pub fn draw(self: *const Button) void {
    const textWidth: f32 = @as(f32, @floatFromInt(rl.measureText(self.text, self.fontSize)));
    const textX: f32 = self.pos.x + (self.pos.width - textWidth) / 2;
    const textY: f32 = self.pos.y + (self.pos.height - @as(f32, @floatFromInt(self.fontSize))) / 2;
    const srcRect: rl.Rectangle = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(gui.buttonTexture.width),
        .height = @floatFromInt(gui.buttonTexture.height),
    };

    const hoverScale: f32 = if (self.isHovered()) 1.05 else 1.0;
    const scaledPos = rl.Rectangle{
        .x = self.pos.x - (self.pos.width * (hoverScale - 1.0) / 2),
        .y = self.pos.y - (self.pos.height * (hoverScale - 1.0) / 2),
        .width = self.pos.width * hoverScale,
        .height = self.pos.height * hoverScale,
    };
    rl.drawTexturePro(if (self.isHovered()) gui.buttonHoveredTexture else gui.buttonTexture, srcRect, scaledPos, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.Color.white);
    rl.drawText(self.text, @intFromFloat(textX), @intFromFloat(textY), self.fontSize, rl.Color.black);
}

pub fn isHovered(self: *const Button) bool {
    const mousePos = rl.getMousePosition();
    return rl.checkCollisionPointRec(mousePos, self.pos);
}

pub fn isPressed(self: *const Button) bool {
    const mousePos = rl.getMousePosition();
    return rl.checkCollisionPointRec(mousePos, self.pos) and rl.isMouseButtonPressed(.left);
}
// };
