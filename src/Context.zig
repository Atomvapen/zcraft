const Self = @This();
const std = @import("std");
const Player = @import("player/player.zig").Player;
const map = @import("map/world.zig");
const rl = @import("raylib");

allocator: std.mem.Allocator,
time: f64 = 0,
deltatime: f64 = 0,
player: *Player = undefined,
state: State = .{},
settings: Settings = .{},
generated: bool = false,
cursorEnabled: bool = true,

const State = struct {
    const GameState = enum { None, Menu, Playing, Settings, Exiting };
    current: GameState = .Menu,
    previous: GameState = .None,
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
    };

    return context;
}

pub fn destroy(self: *Self, allocator: std.mem.Allocator) void {
    self.player.destroy(self);
    allocator.destroy(self);
}

pub fn update(self: *Self) !void {
    self.keybinds();

    if (self.state.current == .Playing) {
        self.deltatime = @floatCast(rl.getFrameTime());
        try self.player.update(self);
        map.Map.update();
    }
}

fn setCursorVisibility(current: *bool, desired: bool) void {
    if (desired != current.*) {
        current.* = desired;
        if (desired) rl.enableCursor() else rl.disableCursor();
    }
}

fn keybinds(self: *Self) void {
    const shader = @import("rendering/shader.zig");

    switch (rl.getKeyPressed()) {
        .f3 => self.settings.debug = !self.settings.debug,
        .f11 => rl.toggleFullscreen(),
        .escape => self.state.current = .Settings,
        .l => std.debug.print("{any}\n", .{self.player.inventory.items[0]}),
        else => {},
    }

    if (rl.isKeyDown(.k)) {
        shader.lightCam.target.z += 0.01;
    }

    if (rl.isKeyDown(.l)) {
        shader.lightCam.target.z -= 0.01;
    }
}
