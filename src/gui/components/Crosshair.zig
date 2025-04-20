const Self = @This();
const root = @import("root");
const rl = @import("raylib");
const gui = @import("../gui.zig");
const std = @import("std");

pub const InitArgs = struct {
    visible: bool,
    size: i32,
};

visible: bool,
size: i32,

pub fn init(args: InitArgs) Self {
    return Self{
        .size = args.size,
        .visible = args.visible,
    };
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
