const rl = @import("raylib");
const std = @import("std");
const Context = @import("../Context.zig");
const root = @import("root");

pub var context: *Context = undefined;

pub fn init(ctx: *Context) !void {
    context = ctx;
    try DrawBuffer.init();
    try Textures.init();
}

pub fn deinit() void {
    DrawBuffer.deinit();
    Textures.deinit();
}

pub const Callback = struct {
    pub const Action = enum(u8) {
        play,
        exit,
        settings,
        pause,
        menu,
        _,
    };

    pub fn run(action: Action) void {
        switch (action) {
            .exit => context.state.current = .exiting,
            .play => context.state.current = .playing,
            .settings => context.state.current = .settings,
            .pause => context.state.current = .pause,
            .menu => context.state.current = .menu,
            else => unreachable,
        }
    }
};

pub const Component = union(Tag) {
    const Tag = enum { button, slider, checkBox, label, image, gradiant, crosshair, hotbar, inventory };
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

    pub fn create(comptime tag: Tag, args: @typeInfo(@typeInfo(Component).@"union".fields[@intFromEnum(tag)].type).pointer.child.InitArgs) !Component {
        const field_type = @typeInfo(Component).@"union".fields[@intFromEnum(tag)].type;
        const T = @typeInfo(field_type).pointer.child;
        const ptr = try root.allocator.create(T);
        ptr.* = T.init(args);
        return @unionInit(Component, @tagName(tag), ptr);
    }

    pub fn destroy(self: Component) void {
        switch (self) {
            inline else => |c| root.allocator.destroy(c),
        }
    }

    pub fn render(self: Component) void {
        switch (self) {
            inline else => |c| if (@hasDecl(@TypeOf(c.*), "render")) c.render(),
        }
    }

    pub fn update(self: Component) void {
        switch (self) {
            inline else => |c| if (@hasDecl(@TypeOf(c.*), "update")) c.update(),
        }
    }
};

pub const Window = struct {
    const main = @import("windows/main.zig");
    const settings = @import("windows/settings.zig");
    const pause = @import("windows/pause.zig");

    pub fn render(ctx: *Context, kind: enum { main, settings, pause }) !void {
        try switch (kind) {
            .main => main.render(),
            .settings => settings.render(ctx),
            .pause => pause.render(ctx),
        };
    }
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

    pub fn init() !void {
        list = std.ArrayList(Component).init(root.allocator);
    }

    pub fn deinit() void {
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

pub fn setCursorVisibility(ctx: *Context) void {
    if (ctx.player.inventory.open != ctx.player.cursorEnabled) {
        ctx.player.cursorEnabled = ctx.player.inventory.open;
        if (ctx.player.inventory.open) rl.enableCursor() else rl.disableCursor();
    }
}
