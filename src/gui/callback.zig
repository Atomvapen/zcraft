const Context = @import("../Context.zig");

pub const Action = enum(u8) {
    play,
    exit,
    settings,
    menu,
    back,
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
        .menu => context.state.current = .Menu,
        .back => context.state.current = switch (context.generated) {
            true => .Playing,
            false => .Menu,
        },
        else => unreachable,
    }
}
