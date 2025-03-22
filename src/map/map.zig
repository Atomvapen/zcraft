const std = @import("std");
const model = @import("../rendering/models.zig");
const cull = @import("../rendering/frustumCulling.zig");
const util = @import("../rendering/utilities.zig");
const rl = @import("raylib");
const Context = @import("../Context.zig");
const Blocks = @import("blocks.zig");

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

    pub fn setBlock(self: *Chunk, position: rl.Vector3, b: u8) void {
        const x: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.x)), chunkSize));
        const y: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.y)), chunkSize));
        const z: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.z)), chunkSize));

        self.*.blocks[x][y][z] = b;
        self.*.dirty = true;
    }
};

const ChunkPosition = struct {
    wx: i32,
    wy: i32,
    wz: i32,

    pub fn fromVec3(v: rl.Vector3) ChunkPosition {
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

    pub fn hashFromPos(self: ChunkPosition) u96 {
        var result: u96 = 0;

        result |= @as(u96, @as(u32, @bitCast(self.wx))) << 64;
        result |= @as(u96, @as(u32, @bitCast(self.wy))) << 32;
        result |= @as(u96, @as(u32, @bitCast(self.wz)));

        return result;
    }

    pub fn posFromHash(key: u96) ChunkPosition {
        return .{
            .wx = @bitCast(@as(u32, @truncate(key >> 64))),
            .wy = @bitCast(@as(u32, @truncate(key >> 32))),
            .wz = @bitCast(@as(u32, @truncate(key))),
        };
    }

    pub fn distanceTo(self: ChunkPosition, player_x: f32, player_y: f32, player_z: f32) f32 {
        const center_x = @as(f32, @floatFromInt(self.wx * chunkSize)) + (chunkSize / 2.0);
        const center_y = @as(f32, @floatFromInt(self.wy * chunkSize)) + (chunkSize / 2.0);
        const center_z = @as(f32, @floatFromInt(self.wz * chunkSize)) + (chunkSize / 2.0);

        const dx = player_x - center_x;
        const dy = player_y - center_y;
        const dz = player_z - center_z;

        return @sqrt(dx * dx + dy * dy + dz * dz);
    }

    pub fn distanceSquaredTo(self: ChunkPosition, player_x: f32, player_y: f32, player_z: f32) f32 {
        const center_x = @as(f32, @floatFromInt(self.wx * chunkSize)) + (chunkSize / 2.0);
        const center_y = @as(f32, @floatFromInt(self.wy * chunkSize)) + (chunkSize / 2.0);
        const center_z = @as(f32, @floatFromInt(self.wz * chunkSize)) + (chunkSize / 2.0);

        const dx = player_x - center_x;
        const dy = player_y - center_y;
        const dz = player_z - center_z;

        return dx * dx + dy * dy + dz * dz;
    }
};

pub const Map = struct {
    var chunks: std.AutoHashMap(u96, Chunk) = std.AutoHashMap(u96, Chunk).init(util.allocator);

    pub fn draw(ctx: *Context) void {
        var mapIter = chunks.iterator();
        while (mapIter.next()) |entry| {
            const chunk = entry.value_ptr;

            if (chunk.model == null) continue;
            const pos = chunk.pos.toVec3();
            if (!cull.isChunkVisible(pos, ctx)) continue;
            rl.drawModel(chunk.model.?, pos, 1, rl.Color.white);
        }
    }

    pub fn update() void {
        var mapIter = chunks.iterator();

        while (mapIter.next()) |entry| {
            var chunk = entry.value_ptr;
            if (!chunk.dirty) continue;
            const pos = toChunkPos(chunk.pos.toVec3());
            chunk.generateMesh(pos) catch {};
            chunk.*.dirty = false;
        }
    }

    pub fn getChunkRelativePos(position: rl.Vector3) ?*Chunk {
        const pos = toChunkPos(position);
        return chunks.getPtr(hashFromChunkPos(pos.x, pos.y, pos.z));
    }

    pub fn getBlock(position: rl.Vector3) u8 {
        const chunk = getChunk(toChunkPos(position));
        return if (chunk) |c| c.getBlock(position) else 0;
    }

    pub fn setBlock(position: rl.Vector3, b: u8) void {
        const chunk = getChunkOrGen(toChunkPos(position));
        chunk.setBlock(position, b);
    }

    pub fn updateNeighbor(position: rl.Vector3) void {
        for (Neighbor.iterable) |n| {
            const offset = n.relPos();
            const neighbor_pos = rl.Vector3{
                .x = position.x + offset.x,
                .y = position.y + offset.y,
                .z = position.z + offset.z,
            };
            const chunk = getChunkOrGen(toChunkPos(neighbor_pos));

            if (chunk.getBlock(neighbor_pos) != 0) {
                chunk.*.dirty = true;
            }
        }
    }

    pub fn setBlockUpdate(position: rl.Vector3, b: u8) void {
        if (!Blocks.Block.valid(b)) return;
        updateNeighbor(position);
        setBlock(position, b);
    }

    pub fn addChunk(position: anytype) void {
        var newChunk = Chunk.Empty;
        newChunk.pos = ChunkPosition.fromVec3(toWorldPos(position));
        chunks.ensureUnusedCapacity(15) catch {};
        chunks.put(hashFromChunkPos(position.x, position.y, position.z), newChunk) catch |err| std.debug.print("cannot addChunk {}", .{err});
    }

    pub fn getChunk(position: rl.Vector3) ?*Chunk {
        return chunks.getPtr(hashFromChunkPos(position.x, position.y, position.z));
    }

    pub fn getChunkOrGen(position: rl.Vector3) *Chunk {
        var chunk = getChunk(position);
        if (chunk == null) {
            addChunk(position);
            chunk = getChunk(position);
        }
        return chunk.?;
    }

    fn hashFromChunkPos(x: f32, y: f32, z: f32) u96 {
        const x_bits: i32 = @intFromFloat(x);
        const y_bits: i32 = @intFromFloat(y);
        const z_bits: i32 = @intFromFloat(z);

        var result: u96 = 0;

        result |= @as(u96, @as(u32, @bitCast(x_bits))) << 64;
        result |= @as(u96, @as(u32, @bitCast(y_bits))) << 32;
        result |= @as(u96, @as(u32, @bitCast(z_bits)));

        return result;
    }
};

pub const Generate = struct {
    pub fn generate(position: rl.Vector3) void {
        var chunk = Map.getChunk(position);

        if (Map.getChunk(position)) |c| {
            if (c.generated) return;
        } else Map.addChunk(position);

        chunk = Map.getChunk(position);

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
                        Map.setBlock(blockPos, @intCast(@intFromEnum(Blocks.Block.ID.stone)));
                        // c.setBlock(blockPos, @intCast(@intFromEnum(Blocks.Block.ID.stone)));
                    }

                    const blockPos: rl.Vector3 = .{ .x = setBlockPos.x + @as(f32, @floatFromInt(c.pos.wx)), .y = @floatFromInt(height), .z = setBlockPos.z + @as(f32, @floatFromInt(c.pos.wz)) };
                    Map.setBlock(blockPos, @intCast(@intFromEnum(Blocks.Block.ID.grass)));
                    // c.setBlock(blockPos, @intCast(@intFromEnum(Blocks.Block.ID.grass)));

                    if (rl.getRandomValue(0, 100) == 1) {
                        createTree(blockPos);
                    }
                }
            }

            c.generated = true;
        }
    }

    // pub fn generate(position: rl.Vector3) void {
    //     const chunk = Map.getChunk(position);
    //     if (chunk) |c| if (c.generated) return;

    //     const pos = toWorldPos(position);
    //     const size = chunkSize;

    //     const image = rl.genImagePerlinNoise(size, size, @intFromFloat(pos.x), @intFromFloat(pos.z), 0.1);
    //     defer image.unload();

    //     const image2 = rl.genImagePerlinNoise(size, size, @intFromFloat(pos.x), @intFromFloat(pos.z), 2);
    //     defer image2.unload();

    //     const colors = rl.loadImageColors(image) catch unreachable;
    //     const colors2 = rl.loadImageColors(image2) catch unreachable;

    //     for (0..@intCast(image.height)) |z| {
    //         for (0..@intCast(image.width)) |x| {
    //             const index = z * @as(usize, @intCast(image.width)) + x;
    //             const pixel = colors[index];
    //             const pixel2 = colors2[index];

    //             var height: i32 = 0;
    //             height += pixel2.r;
    //             height += pixel2.g;
    //             height += pixel2.b;
    //             height = @divFloor(height, 10);

    //             height += pixel.b;
    //             height += pixel.r;
    //             height += pixel.g;
    //             height = @divFloor(height, 40);
    //             height += 20;

    //             const setBlockPos = rl.Vector3{ .x = @floatFromInt(x), .y = @floatFromInt(height), .z = @floatFromInt(z) };

    //             for (0..@intCast(height)) |h| {
    //                 const blockPos: rl.Vector3 = .{ .x = setBlockPos.x + pos.x, .y = @as(f32, @floatFromInt(height)) - @as(f32, @floatFromInt(@as(i32, @intCast(h)))), .z = setBlockPos.z + pos.z };
    //                 Map.setBlock(blockPos, @intCast(@intFromEnum(Blocks.Block.ID.stone)));
    //             }

    //             const blockPos: rl.Vector3 = .{ .x = setBlockPos.x + pos.x, .y = @floatFromInt(height), .z = setBlockPos.z + pos.z };
    //             Map.setBlock(blockPos, @intCast(@intFromEnum(Blocks.Block.ID.grass)));

    //             if (rl.getRandomValue(0, 100) == 1) {
    //                 createTree(blockPos);
    //             }
    //         }
    //     }

    //     Map.getChunk(position).?.generated = true;
    // }

    pub fn createTree(position: rl.Vector3) void {
        Map.setBlock(position, 1);

        for (0..3) |i| {
            const x: f32 = @floatFromInt(i);
            for (0..3) |t| {
                const y: f32 = @floatFromInt(t);
                for (0..3) |q| {
                    const z: f32 = @floatFromInt(q);
                    Map.setBlock(
                        .{ .x = position.x + x - 1, .y = position.y + 4 + y, .z = position.z + z - 1 },
                        @intCast(@intFromEnum(Blocks.Block.ID.leaf)),
                    );
                }
            }
        }

        for (0..5) |i| {
            const h: f32 = @floatFromInt(i);
            Map.setBlock(
                .{ .x = position.x, .y = position.y + h, .z = position.z },
                @intCast(@intFromEnum(Blocks.Block.ID.wood)),
            );
        }
    }
};
