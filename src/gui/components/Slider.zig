const Self = @This();
const root = @import("root");
const rl = @import("raylib");
const gui = @import("../gui.zig");
const std = @import("std");

const State = enum {
    disabled,
    default,
    hovered,
    dragging,
};

pos: rl.Rectangle,
minValue: f32,
maxValue: f32,
value: *f32,
thumbWidth: f32,
state: State = .default,
step: f32,

pub const InitArgs = struct {
    pos: rl.Rectangle,
    minValue: f32,
    maxValue: f32,
    value: *f32,
    thumbWidth: f32,
    step: f32,
};

pub fn init(args: InitArgs) Self {
    return Self{
        .pos = args.pos,
        .minValue = args.minValue,
        .maxValue = args.maxValue,
        .value = args.value,
        .thumbWidth = args.thumbWidth,
        .step = args.step,
        .state = .default,
    };
}

pub fn render(self: *Self) void {
    { // Track
        const sourceRect: rl.Rectangle = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(gui.Textures.get(.button).width),
            .height = @floatFromInt(gui.Textures.get(.button).height),
        };
        rl.drawTexturePro(gui.Textures.get(.button), sourceRect, self.pos, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.Color.white);
    }

    { // Thumb
        // Calculate the thumb's position based on the current value
        const thumbPosX: f32 = self.pos.x + (self.value.* - self.minValue) / (self.maxValue - self.minValue) * self.pos.width - self.thumbWidth / 2;

        // Draw the thumb (the part that the user drags)
        const thumbRect = rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(gui.Textures.get(.sliderThumb).width), .height = @floatFromInt(gui.Textures.get(.sliderThumb).height) };
        const thumbHoverScalar: f32 = if (self.state == .hovered or self.state == .dragging) 1.05 else 1.0;
        const scaledRect = rl.Rectangle{ .x = thumbPosX, .y = self.pos.y - (thumbRect.height * (thumbHoverScalar - 1.0) / 2), .width = self.thumbWidth * thumbHoverScalar, .height = thumbRect.height * thumbHoverScalar };
        rl.drawTexturePro(if (self.state == .hovered or self.state == .dragging) gui.Textures.get(.sliderThumbHovered) else gui.Textures.get(.sliderThumb), thumbRect, scaledRect, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.Color.white);

        // Draw the current value text
        var buffer: [20]u8 = undefined;
        const valueText: [:0]const u8 = std.fmt.bufPrintZ(&buffer, "{d}", .{@as(i32, @intFromFloat(self.value.*))}) catch "";
        const scaledFont: i32 = if (self.state == .hovered or self.state == .dragging) 15 + 3 else 15;
        const textWidth: f32 = @as(f32, @floatFromInt(rl.measureText(valueText, scaledFont)));
        const textX: f32 = thumbPosX + (thumbRect.width - textWidth) / 2;
        const textY: f32 = self.pos.y + (thumbRect.height - @as(f32, @floatFromInt(scaledFont))) / 2;
        rl.drawText(valueText, @intFromFloat(textX), @intFromFloat(textY), scaledFont, rl.Color.black);
    }
}

pub fn update(self: *Self) void {
    if (self.state == .disabled) return;
    const mousePos = rl.getMousePosition();
    self.state = if (rl.checkCollisionPointRec(mousePos, self.pos)) .hovered else .default;

    if (self.state == .hovered and rl.isMouseButtonDown(.left)) self.state = .dragging;

    if (self.state == .dragging) {
        const newThumbPosX = mousePos.x - self.pos.x;
        // Calculate the new value
        self.value.* = self.minValue + newThumbPosX / self.pos.width * (self.maxValue - self.minValue);

        // Snap the value to the nearest step
        if (self.step != 0.0) self.value.* = @round(self.value.* / self.step) * self.step;

        // Clamp value to [minValue, maxValue]
        self.value.* = @min(self.maxValue, @max(self.minValue, self.value.*));
    }

    if (rl.isMouseButtonReleased(.left)) self.state = .default;
}
