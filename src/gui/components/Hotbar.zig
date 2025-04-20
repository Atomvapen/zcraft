const Self = @This();
const root = @import("root");
const rl = @import("raylib");
const gui = @import("../gui.zig");
const blocks = @import("../../map/blocks.zig");
const std = @import("std");
const Context = @import("../../Context.zig");

pub const InitArgs = struct {
    selection: *u8,
    pos: rl.Rectangle,
    ctx: *Context,
};

selection: *u8,
pos: rl.Rectangle,
ctx: *Context,

pub fn init(args: InitArgs) Self {
    return Self{
        .selection = args.selection,
        .pos = args.pos,
        .ctx = args.ctx,
    };
}

pub fn render(self: *Self) void {
    const inventory = self.ctx.player.inventory;

    if (!inventory.hotbar.visible) return;
    const scalar: f32 = 0.25;

    const screenWidth: f32 = @floatFromInt(rl.getScreenWidth());
    const screenHeight: f32 = @floatFromInt(rl.getScreenHeight());
    const slotWidth: f32 = @floatFromInt(gui.Textures.get(.slot).width);
    const slotHeight: f32 = @floatFromInt(gui.Textures.get(.slot).height);

    const sourceRect = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = slotWidth,
        .height = slotHeight,
    };
    const barCenterX = screenWidth / 2.0;
    const slotSpacing = slotWidth * scalar;
    const posY = screenHeight - (slotHeight * scalar); // - 10.0;
    const hotbarItemsLen: i32 = inventory.items[0].len;

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
            if (isSelected) gui.Textures.get(.slotActive) else gui.Textures.get(.slot),
            sourceRect,
            destRect,
            rl.Vector2{ .x = 0, .y = 0 },
            0,
            rl.Color.white,
        );

        { // Icon

            const blockIndex = inventory.items[0][i];
            const block = blocks.Block.fromInt(blockIndex.id);
            if (@intFromEnum(block.id) == 0) continue;
            const texture = block.getIcon() catch continue;

            const iconSource = rl.Rectangle{
                .x = 0,
                .y = 0,
                .width = @floatFromInt(texture.width),
                .height = @floatFromInt(texture.height),
            };

            const iconScale: f32 = (scaledWidth * 0.5) / @as(f32, @floatFromInt(texture.height));
            const iconDest = rl.Rectangle{
                .x = destRect.x + (destRect.width - (iconSource.width * iconScale)) / 2.0,
                .y = destRect.y + (destRect.height - (iconSource.height * iconScale)) / 2.0,
                .width = iconSource.width * iconScale,
                .height = iconSource.height * iconScale,
            };

            rl.drawTexturePro(
                texture.*,
                iconSource,
                iconDest,
                rl.Vector2{ .x = 0, .y = 0 },
                0,
                rl.Color.white,
            );

            const amount = blockIndex.amount;
            if (amount > 1) {
                var amountBuf: [8]u8 = undefined;
                const amountText: [:0]u8 = std.fmt.bufPrintZ(amountBuf[0..], "{}", .{amount}) catch continue;
                const fontSize: i32 = 24;
                const textWidth: i32 = rl.measureText(amountText, fontSize);

                rl.drawText(
                    amountText,
                    @intFromFloat(destRect.x + destRect.width - @as(f32, @floatFromInt(textWidth)) - 2),
                    @intFromFloat(destRect.y + destRect.height - @as(f32, fontSize) - 2),
                    fontSize,
                    rl.Color.white,
                );
            }
        }
    }
}
