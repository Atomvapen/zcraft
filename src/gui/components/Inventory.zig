const Self = @This();
const root = @import("root");
const rl = @import("raylib");
const gui = @import("../gui.zig");
const Context = @import("../../Context.zig");

pub const InitArgs = struct {
    pos: rl.Rectangle,
    ctx: *Context,
};

pos: rl.Rectangle,
ctx: *Context,

pub fn init(args: InitArgs) Self {
    return Self{
        .pos = args.pos,
        .ctx = args.ctx,
    };
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

    // Save for hover checks
    self.pos = destRect;

    rl.drawTexturePro(
        gui.Textures.inventory,
        sourceRect,
        destRect,
        rl.Vector2{ .x = 0, .y = 0 },
        0,
        rl.Color.white,
    );

    { // Highlighting
        const mouse = rl.getMousePosition();

        // Main Inventory
        drawSlotGrid(destRect.x + 7.0 * inventoryScale, destRect.y + 84.0 * inventoryScale, 9, 3, inventoryScale, mouse);

        // Hotbar
        drawSlotGrid(destRect.x + 7.0 * inventoryScale, destRect.y + 142.0 * inventoryScale, 9, 1, inventoryScale, mouse);

        // Armor
        drawSlotGrid(destRect.x + 7.0 * inventoryScale, destRect.y + 7.0 * inventoryScale, 1, 4, inventoryScale, mouse);
        drawSingleSlot(destRect.x + 76.0 * inventoryScale, destRect.y + 62.0 * inventoryScale, inventoryScale, mouse);

        // Crafting Grid
        drawSlotGrid(destRect.x + 97.0 * inventoryScale, destRect.y + 17.0 * inventoryScale, 2, 2, inventoryScale, mouse);

        // Crafting Result
        drawSingleSlot(destRect.x + 139.0 * inventoryScale, destRect.y + 35.0 * inventoryScale, inventoryScale, mouse);
    }
}

fn drawSlotGrid(start_x: f32, start_y: f32, cols: u32, rows: u32, scale: f32, mouse: rl.Vector2) void {
    const slot_size = 18.0 * scale;
    for (0..rows) |row| {
        for (0..cols) |col| {
            const x = start_x + @as(f32, @floatFromInt(col)) * slot_size;
            const y = start_y + @as(f32, @floatFromInt(row)) * slot_size;

            const rect = rl.Rectangle{ .x = x, .y = y, .width = slot_size, .height = slot_size };
            if (rl.checkCollisionPointRec(mouse, rect)) {
                rl.drawRectangleRec(rect, rl.Color{ .r = 255, .g = 255, .b = 255, .a = 80 });
            }
        }
    }
}

fn drawSingleSlot(x: f32, y: f32, scale: f32, mouse: rl.Vector2) void {
    const size = 18.0 * scale;
    const rect = rl.Rectangle{ .x = x, .y = y, .width = size, .height = size };
    if (rl.checkCollisionPointRec(mouse, rect)) {
        rl.drawRectangleRec(rect, rl.Color{ .r = 255, .g = 255, .b = 255, .a = 80 });
    }
}

// pub fn render(self: *Self) void {
//     const inventory = self.ctx.player.inventory;
//     if (!inventory.open) return;

//     const screenWidth: f32 = @floatFromInt(rl.getScreenWidth());
//     const screenHeight: f32 = @floatFromInt(rl.getScreenHeight());
//     const inventoryWidth: f32 = @floatFromInt(gui.Textures.inventory.width);
//     const inventoryHeight: f32 = @floatFromInt(gui.Textures.inventory.height);

//     const sourceRect = rl.Rectangle{
//         .x = 0,
//         .y = 0,
//         .width = inventoryWidth,
//         .height = inventoryHeight,
//     };
//     const centerX = screenWidth / 2.0;
//     const centerY = screenHeight / 2.0;

//     const inventoryScale: f32 = 2.5;
//     const inventoryDrawWidth = inventoryWidth * inventoryScale;
//     const inventoryDrawHeight = inventoryHeight * inventoryScale;

//     const destRect = rl.Rectangle{
//         .x = centerX - inventoryDrawWidth / 2.0,
//         .y = centerY - inventoryDrawHeight / 2.0,
//         .width = inventoryDrawWidth,
//         .height = inventoryDrawHeight,
//     };

//     // Save for hover checks
//     self.pos = destRect;

//     rl.drawTexturePro(
//         gui.Textures.inventory,
//         sourceRect,
//         destRect,
//         rl.Vector2{ .x = 0, .y = 0 },
//         0,
//         rl.Color.white,
//     );

//     // Slot hover highlight (assuming 9x3 inventory grid)
//     // const rows: i32 = 3;
//     // const cols: i32 = 9;
//     // const slot_size: f32 = 17.0; // original texture pixel size of a slot
//     // const slot_spacing: f32 = 1.0; // adjust if spacing exists in texture

//     // const slot_scaled = slot_size * inventoryScale;
//     // const spacing_scaled = slot_spacing * inventoryScale;

//     const slots_start_x = destRect.x + 7.0 * inventoryScale;
//     const slots_start_y = destRect.y + 84.0 * inventoryScale;

//     const mouse = rl.getMousePosition();

//     // Main Inventory
//     drawSlotGrid(slots_start_x, slots_start_y, 9, 3, inventoryScale, mouse, inventory);

//     // Hotbar
//     drawSlotGrid(destRect.x + 7.0 * inventoryScale, destRect.y + 142.0 * inventoryScale, 9, 1, inventoryScale, mouse, inventory);

//     // Armor
//     drawSlotGrid(destRect.x + 7.0 * inventoryScale, destRect.y + 7.0 * inventoryScale, 1, 4, inventoryScale, mouse, inventory);
//     drawSingleSlot(destRect.x + 62.0 * inventoryScale, destRect.y + 62.0 * inventoryScale, inventoryScale, mouse, inventory);

//     // Crafting Grid
//     drawSlotGrid(destRect.x + 97.0 * inventoryScale, destRect.y + 17.0 * inventoryScale, 2, 2, inventoryScale, mouse, inventory);

//     // Crafting Result
//     drawSingleSlot(destRect.x + 139.0 * inventoryScale, destRect.y + 35.0 * inventoryScale, inventoryScale, mouse, inventory);
// }

// fn drawSlotGrid(start_x: f32, start_y: f32, cols: u32, rows: u32, scale: f32, mouse: rl.Vector2, inventory: Inventory) void {
//     const slot_size = 18.0 * scale;
//     for (0..rows - 1) |row| {
//         for (0..cols - 1) |col| {
//             const x = start_x + @as(f32, @floatFromInt(col)) * slot_size;
//             const y = start_y + @as(f32, @floatFromInt(row)) * slot_size;

//             const rect = rl.Rectangle{ .x = x, .y = y, .width = slot_size, .height = slot_size };
//             if (rl.checkCollisionPointRec(mouse, rect)) {
//                 rl.drawRectangleRec(rect, rl.Color{ .r = 255, .g = 255, .b = 255, .a = 80 });
//             }

//             // Block Icon Rendering for Inventory Slots
//             const blockIndex = inventory.items[row][col];
//             const block = blocks.Block.fromInt(blockIndex.id);
//             if (@intFromEnum(block.id) == 0) continue; // Skip if the block id is 0 (empty slot)
//             const texture = block.getIcon() catch continue;

//             const iconSource = rl.Rectangle{
//                 .x = 0,
//                 .y = 0,
//                 .width = @floatFromInt(texture.width),
//                 .height = @floatFromInt(texture.height),
//             };

//             const iconScale: f32 = (slot_size * 0.5) / @as(f32, @floatFromInt(texture.height));
//             const iconDest = rl.Rectangle{
//                 .x = rect.x + (rect.width - (iconSource.width * iconScale)) / 2.0,
//                 .y = rect.y + (rect.height - (iconSource.height * iconScale)) / 2.0,
//                 .width = iconSource.width * iconScale,
//                 .height = iconSource.height * iconScale,
//             };

//             rl.drawTexturePro(
//                 texture.*,
//                 iconSource,
//                 iconDest,
//                 rl.Vector2{ .x = 0, .y = 0 },
//                 0,
//                 rl.Color.white,
//             );

//             const amount = blockIndex.amount;
//             if (amount > 1) {
//                 var amountBuf: [8]u8 = undefined;
//                 const amountText: [:0]u8 = std.fmt.bufPrintZ(amountBuf[0..], "{}", .{amount}) catch continue;
//                 const fontSize: i32 = 24;
//                 const textWidth: i32 = rl.measureText(amountText, fontSize);

//                 rl.drawText(
//                     amountText,
//                     @intFromFloat(rect.x + rect.width - @as(f32, @floatFromInt(textWidth)) - 2),
//                     @intFromFloat(rect.y + rect.height - @as(f32, fontSize) - 2),
//                     fontSize,
//                     rl.Color.white,
//                 );
//             }
//         }
//     }
// }

// fn drawSingleSlot(x: f32, y: f32, scale: f32, mouse: rl.Vector2, inventory: Inventory) void {
//     const size = 18.0 * scale;
//     const rect = rl.Rectangle{ .x = x, .y = y, .width = size, .height = size };
//     if (rl.checkCollisionPointRec(mouse, rect)) {
//         rl.drawRectangleRec(rect, rl.Color{ .r = 255, .g = 255, .b = 255, .a = 80 });
//     }

//     // Block Icon Rendering for Single Slot
//     const blockIndex = inventory.items[0][0]; // Assuming a single item in the slot, you can modify accordingly
//     const block = blocks.Block.fromInt(blockIndex.id);
//     if (@intFromEnum(block.id) == 0) return; // Skip if the block id is 0 (empty slot)
//     const texture = block.getIcon() catch return;

//     const iconSource = rl.Rectangle{
//         .x = 0,
//         .y = 0,
//         .width = @floatFromInt(texture.width),
//         .height = @floatFromInt(texture.height),
//     };

//     const iconScale: f32 = (size * 0.5) / @as(f32, @floatFromInt(texture.height));
//     const iconDest = rl.Rectangle{
//         .x = rect.x + (rect.width - (iconSource.width * iconScale)) / 2.0,
//         .y = rect.y + (rect.height - (iconSource.height * iconScale)) / 2.0,
//         .width = iconSource.width * iconScale,
//         .height = iconSource.height * iconScale,
//     };

//     rl.drawTexturePro(
//         texture.*,
//         iconSource,
//         iconDest,
//         rl.Vector2{ .x = 0, .y = 0 },
//         0,
//         rl.Color.white,
//     );
// }
