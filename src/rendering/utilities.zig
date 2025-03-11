const std = @import("std");

// var gpa = std.heap.GeneralPurposeAllocator(.{}){};
// pub const allocator = gpa.allocator(); // main game allocator
pub const allocator = std.heap.c_allocator;

const rl = @import("raylib");

var map = std.StringHashMap(rl.Texture).init(allocator);

pub fn loadTexture(texLoc: []const u8) rl.Texture {
    // give texture if already loaded
    if (map.get(texLoc) != null)
        return map.get(texLoc).?;

    const texture = rl.loadTexture(@ptrCast(texLoc)) catch unreachable;

    //ray.GenTextureMipmaps(@ptrCast(&texture));
    //ray.SetTextureWrap(texture, ray.TEXTURE_WRAP_REPEAT);
    rl.setTextureFilter(texture, .point);

    map.put(texLoc, texture) catch |err| std.debug.print("texture hashmap failed: {}", .{err});
    return texture;
}

pub fn unloadTexture() void {
    var iter = map.iterator();
    while (iter.next()) |*item| {
        item.value_ptr.unload();
    }
}
