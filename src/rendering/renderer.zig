const map = @import("../map/world.zig").Map;
const Context = @import("../Context.zig");
const Player = @import("../player/player.zig").Player;
const Collision = @import("../player/player.zig").Collision;
const rl = @import("raylib");
const shader = @import("shader.zig");
const vec = @import("../math/vec.zig");
const gui = @import("../gui/gui.zig");

pub fn init() void {
    rl.gl.rlDisableBackfaceCulling();
}

pub fn drawFrame(ctx: *Context) !void {
    rl.beginDrawing();
    defer rl.endDrawing();
    rl.clearBackground(rl.Color.gray);

    switch (ctx.state.current) {
        .Menu => try gui.Window.main.render(),
        .Playing => try renderGame(ctx),
        .Settings => try gui.Window.settings.render(ctx),
        else => {},
    }

    gui.DrawBuffer.update();
}

pub fn render3D(ctx: *Context) !void {
    map.draw(ctx);
    try Render.shadow(ctx.player);
    try Render.model(ctx.player);
}

pub fn render2D(ctx: *Context) !void {
    try Render.ui(ctx.player, ctx);
    if (ctx.settings.debug) drawDebug();
}

pub fn renderGame(ctx: *Context) !void {
    ctx.generated = true;

    ctx.setCursorVisibility();

    try shader.drawShadow(ctx);
    rl.beginMode3D(ctx.player.camera);
    try render3D(ctx);
    rl.endMode3D();
    try render2D(ctx);
}

pub fn drawDebug() void {
    rl.drawFPS(100, 100);
}

pub const Render = struct {
    pub fn shadow(self: *Player) !void {
        if (@abs((shader.lightCam.position.x + shader.lightCam.position.z) - (self.camera.position.x + self.camera.position.z)) > 50) {
            shader.lightCam.position.x = self.camera.position.x;
            shader.lightCam.position.z = self.camera.position.z;
            shader.lightCam.target.x = self.camera.position.x;
            shader.lightCam.target.z = self.camera.position.z + 0.001;
        }
    }

    pub fn model(self: *Player) !void {
        if (Collision.sendRayCameraTarget(self)) |hit| {
            const pos: rl.Vector3 = vec.rlTransform(@round(hit.position), rl.Vector3);
            rl.drawCube(pos, 1.01, 1.01, 1.01, rl.colorAlpha(rl.Color.black, 0.5));
        }
    }

    pub fn ui(self: *Player, ctx: *Context) !void {
        const Component = gui.Component;
        if (gui.DrawBuffer.list.items.len == 0) { // Refactor out of player?
            gui.DrawBuffer.append(Component{ .hotbar = try .create(&self.inventory.hotbar.selection, ctx) });
            gui.DrawBuffer.append(Component{ .crosshair = try .create(10) });
            gui.DrawBuffer.append(Component{ .inventory = try .create(ctx) });
        }
    }
};
