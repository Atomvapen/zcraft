const rl = @import("raylib");
const std = @import("std");
const map = @import("../map/map.zig");
// const mapGen = @import("../map/generation.zig");
const Context = @import("../Context.zig");
const shader = @import("../rendering/shader.zig");
const gui = @import("../gui/gui.zig");
const Inventory = @import("../player/Inventory.zig");
const Hotbar = @import("../player/Hotbar.zig");

pub const Player = struct {
    const Self = @This();

    camera: rl.Camera3D = rl.Camera3D{
        .position = .{ .x = 1.0, .y = 40.0, .z = 1.0 },
        .target = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 },
        .fovy = 90.0,
        .projection = rl.CameraProjection.perspective,
    },

    pos: rl.Vector3 = .{ .x = 1.0, .y = 40.0, .z = 1.0 },
    vel: rl.Vector3 = undefined,

    onGround: bool = false,
    stats: struct {
        stamina: f32 = 100,
        // speed: f32 = 0,
        health: i32 = 100,
    } = .{},
    // movementState: enum { default, crouching, sprinting, swimming, flying },
    spritning: bool = false,
    crouching: bool = false,
    speed: f32 = 0,
    hotbar: Hotbar = .{},
    inventory: Inventory = .{},

    pub fn create(ctx: *Context) !*Self {
        const player: *Self = try ctx.allocator.create(Self);
        player.* = .{};
        return player;
    }

    pub fn destroy(self: *Self, ctx: *Context) void {
        ctx.allocator.destroy(self);
    }

    pub fn kill(self: *Self) void {
        self.stats.health = 0;
    }

    fn handleKeybindings(self: *Self, ctx: *Context) !void {
        for (49..57 + 1) |key| {
            if (rl.isKeyPressed(@enumFromInt(key))) self.hotbar.selection = @intCast(key - 49);
        }

        // Scroll wheel
        const wheel_move: f32 = rl.getMouseWheelMove();
        if (wheel_move != 0) {
            var direction: f32 = 1;
            if (ctx.settings.reverseScrolling) direction = -1;
            const block_count: u8 = 9;
            const wheel_move_int: i32 = @intFromFloat(wheel_move * direction);
            self.hotbar.selection = @intCast(@mod((self.hotbar.selection + block_count + wheel_move_int), block_count));
            if (self.hotbar.selection == -1) self.hotbar.selection = block_count;
        }

        if (rl.isMouseButtonPressed(.right)) {
            try self.placeBlock();
        }

        if (rl.isMouseButtonPressed(.left)) {
            try self.breakBlock();
        }

        if (rl.isMouseButtonPressed(.middle)) {
            self.getBlock();
        }
    }

    fn updateMap(self: *Player, ctx: *Context) !void {
        const chunkPos = map.toChunkPos(.{ .x = self.camera.position.x, .y = 0, .z = self.camera.position.z });

        // const renderDistance: i32 = 5;
        const renderDistance: i32 = @intFromFloat(ctx.settings.renderDistance);
        for (0..@intCast(renderDistance)) |i| {
            for (0..@intCast(renderDistance)) |y| {
                try map.Generate.generate(.{
                    .x = @floatFromInt(@as(i32, @intFromFloat(chunkPos.x)) + @as(i32, @intCast(i)) - @divTrunc(renderDistance, 2)),
                    .y = 0,
                    .z = @floatFromInt(@as(i32, @intFromFloat(chunkPos.z)) + @as(i32, @intCast(y)) - @divTrunc(renderDistance, 2)),
                });
            }
        }
    }

    pub fn update(self: *Self, ctx: *Context) !void {
        try self.updateMap(ctx);
        try self.handleKeybindings(ctx);

        self.applyGravity(@floatCast(ctx.deltatime));
        self.movePlayer(@floatCast(ctx.deltatime));
        self.updatePos(@floatCast(ctx.deltatime));
    }

    fn sprint(self: *Self) !void {
        if (rl.isKeyDown(.left_shift) and !(self.stats.stamina <= 10)) {
            self.speed *= 1.5;
            self.stats.stamina -= 0.02;
            self.camera.fovy = 100;
        } else {
            self.stats.stamina += 0.01;
            self.camera.fovy = 90;
        }
        self.stats.stamina = rl.math.clamp(self.stats.stamina, 0, 100);
    }

    fn movePlayer(self: *Self, deltaTime: f32) void {
        self.speed = 15.0 * deltaTime * 0.5;

        const forward = rl.Vector3.normalize(self.camera.target.subtract(self.camera.position));
        const right = rl.Vector3.normalize(rl.Vector3.crossProduct(rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }, forward));

        var new_pos = self.pos;

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

    pub fn render2D(self: *Self, ctx: *Context) !void {
        _ = self;
        const Component = gui.Component;
        // Refactor out of player?
        if (gui.DrawBuffer.list.items.len == 0) {
            gui.DrawBuffer.append(Component{ .hotbar = try .create(ctx.allocator, &ctx.player.hotbar.selection, ctx) });
            gui.DrawBuffer.append(Component{ .crosshair = try .create(ctx.allocator, 10) });
        }
    }

    pub fn render3D(self: *Self) !void {
        // Shadow follow player
        if (@abs((shader.lightCam.position.x + shader.lightCam.position.z) - (self.camera.position.x + self.camera.position.z)) > 50) {
            shader.lightCam.position.x = self.camera.position.x;
            shader.lightCam.position.z = self.camera.position.z;
            shader.lightCam.target.x = self.camera.position.x;
            shader.lightCam.target.z = self.camera.position.z + 0.001;
        }

        if (Collision.sendRayCameraTarget(self) != null) {
            rl.drawCube(Collision.sendRayCameraTarget(self).?, 1.01, 1.01, 1.01, rl.colorAlpha(rl.Color.black, 0.5));
        }
    }

    pub fn placeBlock(self: *Self) !void {
        if (Collision.sendRayNormal(self)) |hit| {
            { //TODO FIX
                const hit_size = rl.Vector3{ .x = 1, .y = 1, .z = 1 }; // Adjust based on hitbox
                const player_size = rl.Vector3{ .x = 1, .y = 2, .z = 1 }; // Example player size
                var hit1: rl.Vector3 = hit[0];
                const hit2: rl.Vector3 = hit[0];

                hit1.y += 1; // Moving the hitbox down

                if (Collision.isIntersectingAABB(hit1, hit_size, self.pos, player_size)) return;
                if (Collision.isIntersectingAABB(hit2, hit_size, self.pos, player_size)) return;
            }

            const hitPos: rl.Vector3 = hit[0]; // Block position
            const hitNormal: rl.Vector3 = hit[1]; // Correct face normal

            const newBlockPos: rl.Vector3 = .{
                .x = @round(hitPos.x + hitNormal.x),
                .y = @round(hitPos.y + hitNormal.y),
                .z = @round(hitPos.z + hitNormal.z),
            };

            try map.Map.setBlockUpdate(newBlockPos, self.hotbar.items[self.hotbar.selection]);
        }
    }

    pub fn breakBlock(self: *Self) !void {
        if (Collision.sendRayCameraTarget(self)) |hit| {
            try map.Map.setBlockUpdate(hit, 0);
            // if (map.Map.getChunkRelativePos(hit)) |c| c.setBlockUpdate(hit, 0);
        }
    }

    pub fn getBlock(self: *Self) void {
        if (Collision.sendRayCameraTarget(self)) |hit| {
            if (map.Map.getChunk(map.toChunkPos(hit))) |c| self.hotbar.items[self.hotbar.selection] = c.getBlock(hit);
            // why ChunkPos needed?
        }
    }

    fn checkCollision(self: *Self, pos: rl.Vector3) void {
        const check_offsets = [_]f32{ -0.9, 0.0, 0.4 }; // Feet, middle, head

        // Check X movement for collisions with blocks on the side
        var can_move_x = true;
        for (check_offsets) |offset| {
            if (map.Map.getBlock(.{ .x = @round(pos.x), .y = @round(self.pos.y + offset), .z = @round(self.pos.z) }) != 0) {
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
            if (map.Map.getBlock(.{ .x = @round(self.pos.x), .y = @round(self.pos.y + offset), .z = @round(pos.z) }) != 0) {
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

        if (Collision.sendRayDirection(self, .down, 16)) |r| {
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
        //     if (map.Map.getBlock(.{ .x = @round(self.pos.x), .y = @round(new_y + check_offsets[2]), .z = @round(self.pos.z) }) != 0) {
        //         self.vel.y = 0; // Stop upward movement
        //     }
    }
};

const Collision = struct {
    fn isIntersectingAABB(pos1: rl.Vector3, size1: rl.Vector3, pos2: rl.Vector3, size2: rl.Vector3) bool {
        return (pos1.x < pos2.x + size2.x and pos1.x + size1.x > pos2.x) and
            (pos1.y < pos2.y + size2.y and pos1.y + size1.y > pos2.y) and
            (pos1.z < pos2.z + size2.z and pos1.z + size1.z > pos2.z);
    }

    fn sendRayCameraTarget(player: *Player) ?rl.Vector3 {
        const amount: usize = 50;
        const stepAmount: f32 = 0.1;

        for (0..amount) |i| {
            const distance = @as(f32, @floatFromInt(i)) * stepAmount;

            var pos = rl.Vector3.moveTowards(player.camera.position, player.camera.target, distance);
            pos = .{ .x = @round(pos.x), .y = @round(pos.y), .z = @round(pos.z) };

            if (map.Map.getBlock(pos) != 0) return pos;
        }

        return null;
    }

    fn sendRayNormal(player: *Player) ?struct { rl.Vector3, rl.Vector3 } {
        const max_distance: f32 = 4.0; // Max ray distance
        const ray_dir = rl.Vector3.normalize(player.camera.target.subtract(player.camera.position));

        // Start position (rounded to voxel grid center)
        var pos: rl.Vector3 = .{
            .x = @round(player.camera.position.x),
            .y = @round(player.camera.position.y),
            .z = @round(player.camera.position.z),
        };

        const step: rl.Vector3 = .{
            .x = if (ray_dir.x > 0) 1 else -1,
            .y = if (ray_dir.y > 0) 1 else -1,
            .z = if (ray_dir.z > 0) 1 else -1,
        };

        var t_max: rl.Vector3 = .{
            .x = if (ray_dir.x != 0) (@abs((pos.x + step.x - player.camera.position.x) / ray_dir.x)) else 9999,
            .y = if (ray_dir.y != 0) (@abs((pos.y + step.y - player.camera.position.y) / ray_dir.y)) else 9999,
            .z = if (ray_dir.z != 0) (@abs((pos.z + step.z - player.camera.position.z) / ray_dir.z)) else 9999,
        };

        const t_delta: rl.Vector3 = .{
            .x = if (ray_dir.x != 0) @abs(1 / ray_dir.x) else 9999,
            .y = if (ray_dir.y != 0) @abs(1 / ray_dir.y) else 9999,
            .z = if (ray_dir.z != 0) @abs(1 / ray_dir.z) else 9999,
        };

        var normal: rl.Vector3 = rl.Vector3{ .x = 0, .y = 0, .z = 0 };

        while (@abs(pos.x - player.camera.position.x) < max_distance and
            @abs(pos.y - player.camera.position.y) < max_distance and
            @abs(pos.z - player.camera.position.z) < max_distance)
        {
            // Check for block hit
            if (map.Map.getBlock(pos) != 0) {
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

    fn sendRayDirection(player: *Player, Direction: enum { up, down, left, right, forward, backward }, amount: usize) ?rl.Vector3 {
        // const amount: i32 = 16;
        const step: f32 = 0.1;

        for (0..amount) |i| {
            const distance = @as(f32, @floatFromInt(i)) * step;

            var pos = player.camera.position;
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

            if (map.Map.getBlock(pos) != 0) return pos;
        }

        return null;
    }
};
