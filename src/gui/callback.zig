const Context = @import("../Context.zig");

pub const Action = enum {
    play,
    exit,
    settings,
    menu,
};

pub var context: *Context = undefined;

pub fn init(ctx: *Context) void {
    context = ctx;
}

pub fn run(action: Action) void {
    switch (action) {
        .exit => context.state = .Exiting,
        .play => context.state = .Playing,
        .settings => context.state = .Settings,
        .menu => context.state = .Menu,
    }
}
