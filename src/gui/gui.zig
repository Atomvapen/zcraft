const rl = @import("raylib");
const std = @import("std");
const Context = @import("../Context.zig");
const root = @import("root");

pub const Callback = struct {
    pub const Action = enum(u8) {
        play,
        exit,
        settings,
        settingsInGame,
        menu,
        _,
    };

    pub var context: *Context = undefined;

    pub fn init(ctx: *Context) void {
        context = ctx;
    }

    pub fn run(action: Action) void {
        switch (action) {
            .exit => context.state.current = .Exiting,
            .play => context.state.current = .Playing,
            .settings => context.state.current = .Settings,
            .settingsInGame => context.state.current = .SettingsInGame,
            .menu => context.state.current = .Menu,
            else => unreachable,
        }
    }
};

pub const Component = union(enum) {
    const Button = @import("components/Button.zig");
    const Slider = @import("components/Slider.zig");
    const CheckBox = @import("components/CheckBox.zig");
    const Label = @import("components/Label.zig");
    const Image = @import("components/Image.zig");
    const GradiantRectangle = @import("components/RectangleGradiant.zig");
    const Crosshair = @import("components/Crosshair.zig");
    const Hotbar = @import("components/Hotbar.zig");
    const Inventory = @import("components/Inventory.zig");

    button: *Button,
    slider: *Slider,
    checkBox: *CheckBox,
    label: *Label,
    image: *Image,
    gradiant: *GradiantRectangle,
    crosshair: *Crosshair,
    hotbar: *Hotbar,
    inventory: *Inventory,
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
            .inventory => |inv| inv.render(),
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

    pub fn destroy(self: Component) void {
        switch (self) {
            .button => |b| b.destroy(),
            .slider => |s| s.destroy(),
            .checkBox => |c| c.destroy(),
            .label => |l| l.destroy(),
            .image => |i| i.destroy(),
            .gradiant => |g| g.destroy(),
            .crosshair => |c| c.destroy(),
            .hotbar => |h| h.destroy(),
            .inventory => |inv| inv.destroy(),
            else => {},
        }
    }
};

pub const Window = struct {
    pub const main = @import("windows/main.zig");
    pub const settings = @import("windows/settings.zig");
    pub const settingsInGame = @import("windows/settingsInGame.zig");
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

    pub var inventory: rl.Texture = undefined;

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
        Textures.inventory = try rl.loadTexture("assets/gui/inventory.png");
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

        rl.unloadTexture(Textures.inventory);
    }
};

pub const DrawBuffer = struct {
    pub var list: std.ArrayList(Component) = undefined;

    pub fn init(ctx: *Context) !void {
        try Textures.init();
        list = std.ArrayList(Component).init(root.allocator);
        Callback.init(ctx);
    }

    pub fn deinit() void {
        Textures.deinit();
        list.deinit();
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

    pub fn clear() void {
        for (list.items) |item| {
            item.destroy();
        }

        list.clearRetainingCapacity();
    }
};
