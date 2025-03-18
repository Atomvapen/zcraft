const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zcraft",
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
    });

    const rl = b.dependency("raylib_zig", .{});
    exe.root_module.addImport("raylib", rl.module("raylib"));
    exe.linkLibrary(rl.artifact("raylib"));

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run zcraft");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);

    // const check = b.addExecutable(.{
    //     .name = "zcraft",
    //     .root_source_file = b.path("src/main.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const check_step = b.step("check", "Check if zcraft compiles");
    // check_step.dependOn(&check.step);
}
