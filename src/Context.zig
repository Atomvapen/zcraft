const Self = @This();

const std = @import("std");
const Player = @import("player.zig");
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
settings: struct { volume: f32 = 70, reverseScrolling: bool = true } = .{},

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
    self.player.destroy();
    allocator.destroy(self);
}

pub fn update(self: *Self) void {
    self.keybinds();

    if (self.state == .Playing) {
        self.deltatime = @floatCast(rl.getFrameTime());
        self.player.update();
        map.update();
    }
}

fn keybinds(self: *Self) void {
    switch (rl.getKeyPressed()) {
        .f3 => self.debug = !self.debug,
        .f11 => rl.toggleFullscreen(),
        else => {},
    }
}
