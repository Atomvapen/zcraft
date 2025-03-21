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

const ChunkPosition = struct {
    wx: i32,
    wy: i32,
    wz: i32,
};

const Chunk = struct {
    blocks: [chunkSize][chunkSize][chunkSize]u8,
    model: ?rl.Model = null,
    dirty: bool = false,
    generated: bool = false,
    pos: ChunkPosition,

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

    pub fn getChunkBlock(self: *Chunk, position: rl.Vector3) u8 {
        const x: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.x)), chunkSize));
        const y: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.y)), chunkSize));
        const z: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.z)), chunkSize));

        return self.blocks[x][y][z];
    }

    pub fn setChunkBlock(self: *Chunk, position: rl.Vector3, b: u8) void {
        const x: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.x)), chunkSize));
        const y: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.y)), chunkSize));
        const z: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.z)), chunkSize));

        self.*.blocks[x][y][z] = b;
        self.*.dirty = true;
    }

    pub fn setBlockUpdate(self: *Chunk, position: rl.Vector3, b: u8) void {
        // update Chunks around block that is updated
        const sides = [_]rl.Vector3{ .{ .x = 0, .y = 1, .z = 0 }, .{ .x = 0, .y = -1, .z = 0 }, .{ .x = 1, .y = 0, .z = 0 }, .{ .x = -1, .y = 0, .z = 0 }, .{ .x = 0, .y = 0, .z = 1 }, .{ .x = 0, .y = 0, .z = -1 } };
        for (sides) |s| {
            const pos: rl.Vector3 = .{ .x = position.x + s.x, .y = position.y + s.y, .z = position.z + s.z };
            if (self.getChunkBlock(pos) != 0) {
                const chunk = Map.getChunk(pos);
                if (chunk) |c| c.*.dirty = true;
                // getChunkOrGen(toChunkPos(.{ .x = position.x + s.x, .y = position.y + s.y, .z = position.z + s.z })).*.dirty = true;
                // self.dirty = true;
            }
        }

        self.setChunkBlock(position, b);
    }
};

pub const Map = struct {
    var chunks: std.AutoHashMap(u96, Chunk) = std.AutoHashMap(u96, Chunk).init(util.allocator);

    pub fn draw(ctx: *Context) void {
        var mapIter = chunks.iterator();
        while (mapIter.next()) |chunk| {
            if (chunk.value_ptr.model == null) continue;
            const pos = toWorldPos(chunkPosFromHash(chunk.key_ptr.*));
            if (!cull.isChunkVisible(pos, ctx)) continue;
            rl.drawModel(chunk.value_ptr.model.?, pos, 1, rl.Color.white);
        }
    }

    pub fn update() void {
        var mapIter = chunks.iterator();

        while (mapIter.next()) |chunk| {
            if (chunk.value_ptr.dirty == false) continue;
            chunk.value_ptr.generateMesh(chunkPosFromHash(chunk.key_ptr.*)) catch {};
            chunk.value_ptr.*.dirty = false;
        }
    }

    pub fn getChunkRelativePos(position: rl.Vector3) ?*Chunk {
        const pos = toChunkPos(position);
        return chunks.getPtr(hashFromChunkPos(pos.x, pos.y, pos.z));
    }

    // pub fn getChunkOrGenRelativePos(position: rl.Vector3) ?*Chunk {
    //     var chunk = getChunkRelativePos(position);
    //     if (chunk == null) {
    //         addChunk(position);
    //         chunk = getChunkRelativePos(position);
    //     }
    //     return chunk.?;
    // }

    pub fn getBlock(position: rl.Vector3) u8 {
        const chunk = getChunk(toChunkPos(position));
        return if (chunk) |c| c.getChunkBlock(position) else 0;
    }

    pub fn setBlock(position: rl.Vector3, b: u8) void {
        const chunk = getChunkOrGen(toChunkPos(position));
        chunk.setChunkBlock(position, b);
    }

    pub fn setBlockUpdate(position: rl.Vector3, b: u8) void {
        if (!Blocks.Block.valid(b)) return;

        // update Chunks around block that is updated
        const sides = [_]rl.Vector3{ .{ .x = 0, .y = 1, .z = 0 }, .{ .x = 0, .y = -1, .z = 0 }, .{ .x = 1, .y = 0, .z = 0 }, .{ .x = -1, .y = 0, .z = 0 }, .{ .x = 0, .y = 0, .z = 1 }, .{ .x = 0, .y = 0, .z = -1 } };
        for (sides) |s| {
            const pos: rl.Vector3 = .{ .x = position.x + s.x, .y = position.y + s.y, .z = position.z + s.z };
            if (getBlock(pos) != 0) getChunkOrGen(toChunkPos(pos)).*.dirty = true;
        }

        setBlock(position, b);
    }

    pub fn addChunk(position: anytype) void {
        const emptyChunk = undefined;
        chunks.ensureUnusedCapacity(10) catch {};
        chunks.put(hashFromChunkPos(position.x, position.y, position.z), emptyChunk) catch |err| std.debug.print("cannot addChunk {}", .{err});
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

    fn chunkPosFromHash(key: u96) rl.Vector3 {
        return rl.Vector3{
            .x = @floatFromInt(@as(i32, @bitCast(@as(u32, @truncate(key >> 64))))),
            .y = @floatFromInt(@as(i32, @bitCast(@as(u32, @truncate(key >> 32))))),
            .z = @floatFromInt(@as(i32, @bitCast(@as(u32, @truncate(key))))),
        };
    }
};

pub const Generate = struct {
    pub fn generate(position: rl.Vector3) void {
        if (Map.getChunk(position)) |c| if (c.generated) return;

        const pos = toWorldPos(position);
        const size = chunkSize;

        const image = rl.genImagePerlinNoise(size, size, @intFromFloat(pos.x), @intFromFloat(pos.z), 0.1);
        defer image.unload();

        const image2 = rl.genImagePerlinNoise(size, size, @intFromFloat(pos.x), @intFromFloat(pos.z), 2);
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
                    Map.setBlock(
                        .{ .x = setBlockPos.x + pos.x, .y = @floatFromInt(height - @as(i32, @intCast(h))), .z = setBlockPos.z + pos.z },
                        @intCast(@intFromEnum(Blocks.Block.ID.stone)),
                    );
                }
                Map.setBlock(
                    .{ .x = setBlockPos.x + pos.x, .y = @floatFromInt(height), .z = setBlockPos.z + pos.z },
                    @intCast(@intFromEnum(Blocks.Block.ID.grass)),
                );

                if (rl.getRandomValue(0, 100) == 1) {
                    createTree(.{ .x = setBlockPos.x + pos.x, .y = @floatFromInt(height), .z = setBlockPos.z + pos.z });
                }
            }
        }

        Map.getChunk(position).?.generated = true;
    }

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

// pub fn getBlockStruct(position: rl.Vector3) blocks.Block {
//     const chunk = Map.getChunk(toChunkPos(position));
//     const block = blocks.Block.fromInt(if (chunk) |c| c.getBlock2(position) else 0);
//     return block;
// }

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
