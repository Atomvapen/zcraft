const Self = @This();
const root = @import("root");
const rl = @import("raylib");
const gui = @import("../gui.zig");
const blocks = @import("../../map/blocks.zig");
const std = @import("std");
const Context = @import("../../Context.zig");

pos: rl.Rectangle,
ctx: *Context,

pub fn create(ctx: *Context) !*Self {
    const slot: *Self = try root.allocator.create(Self);

    slot.* = .{
        .pos = .{ .x = 0, .y = 0, .width = 0, .height = 0 },
        .ctx = ctx,
    };

    return slot;
}

pub fn destroy(self: *const Self) void {
    root.allocator.destroy(self);
}

pub fn render(self: *Self) void {
    const inventory = self.ctx.player.inventory;
    if (!inventory.open) return;

    const screenWidth: f32 = @floatFromInt(rl.getScreenWidth());
    const screenHeight: f32 = @floatFromInt(rl.getScreenHeight());
    const inventoryWidth: f32 = @floatFromInt(gui.Textures.inventory.width);
    const inventoryHeight: f32 = @floatFromInt(gui.Textures.inventory.height);

    const sourceRect = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = inventoryWidth,
        .height = inventoryHeight,
    };
    const centerX = screenWidth / 2.0;
    const centerY = screenHeight / 2.0;

    const inventoryScale: f32 = 2.5;
    const inventoryDrawWidth = inventoryWidth * inventoryScale;
    const inventoryDrawHeight = inventoryHeight * inventoryScale;

    const destRect = rl.Rectangle{
        .x = centerX - inventoryDrawWidth / 2.0,
        .y = centerY - inventoryDrawHeight / 2.0,
        .width = inventoryDrawWidth,
        .height = inventoryDrawHeight,
    };

    rl.drawTexturePro(
        gui.Textures.inventory,
        sourceRect,
        destRect,
        rl.Vector2{ .x = 0, .y = 0 },
        0,
        rl.Color.white,
    );
}
