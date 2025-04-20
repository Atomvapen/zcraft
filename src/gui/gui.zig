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
        const Field = @typeInfo(Component).@"union".fields[@intFromEnum(tag)].type;
        const Child = @typeInfo(Field).pointer.child;
        const ptr: *Child = try root.allocator.create(Child);
        ptr.* = Child.init(args);
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
    const TextureId = enum(u8) {
        dirtFlat,
        grassFlat,

        button,
        buttonHovered,

        sliderThumb,
        sliderThumbHovered,

        checkBox,
        checkBoxHovered,
        checkBoxChecked,
        checkBoxCheckedHovered,

        slot,
        slotActive,
        inventory,
    };
    const TexturePath = struct {
        id: TextureId,
        path: [:0]const u8,
    };
    var textures: [@typeInfo(TextureId).@"enum".fields.len]rl.Texture = undefined;

    const paths = [_]TexturePath{
        //Backgrounds
        .{ .id = .dirtFlat, .path = "assets/blocks/dirt_flat.png" },
        .{ .id = .grassFlat, .path = "assets/blocks/grass_flat.png" },

        // Slider
        .{ .id = .sliderThumb, .path = "assets/gui/slider_thumb.png" },
        .{ .id = .sliderThumbHovered, .path = "assets/gui/slider_thumb_hover.png" },

        //Button
        .{ .id = .button, .path = "assets/gui/button.png" },
        .{ .id = .buttonHovered, .path = "assets/gui/button_hover.png" },

        //CheckBox
        .{ .id = .checkBox, .path = "assets/gui/checkbox.png" },
        .{ .id = .checkBoxHovered, .path = "assets/gui/checkbox_hovered.png" },
        .{ .id = .checkBoxChecked, .path = "assets/gui/checkbox_checked.png" },
        .{ .id = .checkBoxCheckedHovered, .path = "assets/gui/checkbox_checked_hovered.png" },

        //Inventory
        .{ .id = .slot, .path = "assets/gui/hotbar.png" },
        .{ .id = .slotActive, .path = "assets/gui/hotbar_active.png" },
        .{ .id = .inventory, .path = "assets/gui/inventory.png" },
    };

    pub fn init() !void {
        for (paths) |p| {
            textures[@intFromEnum(p.id)] = try rl.loadTexture(p.path);
        }
    }

    pub fn deinit() void {
        for (textures) |tex| {
            rl.unloadTexture(tex);
        }
    }

    pub fn get(id: TextureId) rl.Texture {
        const index = @intFromEnum(id);
        std.debug.assert(index < textures.len);
        return textures[index];
    }
};

pub const DrawBuffer = struct {
    var list: std.ArrayList(Component) = undefined;

    pub inline fn count() usize {
        return list.items.len;
    }

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
        for (list.items) |item| item.update();
    }

    pub fn render() void {
        for (list.items) |item| item.render();
    }

    pub fn clear() void {
        for (list.items) |item| item.destroy();
        list.clearRetainingCapacity();
    }
};

pub fn setCursorVisibility(ctx: *Context) void {
    if (ctx.player.inventory.open != ctx.player.cursorEnabled) {
        ctx.player.cursorEnabled = ctx.player.inventory.open;
        if (ctx.player.inventory.open) rl.enableCursor() else rl.disableCursor();
    }
}
