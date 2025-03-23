const std = @import("std");

pub fn parse(path: []const u8, T: type) !T {
    const allocator: std.mem.Allocator = std.heap.c_allocator;

    const file_data: []u8 = try std.fs.cwd().readFileAlloc(allocator, path, 10 * 1024);
    defer allocator.free(file_data);

    const file_dataZ: [:0]u8 = try allocator.dupeZ(u8, file_data);
    defer allocator.free(file_dataZ);

    var status: std.zon.parse.Status = .{};
    const parsed = std.zon.parse.fromSlice(T, allocator, file_dataZ, &status, .{ .ignore_unknown_fields = true }) catch null;

    if (parsed) |payload| {
        return payload;
    } else {
        std.debug.print("Zon parsing failed with status: {any}\n", .{status});
        return error.ZonParse;
    }
}
