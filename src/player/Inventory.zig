const Self = @This();
const std = @import("std");
const Block = @import("../map/blocks.zig").Block;

const rows: i32 = 3;
const columns: i32 = 9;

items: [rows][columns]Item = undefined,
hotbar: Hotbar = .{},
open: bool = false,

const Kind = enum(u8) {
    block,
    // Tool,
    // Consumable,
};

// TODO: Item should be a union
const Item = struct {
    id: u8,
    amount: i32,
    kind: Kind = .block,
};

const Position = struct {
    row: u8,
    col: u8,
};

const Command = enum(8) {
    open = 0,
    close,
    deposit,
    drop = 5,
    clear = 8,
};

pub const Hotbar = struct {
    selection: u8 = 0,
    visible: bool = true,

    pub fn setSelection(inventory: *Self, index: u8) void {
        if (index >= columns) return;
        inventory.hotbar.selection = index;
    }

    pub fn getSelection(inventory: *Self) u8 {
        return inventory.hotbar.selection;
    }

    pub fn setSlot(inventory: *Self, index: u8, block: u8, amount: i32) void {
        if (index >= columns) return;
        inventory.items[0][index].id = block;
        inventory.items[0][index].amount = amount;
    }

    pub fn getSlot(inventory: *Self, index: u8) Item {
        if (index >= columns) return;
        return inventory.items[0][index];
    }
};

pub fn contains(self: *Self, b: u8) ?Position {
    for (0..rows) |r| for (0..columns) |c| {
        if (self.items[r][c].id == b and self.items[r][c].amount > 0) {
            return .{ .row = @intCast(r), .col = @intCast(c) };
        }
    };
    return null;
}

pub fn swap(self: *Self, from: Position, to: Position) void {
    std.debug.assert(from.row < rows and from.col < columns);
    std.debug.assert(to.row < rows and to.col < columns);

    const tmp: Item = self.items[to.row][to.col];
    self.items[to.row][to.col] = self.items[from.row][from.col];
    self.items[from.row][from.col] = tmp;
}

// Debug
pub fn setRow(self: *Self, items: [columns]u8, row: u8) void {
    std.debug.assert(items.len == columns);

    var col: u8 = 0;
    for (items) |value| {
        self.items[row][col] = Item{ .amount = 15, .id = value };
        col += 1;
    }
}
