const rl = @import("raylib");
const gui = @import("../gui.zig");
const std = @import("std");
const Button = @This();

pos: rl.Rectangle,
text: [:0]const u8,
fontSize: i32,
action: gui.Callback = undefined,
hovered: bool = false,
pressed: bool = false,

pub fn init(allocator: std.mem.Allocator, text: [:0]const u8, fontSize: i32, pos: rl.Rectangle, action: gui.Callback) !*Button {
    const button: *Button = try allocator.create(Button);

    button.* = .{
        .pos = pos,
        .text = text,
        .fontSize = fontSize,
        .action = action,
    };

    return button;
}

pub fn draw(self: *const Button) void {
    const scaledFont = if (self.hovered) self.fontSize + 3 else self.fontSize;
    const textWidth: f32 = @as(f32, @floatFromInt(rl.measureText(self.text, scaledFont)));
    const textX: f32 = self.pos.x + (self.pos.width - textWidth) / 2;
    const textY: f32 = self.pos.y + (self.pos.height - @as(f32, @floatFromInt(scaledFont))) / 2;
    const srcRect: rl.Rectangle = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(gui.Textures.buttonTexture.width),
        .height = @floatFromInt(gui.Textures.buttonTexture.height),
    };

    const hoverScale: f32 = if (self.hovered) 1.05 else 1.0;
    const scaledPos = rl.Rectangle{
        .x = self.pos.x - (self.pos.width * (hoverScale - 1.0) / 2),
        .y = self.pos.y - (self.pos.height * (hoverScale - 1.0) / 2),
        .width = self.pos.width * hoverScale,
        .height = self.pos.height * hoverScale,
    };
    rl.drawTexturePro(if (self.hovered) gui.Textures.buttonHoveredTexture else gui.Textures.buttonTexture, srcRect, scaledPos, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.Color.white);
    rl.drawText(self.text, @intFromFloat(textX), @intFromFloat(textY), scaledFont, rl.Color.black);
}

// pub fn isHovered(self: *const Button) bool {
//     const mousePos = rl.getMousePosition();
//     return rl.checkCollisionPointRec(mousePos, self.pos);
// }

// pub fn isPressed(self: *const Button) bool {
//     return self.hovered and rl.isMouseButtonPressed(.left);
// }

pub fn update(self: *Button) void {
    const mousePos = rl.getMousePosition();
    self.hovered = rl.checkCollisionPointRec(mousePos, self.pos);
    self.pressed = self.hovered and rl.isMouseButtonPressed(.left);
    if (self.pressed) gui.callback(self.action);
}
