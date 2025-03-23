const std = @import("std");
const model = @import("../rendering/models.zig");
const cull = @import("../rendering/frustumCulling.zig");
const util = @import("../rendering/utilities.zig");
const rl = @import("raylib");
const Context = @import("../Context.zig");
const Blocks = @import("blocks.zig");
const zon = @import("../zon.zig");

pub const chunkSize: u8 = 16;

fn isTransparent(i: u8) bool {
    return Blocks.Block.fromInt(i).isTransparent();
}

pub fn toChunkPos(position: rl.Vector3) rl.Vector3 {
    return rl.Vector3{
        .x = @divFloor(position.x, chunkSize),
        .y = @divFloor(position.y, chunkSize),
        .z = @divFloor(position.z, chunkSize),
    };
}

pub fn toWorldPos(position: rl.Vector3) rl.Vector3 {
    return rl.Vector3.scale(position, chunkSize);
}

pub const Neighbor = enum(u3) {
    posY,
    negY,
    posX,
    negX,
    posZ,
    negZ,

    pub const iterable = [_]Neighbor{ @enumFromInt(0), @enumFromInt(1), @enumFromInt(2), @enumFromInt(3), @enumFromInt(4), @enumFromInt(5) };

    pub inline fn toInt(self: Neighbor) u3 {
        return @intFromEnum(self);
    }

    pub inline fn fromInt(b: u3) Neighbor {
        return @enumFromInt(b);
    }

    pub inline fn relPos(self: Neighbor) rl.Vector3 {
        return switch (self) {
            .posY => .{ .x = 0, .y = 1, .z = 0 },
            .negY => .{ .x = 0, .y = -1, .z = 0 },
            .posX => .{ .x = 1, .y = 0, .z = 0 },
            .negX => .{ .x = -1, .y = 0, .z = 0 },
            .posZ => .{ .x = 0, .y = 0, .z = 1 },
            .negZ => .{ .x = 0, .y = 0, .z = -1 },
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

const Chunk = struct {
    blocks: [chunkSize][chunkSize][chunkSize]u8,
    model: ?rl.Model = null,
    dirty: bool = false,
    generated: bool = false,
    pos: ChunkPosition,

    pub const Empty: Chunk = .{ .blocks = undefined, .pos = undefined };

    pub fn create() !*Chunk {
        const chunk = try util.allocator.create(Chunk);
        return chunk;
    }

    pub fn destroy(self: *Chunk) void {
        util.allocator.destroy(self);
    }

    fn generateMesh(self: *Chunk, pos: rl.Vector3) !void {
        const chunkPosWorld = rl.Vector3.scale(pos, chunkSize);

        var vertList = std.ArrayList(f32).init(util.allocator);
        defer vertList.deinit();

        var indsList = std.ArrayList(u16).init(util.allocator);
        defer indsList.deinit();

        var texList = std.ArrayList(u8).init(util.allocator);
        defer texList.deinit();

        var indsOffset: u16 = 0;

        for (0..chunkSize) |x| {
            for (0..chunkSize) |y| {
                for (0..chunkSize) |z| {
                    if (self.blocks[x][y][z] == 0) continue;

                    const bc = rl.Vector3{ .x = @floatFromInt(x), .y = @floatFromInt(y), .z = @floatFromInt(z) };
                    const bw = rl.Vector3.add(chunkPosWorld, bc);

                    //const tSize = 1;//1.0 / 16.0; //tile size
                    //const xt = tSize * @as(f32, @floatFromInt(getBlock(.{bw.x, bw.y, bw.z}) - 1));
                    //const texCords = [_]f32{ xt, 0.0, tSize + xt, 0.0, tSize + xt, tSize, 0.0 + xt, tSize };
                    // std.debug.print("bw {any}\n", .{bw});
                    const block = Map.getBlock(.{ .x = bw.x, .y = bw.y, .z = bw.z }) - 1;
                    const texCords = [_]u8{ block, block + 1, block + 18, block + 17 };

                    // up face
                    if (isTransparent(Map.getBlock(.{ .x = bw.x, .y = bw.y + 1, .z = bw.z }))) {
                        // if (getBlock3(.{ .x = bw.x, .y = bw.y + 1, .z = bw.z }).isTransparent()) {
                        const vert = [_]f32{ bc.x, bc.y + 1, bc.z, bc.x + 1, bc.y + 1, bc.z, bc.x + 1, bc.y + 1, bc.z + 1, bc.x, bc.y + 1, bc.z + 1 };
                        const inds = [_]u16{ indsOffset, indsOffset + 2, indsOffset + 1, indsOffset, indsOffset + 3, indsOffset + 2 };

                        vertList.appendSlice(&vert) catch {};
                        indsList.appendSlice(&inds) catch {};
                        texList.appendSlice(&texCords) catch {};
                        indsOffset += 4;
                    }

                    if (isTransparent(Map.getBlock(.{ .x = bw.x, .y = bw.y - 1, .z = bw.z }))) {
                        const vert = [_]f32{ bc.x, bc.y, bc.z, bc.x + 1, bc.y, bc.z, bc.x + 1, bc.y, bc.z + 1, bc.x, bc.y, bc.z + 1 };
                        const inds = [_]u16{ indsOffset, indsOffset + 1, indsOffset + 2, indsOffset, indsOffset + 2, indsOffset + 3 };

                        vertList.appendSlice(&vert) catch {};
                        indsList.appendSlice(&inds) catch {};
                        texList.appendSlice(&texCords) catch {};
                        indsOffset += 4;
                    }

                    if (isTransparent(Map.getBlock(.{ .x = bw.x, .y = bw.y, .z = bw.z + 1 }))) {
                        const vert = [_]f32{ bc.x, bc.y, bc.z + 1, bc.x + 1, bc.y, bc.z + 1, bc.x + 1, bc.y + 1, bc.z + 1, bc.x, bc.y + 1, bc.z + 1 };
                        const inds = [_]u16{ indsOffset, indsOffset + 1, indsOffset + 2, indsOffset, indsOffset + 2, indsOffset + 3 };

                        vertList.appendSlice(&vert) catch {};
                        indsList.appendSlice(&inds) catch {};
                        texList.appendSlice(&texCords) catch {};
                        indsOffset += 4;
                    }

                    if (isTransparent(Map.getBlock(.{ .x = bw.x, .y = bw.y, .z = bw.z - 1 }))) {
                        const vert = [_]f32{ bc.x, bc.y, bc.z, bc.x + 1, bc.y, bc.z, bc.x + 1, bc.y + 1, bc.z, bc.x, bc.y + 1, bc.z };
                        const inds = [_]u16{ indsOffset, indsOffset + 2, indsOffset + 1, indsOffset, indsOffset + 3, indsOffset + 2 };

                        vertList.appendSlice(&vert) catch {};
                        indsList.appendSlice(&inds) catch {};
                        texList.appendSlice(&texCords) catch {};
                        indsOffset += 4;
                    }

                    if (isTransparent(Map.getBlock(.{ .x = bw.x + 1, .y = bw.y, .z = bw.z }))) {
                        const vert = [_]f32{ bc.x + 1, bc.y, bc.z, bc.x + 1, bc.y, bc.z + 1, bc.x + 1, bc.y + 1, bc.z + 1, bc.x + 1, bc.y + 1, bc.z };
                        const inds = [_]u16{ indsOffset, indsOffset + 2, indsOffset + 1, indsOffset, indsOffset + 3, indsOffset + 2 };

                        vertList.appendSlice(&vert) catch {};
                        indsList.appendSlice(&inds) catch {};
                        texList.appendSlice(&texCords) catch {};
                        indsOffset += 4;
                    }

                    if (isTransparent(Map.getBlock(.{ .x = bw.x - 1, .y = bw.y, .z = bw.z }))) {
                        const vert = [_]f32{ bc.x, bc.y, bc.z, bc.x, bc.y, bc.z + 1, bc.x, bc.y + 1, bc.z + 1, bc.x, bc.y + 1, bc.z };
                        const inds = [_]u16{ indsOffset, indsOffset + 1, indsOffset + 2, indsOffset, indsOffset + 2, indsOffset + 3 };

                        vertList.appendSlice(&vert) catch {};
                        indsList.appendSlice(&inds) catch {};
                        texList.appendSlice(&texCords) catch {};
                        indsOffset += 4;
                    }
                }
            }
        }

        if (vertList.items.len == 0) { //emptyChunk
            if (self.model != null) {
                model.unloadMesh(self.model.?.meshes[0]);
                self.model = null;
            }
            return;
        }

        if (self.model != null) {
            model.unloadMesh(self.model.?.meshes[0]);
        }

        var mesh = rl.Mesh{
            .triangleCount = @intCast(vertList.items.len / 6),
            .vertexCount = @intCast(vertList.items.len / 3),
            .indices = @ptrCast(try util.allocator.alloc(u16, indsList.items.len)),
            .vertices = null,
            .texcoords = null,
            .texcoords2 = null,
            .normals = null,
            .tangents = null,
            .colors = null,
            .animVertices = null,
            .animNormals = null,
            .boneIds = null,
            .boneWeights = null,
            .boneMatrices = null,
            .boneCount = 0,
            .vaoId = 0,
            .vboId = null,
        };
        // defer util.allocator.free((mesh.indices));

        var vertlistcap = try util.allocator.alloc(u32, vertList.items.len);
        defer util.allocator.free(vertlistcap);

        var texCoords = try util.allocator.alloc(u8, texList.items.len);
        defer util.allocator.free(texCoords);

        // remove extra capacity
        for (0..indsList.items.len) |e| mesh.indices[e] = indsList.items[@intCast(e)];
        for (0..texList.items.len) |e| texCoords[e] = texList.items[@intCast(e)];

        var i: usize = 0;
        var vi: usize = 0;

        while (vertList.items.len > i) {
            vertlistcap[vi] = @as(u8, texCoords[vi]);
            vertlistcap[vi] <<= 8;

            vertlistcap[vi] += @as(u6, @intFromFloat(vertList.items[i] + 0.5));
            vertlistcap[vi] <<= 6;
            vertlistcap[vi] += @as(u6, @intFromFloat(vertList.items[i + 1] + 0.5));
            vertlistcap[vi] <<= 6;
            vertlistcap[vi] += @as(u6, @intFromFloat(vertList.items[i + 2] + 0.5));

            i += 3;
            vi = i / 3;
        }

        try model.UploadMesh(&mesh, vertlistcap.ptr);

        self.model = try rl.loadModelFromMesh(mesh);

        model.setTexture(self.model.?, util.loadTexture("res/sprites.png"));
        model.setShadowShader(self.model.?);
    }

    pub fn getBlock(self: *Chunk, position: rl.Vector3) u8 {
        const x: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.x)), chunkSize));
        const y: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.y)), chunkSize));
        const z: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.z)), chunkSize));

        return self.blocks[x][y][z];
    }

    /// Worldpos set block
    pub fn setBlock(self: *Chunk, position: rl.Vector3, b: u8) void {
        const x: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.x)), chunkSize));
        const y: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.y)), chunkSize));
        const z: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.z)), chunkSize));
        std.debug.assert(x < chunkSize and y < chunkSize and z < chunkSize);
        self.*.blocks[x][y][z] = b;
        self.*.dirty = true;
    }
};

const ChunkPosition = struct {
    wx: i32,
    wy: i32,
    wz: i32,

    pub fn toChunkPos(self: *ChunkPosition) rl.Vector3 {
        const position = self.toVec3();
        return rl.Vector3{
            .x = @divFloor(position.x, chunkSize),
            .y = @divFloor(position.y, chunkSize),
            .z = @divFloor(position.z, chunkSize),
        };
    }

    pub fn fromWorldPos(v: rl.Vector3) ChunkPosition {
        return fromVec3(rl.Vector3.scale(v, chunkSize));
    }

    fn fromVec3(v: rl.Vector3) ChunkPosition {
        return .{
            .wx = @intFromFloat(v.x),
            .wy = @intFromFloat(v.y),
            .wz = @intFromFloat(v.z),
        };
    }

    pub fn toVec3(self: *ChunkPosition) rl.Vector3 {
        return .{
            .x = @floatFromInt(self.wx),
            .y = @floatFromInt(self.wy),
            .z = @floatFromInt(self.wz),
        };
    }

    pub fn hashFromPos(pos: rl.Vector3) u96 {
        const x_bits: i32 = @intFromFloat(pos.x);
        const y_bits: i32 = @intFromFloat(pos.y);
        const z_bits: i32 = @intFromFloat(pos.z);

        var result: u96 = 0;

        result |= @as(u96, @as(u32, @bitCast(x_bits))) << 64;
        result |= @as(u96, @as(u32, @bitCast(y_bits))) << 32;
        result |= @as(u96, @as(u32, @bitCast(z_bits)));

        return result;
    }

    pub fn hashFromChunkPos(self: *ChunkPosition) u96 {
        const position = self.toVec3();
        const pos = rl.Vector3{
            .x = @divFloor(position.x, chunkSize),
            .y = @divFloor(position.y, chunkSize),
            .z = @divFloor(position.z, chunkSize),
        };

        const x_bits: i32 = @intFromFloat(pos.x);
        const y_bits: i32 = @intFromFloat(pos.y);
        const z_bits: i32 = @intFromFloat(pos.z);

        var result: u96 = 0;

        result |= @as(u96, @as(u32, @bitCast(x_bits))) << 64;
        result |= @as(u96, @as(u32, @bitCast(y_bits))) << 32;
        result |= @as(u96, @as(u32, @bitCast(z_bits)));

        return result;
    }

    pub fn posFromHash(key: u96) ChunkPosition {
        return .{
            .wx = @bitCast(@as(u32, @truncate(key >> 64))),
            .wy = @bitCast(@as(u32, @truncate(key >> 32))),
            .wz = @bitCast(@as(u32, @truncate(key))),
        };
    }

    fn distanceToChunk(self: *ChunkPosition, b: rl.Vector3) f32 {
        const ax = @as(f32, @floatFromInt(self.wx)) / @as(f32, chunkSize);
        const ay = @as(f32, @floatFromInt(self.wy)) / @as(f32, chunkSize);
        const az = @as(f32, @floatFromInt(self.wz)) / @as(f32, chunkSize);

        const bx = b.x / @as(f32, chunkSize);
        const by = b.y / @as(f32, chunkSize);
        const bz = b.z / @as(f32, chunkSize);

        const dx = ax - bx;
        const dy = ay - by;
        const dz = az - bz;

        return @sqrt(dx * dx + dy * dy + dz * dz);
    }

    fn distanceToChunkSquared(self: *ChunkPosition, b: rl.Vector3) f32 {
        const ax = @as(f32, @floatFromInt(self.wx)) / @as(f32, chunkSize);
        const ay = @as(f32, @floatFromInt(self.wy)) / @as(f32, chunkSize);
        const az = @as(f32, @floatFromInt(self.wz)) / @as(f32, chunkSize);

        const bx = b.x / @as(f32, chunkSize);
        const by = b.y / @as(f32, chunkSize);
        const bz = b.z / @as(f32, chunkSize);

        const dx = ax - bx;
        const dy = ay - by;
        const dz = az - bz;

        return dx * dx + dy * dy + dz * dz;
    }
};

pub const Map = struct {
    // var chunks: std.AutoHashMap(u96, *Chunk) = std.AutoHashMap(u96, *Chunk).init(util.allocator);
    var chunks: std.AutoHashMap(u96, *Chunk) = undefined;

    pub fn init() void {
        chunks = std.AutoHashMap(u96, *Chunk).init(util.allocator);
    }

    pub fn deinit() void {
        var mapIter = chunks.iterator();
        while (mapIter.next()) |entry| {
            entry.value_ptr.*.destroy();
            // util.allocator.free(entry.value_ptr.*);
        }
        chunks.deinit();
    }

    pub fn draw(ctx: *Context) void {
        var mapIter = chunks.iterator();
        while (mapIter.next()) |entry| {
            const chunk = entry.value_ptr.*;

            if (chunk.model == null) continue;
            if (chunk.pos.distanceToChunk(ctx.player.pos) > ctx.settings.renderDistance) continue;

            const pos = chunk.pos.toVec3();
            if (!cull.isChunkVisible(pos, ctx)) continue;
            if (chunk.model) |m| rl.drawModel(m, pos, 1, rl.Color.white);
        }
    }

    pub fn update() void {
        var mapIter = chunks.iterator();
        while (mapIter.next()) |entry| {
            var chunk = entry.value_ptr.*;
            if (!chunk.dirty) continue;
            const pos = chunk.pos.toChunkPos();
            chunk.generateMesh(pos) catch {}; //Continue?
            chunk.*.dirty = false;
        }
    }

    pub fn getBlock(position: rl.Vector3) u8 {
        const chunk = getChunk(toChunkPos(position));
        return if (chunk) |c| c.getBlock(position) else 0;
    }

    pub fn setBlock(position: rl.Vector3, b: u8) !void {
        const chunk = try getChunkOrGen(toChunkPos(position));
        chunk.setBlock(position, b);
        chunk.*.dirty = true; //TODO Needed?
    }

    pub fn setBlockUpdate(position: rl.Vector3, b: u8) !void {
        if (!Blocks.Block.valid(b)) return;
        try updateNeighbors(position);
        try setBlock(position, b);
    }

    pub fn updateNeighbors(position: rl.Vector3) !void {
        for (Neighbor.iterable) |n| {
            const offset = n.relPos();
            const neighbor_pos = rl.Vector3{
                .x = position.x + offset.x,
                .y = position.y + offset.y,
                .z = position.z + offset.z,
            };
            const chunk = try getChunkOrGen(toChunkPos(neighbor_pos));

            if (chunk.getBlock(neighbor_pos) != 0) {
                chunk.*.dirty = true;
            }
        }
    }

    pub fn addChunk(position: anytype) !void {
        const newChunk = try Chunk.create();

        newChunk.* = Chunk.Empty;
        newChunk.*.pos = ChunkPosition.fromWorldPos(position);

        chunks.put(newChunk.pos.hashFromChunkPos(), newChunk) catch |err| std.debug.print("cannot addChunk {}", .{err});
    }

    pub fn getChunk(position: rl.Vector3) ?*Chunk {
        const hash = ChunkPosition.hashFromPos(position);
        const chunkPtr = chunks.get(hash);
        return if (chunkPtr) |ptr| ptr else null;
    }

    pub fn getChunkOrGen(position: rl.Vector3) !*Chunk {
        var chunk = getChunk(position);
        if (chunk == null) {
            try addChunk(position);
            chunk = getChunk(position);
        }
        return chunk.?;
    }
};

pub const Generate = struct {
    fn safeSetBlock(pos: rl.Vector3, block: Blocks.Block.ID) !void {
        if (Map.getChunk(toChunkPos(pos)) == null) try Map.addChunk(toChunkPos(pos));
        const targetChunk = Map.getChunk(toChunkPos(pos));
        if (targetChunk) |t| t.setBlock(pos, @intCast(@intFromEnum(block)));
    }

    pub fn generate(position: rl.Vector3) !void {
        if (Map.getChunk(position)) |c| {
            if (c.generated) return;
        } else {
            try Map.addChunk(position);
        }

        const chunk = Map.getChunk(position);
        if (chunk == null) return;

        const radius: i32 = 8; // TODO get real radius
        const chunk_count = (radius * 2 + 1) * (radius * 2 + 1) * (radius * 2 + 1);
        try Map.chunks.ensureTotalCapacity(chunk_count); // Total or unused?

        if (chunk) |c| {
            const size = chunkSize;

            const image = rl.genImagePerlinNoise(size, size, c.pos.wx, c.pos.wz, 0.1);
            defer image.unload();

            const image2 = rl.genImagePerlinNoise(size, size, c.pos.wx, c.pos.wz, 2);
            defer image2.unload();

            const colors = rl.loadImageColors(image) catch unreachable;
            const colors2 = rl.loadImageColors(image2) catch unreachable;

            for (0..@intCast(image.height)) |z| {
                for (0..@intCast(image.width)) |x| {
                    const index = z * @as(usize, @intCast(image.width)) + x;
                    const pixel = colors[index];
                    const pixel2 = colors2[index];

                    var height: i32 = 0;
                    height += pixel2.r;
                    height += pixel2.g;
                    height += pixel2.b;
                    height = @divFloor(height, 10);

                    height += pixel.b;
                    height += pixel.r;
                    height += pixel.g;
                    height = @divFloor(height, 40);
                    height += 20;

                    const setBlockPos = rl.Vector3{ .x = @floatFromInt(x), .y = @floatFromInt(height), .z = @floatFromInt(z) };

                    for (0..@intCast(height)) |h| {
                        const blockPos: rl.Vector3 = .{ .x = setBlockPos.x + @as(f32, @floatFromInt(c.pos.wx)), .y = @as(f32, @floatFromInt(height)) - @as(f32, @floatFromInt(@as(i32, @intCast(h)))), .z = setBlockPos.z + @as(f32, @floatFromInt(c.pos.wz)) };
                        try safeSetBlock(blockPos, .stone);
                    }

                    const blockPos: rl.Vector3 = .{ .x = setBlockPos.x + @as(f32, @floatFromInt(c.pos.wx)), .y = @floatFromInt(height), .z = setBlockPos.z + @as(f32, @floatFromInt(c.pos.wz)) };
                    try safeSetBlock(blockPos, .grass);

                    if (rl.getRandomValue(0, 100) == 1) {
                        try Structures.place(.oak_tree, blockPos);
                    }
                }
            }

            c.generated = true;
        }
    }

    pub const Structures = struct {
        const BlockDef = struct { x: i32, y: i32, z: i32, id: Blocks.Block.ID };
        const StructureData = struct { blocks: []const BlockDef };
        const StructType = enum(u8) {
            oak_tree,
            _,

            const iterable = [_]StructType{@enumFromInt(0)};
        };

        var oak_tree: StructureData = undefined;

        pub fn init() !void {
            for (StructType.iterable) |structure| {
                switch (structure) {
                    .oak_tree => Structures.oak_tree = try zon.parse("src/map/structures/oak_tree.zig.zon", StructureData),
                    else => continue,
                }
            }
        }

        pub fn place(structure: StructType, base_pos: rl.Vector3) !void {
            const data = switch (structure) {
                .oak_tree => Structures.oak_tree,
                else => null,
            };

            if (data) |payload| {
                if (payload.blocks.len == 0) return;

                for (payload.blocks) |block| {
                    const world_pos = rl.Vector3{
                        .x = base_pos.x + @as(f32, @floatFromInt(block.x)),
                        .y = base_pos.y + @as(f32, @floatFromInt(block.y)),
                        .z = base_pos.z + @as(f32, @floatFromInt(block.z)),
                    };
                    try safeSetBlock(world_pos, block.id);
                }
            }
        }
    };
};
