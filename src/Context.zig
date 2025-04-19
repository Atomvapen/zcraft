const Self = @This();
const std = @import("std");
const Player = @import("player/player.zig").Player;
const map = @import("map/world.zig").Map;
const rl = @import("raylib");

allocator: std.mem.Allocator,
player: *Player,
state: State,
settings: Settings,
time: f64,
deltatime: f64,

const State = struct {
    const GameState = enum { none, menu, playing, settings, exiting, pause };
    current: GameState = .menu,
    previous: GameState = .none,
};

const Settings = struct {
    volume: f32 = 70,
    reverseScrolling: bool = true,
    renderDistance: f32 = 5,
    debug: bool = false,
};

pub fn create(allocator: std.mem.Allocator) !*Self {
    const context: *Self = try allocator.create(Self);
    context.* = .{
        .allocator = allocator,
        .player = try Player.create(context),
        .settings = .{},
        .state = .{},
        .time = 0,
        .deltatime = 0,
    };
    return context;
}

pub fn destroy(self: *Self, allocator: std.mem.Allocator) void {
    self.player.destroy(self);
    allocator.destroy(self);
}

pub fn update(self: *Self) !void {
    switch (self.state.current) {
        .playing => {
            self.deltatime = @floatCast(rl.getFrameTime());
            try self.player.update(self);
            map.update();
        },
        else => {},
    }
}
