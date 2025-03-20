const rl = @import("raylib");
// const std = @import("std");

pub fn init() !void {
    const grass = try rl.loadTexture("assets/blocks/grass_flat.png");
    const dirt = try rl.loadTexture("assets/blocks/dirt_flat.png");

    textures[1] = grass;
    textures[4] = dirt;
}

pub fn deinit() void {
    for (0..textures.len) |i| {
        textures[i].unload();
    }
}

pub const Type = enum(u8) {
    air = 0,
    grass,
    glass,
    brick,
    stone,
    wood,
    leaf,
    _,

    pub fn hasTexture(b: u8) bool { //TEMP
        return b == 1 or b == 4;
    }

    pub fn getTexture(b: u8) rl.Texture {
        return textures[b];
    }

    pub fn toInt(self: Type) i32 {
        return @intFromEnum(self);
    }

    pub fn toType(b: u8) Type {
        return @enumFromInt(b);
    }

    pub fn transparent(b: u8) bool {
        return switch (@as(Type, @enumFromInt(b))) {
            .air, .glass, .leaf => true,
            else => false,
        };
    }

    pub fn solid(b: u8) bool {
        return switch (@as(Type, @enumFromInt(b))) {
            .air => false,
            else => true,
        };
    }

    pub fn valid(b: u8) bool {
        const field_count = @typeInfo(Type).@"enum".fields.len;
        return b < field_count;
    }
};

const maxBlockCount: usize = 9; // 255= 8 bit limit

var transparent: [maxBlockCount]bool = undefined;
var solid: [maxBlockCount]bool = undefined;
var collision: [maxBlockCount]bool = undefined;
var textures: [maxBlockCount]rl.Texture = undefined;

pub const Block = struct {
    pub const ID = enum(u64) { air, grass, glass, brick, stone, wood, leaf, _ };

    id: ID = @enumFromInt(0),
    // type: Type,
    // texture: *rl.Texture,

    // collision: bool,
    // transparent: bool,
    // solid: bool,

    pub fn toInt(self: Block) i32 {
        return @intFromEnum(self.type);
    }

    pub fn fromInt(b: u8) Block {
        return Block{ .id = @enumFromInt(b) };
    }

    pub inline fn isTransparent(self: Block) bool {
        return transparent[@intFromEnum(self.id)];
    }

    pub inline fn hasCollision(self: Block) bool {
        return collision[@intFromEnum(self.id)];
    }

    pub inline fn getTexture(self: Block) !*rl.Texture {
        if (textures[@intFromEnum(self.id)].id == 0) return error.LoadImage;
        return &textures[@intFromEnum(self.id)];
    }
};
