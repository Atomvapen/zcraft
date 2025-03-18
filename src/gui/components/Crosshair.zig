const Self = @This();

const rl = @import("raylib");
const gui = @import("../gui.zig");
const blocks = @import("../../map/blocks.zig");
const std = @import("std");
const Context = @import("../../Context.zig");

visible: bool = true,
size: i32,

pub fn create(allocator: std.mem.Allocator, size: i32) !*Self {
    const crosshair: *Self = try allocator.create(Self);

    crosshair.* = .{
        .size = size,
    };

    return crosshair;
}

pub fn destroy(self: *const Self, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn render(self: *Self) void {
    if (!self.visible) return;

    const screenWidth: i32 = rl.getScreenWidth();
    const screenHeight: i32 = rl.getScreenHeight();
    const centerX: i32 = @divExact(screenWidth, 2);
    const centerY: i32 = @divExact(screenHeight, 2);
    const color: rl.Color = rl.Color.black;

    // Draw vertical and horizontal lines
    rl.drawLine(centerX - self.size, centerY, centerX + self.size, centerY, color); // Horizontal
    rl.drawLine(centerX, centerY - self.size, centerX, centerY + self.size, color); // Vertical

}
