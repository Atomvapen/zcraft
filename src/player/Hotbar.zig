const Self = @This();
const rl = @import("raylib");
const inventeory = @import("Inventory.zig");

const slots: i32 = 9;

items: [slots]u8 = undefined,
selection: u8 = 0,
visible: bool = true,

pub fn setSelection(self: *Self, index: u8) void {
    if (index >= slots) return;
    self.selection = index;
}

pub fn getSelection(self: *Self) u8 {
    return self.selection;
}

pub fn setSlot(self: *Self, index: u8, block: u8) void {
    if (index >= slots) return;
    self.items[index] = block;
}

pub fn getSlot(self: *Self, index: u8) u8 {
    if (index >= slots) return;
    return self.items[index];
}

pub fn setRow(self: *Self, items: [slots]u8) void {
    if (items.len != slots) return;
    for (items) |item| {
        if (item >= slots) return;
    }
    self.items = items;
}
