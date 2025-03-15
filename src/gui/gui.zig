const rl = @import("raylib");
const std = @import("std");
const Context = @import("../Context.zig");

pub const Component = union(enum) {
    button: *@import("components/Button.zig"),
    slider: *@import("components/Slider.zig"),

    pub fn draw(self: Component) void {
        switch (self) {
            .button => |b| b.draw(),
            .slider => |s| s.draw(),
        }
    }

    pub fn update(self: Component) void {
        switch (self) {
            .button => |b| b.update(),
            .slider => |s| s.update(),
        }
    }

    pub fn destroy(self: Component, allocator: std.mem.Allocator) void {
        switch (self) {
            .button => |b| allocator.destroy(b),
            .slider => |s| allocator.destroy(s),
        }
    }
};

pub const Textures = struct {
    pub var buttonTexture: rl.Texture = undefined;
    pub var buttonHoveredTexture: rl.Texture = undefined;
    pub var backgroundTexture: rl.Texture = undefined;
    pub var backgroundImage: rl.Image = undefined;

    pub fn deinit() void {
        rl.unloadTexture(Textures.buttonTexture);
        rl.unloadTexture(Textures.buttonHoveredTexture);
        rl.unloadTexture(Textures.backgroundTexture);
        rl.unloadImage(Textures.backgroundImage);
    }
};

pub var list: std.ArrayList(Component) = undefined;
pub var context: *Context = undefined;

pub fn init(ctx: *Context) !void {
    Textures.buttonTexture = try rl.loadTexture("assets/gui/button.png");
    Textures.buttonHoveredTexture = try rl.loadTexture("assets/gui/button_hover.png");
    Textures.backgroundImage = try rl.loadImage("assets/gui/dirt.png");
    // backgroundImage = try rl.loadTexture("assets/gui/dirt.png");
    rl.imageResize(&Textures.backgroundImage, @divFloor(rl.getScreenWidth(), 10), @divFloor(rl.getScreenHeight(), 10));
    Textures.backgroundTexture = try rl.loadTextureFromImage(Textures.backgroundImage);
    list = std.ArrayList(Component).init(ctx.allocator);
    context = ctx;
}

pub fn deinit() void {
    Textures.deinit();
    list.deinit();
}

pub fn update() void {
    for (list.items) |item| {
        item.update();
        item.draw();
    }
}

pub fn clear(allocator: std.mem.Allocator) void {
    for (list.items) |item| {
        item.destroy(allocator);
    }

    list.clearAndFree();
    std.debug.print("test", .{});
}

pub const Callback = enum {
    play,
    exit,
    settings,
    menu,
};

pub fn callback(action: Callback) void {
    switch (action) {
        .exit => context.state = .Exiting,
        .play => context.state = .Playing,
        .settings => context.state = .Settings,
        .menu => context.state = .Menu,
    }
}
