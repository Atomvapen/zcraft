const Self = @This();

const rl = @import("raylib");
const gui = @import("../gui.zig");
const blocks = @import("../../map/blocks.zig");
const std = @import("std");
const Context = @import("../../Context.zig");

selection: *u8,
pos: rl.Rectangle,
ctx: *Context,

pub fn create(allocator: std.mem.Allocator, selection: *u8, ctx: *Context) !*Self {
    const slot: *Self = try allocator.create(Self);

    slot.* = .{
        .pos = .{ .x = 0, .y = 0, .width = 0, .height = 0 },
        .selection = selection,
        .ctx = ctx,
    };

    return slot;
}

pub fn destroy(self: *const Self, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn render(self: *Self) void {
    if (!self.ctx.player.hotbar.visible) return;
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
    const hotbarItemsLen: i32 = self.ctx.player.hotbar.items.len;

    for (0..hotbarItemsLen) |i| {
        const isSelected = (i == @as(usize, self.selection.*));
        const scale: f32 = if (isSelected) 1.05 else 1.0;
        const scaledWidth = slotWidth * scalar * scale;
        const scaledHeight = slotHeight * scalar * scale;

        const offset = @as(f32, @floatFromInt(i)) - ((@as(f32, @floatFromInt(hotbarItemsLen)) - 1.0) / 2.0);
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

        { // Icon
            const blockIndex = self.ctx.player.hotbar.items[i];
            if (!blocks.Type.hasIcon(@intCast(blockIndex))) continue;

            const iconSource = rl.Rectangle{
                .x = 0,
                .y = 0,
                .width = @floatFromInt(blocks.list[blockIndex].width),
                .height = @floatFromInt(blocks.list[blockIndex].height),
            };

            const iconScale: f32 = (scaledWidth * 0.5) / @as(f32, @floatFromInt(blocks.list[blockIndex].width));
            const iconDest = rl.Rectangle{
                .x = destRect.x + (destRect.width - (iconSource.width * iconScale)) / 2.0,
                .y = destRect.y + (destRect.height - (iconSource.height * iconScale)) / 2.0,
                .width = iconSource.width * iconScale,
                .height = iconSource.height * iconScale,
            };

            rl.drawTexturePro(
                blocks.list[blockIndex],
                iconSource,
                iconDest,
                rl.Vector2{ .x = 0, .y = 0 },
                0,
                rl.Color.white,
            );
        }
    }
}
