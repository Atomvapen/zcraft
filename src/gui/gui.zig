const rl = @import("raylib");
const std = @import("std");
const Context = @import("../Context.zig");

pub const Callback = @import("callback.zig");

pub const Component = union(enum) {
    const Button = @import("components/Button.zig");
    const Slider = @import("components/Slider.zig");
    const CheckBox = @import("components/CheckBox.zig");
    //const Text = @import("");
    //const Image = @import("");

    button: *Button,
    slider: *Slider,
    checkBox: *CheckBox,
    //text: *Text,
    //image: *Image,

    pub fn render(self: Component) void {
        switch (self) {
            .button => |b| b.render(),
            .slider => |s| s.render(),
            .checkBox => |c| c.render(),
        }
    }

    pub fn update(self: Component) void {
        switch (self) {
            .button => |b| b.update(),
            .slider => |s| s.update(),
            .checkBox => |c| c.update(),
        }
    }

    //pub fn destroy(self: Component, allocator: std.mem.Allocator) void {
    //  switch (self) {
    //    .button => |b| allocator.destroy(b),
    //   .slider => |s| allocator.destroy(s),
    //}
    // }
};

pub const Window = struct {
    pub const main = @import("windows/main.zig");
    pub const settings = @import("windows/settings.zig");
};

pub const Textures = struct {
    pub var backgroundTexture: rl.Texture = undefined;
    pub var backgroundImage: rl.Image = undefined;

    pub var button: rl.Texture = undefined;
    pub var buttonHovered: rl.Texture = undefined;

    pub var sliderThumbHovered: rl.Texture = undefined;
    pub var sliderThumb: rl.Texture = undefined;

    pub var checkBox: rl.Texture = undefined;
    pub var checkBoxHovered: rl.Texture = undefined;
    pub var checkBoxChecked: rl.Texture = undefined;
    pub var checkBoxCheckedHovered: rl.Texture = undefined;

    pub fn init() !void {
        Textures.backgroundImage = try rl.loadImage("assets/gui/dirt.png");
        rl.imageResize(&Textures.backgroundImage, @divFloor(rl.getScreenWidth(), 10), @divFloor(rl.getScreenHeight(), 10));
        Textures.backgroundTexture = try rl.loadTextureFromImage(Textures.backgroundImage);

        Textures.sliderThumbHovered = try rl.loadTexture("assets/gui/slider_thumb_hover.png");
        Textures.sliderThumb = try rl.loadTexture("assets/gui/slider_thumb.png");

        Textures.button = try rl.loadTexture("assets/gui/button.png");
        Textures.buttonHovered = try rl.loadTexture("assets/gui/button_hover.png");

        Textures.checkBox = try rl.loadTexture("assets/gui/checkbox.png");
        Textures.checkBoxHovered = try rl.loadTexture("assets/gui/checkbox_hovered.png");
        Textures.checkBoxChecked = try rl.loadTexture("assets/gui/checkbox_checked.png");
        Textures.checkBoxCheckedHovered = try rl.loadTexture("assets/gui/checkbox_checked_hovered.png");
    }

    pub fn deinit() void {
        rl.unloadTexture(Textures.button);
        rl.unloadTexture(Textures.buttonHovered);
        rl.unloadTexture(Textures.backgroundTexture);
        rl.unloadImage(Textures.backgroundImage);
    }
};

pub var list: std.ArrayList(Component) = undefined;

pub fn init(ctx: *Context) !void {
    try Textures.init();
    list = std.ArrayList(Component).init(ctx.allocator);
    Callback.init(ctx);
}

pub fn deinit() void {
    Textures.deinit();
    list.deinit();
}

pub fn update() void {
    for (list.items) |item| {
        item.update();
        item.render();
    }
}

pub fn clear(allocator: std.mem.Allocator) void {
    for (list.items) |item| {
        switch (item) {
            .button => |b| b.destroy(allocator),
            .slider => |s| s.destroy(allocator),
            .checkBox => |c| c.destroy(allocator),
        }
        //item.destroy(allocator);
    }

    list.clearAndFree();
}
