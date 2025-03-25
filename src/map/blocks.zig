const rl = @import("raylib");
const std = @import("std");
const Context = @import("../Context.zig");
const zon = @import("../zon.zig");

const maxBlockType = u8;
const maxBlockCount: usize = std.math.maxInt(maxBlockType); // 255= 8 bit limit

pub var sprite: rl.Texture2D = undefined;

var transparent: [maxBlockCount]bool = undefined;
var solid: [maxBlockCount]bool = undefined;
var collision: [maxBlockCount]bool = undefined; // set to - [_]bool{false} ** maxBlockCount - maybe?
var icon: [maxBlockCount]rl.Texture2D = undefined;
var faceIndex: [maxBlockCount][3]u8 = undefined; //top, bottom, side
// var texture: [maxBlockCount]rl.Texture = undefined;

pub fn init() !void {
    const faces = struct { top: u8, bottom: u8, side: u8 };
    const BlockDef = struct {
        id: Block.ID,
        // name: []const u8 ,
        icon_path: [:0]const u8,
        // texture_path: []const u8,
        transparent: bool,
        collision: bool,
        // texture_faces
        // sprite_indexes
        faces: ?faces,
    };

    const BlocksData = struct {
        blocks: []const BlockDef,
    };

    const parsed = try zon.parse("src/map/blocks.zig.zon", BlocksData);

    for (parsed.blocks, 0..) |def, i| {
        if (def.icon_path.len > 0) {
            icon[i] = try rl.loadTexture(def.icon_path);
        }
        transparent[i] = def.transparent;
        collision[i] = def.collision;
        if (def.faces) |face| {
            faceIndex[i][0] = face.top;
            faceIndex[i][1] = face.bottom;
            faceIndex[i][2] = face.side;
        } else { // TODO make if faceIndex[X][0] == 0, then its same texture for every face?
            faceIndex[i][0] = 0;
            faceIndex[i][1] = 0;
            faceIndex[i][2] = 0;
        }
    }
    sprite = try rl.loadTexture("res/sprites2.png");
}

pub fn deinit() void {
    for (0..icon.len) |i| {
        if (icon[i].id != 0) {
            icon[i].unload();
        }
    }
    sprite.unload();
}

pub const Block = struct {
    pub const ID = enum(maxBlockType) { air, grass, dirt, glass, brick, stone, wood, leaf, _ };

    id: ID = @enumFromInt(0),
    // data: Data = .{},

    pub inline fn getFaceTexture(self: Block, face: enum { Top, Bottom, Side }) u8 {
        return faceIndex[@intFromEnum(self.id)][@intFromEnum(face)];
    }

    // pub inline fn getTexture(self: Block, side: enum { top, bottom, side }) u8 {
    //     return texture[@intFromEnum(self.id)];
    // }

    pub inline fn toInt(self: Block) i32 {
        return @intFromEnum(self.id);
    }

    pub inline fn fromInt(b: u8) Block {
        return Block{ .id = @enumFromInt(b) };
    }

    pub inline fn toId(self: Block) ID {
        return self.id;
    }

    pub inline fn fromId(id: ID) Block {
        return Block{ .id = id };
    }

    pub inline fn isTransparent(self: Block) bool {
        return transparent[@intFromEnum(self.id)];
    }

    pub inline fn hasCollision(self: Block) bool {
        return collision[@intFromEnum(self.id)];
    }

    pub inline fn getIcon(self: Block) !*rl.Texture {
        if (icon[@intFromEnum(self.id)].id == 0) return error.LoadImage;
        return &icon[@intFromEnum(self.id)];
    }

    pub inline fn valid(b: u8) bool {
        const field_count = @typeInfo(ID).@"enum".fields.len;
        return b < field_count;
    }
};
