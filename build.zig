const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {

    // Target STM32F303VC
    const target = b.standardTargetOptions(.{ .default_target = .{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m7 },
        .os_tag = .freestanding,
        .abi = .eabihf,
    } });

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig-stm32-blink",
        .root_source_file = b.path("src/startup.zig"),
        .target = target,
        .optimize = optimize,
    });

    const vector = b.addObject(.{
        .name = "vector",
        .root_source_file = b.path("src/vector.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.setLinkerScript(.{ .cwd_relative = "src/linker.ld" });
    exe.addObject(vector);
    exe.entry = .{ .symbol_name = "resetHandler" };
    b.installArtifact(exe);
}
