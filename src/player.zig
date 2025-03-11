const Self = @This();

const map = @import("map/map.zig");
const shader = @import("rendering/shader.zig");
const mapGen = @import("map/generation.zig");
const rl = @import("raylib");
const std = @import("std");
const Context = @import("Context.zig");

ctx: *Context,
camera: rl.Camera3D = rl.Camera3D{
    .position = .{ .x = 1.0, .y = 40.0, .z = 1.0 },
    .target = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
    .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 },
    .fovy = 90.0,
    .projection = rl.CameraProjection.perspective,
},
selectedBlock: u8 = 1,
pos: rl.Vector3 = .{ .x = 1.0, .y = 40.0, .z = 1.0 },
vel: rl.Vector3 = undefined,
onGround: bool = false,
stats: struct { stamina: f32 = 100 } = .{},
spritning: bool = false,
crouching: bool = false,
speed: f32 = 0,

pub fn create(ctx: *Context) !*Self {
    const player: *Self = try ctx.allocator.create(Self);

    player.* = .{ .ctx = ctx };

    return player;
}

pub fn destroy(self: *Self) void {
    self.ctx.allocator.destroy(self);
}

pub fn update(self: *Self) void {
    // std.debug.print("Player pos: {} Camera pos: {} Camera target: {}\n", .{ self.pos, self.camera.position, self.camera.target });
    // self.camera.target = self.camera.position.add(rl.Vector3{ .x = 0, .y = 0, .z = 1 });

    self.render();
    self.updateMap();
    self.handleKeybindings();

    self.applyGravity(@floatCast(self.ctx.deltatime));
    self.movePlayer(@floatCast(self.ctx.deltatime));
    self.updatePos(@floatCast(self.ctx.deltatime));
}

fn render(self: *Self) void {
    // Shadow follow player
    if (@abs((shader.lightCam.position.x + shader.lightCam.position.z) - (self.camera.position.x + self.camera.position.z)) > 50) {
        shader.lightCam.position.x = self.camera.position.x;
        shader.lightCam.position.z = self.camera.position.z;
        shader.lightCam.target.x = self.camera.position.x;
        shader.lightCam.target.z = self.camera.position.z + 0.001;
    }

    if (self.sendRayCameraTarget() != null) {
        rl.drawCube(sendRayCameraTarget(self).?, 1.01, 1.01, 1.01, rl.colorAlpha(rl.Color.black, 0.5));
    }
}

fn isIntersectingAABB(pos1: rl.Vector3, size1: rl.Vector3, pos2: rl.Vector3, size2: rl.Vector3) bool {
    return (pos1.x < pos2.x + size2.x and pos1.x + size1.x > pos2.x) and
        (pos1.y < pos2.y + size2.y and pos1.y + size1.y > pos2.y) and
        (pos1.z < pos2.z + size2.z and pos1.z + size1.z > pos2.z);
}

fn sprint(self: *Self) !void {
    if (rl.isKeyDown(.left_shift) and !(self.stats.stamina <= 10)) {
        self.speed *= 1.5;
        self.stats.stamina -= 0.2;
        self.camera.fovy = 100;
    } else {
        self.stats.stamina += 0.1;
        self.camera.fovy = 90;
    }
    self.stats.stamina = rl.math.clamp(self.stats.stamina, 0, 100);

    // std.debug.print("{}\n", .{self.stats.stamina});
}

// fn crouch(self: *Self) void {}

fn handleKeybindings(self: *Self) void {
    if (rl.isKeyPressed(.f11)) {
        rl.toggleFullscreen();
    }

    if (rl.isKeyDown(.k)) {
        shader.lightCam.target.z += 0.01;
    }

    if (rl.isKeyPressed(.x)) {
        mapGen.createTree(self.camera.position);
    }

    if (rl.isKeyDown(.l)) {
        shader.lightCam.target.z -= 0.01;
    }

    //Hotbar TEMP
    for (49..57) |key| {
        if (rl.isKeyPressed(@enumFromInt(key))) self.selectedBlock = @intCast(key - 48);
    }

    if (rl.isMouseButtonPressed(.right)) {
        if (self.sendRayNormal()) |hit| {
            { //TODO FIX
                const hit_size = rl.Vector3{ .x = 1, .y = 1, .z = 1 }; // Adjust based on hitbox
                const player_size = rl.Vector3{ .x = 1, .y = 2, .z = 1 }; // Example player size
                var hit1: rl.Vector3 = hit[0];
                const hit2: rl.Vector3 = hit[0];

                hit1.y += 1; // Moving the hitbox down

                if (isIntersectingAABB(hit1, hit_size, self.pos, player_size)) return;
                if (isIntersectingAABB(hit2, hit_size, self.pos, player_size)) return;
            }

            const hitPos: rl.Vector3 = hit[0]; // Block position
            const hitNormal: rl.Vector3 = hit[1]; // Correct face normal

            // Compute new block position correctly
            // const newBlockPos: rl.Vector3 = rl.Vector3{
            //     .x = hitPos.x + hitNormal.x,
            //     .y = hitPos.y + hitNormal.y,
            //     .z = hitPos.z + hitNormal.z,
            // };
            const newBlockPos: rl.Vector3 = .{
                .x = @round(hitPos.x + hitNormal.x),
                .y = @round(hitPos.y + hitNormal.y),
                .z = @round(hitPos.z + hitNormal.z),
            };
            // const newBlockPos: rl.Vector3 = if (hitNormal.x != 0)
            //     if (hitNormal.x > 0) rl.Vector3{ .x = hitPos.x - 1, .y = hitPos.y, .z = hitPos.z } else rl.Vector3{ .x = hitPos.x + 1, .y = hitPos.y, .z = hitPos.z }
            // else if (hitNormal.y != 0)
            //     if (hitNormal.y > 0) rl.Vector3{ .x = hitPos.x, .y = hitPos.y + 1, .z = hitPos.z } // Place above for top face
            //     else rl.Vector3{ .x = hitPos.x, .y = hitPos.y - 1, .z = hitPos.z } // Place below for bottom face
            // else if (hitNormal.z != 0)
            //     if (hitNormal.z > 0) rl.Vector3{ .x = hitPos.x, .y = hitPos.y, .z = hitPos.z + 1 } else rl.Vector3{ .x = hitPos.x, .y = hitPos.y, .z = hitPos.z - 1 }
            // else
            //     hitPos; // Fallback

            // std.debug.print("Hit: {any}, Normal: {any}, NewPos: {any}\n", rl.Vector3{ hitPos, hitNormal, newBlockPos });

            // std.debug.print("pos: {any}\n", .{hitPos});
            // std.debug.print("normal: {any}\n", .{hitNormal});
            // std.debug.print("newpos: {any}\n", .{newBlockPos});

            map.setBlock(newBlockPos, self.selectedBlock);
        }
    }

    if (rl.isMouseButtonPressed(.left)) {
        if (self.sendRayCameraTarget()) |hit| {
            map.setBlock(hit, 0);
        }
    }

    if (rl.isMouseButtonPressed(.middle)) {
        if (self.sendRayCameraTarget()) |hit| {
            self.selectedBlock = map.getBlock(hit);
        }
    }
}

fn updateMap(self: *Self) void {
    const chunkPos = map.toChunkPos(.{ .x = self.camera.position.x, .y = 0, .z = self.camera.position.z });
    const chunk = map.getChunk(chunkPos);

    if (chunk) |c| {
        if (!c.Generated) mapGen.generate(chunkPos);
    } else {
        mapGen.generate(chunkPos);
    }

    // const renderDistance: f32 = 5;
    // for (0..@intFromFloat(renderDistance)) |x| {
    //     for (0..@intFromFloat(renderDistance)) |z| {
    //         mapGen.generate(.{
    //             .x = chunkPos.x + @as(f32, @floatFromInt(x)) - (renderDistance / 2),
    //             .y = 0,
    //             .z = chunkPos.z + @as(f32, @floatFromInt(z)) - (renderDistance / 2),
    //         });
    //     }
    // }

    const renderDistance: i32 = 5;
    for (0..@intCast(renderDistance)) |i| {
        for (0..@intCast(renderDistance)) |y| {
            mapGen.generate(.{
                .x = @floatFromInt(@as(i32, @intFromFloat(chunkPos.x)) + @as(i32, @intCast(i)) - renderDistance / 2),
                .y = 0,
                .z = @floatFromInt(@as(i32, @intFromFloat(chunkPos.z)) + @as(i32, @intCast(y)) - renderDistance / 2),
            });
        }
    }
}

fn sendRayNormal(self: *Self) ?struct { rl.Vector3, rl.Vector3 } {
    const max_distance: f32 = 4.0; // Max ray distance
    const ray_dir = rl.Vector3.normalize(self.camera.target.subtract(self.camera.position));

    // Start position (rounded to voxel grid center)
    var pos: rl.Vector3 = .{
        .x = @round(self.camera.position.x),
        .y = @round(self.camera.position.y),
        .z = @round(self.camera.position.z),
    };

    const step: rl.Vector3 = .{
        .x = if (ray_dir.x > 0) 1 else -1,
        .y = if (ray_dir.y > 0) 1 else -1,
        .z = if (ray_dir.z > 0) 1 else -1,
    };

    var t_max: rl.Vector3 = .{
        .x = if (ray_dir.x != 0) (@abs((pos.x + step.x - self.camera.position.x) / ray_dir.x)) else 9999,
        .y = if (ray_dir.y != 0) (@abs((pos.y + step.y - self.camera.position.y) / ray_dir.y)) else 9999,
        .z = if (ray_dir.z != 0) (@abs((pos.z + step.z - self.camera.position.z) / ray_dir.z)) else 9999,
    };

    const t_delta: rl.Vector3 = .{
        .x = if (ray_dir.x != 0) @abs(1 / ray_dir.x) else 9999,
        .y = if (ray_dir.y != 0) @abs(1 / ray_dir.y) else 9999,
        .z = if (ray_dir.z != 0) @abs(1 / ray_dir.z) else 9999,
    };

    var normal: rl.Vector3 = rl.Vector3{ .x = 0, .y = 0, .z = 0 };

    while (@abs(pos.x - self.camera.position.x) < max_distance and
        @abs(pos.y - self.camera.position.y) < max_distance and
        @abs(pos.z - self.camera.position.z) < max_distance)
    {
        // Check for block hit
        if (map.getBlock(pos) != 0) {
            // Return the position of the hit and the normal for placement
            return .{ pos, normal };
        }

        // Move to the next voxel along the ray
        if (t_max.x < t_max.y and t_max.x < t_max.z) {
            pos.x += step.x;
            t_max.x += t_delta.x;
            normal = .{ .x = -step.x, .y = 0, .z = 0 }; // X-axis normal
        } else if (t_max.y < t_max.z) {
            pos.y += step.y;
            t_max.y += t_delta.y;
            normal = .{ .x = 0, .y = -step.y, .z = 0 }; // Y-axis normal
        } else {
            pos.z += step.z;
            t_max.z += t_delta.z;
            normal = .{ .x = 0, .y = 0, .z = -step.z }; // Z-axis normal
        }
    }

    return null;
}

fn sendRayCameraTarget(self: *Self) ?rl.Vector3 {
    const amount: usize = 50;
    const stepAmount: f32 = 0.1;

    for (0..amount) |i| {
        const distance = @as(f32, @floatFromInt(i)) * stepAmount;

        var pos = rl.Vector3.moveTowards(self.camera.position, self.camera.target, distance);
        pos = .{ .x = @round(pos.x), .y = @round(pos.y), .z = @round(pos.z) };

        if (map.getBlock(pos) != 0) return pos;
    }

    return null;
}

fn sendRayDirection(self: *Self, Direction: enum { up, down, left, right, forward, backward }, amount: usize) ?rl.Vector3 {
    // const amount: i32 = 16;
    const step: f32 = 0.1;

    for (0..amount) |i| {
        const distance = @as(f32, @floatFromInt(i)) * step;

        var pos = self.camera.position;
        switch (Direction) {
            .down => pos.y -= distance,
            .up => pos.y += distance,
            .left => pos.x -= distance, // Assuming left modifies x
            .right => pos.x += distance, // Assuming right modifies x
            .forward => pos.z -= distance, // Forward moves along negative z
            .backward => pos.z += distance, // Backward moves along positive z
        }

        // var pos = rl.Vector3.moveTowards(self.camera.position, vec, distance);
        pos = .{ .x = @round(pos.x), .y = @round(pos.y), .z = @round(pos.z) };

        if (map.getBlock(pos) != 0) return pos;
    }

    return null;
}

// fn checkCollision(self: *Self, new_pos_x: rl.Vector3, new_pos_z: rl.Vector3) void {
//     const check_offsets = [_]f32{ -0.9, 0.0, 0.4 }; // Feet, middle, head

//     // Check X movement for collisions with blocks on the side
//     var can_move_x = true;
//     for (check_offsets) |offset| {
//         if (map.getBlock(.{ .x = @round(new_pos_x.x), .y = @round(self.pos.y + offset), .z = @round(self.pos.z) }) != 0) {
//             can_move_x = false;
//             break;
//         }
//     }
//     if (can_move_x) {
//         self.pos.x = new_pos_x.x;
//     }

//     // Check Z movement for collisions with blocks on the side
//     var can_move_z = true;
//     for (check_offsets) |offset| {
//         if (map.getBlock(.{ .x = @round(self.pos.x), .y = @round(self.pos.y + offset), .z = @round(new_pos_z.z) }) != 0) {
//             can_move_z = false;
//             break;
//         }
//     }
//     if (can_move_z) {
//         self.pos.z = new_pos_z.z;
//     }

//     // ✅ **New: Check Y movement (ground & ceiling collisions)**
//     // const new_y = self.pos.y - self.vel.y * 0.001; // Apply movement step

//     // // **Check ground collision**
//     // if (self.sendRayDirection(.down, 16)) |r| {
//     //     _ = r;
//     //     self.vel.y = 0; // Stop downward movement
//     //     self.onGround = true; // Mark player as grounded
//     // } else {
//     //     self.onGround = false;
//     //     // self.pos.y = new_y; // Apply movement if no collision
//     //     self.pos.y -= self.vel.y;
//     // }

//     if (self.sendRayDirection(.down, 16)) |r| {
//         _ = r;

//         // If the player was falling, now they're on the ground
//         if (self.vel.y > 0) self.vel.y = 0; // Stop downward movement
//         self.onGround = true; // Mark player as grounded
//     } else {
//         self.onGround = false;
//     }

//     // Apply movement regardless
//     self.pos.y -= self.vel.y;

//     //     // **Check ceiling collision**
//     //     if (map.getBlock(.{ .x = @round(self.pos.x), .y = @round(new_y + check_offsets[2]), .z = @round(self.pos.z) }) != 0) {
//     //         self.vel.y = 0; // Stop upward movement
//     //     }
// }

fn checkCollision(self: *Self, pos: rl.Vector3) void {
    const check_offsets = [_]f32{ -0.9, 0.0, 0.4 }; // Feet, middle, head

    // Check X movement for collisions with blocks on the side
    var can_move_x = true;
    for (check_offsets) |offset| {
        if (map.getBlock(.{ .x = @round(pos.x), .y = @round(self.pos.y + offset), .z = @round(self.pos.z) }) != 0) {
            can_move_x = false;
            break;
        }
    }
    if (can_move_x) {
        self.pos.x = pos.x;
    }

    // Check Z movement for collisions with blocks on the side
    var can_move_z = true;
    for (check_offsets) |offset| {
        if (map.getBlock(.{ .x = @round(self.pos.x), .y = @round(self.pos.y + offset), .z = @round(pos.z) }) != 0) {
            can_move_z = false;
            break;
        }
    }
    if (can_move_z) {
        self.pos.z = pos.z;
    }

    // ✅ **New: Check Y movement (ground & ceiling collisions)**
    // const new_y = self.pos.y - self.vel.y * 0.001; // Apply movement step

    // // **Check ground collision**
    // if (self.sendRayDirection(.down, 16)) |r| {
    //     _ = r;
    //     self.vel.y = 0; // Stop downward movement
    //     self.onGround = true; // Mark player as grounded
    // } else {
    //     self.onGround = false;
    //     // self.pos.y = new_y; // Apply movement if no collision
    //     self.pos.y -= self.vel.y;
    // }

    if (self.sendRayDirection(.down, 16)) |r| {
        _ = r;

        // If the player was falling, now they're on the ground
        if (self.vel.y > 0) self.vel.y = 0; // Stop downward movement
        self.onGround = true; // Mark player as grounded
    } else {
        self.onGround = false;
    }

    // Apply movement regardless
    self.pos.y -= self.vel.y;

    //     // **Check ceiling collision**
    //     if (map.getBlock(.{ .x = @round(self.pos.x), .y = @round(new_y + check_offsets[2]), .z = @round(self.pos.z) }) != 0) {
    //         self.vel.y = 0; // Stop upward movement
    //     }
}

// fn movePlayer(self: *Self, deltaTime: f32) void {
//     var speed: f32 = 15.0 * deltaTime * 0.5;
//     if (rl.isKeyDown(.left_shift)) speed *= 1.5;

//     const forward = rl.Vector3.normalize(self.camera.target.subtract(self.camera.position));
//     const right = rl.Vector3.normalize(rl.Vector3.crossProduct(rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }, forward));

//     var new_pos_x = self.pos;
//     var new_pos_z = self.pos;

//     if (rl.isKeyDown(.w)) {
//         new_pos_x.x += forward.x * speed;
//         new_pos_z.z += forward.z * speed;
//     }
//     if (rl.isKeyDown(.s)) {
//         new_pos_x.x -= forward.x * speed;
//         new_pos_z.z -= forward.z * speed;
//     }
//     if (rl.isKeyDown(.d)) {
//         new_pos_x.x -= right.x * speed;
//         new_pos_z.z -= right.z * speed;
//     }
//     if (rl.isKeyDown(.a)) {
//         new_pos_x.x += right.x * speed;
//         new_pos_z.z += right.z * speed;
//     }

//     if (rl.isKeyPressed(.space) and self.onGround) {
//         self.vel.y -= 0.01;
//         self.onGround = false;
//     }

//     self.checkCollision(new_pos_x, new_pos_z);
// }

fn movePlayer(self: *Self, deltaTime: f32) void {
    self.speed = 15.0 * deltaTime * 0.5;
    // if (rl.isKeyDown(.left_shift)) speed *= 1.5;

    const forward = rl.Vector3.normalize(self.camera.target.subtract(self.camera.position));
    const right = rl.Vector3.normalize(rl.Vector3.crossProduct(rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }, forward));

    var new_pos = self.pos;
    // var new_pos_x = self.pos;
    // var new_pos_z = self.pos;

    if (forward.x != 0 and forward.z != 0) self.sprint() catch {};

    if (rl.isKeyDown(.w)) {
        new_pos.x += forward.x * self.speed;
        new_pos.z += forward.z * self.speed;
    }
    if (rl.isKeyDown(.s)) {
        new_pos.x -= forward.x * self.speed;
        new_pos.z -= forward.z * self.speed;
    }
    if (rl.isKeyDown(.d)) {
        new_pos.x -= right.x * self.speed;
        new_pos.z -= right.z * self.speed;
    }
    if (rl.isKeyDown(.a)) {
        new_pos.x += right.x * self.speed;
        new_pos.z += right.z * self.speed;
    }

    if (rl.isKeyPressed(.space) and self.onGround) {
        self.vel.y -= 0.006;
        self.onGround = false;
    }

    self.checkCollision(new_pos);
}

fn applyGravity(self: *Self, deltaTime: f32) void {
    if (!self.onGround) self.vel.y += 9.8 * deltaTime * 0.002;
}

//TODO vad gör ens denna??
fn updatePos(self: *Self, deltaTime: f32) void {
    const scalar: f32 = 0.0001;

    var newPos: rl.Vector3 = self.pos;

    // Apply velocity to position
    newPos.x -= self.vel.x * deltaTime * scalar;
    newPos.y -= self.vel.y * deltaTime * scalar;
    newPos.z -= self.vel.z * deltaTime * scalar;

    self.checkCollision(newPos);

    self.camera.position = self.pos;

    rl.updateCamera(&self.camera, rl.CameraMode.first_person);
}
