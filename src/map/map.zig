const std = @import("std");
const model = @import("../rendering/models.zig");
const cull = @import("../rendering/frustumCulling.zig");
const util = @import("../rendering/utilities.zig");
const rl = @import("raylib");
const Context = @import("../Context.zig");
const blocks = @import("blocks.zig");

pub const chunkSize: u8 = 16;

// pub const BlockTypes = enum(u8) {
//     air = 0,
//     grass,
//     glass,
//     brick,
//     stone,
//     wood,
//     leaf,

//     pub fn toInt(self: BlockTypes) i32 {
//         return @intFromEnum(self);
//     }
// };

const Chunk = struct {
    Blocks: [chunkSize][chunkSize][chunkSize]u8,
    Model: ?rl.Model = null,
    Dirty: bool = false,
    Generated: bool = false,

    // Function to start async mesh generation
    // pub fn startGenMesh(self: *Chunk, pos: rl.Vector3) !void {
    //     // Spawn a new task to generate the mesh asynchronously
    //     const allocator = std.heap.page_allocator;
    //     _ = try std.Thread.spawn(.{ .allocator = allocator }, asyncGenMesh, .{ self, pos });
    // }

    // // Async function for mesh generation
    // fn asyncGenMesh(self: *Chunk, pos: rl.Vector3) !void {
    //     // Call the mesh generation function synchronously in a separate task
    //     try self.genMesh(pos);
    //     // if (result) |err| {
    //     //     std.debug.print("Error generating mesh: {}\n", .{err});
    //     // }
    // }
    // var Mutex = std.Thread.Mutex{};

    fn genMesh(self: *Chunk, pos: rl.Vector3) !void {
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
                    if (self.Blocks[x][y][z] == 0) {
                        continue;
                    }

                    const bc = rl.Vector3{ .x = @floatFromInt(x), .y = @floatFromInt(y), .z = @floatFromInt(z) };
                    const bw = rl.Vector3.add(chunkPosWorld, bc);

                    //const tSize = 1;//1.0 / 16.0; //tile size
                    //const xt = tSize * @as(f32, @floatFromInt(getBlock(.{bw.x, bw.y, bw.z}) - 1));
                    //const texCords = [_]f32{ xt, 0.0, tSize + xt, 0.0, tSize + xt, tSize, 0.0 + xt, tSize };
                    const block = getBlock(.{ .x = bw.x, .y = bw.y, .z = bw.z }) - 1;
                    const texCords = [_]u8{ block, block + 1, block + 18, block + 17 };

                    // up face
                    if (isTransparent(getBlock(.{ .x = bw.x, .y = bw.y + 1, .z = bw.z }))) {
                        const vert = [_]f32{ bc.x, bc.y + 1, bc.z, bc.x + 1, bc.y + 1, bc.z, bc.x + 1, bc.y + 1, bc.z + 1, bc.x, bc.y + 1, bc.z + 1 };
                        const inds = [_]u16{ indsOffset, indsOffset + 2, indsOffset + 1, indsOffset, indsOffset + 3, indsOffset + 2 };

                        vertList.appendSlice(&vert) catch {};
                        indsList.appendSlice(&inds) catch {};
                        texList.appendSlice(&texCords) catch {};
                        indsOffset += 4;
                    }

                    if (isTransparent(getBlock(.{ .x = bw.x, .y = bw.y - 1, .z = bw.z }))) {
                        const vert = [_]f32{ bc.x, bc.y, bc.z, bc.x + 1, bc.y, bc.z, bc.x + 1, bc.y, bc.z + 1, bc.x, bc.y, bc.z + 1 };
                        const inds = [_]u16{ indsOffset, indsOffset + 1, indsOffset + 2, indsOffset, indsOffset + 2, indsOffset + 3 };

                        vertList.appendSlice(&vert) catch {};
                        indsList.appendSlice(&inds) catch {};
                        texList.appendSlice(&texCords) catch {};
                        indsOffset += 4;
                    }

                    if (isTransparent(getBlock(.{ .x = bw.x, .y = bw.y, .z = bw.z + 1 }))) {
                        const vert = [_]f32{ bc.x, bc.y, bc.z + 1, bc.x + 1, bc.y, bc.z + 1, bc.x + 1, bc.y + 1, bc.z + 1, bc.x, bc.y + 1, bc.z + 1 };
                        const inds = [_]u16{ indsOffset, indsOffset + 1, indsOffset + 2, indsOffset, indsOffset + 2, indsOffset + 3 };

                        vertList.appendSlice(&vert) catch {};
                        indsList.appendSlice(&inds) catch {};
                        texList.appendSlice(&texCords) catch {};
                        indsOffset += 4;
                    }

                    if (isTransparent(getBlock(.{ .x = bw.x, .y = bw.y, .z = bw.z - 1 }))) {
                        const vert = [_]f32{ bc.x, bc.y, bc.z, bc.x + 1, bc.y, bc.z, bc.x + 1, bc.y + 1, bc.z, bc.x, bc.y + 1, bc.z };
                        const inds = [_]u16{ indsOffset, indsOffset + 2, indsOffset + 1, indsOffset, indsOffset + 3, indsOffset + 2 };

                        vertList.appendSlice(&vert) catch {};
                        indsList.appendSlice(&inds) catch {};
                        texList.appendSlice(&texCords) catch {};
                        indsOffset += 4;
                    }

                    if (isTransparent(getBlock(.{ .x = bw.x + 1, .y = bw.y, .z = bw.z }))) {
                        const vert = [_]f32{ bc.x + 1, bc.y, bc.z, bc.x + 1, bc.y, bc.z + 1, bc.x + 1, bc.y + 1, bc.z + 1, bc.x + 1, bc.y + 1, bc.z };
                        const inds = [_]u16{ indsOffset, indsOffset + 2, indsOffset + 1, indsOffset, indsOffset + 3, indsOffset + 2 };

                        vertList.appendSlice(&vert) catch {};
                        indsList.appendSlice(&inds) catch {};
                        texList.appendSlice(&texCords) catch {};
                        indsOffset += 4;
                    }

                    if (isTransparent(getBlock(.{ .x = bw.x - 1, .y = bw.y, .z = bw.z }))) {
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
            if (self.Model != null) {
                model.unloadMesh(self.Model.?.meshes[0]);
                self.Model = null;
            }
            return;
        }

        if (self.Model != null) {
            model.unloadMesh(self.Model.?.meshes[0]);
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

        self.Model = try rl.loadModelFromMesh(mesh);

        model.setTexture(self.Model.?, util.loadTexture("res/sprites.png"));
        model.setShadowShader(self.Model.?);
    }

    // fn genMesh(self: *Chunk, pos: rl.Vector3) !void {
    //     const chunkPosWorld = rl.Vector3.scale(pos, chunkSize);

    //     var vertList = std.ArrayList(f32).init(util.allocator);
    //     defer vertList.deinit();

    //     var indsList = std.ArrayList(u32).init(util.allocator); // Use u32 for indices
    //     defer indsList.deinit();

    //     var texList = std.ArrayList(u8).init(util.allocator);
    //     defer texList.deinit();

    //     var indsOffset: u32 = 0;

    //     for (0..chunkSize) |x| {
    //         for (0..chunkSize) |y| {
    //             for (0..chunkSize) |z| {
    //                 if (self.Blocks[x][y][z] == 0) {
    //                     continue;
    //                 }

    //                 const bc = rl.Vector3{ .x = @floatFromInt(x), .y = @floatFromInt(y), .z = @floatFromInt(z) };
    //                 const bw = rl.Vector3.add(chunkPosWorld, bc);

    //                 const block = getBlock(.{ .x = bw.x, .y = bw.y, .z = bw.z }) - 1;
    //                 const texCords = [_]u8{ block, block + 1, block + 18, block + 17 };

    //                 // Handle faces similarly as you did before
    //                 // For example: the 'up face' part can be added here

    //                 // up face (example)
    //                 if (isTransparent(getBlock(.{ .x = bw.x, .y = bw.y + 1, .z = bw.z }))) {
    //                     const vert = [_]f32{ bc.x, bc.y + 1, bc.z, bc.x + 1, bc.y + 1, bc.z, bc.x + 1, bc.y + 1, bc.z + 1, bc.x, bc.y + 1, bc.z + 1 };
    //                     const inds = [_]u32{ indsOffset, indsOffset + 2, indsOffset + 1, indsOffset, indsOffset + 3, indsOffset + 2 };

    //                     vertList.appendSlice(&vert) catch {};
    //                     indsList.appendSlice(&inds) catch {};
    //                     texList.appendSlice(&texCords) catch {};
    //                     indsOffset += 4;
    //                 }
    //                 // Similarly, handle other faces (down, left, right, etc.)
    //             }
    //         }
    //     }

    //     if (vertList.items.len == 0) { // emptyChunk
    //         if (self.Model != null) {
    //             model.unloadMesh(self.Model.?.meshes[0]);
    //             self.Model = null;
    //         }
    //         return;
    //     }

    //     if (self.Model != null) {
    //         model.unloadMesh(self.Model.?.meshes[0]);
    //     }

    //     var mesh = rl.Mesh{
    //         .triangleCount = @intCast(vertList.items.len / 6),
    //         .vertexCount = @intCast(vertList.items.len / 3),
    //         .indices = null, // We will set this later
    //         .vertices = null,
    //         .texcoords = null,
    //         .texcoords2 = null,
    //         .normals = null,
    //         .tangents = null,
    //         .colors = null,
    //         .animVertices = null,
    //         .animNormals = null,
    //         .boneIds = null,
    //         .boneWeights = null,
    //         .boneMatrices = null,
    //         .boneCount = 0,
    //         .vaoId = 0,
    //         .vboId = null,
    //     };

    //     // Allocate memory for indices and texcoords
    //     var indices = try util.allocator.alloc(u32, indsList.items.len);
    //     defer util.allocator.free(indices);

    //     var texCoords = try util.allocator.alloc(u8, texList.items.len);
    //     defer util.allocator.free(texCoords);

    //     // Copy indices data into mesh
    //     for (0..indsList.items.len) |e| indices[e] = indsList.items[e];

    //     // Copy texcoord data into mesh
    //     for (0..texList.items.len) |e| texCoords[e] = texList.items[e];

    //     // Now load the vertex data
    //     var vertices = try util.allocator.alloc(f32, vertList.items.len);
    //     defer util.allocator.free(vertices);

    //     for (0..vertList.items.len) |e| vertices[e] = vertList.items[e];

    //     // Set the mesh data
    //     mesh.indices = @ptrCast(indices.ptr);
    //     mesh.vertices = vertices.ptr;
    //     mesh.texcoords = @alignCast(@ptrCast(texCoords.ptr));

    //     // Upload mesh data to VRAM
    //     try model.UploadMesh(&mesh, vertices.ptr);

    //     self.Model = try rl.loadModelFromMesh(mesh);
    //     model.setTexture(self.Model.?, util.loadTexture("res/sprites.png"));
    //     model.setShadowShader(self.Model.?);
    // }

};

pub var map = std.AutoHashMap(u96, Chunk).init(util.allocator);

pub fn draw(ctx: *Context) void {
    var mapIter = map.iterator();
    while (mapIter.next()) |chunk| {
        if (chunk.value_ptr.Model == null) continue;
        if (!cull.isChunkVisible(toWorldPos(chunkPosFromHash(chunk.key_ptr.*)), ctx)) continue;
        rl.drawModel(chunk.value_ptr.Model.?, toWorldPos(chunkPosFromHash(chunk.key_ptr.*)), 1, rl.Color.white);
    }
}

pub fn update() void {
    var mapIter = map.iterator();

    while (mapIter.next()) |chunk| {
        if (chunk.value_ptr.Dirty == false) continue;
        chunk.value_ptr.genMesh(chunkPosFromHash(chunk.key_ptr.*)) catch {};
        // chunk.value_ptr.startGenMesh(chunkPosFromHash(chunk.key_ptr.*)) catch {};
        chunk.value_ptr.*.Dirty = false;
    }
}

fn isTransparent(i: u8) bool {
    return switch (@as(blocks.Type, @enumFromInt(i))) {
        .air, .glass, .leaf => true,
        else => false,
    };
}

// x i32 + y i32 + z i32 = u96 for hashing
// fn hashingFunc(x: i32, y: i32, z: i32) u96 {
fn hashingFunc(x: f32, y: f32, z: f32) u96 {
    const x1: i32 = @intFromFloat(x);
    const y1: i32 = @intFromFloat(y);
    const z1: i32 = @intFromFloat(z);

    var result: u96 = @as(u32, @bitCast(x1));

    result <<= 32;
    result += @as(u32, @bitCast(y1));

    result <<= 32;
    result += @as(u32, @bitCast(z1));

    return result;
}

pub fn chunkPosFromHash(key: u96) rl.Vector3 {
    return rl.Vector3{
        .x = @floatFromInt(@as(i32, @bitCast(@as(u32, @truncate(key >> 64))))),
        .y = @floatFromInt(@as(i32, @bitCast(@as(u32, @truncate(key >> 32))))),
        .z = @floatFromInt(@as(i32, @bitCast(@as(u32, @truncate(key))))),
    };
}

pub fn getBlock(position: rl.Vector3) u8 {
    const chunk = getChunk(toChunkPos(position));

    if (chunk) |c| {
        const x: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.x)), chunkSize));
        const y: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.y)), chunkSize));
        const z: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.z)), chunkSize));
        return c.Blocks[x][y][z];
    } else {
        return 0;
    }
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

pub fn getChunk(position: rl.Vector3) ?*Chunk {
    // return map.getPtr(hashingFunc(@intFromFloat(position.x), @intFromFloat(position.y), @intFromFloat(position.z)));
    return map.getPtr(hashingFunc(position.x, position.y, position.z));
}

// gen if there is no chunk
pub fn getChunkOrGen(position: rl.Vector3) *Chunk {
    const chunk = getChunk(position);
    if (chunk == null) addChunk(position);
    return getChunk(position).?;
}

pub fn setBlock(position: rl.Vector3, b: u8) void {
    const chunk = getChunkOrGen(toChunkPos(position));

    if (!blocks.Type.valid(b)) return;

    // update Chunks around block that is updated
    const sides = [_]rl.Vector3{ .{ .x = 0, .y = 1, .z = 0 }, .{ .x = 0, .y = -1, .z = 0 }, .{ .x = 1, .y = 0, .z = 0 }, .{ .x = -1, .y = 0, .z = 0 }, .{ .x = 0, .y = 0, .z = 1 }, .{ .x = 0, .y = 0, .z = -1 } };
    for (sides) |s| {
        if (getBlock(.{ .x = position.x + s.x, .y = position.y + s.y, .z = position.z + s.z }) != 0) {
            getChunkOrGen(toChunkPos(.{ .x = position.x + s.x, .y = position.y + s.y, .z = position.z + s.z })).*.Dirty = true;
        }
    }

    const x: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.x)), chunkSize));
    const y: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.y)), chunkSize));
    const z: u8 = @intCast(@mod(@as(i32, @intFromFloat(position.z)), chunkSize));

    chunk.*.Blocks[x][y][z] = b;
    chunk.*.Dirty = true;
}

const emptyChunk = undefined;
pub fn addChunk(position: anytype) void {
    // map.put(hashingFunc(@intFromFloat(position.x), @intFromFloat(position.y), @intFromFloat(position.z)), emptyChunk) catch |err| std.debug.print("cannot addChunk {}", .{err});
    map.put(hashingFunc(position.x, position.y, position.z), emptyChunk) catch |err| std.debug.print("cannot addChunk {}", .{err});
}
