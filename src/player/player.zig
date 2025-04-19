const rl = @import("raylib");
const map = @import("../map/world.zig");
const Context = @import("../Context.zig");
const Inventory = @import("../player/Inventory.zig");
const vec = @import("../math/vec.zig");
const shader = @import("../rendering/shader.zig");

const Vec3f = vec.Vec3f;
const Vec3i = vec.Vec3i;

pub const Player = struct {
    const Self = @This();
    const Stats = struct { stamina: f32 = 100, speed: f32 = 0, health: i32 = 100 };
    // const MovementState = enum { default, crouching, sprinting, swimming, flying };

    camera: rl.Camera3D = rl.Camera3D{
        .position = .{ .x = 1.0, .y = 40.0, .z = 1.0 },
        .target = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 },
        .fovy = 90.0,
        .projection = .perspective,
    },
    pos: rl.Vector3 = .{ .x = 1.0, .y = 40.0, .z = 1.0 },
    vel: rl.Vector3 = undefined,
    onGround: bool = false,
    stats: Stats = .{},
    // movementState: MovementState = .default,
    inventory: Inventory = undefined,
    in_gui: bool = false,
    cursorEnabled: bool = false,

    pub fn create(ctx: *Context) !*Self {
        const player: *Self = try ctx.allocator.create(Self);
        player.* = .{};
        player.*.inventory = .{};
        return player;
    }

    pub fn destroy(self: *Self, ctx: *Context) void {
        ctx.allocator.destroy(self);
    }

    pub fn kill(self: *Self) void {
        self.stats.health = 0;
    }

    pub fn render(self: *Player) !void {
        // Block outline
        if (Collision.sendRayCameraTarget(self)) |hit| {
            const pos: rl.Vector3 = vec.rlTransform(@round(hit.position), rl.Vector3);
            rl.drawCube(pos, 1.01, 1.01, 1.01, rl.colorAlpha(rl.Color.black, 0.5));
        }

        //Player shadow
        if (@abs((shader.lightCam.position.x + shader.lightCam.position.z) - (self.camera.position.x + self.camera.position.z)) > 50) {
            shader.lightCam.position.x = self.camera.position.x;
            shader.lightCam.position.z = self.camera.position.z;
            shader.lightCam.target.x = self.camera.position.x;
            shader.lightCam.target.z = self.camera.position.z + 0.001;
        }
    }

    pub fn placeBlock(self: *Self) !void {
        if (self.in_gui) return;
        if (Collision.sendRayCameraTarget(self)) |hit| { // TODO: Self Collision
            var block = &self.inventory.items[0][self.inventory.hotbar.selection];
            if (block.amount == 0 or block.id == 0) return;
            const pos: Vec3i = @intFromFloat(@round(hit.position + hit.normal));
            if (map.Map.getBlock(pos) != 0) return;
            try map.Map.setBlock(pos, block.id);
            try map.Map.updateBlockNeighbors(pos);
            block.amount -= 1;
            if (block.amount == 0) block.id = 0;
        }
    }

    pub fn breakBlock(self: *Self) !void {
        if (self.in_gui) return;
        if (Collision.sendRayCameraTarget(self)) |hit| {
            const pos: Vec3i = @intFromFloat(@round(hit.position));
            try map.Map.setBlock(pos, 0);
            try map.Map.updateBlockNeighbors(pos);
        }
    }

    pub fn getBlock(self: *Self) void {
        if (self.in_gui) return;
        if (Collision.sendRayCameraTarget(self)) |hit| {
            const pos: Vec3i = @intFromFloat(@round(hit.position));
            if (map.Map.getChunk(map.toChunkPos(pos))) |c| {
                const block: u8 = c.getBlock(pos);
                if (block == self.inventory.items[0][self.inventory.hotbar.selection].id) return;
                if (self.inventory.contains(block)) |p| self.inventory.swap(p, .{ .row = 0, .col = self.inventory.hotbar.selection });
            }
        }
    }

    // Refactor and improve below
    // |
    // V

    fn scrollHotbar(self: *Self, ctx: *Context) void {
        const wheel_move: f32 = rl.getMouseWheelMove();
        if (wheel_move != 0) {
            const direction: f32 = if (ctx.settings.reverseScrolling) -1 else 1;
            const slot_count: u8 = Inventory.columns;
            const wheel_move_int: i32 = @intFromFloat(wheel_move * direction);
            self.inventory.hotbar.selection = @intCast(@mod(self.inventory.hotbar.selection + slot_count + wheel_move_int, slot_count));
        }
    }

    fn handleKeybindings(self: *Self, ctx: *Context) void {
        const key: rl.KeyboardKey = rl.getKeyPressed();
        switch (key) {
            .tab => self.inventory.open = !self.inventory.open,
            .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine => self.inventory.hotbar.selection = @as(u8, @intCast(@intFromEnum((key)))) - 49,
            .t => ctx.settings.debug = !ctx.settings.debug,
            .f11 => rl.toggleFullscreen(),
            .escape => ctx.state.current = .pause,
            .k => @import("../rendering/shader.zig").lightCam.target.z += 0.01,
            .l => @import("../rendering/shader.zig").lightCam.target.z -= 0.01,
            else => {},
        }

        self.scrollHotbar(ctx);

        if (rl.isMouseButtonPressed(.right)) self.placeBlock() catch {};
        if (rl.isMouseButtonPressed(.left)) self.breakBlock() catch {};
        if (rl.isMouseButtonPressed(.middle)) self.getBlock();
    }

    fn updateMap(self: *Player, ctx: *Context) !void {
        const chunkPos: Vec3i = map.toChunkPos(.{ @intFromFloat(self.camera.position.x), 0, @intFromFloat(self.camera.position.z) });

        // const renderDistance: i32 = 5;
        const renderDistance: i32 = @intFromFloat(ctx.settings.renderDistance);
        for (0..@intCast(renderDistance)) |i| {
            for (0..@intCast(renderDistance)) |y| {
                try map.Generate.generateChunk(.{
                    chunkPos[0] + @as(i32, @intCast(i)) - @divTrunc(renderDistance, 2),
                    0,
                    chunkPos[2] + @as(i32, @intCast(y)) - @divTrunc(renderDistance, 2),
                });
            }
        }
    }

    pub fn update(self: *Self, ctx: *Context) !void {
        try self.updateMap(ctx);
        self.handleKeybindings(ctx);

        self.in_gui = (self.inventory.open);

        // rl.updateCamera(&self.camera, rl.CameraMode.free);
        self.applyGravity(@floatCast(ctx.deltatime));
        self.movePlayer(@floatCast(ctx.deltatime));
        self.updatePos(@floatCast(ctx.deltatime));
    }

    fn movePlayer(self: *Self, deltaTime: f32) void {
        if (self.in_gui) return;
        self.stats.speed = 15.0 * deltaTime * 0.5;

        const forward = rl.Vector3.normalize(self.camera.target.subtract(self.camera.position));
        const right = rl.Vector3.normalize(rl.Vector3.crossProduct(rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }, forward));
        var new_pos = self.pos;

        if (forward.x != 0 and forward.z != 0) { //Sprint
            if (rl.isKeyDown(.left_shift) and !(self.stats.stamina <= 10)) {
                self.stats.speed *= 1.5;
                self.stats.stamina -= 0.02;
                self.camera.fovy = 100;
            } else {
                self.stats.stamina += 0.01;
                self.camera.fovy = 90;
            }
            self.stats.stamina = rl.math.clamp(self.stats.stamina, 0, 100);
        }

        if (rl.isKeyDown(.w)) {
            new_pos.x += forward.x * self.stats.speed;
            new_pos.z += forward.z * self.stats.speed;
        }
        if (rl.isKeyDown(.s)) {
            new_pos.x -= forward.x * self.stats.speed;
            new_pos.z -= forward.z * self.stats.speed;
        }
        if (rl.isKeyDown(.d)) {
            new_pos.x -= right.x * self.stats.speed;
            new_pos.z -= right.z * self.stats.speed;
        }
        if (rl.isKeyDown(.a)) {
            new_pos.x += right.x * self.stats.speed;
            new_pos.z += right.z * self.stats.speed;
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

    fn updatePos(self: *Self, deltaTime: f32) void { //TODO vad gör ens denna??
        const scalar: f32 = 0.0001;

        var newPos: rl.Vector3 = self.pos;

        // Apply velocity to position
        newPos.x -= self.vel.x * deltaTime * scalar;
        newPos.y -= self.vel.y * deltaTime * scalar;
        newPos.z -= self.vel.z * deltaTime * scalar;

        self.checkCollision(newPos);

        self.camera.position = self.pos;

        if (!self.inventory.open) rl.updateCamera(&self.camera, rl.CameraMode.first_person);
    }

    fn checkCollision(self: *Self, pos: rl.Vector3) void {
        const check_offsets = [_]f32{ -0.9, 0.0, 0.4 }; // Feet, middle, head

        // Check X movement for collisions with blocks on the side
        var can_move_x = true;
        for (check_offsets) |offset| {
            if (map.Map.getBlock(vec.rlTransform(rl.Vector3{ .x = @round(pos.x), .y = @round(self.pos.y + offset), .z = @round(self.pos.z) }, Vec3i)) != 0) {
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
            if (map.Map.getBlock(vec.rlTransform(rl.Vector3{ .x = @round(self.pos.x), .y = @round(self.pos.y + offset), .z = @round(pos.z) }, Vec3i)) != 0) {
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

        if (Collision.sendRayPlayerDirection(self, .down, 16)) |r| {
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

pub const Collision = struct {
    pub fn sendRayCameraTarget(player: *Player) ?struct { position: Vec3f, normal: Vec3f } {
        const step_amount: f32 = 0.05;
        const max_distance: f32 = 5.0;
        var distance: f32 = 0.0;

        const camera_pos: Vec3f = vec.rlTransform(player.camera.position, Vec3f);
        const target_pos: Vec3f = vec.rlTransform(player.camera.target, Vec3f);
        var previous_pos: Vec3f = @round(camera_pos);

        const ray_dir: Vec3f = vec.normalize(target_pos - camera_pos);

        while (distance < max_distance) : (distance += step_amount) {
            const offset = vec.scale(ray_dir, distance);
            const current_pos = @round(camera_pos + offset);
            if (vec.equal(current_pos, previous_pos)) continue;

            const block_pos: Vec3i = @intFromFloat(current_pos);
            if (map.Map.getBlock(block_pos) != 0) {
                const normal: Vec3f = previous_pos - current_pos;
                return .{ .position = current_pos, .normal = normal };
            }
            previous_pos = current_pos;
        }
        return null;
    }

    pub fn sendRayPlayerDirection(player: *Player, Direction: enum { up, down, left, right, forward, backward }, distance: usize) ?Vec3f {
        const stepAmount: f32 = 0.1;

        for (0..distance) |i| {
            const step = @as(f32, @floatFromInt(i)) * stepAmount;
            var pos: Vec3f = vec.rlTransform(player.camera.position, Vec3f);
            switch (Direction) {
                .down => pos[1] -= step,
                .up => pos[1] += step,
                .left => pos[0] -= step,
                .right => pos[0] += step,
                .forward => pos[2] -= step,
                .backward => pos[2] += step,
            }
            if (map.Map.getBlock(@intFromFloat(@round(pos))) != 0) return pos;
        }
        return null;
    }
};
