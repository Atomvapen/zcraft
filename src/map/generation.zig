const std = @import("std");
const map = @import("map.zig");
const rl = @import("raylib");

pub fn generate(position: rl.Vector3) void {
    if (map.getChunk(position) != null) {
        if (map.getChunk(position).?.Generated == true) {
            //print("already Generated {} \n", .{position});
            return;
        } else {
            map.getChunk(position).?.Generated = true;
        }
    }

    const pos = map.toWorldPos(position);

    const size = map.chunkSize;
    const image = rl.genImagePerlinNoise(size, size, @intFromFloat(pos.x), @intFromFloat(pos.z), 0.1);
    const image2 = rl.genImagePerlinNoise(size, size, @intFromFloat(pos.x), @intFromFloat(pos.z), 2);

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
                map.setBlock(.{ .x = setBlockPos.x + pos.x, .y = @floatFromInt(height - @as(i32, @intCast(h))), .z = setBlockPos.z + pos.z }, 4);
            }
            map.setBlock(.{ .x = setBlockPos.x + pos.x, .y = @floatFromInt(height), .z = setBlockPos.z + pos.z }, 1);

            if (rl.getRandomValue(0, 100) == 1) {
                createTree(.{ .x = setBlockPos.x + pos.x, .y = @floatFromInt(height), .z = setBlockPos.z + pos.z });
            }
        }
    }

    map.getChunk(position).?.Generated = true;
}

pub fn init() !void {
    for (0..2) |i| {
        for (0..2) |y| {
            generate(rl.Vector3{ .x = @floatFromInt(i), .y = 0, .z = @floatFromInt(y) });
        }
    }
}

pub fn createTree(position: rl.Vector3) void {
    map.setBlock(position, 1);

    for (0..3) |i| {
        const x: f32 = @floatFromInt(i);
        for (0..3) |t| {
            const y: f32 = @floatFromInt(t);
            for (0..3) |q| {
                const z: f32 = @floatFromInt(q);
                map.setBlock(.{ .x = position.x + x - 1, .y = position.y + 4 + y, .z = position.z + z - 1 }, 6);
            }
        }
    }

    for (0..5) |i| {
        const h: f32 = @floatFromInt(i);
        map.setBlock(.{ .x = position.x, .y = position.y + h, .z = position.z }, 5);
    }
}
