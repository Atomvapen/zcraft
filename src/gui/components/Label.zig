const Self = @This();
const root = @import("root");
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
};

pos: rl.Rectangle,
text: [:0]const u8,
fontSize: i32,
alignment: Alignment = Alignment.center,
state: State = .default,
color: rl.Color = undefined,

pub fn create(pos: rl.Rectangle, text: [:0]const u8, fontSize: i32, alignment: Alignment, color: rl.Color) !*Self {
    const label: *Self = try root.allocator.create(Self);

    label.* = .{
        .pos = pos,
        .text = text,
        .fontSize = fontSize,
        .alignment = alignment,
        .color = color,
    };

    return label;
}

pub fn destroy(self: *const Self) void {
    root.allocator.destroy(self);
}

pub fn render(self: *const Self) void {
    const textWidth: f32 = @as(f32, @floatFromInt(rl.measureText(self.text, self.fontSize)));
    const textX: f32 = switch (self.alignment) {
        .left => self.pos.x + 5,
        .center => self.pos.x + (self.pos.width - textWidth) / 2,
        .right => self.pos.x + self.pos.width - textWidth - 5,
    };
    const textY: f32 = self.pos.y + (self.pos.height - @as(f32, @floatFromInt(self.fontSize))) / 2;
    rl.drawText(self.text, @intFromFloat(textX), @intFromFloat(textY), self.fontSize, self.color);
}
