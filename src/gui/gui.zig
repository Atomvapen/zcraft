const rl = @import("raylib");

pub var buttonTexture: rl.Texture = undefined;
pub var buttonHoveredTexture: rl.Texture = undefined;
pub var backgroundTexture: rl.Texture = undefined;
pub var backgroundImage: rl.Image = undefined;

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
