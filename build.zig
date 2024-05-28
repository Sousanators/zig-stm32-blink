const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    // Target STM32F407VG
    // const target = b.standardTargetOptions(.{ .default_target = .{
    //     .cpu_arch = .thumb,
    //     .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m4 },
    //     .os_tag = .freestanding,
    //     .abi = .eabihf,
    // } });
    const target = b.standardTargetOptions(.{});

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

    exe.addObject(vector);
    exe.setLinkerScriptPath(.{ .path = "src/linker.ld" });
    exe.entry = .{ .symbol_name = "resetHandler" };

    b.installArtifact(exe);

    const size_cmd = b.addSystemCommand(&[_][]const u8{"size"});
    size_cmd.addArtifactArg(exe);
    size_cmd.step.dependOn(b.getInstallStep());

    const size_step = b.step("size", "Show target size (require installation of 'binutils')");
    size_step.dependOn(&size_cmd.step);
    b.default_step = &size_cmd.step;

    // const bi = b.addObjCopy(b.ar, options: Step.ObjCopy.Options)
    // const bin = b.addInstallRaw(exe, "zig-stm32-blink.bin", .{});
    // const bin_step = b.step("bin", "Generate binary file to be flashed");
    // bin_step.dependOn(&bin.step);

    // const flash_cmd = b.addSystemCommand(&[_][]const u8{
    //     "st-flash",
    //     "write",
    //     b.getInstallPath(bin.dest_dir, bin.dest_filename),
    //     "0x8000000",
    // });
    // flash_cmd.step.dependOn(&bin.step);
    // const flash_step = b.step("flash", "Flash and run the app on your STM32F4Discovery");
    // flash_step.dependOn(&flash_cmd.step);
}
