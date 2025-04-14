const rl = @import("raylib");
const std = @import("std");
const root = @import("root");

pub const Face = enum { top, bottom, side };
const faceCount: usize = @typeInfo(Face).@"enum".fields.len;
const maxBlockType = u8; // 255= 8 bit limit
const maxBlockCount: usize = std.math.maxInt(maxBlockType);

pub var sprite: rl.Texture2D = undefined;

var transparent: [maxBlockCount]bool = undefined;
var solid: [maxBlockCount]bool = undefined;
var collision: [maxBlockCount]bool = undefined;
var icon: [maxBlockCount]rl.Texture2D = undefined;
var faceIndex: [maxBlockCount][faceCount]u8 = undefined;
// var texture: [maxBlockCount]rl.Texture = undefined;
// var names: [maxBlockCount][:0]const u8 = undefined;
// var descriptions: [maxBlockCount][:0]const u8 = undefined;

pub fn init() !void {
    const faces = struct { top: u8 = 0, bottom: u8 = 1, side: u8 = 2 };
    const BlockDef = struct {
        id: Block.ID,
        // name: [:0]const u8 ,
        // description: [:0]const u8 ,
        icon_path: ?[:0]const u8,
        transparent: bool,
        collision: bool,
        faces: ?faces,
    };
    const blocks_file = @embedFile("blocks.zig.zon");
    const parsed = try std.zon.parse.fromSlice([]const BlockDef, root.allocator, blocks_file, null, .{});

    for (parsed, 0..) |def, i| {
        if (def.icon_path) |path| icon[i] = try rl.loadTexture(path);
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
    for (0..icon.len) |i| if (icon[i].id != 0) icon[i].unload();
    sprite.unload();
}

pub const Block = struct {
    pub const ID = enum(maxBlockType) { air, grass, dirt, glass, brick, stone, wood, leaf, _ };

    id: ID = @enumFromInt(0),

    pub inline fn getFaceTexture(self: Block, face: Face) u8 {
        const indexOffset: u8 = 1;

        return faceIndex[@intFromEnum(self.id)][@intFromEnum(face)] - indexOffset;
    }

    // pub inline fn name(self: Block) [:0]const u8 {
    //     return names[@intFromEnum(self.id)];
    // }

    // pub inline fn description(self: Block) [:0]const u8 {
    //     return descriptions[@intFromEnum(self.id)];
    // }

    // pub inline fn getTexture(self: Block, side: enum { top, bottom, side }) u8 {
    //     return texture[@intFromEnum(self.id)];
    // }

    pub inline fn toInt(self: Block) i32 {
        return @intFromEnum(self.id);
    }

    pub inline fn fromInt(b: u8) Block {
        return Block{ .id = @enumFromInt(b) };
    }

    // pub inline fn toId(self: Block) ID {
    //     return self.id;
    // }

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

    pub inline fn valid(b: u8) bool { //TODO: Remove
        const field_count: usize = @typeInfo(ID).@"enum".fields.len;
        return b < field_count;
    }
};
