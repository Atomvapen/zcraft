const rl = @import("raylib");
const std = @import("std");
const Context = @import("../Context.zig");
const zon = @import("../zon.zig");

const Face = enum { top, bottom, side };
const faceCount: usize = @typeInfo(Face).@"enum".fields.len;
const maxBlockType = u8; // 255= 8 bit limit
const maxBlockCount: usize = std.math.maxInt(maxBlockType);

pub var sprite: rl.Texture2D = undefined;

const vec = @import("../math/vec.zig");
const Vec3f = vec.Vec3f;
const Vec3i = vec.Vec3i;

var transparent: [maxBlockCount]bool = undefined;
var solid: [maxBlockCount]bool = undefined;
var collision: [maxBlockCount]bool = undefined; // set to - [_]bool{false} ** maxBlockCount - maybe?
var icon: [maxBlockCount]rl.Texture2D = undefined;
var faceIndex: [maxBlockCount][faceCount]u8 = undefined; //top, bottom, side
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

    pub inline fn getFaceTexture(self: Block, face: Face) u8 {
        const indexOffset: u8 = 1;

        return faceIndex[@intFromEnum(self.id)][@intFromEnum(face)] - indexOffset;
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

    pub inline fn valid(b: u8) bool {
        const field_count: usize = @typeInfo(ID).@"enum".fields.len;
        return b < field_count;
    }
};

pub const Neighbor = enum(u3) {
    posY,
    negY,
    posX,
    negX,
    posZ,
    negZ,

    pub const iterable: [6]Neighbor = [_]Neighbor{ @enumFromInt(0), @enumFromInt(1), @enumFromInt(2), @enumFromInt(3), @enumFromInt(4), @enumFromInt(5) };

    pub inline fn toInt(self: Neighbor) u3 {
        return @intFromEnum(self);
    }

    pub inline fn fromInt(b: u3) Neighbor {
        return @enumFromInt(b);
    }

    pub inline fn relPos(self: Neighbor) Vec3i {
        return switch (self) {
            .posY => .{ 0, 1, 0 },
            .negY => .{ 0, -1, 0 },
            .posX => .{ 1, 0, 0 },
            .negX => .{ -1, 0, 0 },
            .posZ => .{ 0, 0, 1 },
            .negZ => .{ 0, 0, -1 },
        };
    }

    pub inline fn getFace(self: Neighbor) Face {
        return switch (self) {
            .posY => .top,
            .negY => .bottom,
            .posX => .side,
            .negX => .side,
            .posZ => .side,
            .negZ => .side,
        };
    }

    pub inline fn getVerts(self: Neighbor, bci: Vec3i) [12]f32 {
        const bc: Vec3f = vec.transform(bci, Vec3f);

        return switch (self) {
            .posY => .{ bc[0], bc[1] + 1, bc[2], bc[0], bc[1] + 1, bc[2] + 1, bc[0] + 1, bc[1] + 1, bc[2] + 1, bc[0] + 1, bc[1] + 1, bc[2] },
            .negY => .{ bc[0], bc[1], bc[2], bc[0] + 1, bc[1], bc[2], bc[0] + 1, bc[1], bc[2] + 1, bc[0], bc[1], bc[2] + 1 },
            .posZ => .{ bc[0], bc[1], bc[2] + 1, bc[0] + 1, bc[1], bc[2] + 1, bc[0] + 1, bc[1] + 1, bc[2] + 1, bc[0], bc[1] + 1, bc[2] + 1 },
            .negZ => .{ bc[0], bc[1], bc[2], bc[0] + 1, bc[1], bc[2], bc[0] + 1, bc[1] + 1, bc[2], bc[0], bc[1] + 1, bc[2] },
            .posX => .{ bc[0] + 1, bc[1], bc[2], bc[0] + 1, bc[1], bc[2] + 1, bc[0] + 1, bc[1] + 1, bc[2] + 1, bc[0] + 1, bc[1] + 1, bc[2] },
            .negX => .{ bc[0], bc[1], bc[2], bc[0], bc[1], bc[2] + 1, bc[0], bc[1] + 1, bc[2] + 1, bc[0], bc[1] + 1, bc[2] },
        };
    }

    pub inline fn reverse(self: Neighbor) Neighbor {
        return switch (self) {
            .posY => .negY,
            .negY => .posY,
            .posX => .negX,
            .negX => .posX,
            .posZ => .negZ,
            .negZ => .posZ,
        };
    }
};
