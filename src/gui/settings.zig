const rl = @import("raylib");
const Button = @import("components/Button.zig");
const Slider = @import("components/Slider.zig").Slider;
const Context = @import("../Context.zig");
const gui = @import("gui.zig");

pub fn draw(ctx: *Context) void {
    const screenWidth = rl.getScreenWidth();
    rl.clearBackground(rl.Color.ray_white);

    const backButton = Button.init(
        "Back",
        20,
        .{
            .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2,
            .y = 250,
            .width = 400,
            .height = 50,
        },
    );
    backButton.draw();
    if (backButton.isPressed()) ctx.state = .Menu;

    var volumeSlider = Slider.init(
        .{
            .x = (@as(f32, @floatFromInt(rl.getScreenWidth() - 400))) / 2,
            .y = 390,
            .width = 400,
            .height = 50,
        },
        0,
        100,
        &ctx.settings.volume,
        30,
    );

    volumeSlider.draw();
    volumeSlider.update();
}
