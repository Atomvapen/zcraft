const Context = @import("Context.zig");
const rl = @import("raylib");

var buttonTexture: rl.Texture = undefined;
var buttonHoveredTexture: rl.Texture = undefined;
var backgroundTexture: rl.Texture = undefined;
var backgroundImage: rl.Image = undefined;

const Button = struct {
    pos: rl.Rectangle,
    text: [:0]const u8,
    fontSize: i32,

    pub fn init(text: [:0]const u8, fontSize: i32, pos: rl.Rectangle) Button {
        return .{
            .pos = pos,
            .text = text,
            .fontSize = fontSize,
        };
    }

    pub fn draw(self: *const Button) void {
        const textWidth: f32 = @as(f32, @floatFromInt(rl.measureText(self.text, self.fontSize)));
        const textX: f32 = self.pos.x + (self.pos.width - textWidth) / 2;
        const textY: f32 = self.pos.y + (self.pos.height - @as(f32, @floatFromInt(self.fontSize))) / 2;
        const srcRect: rl.Rectangle = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(buttonTexture.width),
            .height = @floatFromInt(buttonTexture.height),
        };

        const hoverScale: f32 = if (self.hovered()) 1.05 else 1.0;
        const scaledPos = rl.Rectangle{
            .x = self.pos.x - (self.pos.width * (hoverScale - 1.0) / 2),
            .y = self.pos.y - (self.pos.height * (hoverScale - 1.0) / 2),
            .width = self.pos.width * hoverScale,
            .height = self.pos.height * hoverScale,
        };
        rl.drawTexturePro(if (self.hovered()) buttonHoveredTexture else buttonTexture, srcRect, scaledPos, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.Color.white);
        rl.drawText(self.text, @intFromFloat(textX), @intFromFloat(textY), self.fontSize, rl.Color.black);
    }

    fn hovered(self: *const Button) bool {
        const mousePos = rl.getMousePosition();
        return rl.checkCollisionPointRec(mousePos, self.pos);
    }

    fn pressed(self: *const Button) bool {
        const mousePos = rl.getMousePosition();
        return rl.checkCollisionPointRec(mousePos, self.pos) and rl.isMouseButtonPressed(.left);
    }
};

pub fn init() !void {
    buttonTexture = try rl.loadTexture("assets/gui/button.png");
    buttonHoveredTexture = try rl.loadTexture("assets/gui/button_hover.png");
    backgroundImage = try rl.loadImage("assets/gui/dirt.png");
    // backgroundImage = try rl.loadTexture("assets/gui/dirt.png");
    rl.imageResize(&backgroundImage, @divFloor(rl.getScreenWidth(), 10), @divFloor(rl.getScreenHeight(), 10));
    backgroundTexture = try rl.loadTextureFromImage(backgroundImage);
}

pub fn deinit() void {
    rl.unloadTexture(buttonTexture);
    rl.unloadTexture(buttonHoveredTexture);
    rl.unloadTexture(backgroundTexture);
    rl.unloadImage(backgroundImage);
}

pub fn drawSettings(ctx: *Context) void {
    const screenWidth = rl.getScreenWidth();
    rl.clearBackground(rl.Color.ray_white);

    const backButton = Button.init("Back", 20, .{ .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2, .y = 250, .width = 400, .height = 50 });
    backButton.draw();
    if (backButton.pressed()) ctx.state = .Menu;
}

fn drawMainTitle() void {
    const screenWidth = rl.getScreenWidth();

    const menuTitleText = "zcraft";
    const menuTitleSize: i32 = 60;
    const menuTitleWidth: i32 = rl.measureText(menuTitleText, menuTitleSize);
    const menuTitlePos = rl.Vector2{ .x = @as(f32, @floatFromInt(screenWidth - menuTitleWidth)) / 2, .y = 100 };
    rl.drawText(menuTitleText, @intFromFloat(menuTitlePos.x), @intFromFloat(menuTitlePos.y), menuTitleSize, rl.Color.dark_gray);

    for (0..6) |i| {
        rl.drawText(menuTitleText, @as(i32, @intFromFloat(menuTitlePos.x)) + @as(i32, @intCast(i)), @as(i32, @intFromFloat(menuTitlePos.y)) + @as(i32, @intCast(i)), menuTitleSize, rl.Color.dark_gray);
    }

    rl.drawText(menuTitleText, @as(i32, @intFromFloat(menuTitlePos.x)), @as(i32, @intFromFloat(menuTitlePos.y)), menuTitleSize, rl.Color.black);
}

fn drawVersionText() void {
    const screenHeight = rl.getScreenHeight();
    rl.drawText("zcraft 0.1.0", 10, screenHeight - 20, 20, rl.Color.gray);
}

fn drawBackground() void {
    const screenWidth = rl.getScreenWidth();
    const screenHeight = rl.getScreenHeight();

    const tilesX: usize = @intCast(@divFloor(screenWidth, backgroundTexture.width) + 2);
    const tilesY: usize = @intCast(@divFloor(screenHeight, backgroundTexture.height) + 2);

    // Resize the texture to be smaller (scaled down)
    const newWidth: f32 = @as(f32, @floatFromInt(@divFloor(screenWidth, @as(i32, @intCast(tilesX)))));
    const newHeight: f32 = @as(f32, @floatFromInt(@divFloor(screenHeight, @as(i32, @intCast(tilesY)))));

    for (0..tilesY) |y| {
        for (0..tilesX) |x| {
            rl.drawTexturePro(
                backgroundTexture,
                rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(backgroundTexture.width), .height = @floatFromInt(backgroundTexture.height) },
                rl.Rectangle{ .x = @as(f32, @floatFromInt(x)) * newWidth, .y = @as(f32, @floatFromInt(y)) * newHeight, .width = newWidth, .height = newHeight },
                rl.Vector2{ .x = 0, .y = 0 },
                0.0,
                rl.Color.white,
            );
        }
    }
}

fn drawBackgroundFade() void {
    const screenWidth = rl.getScreenWidth();
    const screenHeight = rl.getScreenHeight();

    // Create the colors for the gradient
    const topColor = rl.Color{ .r = 0, .g = 0, .b = 0, .a = 0 }; // Transparent black at the top
    const bottomColor = rl.Color{ .r = 0, .g = 0, .b = 0, .a = 200 }; // Opaque black at the bottom

    // Draw a single large rectangle with a vertical gradient
    rl.drawRectangleGradientV(0, 0, screenWidth, screenHeight, topColor, bottomColor);
}

pub fn drawMain(ctx: *Context) !void {
    const screenWidth = rl.getScreenWidth();

    rl.clearBackground(rl.Color.ray_white);

    drawBackground();
    drawBackgroundFade();
    drawMainTitle();
    drawVersionText();

    const playButton = Button.init("Play", 20, .{ .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2, .y = 250, .width = 400, .height = 50 });
    playButton.draw();
    if (playButton.pressed()) ctx.state = .Playing;

    const settButton = Button.init("Settings", 20, .{ .x = (@as(f32, @floatFromInt(screenWidth - 400))) / 2, .y = 320, .width = (400 - 40) / 2, .height = 50 });
    settButton.draw();
    if (settButton.pressed()) ctx.state = .Settings;

    const exitButton = Button.init("Exit", 20, .{ .x = settButton.pos.x + 20 + 400 / 2, .y = 320, .width = (400 - 40) / 2, .height = 50 });
    exitButton.draw();
    if (exitButton.pressed()) ctx.quit = true;
}
