const Self = @This();

const rl = @import("raylib");
const gui = @import("../gui.zig");
const std = @import("std");

// const State = enum {
//     disabled,
//     default,
// };

pos: rl.Rectangle,
// state: State = .default,
topColor: rl.Color,
botColor: rl.Color,

pub fn create(allocator: std.mem.Allocator, pos: rl.Rectangle, topColor: rl.Color, botColor: rl.Color) !*Self {
    const gradiant: *Self = try allocator.create(Self);

    gradiant.* = .{
        .pos = pos,
        .topColor = topColor,
        .botColor = botColor,
    };

    return gradiant;
}

pub fn destroy(self: *const Self, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn render(self: *const Self) void {
    rl.drawRectangleGradientV(@intFromFloat(self.pos.x), @intFromFloat(self.pos.y), @intFromFloat(self.pos.width), @intFromFloat(self.pos.height), self.topColor, self.botColor);
}
