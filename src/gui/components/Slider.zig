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

pub fn create(allocator: std.mem.Allocator, pos: rl.Rectangle, minValue: f32, maxValue: f32, initialValue: *f32, thumbWidth: f32) !*Slider {
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

pub fn destroy(self: *const Slider, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn render(self: *Slider) void {
    { // Track
        const srcRect: rl.Rectangle = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(gui.Textures.button.width),
            .height = @floatFromInt(gui.Textures.button.height),
        };
        rl.drawTexturePro(gui.Textures.button, srcRect, self.pos, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.Color.white);
    }

    { // Thumb
        // Calculate the thumb's position based on the current value
        const thumbPosX: f32 = self.pos.x + (self.currentValue.* - self.minValue) / (self.maxValue - self.minValue) * self.pos.width - self.thumbWidth / 2;

        // Draw the thumb (the part that the user drags)
        const thumb = rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(gui.Textures.sliderThumb.width), .height = @floatFromInt(gui.Textures.sliderThumb.height) };
        const hoverScale: f32 = if (self.isHovered()) 1.05 else 1.0;
        const scaledPos = rl.Rectangle{ .x = thumbPosX, .y = self.pos.y - (thumb.height * (hoverScale - 1.0) / 2), .width = self.thumbWidth * hoverScale, .height = thumb.height * hoverScale };
        rl.drawTexturePro(if (self.isHovered()) gui.Textures.sliderThumbHovered else gui.Textures.sliderThumb, thumb, scaledPos, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.Color.white);

        // Draw the current value text
        var buffer: [20]u8 = undefined;
        const valueText: [:0]const u8 = std.fmt.bufPrintZ(&buffer, "{d}", .{self.currentValue.*}) catch "";
        const scaledFont: i32 = if (self.isHovered()) 15 + 3 else 15;
        const textWidth: f32 = @as(f32, @floatFromInt(rl.measureText(valueText, scaledFont)));
        const textX: f32 = thumbPosX + (thumb.width - textWidth) / 2;
        const textY: f32 = self.pos.y + (thumb.height - @as(f32, @floatFromInt(scaledFont))) / 2;
        rl.drawText(valueText, @intFromFloat(textX), @intFromFloat(textY), scaledFont, rl.Color.black);
    }
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

    // std.debug.print("{any}\n", .{self.currentValue.*});
}

pub fn isHovered(self: *Slider) bool {
    const mousePos = rl.getMousePosition();
    return rl.checkCollisionPointRec(mousePos, self.pos);
}
