const Self = @This();

const rl = @import("raylib");
const gui = @import("../gui.zig");
const std = @import("std");

const Alignment = enum {
    left,
    center,
    right,
};

const State = enum {
    disabled,
    default,
    hovered,
    pressed,
};

pos: rl.Rectangle,
text: [:0]const u8,
fontSize: i32,
action: gui.Callback.Action = undefined,
alignment: Alignment = Alignment.center,
state: State = .default,

pub fn create(allocator: std.mem.Allocator, text: [:0]const u8, fontSize: i32, alignment: Alignment, pos: rl.Rectangle, action: gui.Callback.Action) !*Self {
    const button: *Self = try allocator.create(Self);

    button.* = .{
        .pos = pos,
        .text = text,
        .fontSize = fontSize,
        .action = action,
        .alignment = alignment,
    };

    return button;
}

pub fn destroy(self: *const Self, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn render(self: *const Self) void {
    { // Button body
        const sourceRect: rl.Rectangle = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(gui.Textures.button.width),
            .height = @floatFromInt(gui.Textures.button.height),
        };
        const bodyHoverScalar: f32 = if (self.state == .hovered) 1.05 else 1.0;
        const scaledRect = rl.Rectangle{
            .x = self.pos.x - (self.pos.width * (bodyHoverScalar - 1.0) / 2),
            .y = self.pos.y - (self.pos.height * (bodyHoverScalar - 1.0) / 2),
            .width = self.pos.width * bodyHoverScalar,
            .height = self.pos.height * bodyHoverScalar,
        };
        rl.drawTexturePro(if (self.state == .hovered) gui.Textures.buttonHovered else gui.Textures.button, sourceRect, scaledRect, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.Color.white);
    }

    { //Text
        const textHoverScalar = if (self.state == .hovered) self.fontSize + 3 else self.fontSize;
        const textWidth: f32 = @as(f32, @floatFromInt(rl.measureText(self.text, textHoverScalar)));
        const textX: f32 = switch (self.alignment) {
            .left => self.pos.x + 5,
            .center => self.pos.x + (self.pos.width - textWidth) / 2,
            .right => self.pos.x + self.pos.width - textWidth - 5,
        };
        const textY: f32 = self.pos.y + (self.pos.height - @as(f32, @floatFromInt(textHoverScalar))) / 2;
        rl.drawText(self.text, @intFromFloat(textX), @intFromFloat(textY), textHoverScalar, if (self.state == .disabled) rl.Color.gray else rl.Color.black);
    }
}

pub fn update(self: *Self) void {
    if (self.state == .disabled) return;
    const mousePos: rl.Vector2 = rl.getMousePosition();
    self.state = if (rl.checkCollisionPointRec(mousePos, self.pos)) .hovered else .default;
    if (self.state == .hovered and rl.isMouseButtonPressed(.left)) self.state = .pressed;
    if (self.state == .pressed) gui.Callback.run(self.action);
}
