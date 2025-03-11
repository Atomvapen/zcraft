const std = @import("std");
const util = @import("rendering/utilities.zig");

pub fn getTimeMili() f64 {
    //  3 more zeros for nano sec                                 can remove 2 zeros
    return @as(f64, @floatFromInt(@rem(std.time.microTimestamp(), 1000000000))) * 0.000001;
}

var times = std.StringHashMap(f64).init(util.allocator);

pub fn time(timeName: []const u8) void {
    // give time if already loaded
    if (times.get(timeName) != null) {
        times.put(timeName, getTimeMili() - times.get(timeName).?) catch {};
        return;
    }

    times.put(timeName, getTimeMili()) catch |err| std.debug.print("time hashmap failed: {}", .{err});
}

pub fn clear() void {
    times.clearAndFree();
}
