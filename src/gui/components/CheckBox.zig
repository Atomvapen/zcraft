const Self = @This();

const rl = @import("raylib");
const gui = @import("../gui.zig");
const std = @import("std");

const State = enum {
    disabled,
    default,
    hovered,
    pressed,
};

pos: rl.Rectangle,
text: [:0]const u8,
fontSize: i32,
value: *bool = undefined,
state: State = .default,

pub fn create(allocator: std.mem.Allocator, text: [:0]const u8, fontSize: i32, pos: rl.Rectangle, value: *bool) !*Self {
    const checkBox: *Self = try allocator.create(Self);

    checkBox.* = .{
        .pos = pos,
        .text = text,
        .fontSize = fontSize,
        .value = value,
    };

    return checkBox;
}

pub fn destroy(self: *const Self, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn render(self: *Self) void {
    const sourceRect: rl.Rectangle = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(gui.Textures.checkBox.width),
        .height = @floatFromInt(gui.Textures.checkBox.height),
    };

    const texture = switch (self.state) {
        .disabled => gui.Textures.checkBox,
        .default, .pressed => if (self.value.*) gui.Textures.checkBoxChecked else gui.Textures.checkBox,
        .hovered => if (self.value.*) gui.Textures.checkBoxCheckedHovered else gui.Textures.checkBoxHovered,
    };

    rl.drawTexturePro(texture, sourceRect, self.pos, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.Color.white);
}

pub fn update(self: *Self) void {
    if (self.state == .disabled) return;
    const mousePos = rl.getMousePosition();
    self.state = if (rl.checkCollisionPointRec(mousePos, self.pos)) .hovered else .default;
    if (self.state == .hovered and rl.isMouseButtonPressed(.left)) self.state = .pressed;
    if (self.state == .pressed) self.value.* = !self.value.*;
}
