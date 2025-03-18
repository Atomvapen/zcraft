const Self = @This();

const rl = @import("raylib");
const gui = @import("../gui.zig");
const std = @import("std");

const slots: i32 = 9;

selection: *u8,
pos: rl.Rectangle,

pub fn create(allocator: std.mem.Allocator, selection: *u8) !*Self {
    const slot: *Self = try allocator.create(Self);

    slot.* = .{
        .pos = .{ .x = 0, .y = 0, .width = 0, .height = 0 },
        .selection = selection,
    };

    return slot;
}

pub fn destroy(self: *const Self, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn render(self: *Self) void {
    const scalar: f32 = 0.25;

    const screenWidth: f32 = @floatFromInt(rl.getScreenWidth());
    const screenHeight: f32 = @floatFromInt(rl.getScreenHeight());
    const slotWidth: f32 = @floatFromInt(gui.Textures.slot.width);
    const slotHeight: f32 = @floatFromInt(gui.Textures.slot.height);

    const sourceRect = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = slotWidth,
        .height = slotHeight,
    };
    const barCenterX = screenWidth / 2.0;
    const slotSpacing = slotWidth * scalar;
    const posY = screenHeight - (slotHeight * scalar); // - 10.0;

    for (1..slots + 1) |i| {
        const isSelected = (i == @as(usize, self.selection.*));
        const scale: f32 = if (isSelected) 1.05 else 1.0;
        const scaledWidth = slotWidth * scalar * scale;
        const scaledHeight = slotHeight * scalar * scale;

        const offset = @as(f32, @floatFromInt(i - 1)) - ((@as(f32, @floatFromInt(slots)) - 1.0) / 2.0);
        const slotPosX = barCenterX + offset * slotSpacing;

        const destRect = rl.Rectangle{
            .x = slotPosX - scaledWidth / 2.0,
            .y = posY - scaledHeight / 2.0,
            .width = scaledWidth,
            .height = scaledHeight,
        };

        rl.drawTexturePro(
            if (isSelected) gui.Textures.slotActive else gui.Textures.slot,
            sourceRect,
            destRect,
            rl.Vector2{ .x = 0, .y = 0 },
            0,
            rl.Color.white,
        );

        {
            const iconSource = rl.Rectangle{
                .x = 0,
                .y = 0,
                .width = @floatFromInt(gui.Textures.dirtFlat.width),
                .height = @floatFromInt(gui.Textures.dirtFlat.height),
            };

            const iconScale: f32 = (scaledWidth * 0.5) / @as(f32, @floatFromInt(gui.Textures.dirtFlat.width));
            const iconDest = rl.Rectangle{
                .x = destRect.x + (destRect.width - (iconSource.width * iconScale)) / 2.0,
                .y = destRect.y + (destRect.height - (iconSource.height * iconScale)) / 2.0,
                .width = iconSource.width * iconScale,
                .height = iconSource.height * iconScale,
            };

            rl.drawTexturePro(
                gui.Textures.dirtFlat,
                iconSource,
                iconDest,
                rl.Vector2{ .x = 0, .y = 0 },
                0,
                rl.Color.white,
            );
        }
    }
}
