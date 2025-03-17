const rl = @import("raylib");
const gui = @import("../gui.zig");
const std = @import("std");
const Button = @This();

const Alignment = enum {
    left,
    center,
    right,
};

const Content = struct {
    text: [:0]const u8 = "",
    size: i32 = 0,
    alignment: Alignment = Alignment.center,
};

const State = enum {
    default,
    hovered,
};

pos: rl.Rectangle,
text: [:0]const u8,
fontSize: i32,
action: gui.Callback.Action = undefined,
disabled: bool = false,
alignment: Alignment = Alignment.center,
state: State = .default,
content: ?Content = undefined,

pub fn create(allocator: std.mem.Allocator, text: [:0]const u8, fontSize: i32, alignment: Alignment, pos: rl.Rectangle, action: gui.Callback.Action) !*Button {
    const button: *Button = try allocator.create(Button);

    button.* = .{
        .pos = pos,
        .text = text,
        .fontSize = fontSize,
        .action = action,
        .alignment = alignment,
    };

    return button;
}

pub fn destroy(self: *const Button, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn render(self: *const Button) void {
    const scaledFont = if (self.state == .hovered) self.fontSize + 3 else self.fontSize;
    const textWidth: f32 = @as(f32, @floatFromInt(rl.measureText(self.text, scaledFont)));
    const textX: f32 = switch (self.alignment) {
        .left => self.pos.x + 5,
        .center => self.pos.x + (self.pos.width - textWidth) / 2,
        .right => self.pos.x + self.pos.width - textWidth - 5,
    };
    const textY: f32 = self.pos.y + (self.pos.height - @as(f32, @floatFromInt(scaledFont))) / 2;
    const srcRect: rl.Rectangle = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(gui.Textures.button.width),
        .height = @floatFromInt(gui.Textures.button.height),
    };

    const hoverScale: f32 = if (self.state == .hovered) 1.05 else 1.0;
    const scaledPos = rl.Rectangle{
        .x = self.pos.x - (self.pos.width * (hoverScale - 1.0) / 2),
        .y = self.pos.y - (self.pos.height * (hoverScale - 1.0) / 2),
        .width = self.pos.width * hoverScale,
        .height = self.pos.height * hoverScale,
    };
    rl.drawTexturePro(if (self.state == .hovered) gui.Textures.buttonHovered else gui.Textures.button, srcRect, scaledPos, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.Color.white);
    rl.drawText(self.text, @intFromFloat(textX), @intFromFloat(textY), scaledFont, if (self.disabled) rl.Color.gray else rl.Color.black);
}

pub fn update(self: *Button) void {
    if (self.disabled) return;
    const mousePos = rl.getMousePosition();
    self.state = if (rl.checkCollisionPointRec(mousePos, self.pos)) .hovered else .default;
    if (self.state == .hovered and rl.isMouseButtonPressed(.left)) gui.Callback.run(self.action);
}
