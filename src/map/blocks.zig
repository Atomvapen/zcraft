const rl = @import("raylib");
const std = @import("std");
const Context = @import("../Context.zig");

pub var list: std.ArrayList(rl.Texture) = undefined;

pub var list2: [9]rl.Texture = undefined;

pub fn init(ctx: *Context) !void {
    const grass = try rl.loadTexture("assets/blocks/grass_flat.png");
    const dirt = try rl.loadTexture("assets/blocks/dirt_flat.png");

    list = std.ArrayList(rl.Texture).init(ctx.allocator);

    try list.append(grass);
    try list.append(dirt);

    list2[1] = grass;
    list2[4] = dirt;
}

pub fn deinit() void {
    for (list.items) |item| {
        item.unload();
    }
    list.deinit();
}

pub const Type = enum(u8) {
    air = 0,
    grass,
    glass,
    brick,
    stone,
    wood,
    leaf,

    pub fn hasIcon(i: u8) bool {
        return i == 1 or i == 4;
    }

    pub fn getIcon(i: u8) rl.Texture {
        return list[i];
    }

    pub fn toInt(self: Type) i32 {
        return @intFromEnum(self);
    }

    pub fn toType(i: u8) Type {
        return @enumFromInt(i);
    }

    pub fn transparent(i: u8) bool {
        return switch (@as(Type, @enumFromInt(i))) {
            .air, .glass, .leaf => true,
            else => false,
        };
    }

    pub fn solid(i: u8) bool {
        return switch (@as(Type, @enumFromInt(i))) {
            .air => false,
            else => true,
        };
    }

    pub fn valid(i: u8) bool {
        const field_count = @typeInfo(Type).@"enum".fields.len;
        return i < field_count;
    }
};

pub const Block = struct {
    type: Type,
};
