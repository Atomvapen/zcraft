const std = @import("std");
const model = @import("../rendering/models.zig");
const frustum = @import("../rendering/frustum.zig");
const root = @import("root");
const rl = @import("raylib");
const Context = @import("../Context.zig");
const Blocks = @import("blocks.zig");
const zon = @import("../zon.zig");
const vec = @import("../math/vec.zig");
const Vec3f = vec.Vec3f;
const Vec3i = vec.Vec3i;

const Block = Blocks.Block;
const Neighbor = Blocks.Neighbor;

pub fn toChunkPos(position: Vec3i) Vec3i {
    return .{
        @divFloor(position[0], chunkSize),
        @divFloor(position[1], chunkSize),
        @divFloor(position[2], chunkSize),
    };
}

pub const chunkSize: u8 = 16;

const Chunk = struct {
    // const size: u16 = 16;

    blocks: [chunkSize][chunkSize][chunkSize]u8,
    model: ?rl.Model = null,
    dirty: bool = false,
    generated: bool = false,
    pos: ChunkPosition,

    pub const Empty: Chunk = .{ .blocks = undefined, .pos = undefined };

    pub fn create() !*Chunk {
        const chunk: *Chunk = try root.allocator.create(Chunk);
        return chunk;
    }

    pub fn destroy(self: *Chunk) void {
        root.allocator.destroy(self);
    }

    pub fn draw(self: *Chunk) void {
        if (self.model) |m| {
            const pos: Vec3i = self.pos.toWorldPos();
            if (!frustum.isChunkVisible(pos)) return;
            const pos_rl = vec.rlTransform(pos, rl.Vector3);
            rl.drawModel(m, pos_rl, 1, rl.Color.white);
        }
    }

    fn generateMesh(self: *Chunk) !void {
        const chunkPosWorld: Vec3i = self.pos.toWorldPos();
        const chunkVolume: usize = @as(usize, chunkSize) * chunkSize * chunkSize;
        var indsOffset: u16 = 0;

        var vertList: std.ArrayListAligned(f32, null) = std.ArrayList(f32).init(root.allocator);
        defer vertList.deinit();
        try vertList.ensureTotalCapacityPrecise(chunkVolume * 72);

        var indsList: std.ArrayListAligned(u16, null) = std.ArrayList(u16).init(root.allocator);
        defer indsList.deinit();
        try indsList.ensureTotalCapacityPrecise(chunkVolume * 36);

        var texList: std.ArrayListAligned(u8, null) = std.ArrayList(u8).init(root.allocator);
        defer texList.deinit();
        try texList.ensureTotalCapacityPrecise(chunkVolume * 6);

        for (0..chunkSize) |x| for (0..chunkSize) |y| for (0..chunkSize) |z| {
            const block: Block = Block.fromInt(self.blocks[x][y][z]);
            if (block.id == .air) continue;

            const bc: Vec3i = .{ @intCast(x), @intCast(y), @intCast(z) };
            const bw: Vec3i = bc + chunkPosWorld;

            for (Neighbor.iterable) |neighbor| {
                const offset: Vec3i = neighbor.relPos();

                const nc: Vec3i = bc + offset;
                const nw: Vec3i = bw + offset;

                const nx: i32 = nc[0];
                const ny: i32 = nc[1];
                const nz: i32 = nc[2];

                const neighborBlock: u8 = if (nx >= 0 and nx < chunkSize and ny >= 0 and ny < chunkSize and nz >= 0 and nz < chunkSize)
                    self.blocks[@intCast(nx)][@intCast(ny)][@intCast(nz)]
                else
                    Map.getBlock(nw);

                const nBlock: Block = Block.fromInt(neighborBlock);

                if (!nBlock.isTransparent()) continue;

                const faceTex: u8 = block.getFaceTexture(neighbor.getFace());
                const verts: [12]f32 = neighbor.getVerts(bc);
                const inds: [6]u16 = [_]u16{ indsOffset, indsOffset + 1, indsOffset + 2, indsOffset, indsOffset + 2, indsOffset + 3 };
                const texCords: [4]u8 = [_]u8{ faceTex, faceTex + 1, faceTex + 18, faceTex + 17 };

                try vertList.appendSlice(&verts);
                try indsList.appendSlice(&inds);
                try texList.appendSlice(&texCords);

                indsOffset += 4;
            }
        };

        if (self.model) |m| {
            model.unloadMesh(m.meshes[0]);
            self.model = null;
        }

        if (vertList.items.len == 0 or indsList.items.len == 0) {
            return;
        }

        var mesh: rl.Mesh = rl.Mesh{
            .triangleCount = @intCast(vertList.items.len / 6),
            .vertexCount = @intCast(vertList.items.len / 3),
            .indices = @ptrCast(try root.allocator.alloc(u16, indsList.items.len)),
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
            .vboId = @as([*c]c_int, @ptrCast(try root.allocator.alloc(u32, 9))),
        };
        const vc: f64 = @floatFromInt(mesh.vertexCount);
        defer root.allocator.free(mesh.indices[0..@intFromFloat(vc * 1.5)]);

        var packedVerts: []u32 = try root.allocator.alloc(u32, vertList.items.len);
        defer root.allocator.free(packedVerts);
        @memcpy(mesh.indices[0..indsList.items.len], indsList.items);

        const texCoords: []u8 = texList.items;
        // const texCoords = try util.allocator.alloc(u8, texList.items.len);
        // defer util.allocator.free(texCoords);
        // @memcpy(texCoords.ptr, texList.items);

        var i: usize = 0;
        var vi: usize = 0;
        var pack: u32 = undefined;

        while (i < vertList.items.len) {
            pack = texCoords[vi];
            pack = (pack << 8) | @as(u8, @intCast(@as(i32, @intFromFloat(vertList.items[i] + 0.5))));
            pack = (pack << 6) | @as(u8, @intCast(@as(i32, @intFromFloat(vertList.items[i + 1] + 0.5))));
            pack = (pack << 6) | @as(u8, @intCast(@as(i32, @intFromFloat(vertList.items[i + 2] + 0.5))));
            packedVerts[vi] = pack;

            i += 3;
            vi += 1;
        }

        model.uploadMesh(&mesh, packedVerts.ptr);

        self.model = try rl.loadModelFromMesh(mesh);

        if (self.model) |m| {
            model.setTexture(m, Blocks.sprite);
            model.setShadowShader(m);
        }
    }

    pub fn getBlock(self: *Chunk, pos: Vec3i) u8 {
        const cpos = vec.mod(pos, chunkSize);

        const x: u8 = @intCast(cpos[0]);
        const y: u8 = @intCast(cpos[1]);
        const z: u8 = @intCast(cpos[2]);

        return self.blocks[x][y][z];
    }

    /// Worldpos set block
    pub fn setBlock(self: *Chunk, pos: Vec3i, b: u8) void {
        const cpos = vec.mod(pos, chunkSize);

        const x: u8 = @intCast(cpos[0]);
        const y: u8 = @intCast(cpos[1]);
        const z: u8 = @intCast(cpos[2]);

        std.debug.assert(x < chunkSize and y < chunkSize and z < chunkSize);
        self.*.blocks[x][y][z] = b;
        self.*.dirty = true;
    }
};

const ChunkPosition = struct {
    wx: i32,
    wy: i32,
    wz: i32,

    pub fn toChunkPos(self: *ChunkPosition) Vec3i {
        return .{
            @divFloor(self.wx, chunkSize),
            @divFloor(self.wy, chunkSize),
            @divFloor(self.wz, chunkSize),
        };
    }

    pub fn fromChunkPos(v: *Vec3i) ChunkPosition {
        return .{
            .wx = v[0],
            .wy = v[1],
            .wz = v[2],
        };
    }

    pub fn toWorldPos(self: *ChunkPosition) Vec3i {
        return .{
            self.wx,
            self.wy,
            self.wz,
        };
    }

    pub fn fromWorldPos(v: Vec3i) ChunkPosition {
        return .{
            .wx = v[0] * chunkSize,
            .wy = v[1] * chunkSize,
            .wz = v[2] * chunkSize,
        };
    }

    pub fn hashFromPos(pos: Vec3i) u96 {
        const x_bits: i32 = pos[0];
        const y_bits: i32 = pos[1];
        const z_bits: i32 = pos[2];

        var result: u96 = 0;

        result |= @as(u96, @as(u32, @bitCast(x_bits))) << 64;
        result |= @as(u96, @as(u32, @bitCast(y_bits))) << 32;
        result |= @as(u96, @as(u32, @bitCast(z_bits)));

        return result;
    }

    pub fn hashFromChunkPos(self: *ChunkPosition) u96 {
        const pos: Vec3i = self.toChunkPos();

        const x_bits: i32 = pos[0];
        const y_bits: i32 = pos[1];
        const z_bits: i32 = pos[2];

        var result: u96 = 0;

        result |= @as(u96, @as(u32, @bitCast(x_bits))) << 64;
        result |= @as(u96, @as(u32, @bitCast(y_bits))) << 32;
        result |= @as(u96, @as(u32, @bitCast(z_bits)));

        return result;
    }

    // pub fn posFromHash(key: u96) ChunkPosition {
    //     return .{
    //         .wx = @bitCast(@as(u32, @truncate(key >> 64))),
    //         .wy = @bitCast(@as(u32, @truncate(key >> 32))),
    //         .wz = @bitCast(@as(u32, @truncate(key))),
    //     };
    // }

    fn distanceToChunk(self: *ChunkPosition, b: Vec3i) f32 {
        const a: Vec3i = self.toChunkPos();
        const b_chunk: Vec3i = @Vector(3, i32){ @divFloor(b[0], chunkSize), @divFloor(b[1], chunkSize), @divFloor(b[2], chunkSize) };

        const delta: Vec3f = @floatFromInt(a - b_chunk);
        return @sqrt(@reduce(.Add, @as(Vec3f, delta * delta)));
    }
};

pub const Map = struct {
    var chunks: std.AutoHashMap(u96, *Chunk) = undefined;

    pub fn init() void {
        chunks = std.AutoHashMap(u96, *Chunk).init(root.allocator);
    }

    pub fn deinit() void {
        var mapIter = chunks.iterator();
        while (mapIter.next()) |entry| {
            entry.value_ptr.*.destroy();
        }
        chunks.deinit();
    }

    pub fn draw(ctx: *Context) void {
        var mapIter = chunks.iterator();
        const pos: Vec3i = vec.rlTransform(ctx.player.camera.position, Vec3i);
        const renderDist = ctx.settings.renderDistance;

        while (mapIter.next()) |entry| {
            // const chunk: *Chunk = entry.value_ptr.*;
            const chunk: *Chunk = @atomicLoad(*Chunk, entry.value_ptr, .acquire);
            if (chunk.pos.distanceToChunk(pos) > renderDist) continue;
            chunk.draw();
        }
    }

    pub fn update() void {
        var mapIter = chunks.iterator();
        while (mapIter.next()) |entry| {
            const chunk: *Chunk = @atomicLoad(*Chunk, entry.value_ptr, .acquire);
            if (!chunk.dirty) continue;
            chunk.generateMesh() catch {};
            @atomicStore(bool, &chunk.dirty, false, .release);
        }
    }

    pub fn getBlock(pos: Vec3i) u8 {
        const chunk: ?*Chunk = getChunk(toChunkPos(pos));
        return if (chunk) |c| c.getBlock(pos) else 0;
    }

    pub fn setBlock(position: Vec3i, b: u8) !void {
        const chunk: *Chunk = try getChunkOrGen(toChunkPos(position));
        chunk.setBlock(position, b);
        @atomicStore(bool, &chunk.dirty, true, .release);
    }

    pub fn setBlockUpdate(position: Vec3i, b: u8) !void {
        if (!Block.valid(b)) return;
        try updateNeighbors(position);
        try setBlock(position, b);
    }

    pub fn updateNeighbors(position: Vec3i) !void {
        for (Neighbor.iterable) |n| {
            const offset: Vec3i = n.relPos();
            const neighbor_pos: Vec3i = (offset + position);
            const chunk: *Chunk = try getChunkOrGen(toChunkPos(neighbor_pos));
            if (chunk.getBlock(neighbor_pos) != 0) @atomicStore(bool, &chunk.dirty, true, .release);
        }
    }

    pub fn addChunk(position: anytype) !void {
        const newChunk: *Chunk = try Chunk.create();
        newChunk.* = Chunk.Empty;
        newChunk.*.pos = ChunkPosition.fromWorldPos(position);
        chunks.put(newChunk.pos.hashFromChunkPos(), newChunk) catch |err| std.debug.print("cannot addChunk {}", .{err});
    }

    pub fn getChunk(position: Vec3i) ?*Chunk {
        const hash: u96 = ChunkPosition.hashFromPos(position);
        const chunk: ?*Chunk = chunks.get(hash);
        return if (chunk) |c| c else null;
    }

    pub fn getChunkOrGen(position: Vec3i) !*Chunk {
        var chunk: ?*Chunk = getChunk(position);
        if (chunk == null) {
            try addChunk(position);
            chunk = getChunk(position);
        }
        return chunk.?;
    }
};

pub const Generate = struct {
    fn safeSetBlock(pos: Vec3i, block: Block.ID) !void {
        if (Map.getChunk(toChunkPos(pos)) == null) try Map.addChunk(toChunkPos(pos));
        const targetChunk: ?*Chunk = Map.getChunk(toChunkPos(pos));
        if (targetChunk) |t| t.setBlock(pos, @intCast(@intFromEnum(block)));
    }

    pub fn generateChunk(position: Vec3i) !void { // Move to Chunk type?
        if (Map.getChunk(position)) |c| {
            if (c.generated) return;
        } else {
            try Map.addChunk(position);
        }

        const chunk: ?*Chunk = Map.getChunk(position);
        if (chunk == null) return;

        const radius: i32 = 8; // TODO get real radius
        const chunk_count = (radius * 2 + 1) * (radius * 2 + 1) * (radius * 2 + 1);
        try Map.chunks.ensureTotalCapacity(chunk_count); // Total or unused?

        if (chunk) |c| {
            const size: u8 = chunkSize;

            const image: rl.Image = rl.genImagePerlinNoise(size, size, c.pos.wx, c.pos.wz, 0.1);
            defer image.unload();

            const image2: rl.Image = rl.genImagePerlinNoise(size, size, c.pos.wx, c.pos.wz, 2);
            defer image2.unload();

            const colors: []rl.Color = rl.loadImageColors(image) catch unreachable;
            const colors2: []rl.Color = rl.loadImageColors(image2) catch unreachable;

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

                    const setBlockPos: Vec3i = .{ @intCast(x), height, @intCast(z) };

                    // Stone
                    for (0..@intCast(height)) |h| {
                        const blockPos: Vec3i = .{ setBlockPos[0] + c.pos.wx, height - @as(i32, @intCast(h)), setBlockPos[2] + c.pos.wz };
                        try safeSetBlock(blockPos, .stone);
                    }

                    // Dirt
                    for (0..3) |h| {
                        const blockPos: Vec3i = .{ setBlockPos[0] + c.pos.wx, height + @as(i32, @intCast(h)), setBlockPos[2] + c.pos.wz };
                        try safeSetBlock(blockPos, .dirt);
                    }

                    // Grass
                    const blockPos: Vec3i = .{ setBlockPos[0] + c.pos.wx, height + 3, setBlockPos[2] + c.pos.wz };
                    try safeSetBlock(blockPos, .grass);

                    // Trees
                    if (rl.getRandomValue(0, 100) == 1) {
                        try Structures.place(.oak_tree, blockPos);
                    }
                }
            }

            @atomicStore(bool, &c.generated, true, .release); // c.generated = true;
        }
    }

    pub const Structures = struct {
        const BlockDef = struct { pos: Vec3i, id: Block.ID };
        const StructureData = struct { blocks: []const BlockDef };
        const StructType = enum(u8) {
            oak_tree,
            _,

            const iterable: [1]StructType = [_]StructType{@enumFromInt(0)};
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

        pub fn place(structure: StructType, base_pos: Vec3i) !void {
            const data: ?StructureData = switch (structure) {
                .oak_tree => Structures.oak_tree,
                else => null,
            };

            if (data) |payload| {
                if (payload.blocks.len == 0) return;

                for (payload.blocks) |block| {
                    const world_pos: Vec3i = (base_pos + block.pos);
                    try safeSetBlock(world_pos, block.id);
                }
            }
        }
    };
};
