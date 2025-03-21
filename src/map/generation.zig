const std = @import("std");
const map = @import("map.zig");
const rl = @import("raylib");
const blocks = @import("blocks.zig");

pub fn generate(position: rl.Vector3) void {
    if (map.Map.getChunk(position)) |c| if (c.Generated == true) return;

    const pos = map.toWorldPos(position);
    const size = map.chunkSize;

    const image = rl.genImagePerlinNoise(size, size, @intFromFloat(pos.x), @intFromFloat(pos.z), 0.1);
    defer image.unload();

    const image2 = rl.genImagePerlinNoise(size, size, @intFromFloat(pos.x), @intFromFloat(pos.z), 2);
    defer image2.unload();

    const colors = rl.loadImageColors(image) catch unreachable;
    const colors2 = rl.loadImageColors(image2) catch unreachable;

    for (0..@intCast(image.height)) |z| {
        for (0..@intCast(image.width)) |x| {
            const index = z * @as(usize, @intCast(image.width)) + x;
            const pixel = colors[index];
            const pixel2 = colors2[index];

            var height: i32 = 0;
            height += pixel2.r;
            height += pixel2.g;
            height += pixel2.b;
            height = @divFloor(height, 10);

            height += pixel.b;
            height += pixel.r;
            height += pixel.g;
            height = @divFloor(height, 40);
            height += 20;

            const setBlockPos = rl.Vector3{ .x = @floatFromInt(x), .y = @floatFromInt(height), .z = @floatFromInt(z) };

            for (0..@intCast(height)) |h| {
                map.Map.setBlock(
                    .{ .x = setBlockPos.x + pos.x, .y = @floatFromInt(height - @as(i32, @intCast(h))), .z = setBlockPos.z + pos.z },
                    @intCast(@intFromEnum(blocks.Block.ID.stone)),
                );
            }
            map.Map.setBlock(
                .{ .x = setBlockPos.x + pos.x, .y = @floatFromInt(height), .z = setBlockPos.z + pos.z },
                @intCast(@intFromEnum(blocks.Block.ID.grass)),
            );

            if (rl.getRandomValue(0, 100) == 1) {
                createTree(.{ .x = setBlockPos.x + pos.x, .y = @floatFromInt(height), .z = setBlockPos.z + pos.z });
            }
        }
    }

    map.Map.getChunk(position).?.Generated = true;
}

pub fn createTree(position: rl.Vector3) void {
    map.Map.setBlock(position, 1);

    for (0..3) |i| {
        const x: f32 = @floatFromInt(i);
        for (0..3) |t| {
            const y: f32 = @floatFromInt(t);
            for (0..3) |q| {
                const z: f32 = @floatFromInt(q);
                map.Map.setBlock(
                    .{ .x = position.x + x - 1, .y = position.y + 4 + y, .z = position.z + z - 1 },
                    @intCast(@intFromEnum(blocks.Block.ID.leaf)),
                );
            }
        }
    }

    for (0..5) |i| {
        const h: f32 = @floatFromInt(i);
        map.Map.setBlock(
            .{ .x = position.x, .y = position.y + h, .z = position.z },
            @intCast(@intFromEnum(blocks.Block.ID.wood)),
        );
    }
}
