const Self = @This();

const std = @import("std");
const Player = @import("player.zig");
const map = @import("map/map.zig");
const utilities = @import("rendering/utilities.zig");

const rl = @import("raylib");

allocator: std.mem.Allocator,
time: f64 = 0,
deltatime: f64 = 0,
player: *Player = undefined,

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
    self.deltatime = @floatCast(rl.getFrameTime());
    self.player.update();
    map.update();
}
