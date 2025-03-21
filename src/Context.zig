const Self = @This();

const std = @import("std");
const Player = @import("player/player.zig").Player;
const map = @import("map/map.zig");
const utilities = @import("rendering/utilities.zig");

const rl = @import("raylib");
const GameState = enum { Menu, Playing, Settings, Exiting };

allocator: std.mem.Allocator,
time: f64 = 0,
deltatime: f64 = 0,
player: *Player = undefined,
state: GameState = .Menu,
prevState: GameState = .Menu,
debug: bool = false,
settings: struct { volume: f32 = 70, reverseScrolling: bool = true, renderDistance: f32 = 5 } = .{},
generated: bool = false,

pub fn create(allocator: std.mem.Allocator) !*Self {
    const context: *Self = try allocator.create(Self);

    context.* = .{
        .allocator = allocator,
        .player = try Player.create(context),
    };

    return context;
}

pub fn destroy(self: *Self, allocator: std.mem.Allocator) void {
    utilities.unloadTexture();
    self.player.destroy(self);
    allocator.destroy(self);
}

pub fn update(self: *Self) !void {
    self.keybinds();

    if (self.state == .Playing) {
        self.deltatime = @floatCast(rl.getFrameTime());
        try self.player.update(self);
        map.Map.update();
    }
}

fn keybinds(self: *Self) void {
    const shader = @import("rendering/shader.zig");
    const mapGen = @import("map/generation.zig");

    switch (rl.getKeyPressed()) {
        .f3 => self.debug = !self.debug,
        .f11 => rl.toggleFullscreen(),
        .escape => self.state = .Settings,
        else => {},
    }

    if (rl.isKeyDown(.k)) {
        shader.lightCam.target.z += 0.01;
    }

    if (rl.isKeyDown(.l)) {
        shader.lightCam.target.z -= 0.01;
    }

    if (rl.isKeyPressed(.x)) {
        mapGen.createTree(self.player.camera.position);
    }
}
