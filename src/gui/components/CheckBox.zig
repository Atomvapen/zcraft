const Self = @This();
const root = @import("root");
const rl = @import("raylib");
const gui = @import("../gui.zig");
const std = @import("std");

const State = enum {
    disabled,
    default,
    hovered,
    pressed,
};

pub const InitArgs = struct {
    pos: rl.Rectangle,
    text: [:0]const u8,
    fontSize: i32,
    value: *bool,
};

pos: rl.Rectangle,
text: [:0]const u8,
fontSize: i32,
value: *bool,
state: State,

pub fn init(args: InitArgs) Self {
    return Self{
        .pos = args.pos,
        .text = args.text,
        .fontSize = args.fontSize,
        .value = args.value,
        .state = .default,
    };
}

pub fn render(self: *Self) void {
    const sourceRect: rl.Rectangle = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(gui.Textures.get(.checkBox).width),
        .height = @floatFromInt(gui.Textures.get(.checkBox).height),
    };

    const texture = switch (self.state) {
        .disabled => gui.Textures.get(.checkBox),
        .default, .pressed => if (self.value.*) gui.Textures.get(.checkBoxChecked) else gui.Textures.get(.checkBox),
        .hovered => if (self.value.*) gui.Textures.get(.checkBoxCheckedHovered) else gui.Textures.get(.checkBoxHovered),
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
