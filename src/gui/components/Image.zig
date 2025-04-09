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
state: State = .default,
texture: rl.Texture,

pub fn create(pos: rl.Rectangle, texture: rl.Texture) !*Self {
    const image: *Self = try root.allocator.create(Self);

    image.* = .{
        .pos = pos,
        .texture = texture,
    };

    return image;
}

pub fn destroy(self: *const Self) void {
    root.allocator.destroy(self);
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
