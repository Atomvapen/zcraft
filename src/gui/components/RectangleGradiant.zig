const Self = @This();
const root = @import("root");
const rl = @import("raylib");
const gui = @import("../gui.zig");
const std = @import("std");

const State = enum {
    disabled,
    default,
};

pos: rl.Rectangle,
state: State,
topColor: rl.Color,
botColor: rl.Color,

pub const InitArgs = struct {
    pos: rl.Rectangle,
    topColor: rl.Color,
    botColor: rl.Color,
};

pub fn init(args: InitArgs) Self {
    return Self{
        .pos = args.pos,
        .topColor = args.topColor,
        .botColor = args.botColor,
        .state = .default,
    };
}

pub fn render(self: *const Self) void {
    rl.drawRectangleGradientV(@intFromFloat(self.pos.x), @intFromFloat(self.pos.y), @intFromFloat(self.pos.width), @intFromFloat(self.pos.height), self.topColor, self.botColor);
}
