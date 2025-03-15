const rl = @import("raylib");
const gui = @import("../gui.zig");
const std = @import("std");

const Slider = @This();

pos: rl.Rectangle,
minValue: f32,
maxValue: f32,
currentValue: *f32,
thumbWidth: f32,
isDragging: bool,

pub fn init(allocator: std.mem.Allocator, pos: rl.Rectangle, minValue: f32, maxValue: f32, initialValue: *f32, thumbWidth: f32) !*Slider {
    const slider: *Slider = try allocator.create(Slider);

    slider.* = .{
        .pos = pos,
        .minValue = minValue,
        .maxValue = maxValue,
        .currentValue = initialValue,
        .thumbWidth = thumbWidth,
        .isDragging = false,
    };

    return slider;
}

pub fn draw(self: *Slider) void {
    // Draw the track (the background of the slider)
    const srcRect: rl.Rectangle = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(gui.Textures.buttonTexture.width),
        .height = @floatFromInt(gui.Textures.buttonTexture.height),
    };
    rl.drawTexturePro(gui.Textures.buttonTexture, srcRect, self.pos, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.Color.white);

    // rl.drawRectangleV(.{ .x = self.pos.x, .y = self.pos.y }, rl.Vector2{ .x = self.pos.width, .y = self.pos.height }, rl.Color{ .r = 200, .g = 200, .b = 200, .a = 255 });

    // Calculate the thumb's position based on the current value
    const thumbPosX: f32 = self.pos.x + (self.currentValue.* - self.minValue) / (self.maxValue - self.minValue) * self.pos.width - self.thumbWidth / 2;

    // Draw the thumb (the part that the user drags)
    // rl.drawRectangle(@intFromFloat(thumbPosX), @intFromFloat(self.pos.y), @intFromFloat(self.thumbWidth), @intFromFloat(self.pos.height), rl.Color{ .r = 100, .g = 100, .b = 100, .a = 255 });
    const thumb = rl.Rectangle{ .x = thumbPosX, .y = self.pos.y, .width = self.thumbWidth, .height = self.pos.height };
    rl.drawTexturePro(if (self.isHovered()) gui.Textures.buttonHoveredTexture else gui.Textures.buttonTexture, srcRect, thumb, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.Color.white);

    // Optionally, draw the current value text
    const valueText = "Value: "; // ++ @as([]u8, @intToString(self.currentValue, 10));
    rl.drawText(valueText, @intFromFloat(self.pos.x + 5), @intFromFloat(self.pos.y + 5), 20, rl.Color.black);
}

pub fn update(self: *Slider) void {
    const mousePos = rl.getMousePosition();

    // Check if the mouse is over the slider track
    if (rl.checkCollisionPointRec(mousePos, self.pos) and rl.isMouseButtonDown(.left)) {
        // Start dragging if the mouse is clicked inside the slider track
        self.isDragging = true;
    }

    if (self.isDragging) {
        // Calculate the new value based on mouse X position
        const newThumbPosX = mousePos.x - self.pos.x;
        self.currentValue.* = self.minValue + newThumbPosX / self.pos.width * (self.maxValue - self.minValue);
        self.currentValue.* = @min(self.maxValue, @max(self.minValue, self.currentValue.*)); // Clamp value to [minValue, maxValue]
    }

    // Stop dragging when the mouse button is released
    if (rl.isMouseButtonReleased(.left)) {
        self.isDragging = false;
    }

    std.debug.print("{any}\n", .{self.currentValue.*});
}

pub fn isHovered(self: *Slider) bool {
    const mousePos = rl.getMousePosition();
    return rl.checkCollisionPointRec(mousePos, self.pos);
}
