const Self = @This();
const root = @import("root");
const rl = @import("raylib");
const gui = @import("../gui.zig");
const std = @import("std");

const State = enum {
    disabled,
    default,
};

pub const InitArgs = struct {
    pos: rl.Rectangle,
    texture: rl.Texture,
};

pos: rl.Rectangle,
texture: rl.Texture,
state: State = .default,

pub fn init(args: InitArgs) Self {
    return Self{
        .pos = args.pos,
        .texture = args.texture,
        .state = .default,
    };
}

pub fn render(self: *const Self) void {
    const sourceRect: rl.Rectangle = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(self.texture.width),
        .height = @floatFromInt(self.texture.height),
    };

    rl.drawTexturePro(self.texture, sourceRect, self.pos, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.Color.white);
}
