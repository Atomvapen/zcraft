const rl = @import("raylib");

pub fn render() void {
    const screenWidth: i32 = rl.getScreenWidth();
    const screenHeight: i32 = rl.getScreenHeight();
    const centerX: i32 = @divExact(screenWidth, 2);
    const centerY: i32 = @divExact(screenHeight, 2);
    const size: i32 = 10;
    const color: rl.Color = rl.Color.black;

    // Draw vertical and horizontal lines
    rl.drawLine(centerX - size, centerY, centerX + size, centerY, color); // Horizontal
    rl.drawLine(centerX, centerY - size, centerX, centerY + size, color); // Vertical

}
