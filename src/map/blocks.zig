const rl = @import("raylib");
const std = @import("std");
const Context = @import("../Context.zig");

pub fn init(ctx: *Context) !void {
    const BlockDef = struct {
        id: Block.ID,
        // name: []const u8 ,
        icon_path: []const u8,
        // texture_path: []const u8,
        transparent: bool,
        collision: bool,
    };

    const BlocksData = struct {
        blocks: []const BlockDef,
    };

    const file_data = try std.fs.cwd().readFileAlloc(ctx.allocator, "src/map/blocks.zig.zon", 10 * 1024);
    defer ctx.allocator.free(file_data);

    const file_dataZ: [:0]u8 = try ctx.allocator.dupeZ(u8, file_data);
    defer ctx.allocator.free(file_dataZ);

    const parsed: BlocksData = try std.zon.parse.fromSlice(BlocksData, ctx.allocator, file_dataZ, null, .{ .ignore_unknown_fields = true });

    for (parsed.blocks, 0..) |def, i| {
        if (def.icon_path.len > 0) {
            const icon_pathZ = try ctx.allocator.dupeZ(u8, def.icon_path);
            defer ctx.allocator.free(icon_pathZ);
            icon[i] = try rl.loadTexture(icon_pathZ);
        }
        transparent[i] = def.transparent;
        collision[i] = def.collision;
    }
}

pub fn deinit() void {
    for (0..icon.len) |i| {
        icon[i].unload();
    }
}

const maxBlockCount: usize = 9; // 255= 8 bit limit

// var id: [maxBlockCount]u8 = undefined;
var transparent: [maxBlockCount]bool = undefined;
var solid: [maxBlockCount]bool = undefined;
var collision: [maxBlockCount]bool = undefined; // set to - [_]bool{false} ** maxBlockCount - maybe?
var icon: [maxBlockCount]rl.Texture2D = undefined;
var texture: [maxBlockCount]rl.Texture = undefined;

pub const Block = struct {
    pub const ID = enum(u64) { air, grass, glass, brick, stone, wood, leaf, _ };

    id: ID = @enumFromInt(0),

    pub inline fn toInt(self: Block) i32 {
        return @intFromEnum(self.id);
    }

    pub inline fn fromInt(b: u8) Block {
        return Block{ .id = @enumFromInt(b) };
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

    pub inline fn getTexture(self: Block) !*rl.Texture {
        if (icon[@intFromEnum(self.id)].id == 0) return error.LoadImage;
        return &icon[@intFromEnum(self.id)];
    }

    pub inline fn valid(b: u8) bool {
        const field_count = @typeInfo(ID).@"enum".fields.len;
        return b < field_count;
    }
};
