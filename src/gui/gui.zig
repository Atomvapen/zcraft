const rl = @import("raylib");
const std = @import("std");
const Context = @import("../Context.zig");

pub const Callback = @import("callback.zig");

pub const Component = union(enum) {
    const Button = @import("components/Button.zig");
    const Slider = @import("components/Slider.zig");
    const CheckBox = @import("components/CheckBox.zig");
    const Label = @import("components/Label.zig");
    const Image = @import("components/Image.zig");
    const GradiantRectangle = @import("components/RectangleGradiant.zig");
    const Crosshair = @import("components/Crosshair.zig");
    const Hotbar = @import("components/Hotbar.zig");

    button: *Button,
    slider: *Slider,
    checkBox: *CheckBox,
    label: *Label,
    image: *Image,
    gradiant: *GradiantRectangle,
    crosshair: *Crosshair,
    hotbar: *Hotbar,
    _,

    pub fn render(self: Component) void {
        switch (self) {
            .button => |b| b.render(),
            .slider => |s| s.render(),
            .checkBox => |c| c.render(),
            .label => |l| l.render(),
            .image => |i| i.render(),
            .gradiant => |g| g.render(),
            .crosshair => |c| c.render(),
            .hotbar => |h| h.render(),
            else => {},
        }
    }

    pub fn update(self: Component) void {
        switch (self) {
            .button => |b| b.update(),
            .slider => |s| s.update(),
            .checkBox => |c| c.update(),
            else => {},
        }
    }

    pub fn destroy(self: Component, allocator: std.mem.Allocator) void {
        switch (self) {
            .button => |b| b.destroy(allocator),
            .slider => |s| s.destroy(allocator),
            .checkBox => |c| c.destroy(allocator),
            .label => |l| l.destroy(allocator),
            .image => |i| i.destroy(allocator),
            .gradiant => |g| g.destroy(allocator),
            .crosshair => |c| c.destroy(allocator),
            .hotbar => |h| h.destroy(allocator),
            else => {},
        }
    }
};

pub const Window = struct {
    pub const main = @import("windows/main.zig");
    pub const settings = @import("windows/settings.zig");
};

pub const Textures = struct {
    pub var dirtFlat: rl.Texture = undefined;
    pub var grassFlat: rl.Texture = undefined;

    pub var button: rl.Texture = undefined;
    pub var buttonHovered: rl.Texture = undefined;

    pub var sliderThumbHovered: rl.Texture = undefined;
    pub var sliderThumb: rl.Texture = undefined;

    pub var checkBox: rl.Texture = undefined;
    pub var checkBoxHovered: rl.Texture = undefined;
    pub var checkBoxChecked: rl.Texture = undefined;
    pub var checkBoxCheckedHovered: rl.Texture = undefined;

    pub var slot: rl.Texture = undefined;
    pub var slotActive: rl.Texture = undefined;

    pub fn init() !void {
        Textures.dirtFlat = try rl.loadTexture("assets/blocks/dirt_flat.png");
        Textures.grassFlat = try rl.loadTexture("assets/blocks/grass_flat.png");

        Textures.sliderThumb = try rl.loadTexture("assets/gui/slider_thumb.png");
        Textures.sliderThumbHovered = try rl.loadTexture("assets/gui/slider_thumb_hover.png");

        Textures.button = try rl.loadTexture("assets/gui/button.png");
        Textures.buttonHovered = try rl.loadTexture("assets/gui/button_hover.png");

        Textures.checkBox = try rl.loadTexture("assets/gui/checkbox.png");
        Textures.checkBoxHovered = try rl.loadTexture("assets/gui/checkbox_hovered.png");
        Textures.checkBoxChecked = try rl.loadTexture("assets/gui/checkbox_checked.png");
        Textures.checkBoxCheckedHovered = try rl.loadTexture("assets/gui/checkbox_checked_hovered.png");

        Textures.slot = try rl.loadTexture("assets/gui/hotbar.png");
        Textures.slotActive = try rl.loadTexture("assets/gui/hotbar_active.png");
    }

    pub fn deinit() void {
        rl.unloadTexture(Textures.dirtFlat);
        rl.unloadTexture(Textures.grassFlat);

        rl.unloadTexture(Textures.sliderThumb);
        rl.unloadTexture(Textures.sliderThumbHovered);

        rl.unloadTexture(Textures.button);
        rl.unloadTexture(Textures.buttonHovered);

        rl.unloadTexture(Textures.checkBox);
        rl.unloadTexture(Textures.checkBoxHovered);
        rl.unloadTexture(Textures.checkBoxChecked);
        rl.unloadTexture(Textures.checkBoxCheckedHovered);

        rl.unloadTexture(Textures.slot);
        rl.unloadTexture(Textures.slotActive);
    }
};

pub const DrawBuffer = struct {
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

    pub fn appendSlice(item: []const Component) void {
        list.appendSlice(item) catch {};
    }

    pub fn append(item: Component) void {
        list.append(item) catch {};
    }

    pub fn update() void {
        for (list.items) |item| {
            item.update();
            item.render();
        }
    }

    pub fn clear(allocator: std.mem.Allocator) void {
        for (list.items) |item| {
            item.destroy(allocator);
        }

        list.clearRetainingCapacity();
    }
};
