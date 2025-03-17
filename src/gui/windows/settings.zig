const rl = @import("raylib");
const Context = @import("../../Context.zig");
const gui = @import("../gui.zig");
const Component = gui.Component;

pub fn render(ctx: *Context) !void {
    const screenWidth: i32 = rl.getScreenWidth();

    if (gui.list.items.len == 0) {
        try gui.list.append(Component{ .button = try .create(ctx.allocator, "Back", 20, .center, .{ .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2, .y = 250, .width = 400, .height = 50 }, .menu) });
        try gui.list.append(Component{ .slider = try .create(ctx.allocator, .{ .x = (@as(f32, @floatFromInt(rl.getScreenWidth() - 400))) / 2, .y = 390, .width = 400, .height = 50 }, 0, 100, &ctx.settings.volume, 40) });
        try gui.list.append(Component{ .checkBox = try .create(ctx.allocator, "Safe", 20, .{ .x = (@as(f32, @floatFromInt(rl.getScreenWidth() - 400))) / 2, .y = 460, .width = 50, .height = 50 }, &ctx.settings.safeMode) });
    }
}
