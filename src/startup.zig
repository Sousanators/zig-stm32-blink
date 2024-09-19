const main = @import("main.zig").main;

// These symbols come from the linker script
extern const _data_loadaddr: u32;
extern var _data: u32;
extern const _edata: u32;
extern var _bss: u32;
extern const _ebss: u32;

export fn resetHandler() callconv(.C) void {
    // Copy data from flash to RAM
    const data_loadaddr: [*]const u8 = @ptrCast(&_data_loadaddr);
    const data: [*]u8 = @ptrCast(&_data);
    const data_size = @intFromPtr(&_edata) - @intFromPtr(&_data);
    const values = data_loadaddr[0..data_size];
    @memcpy(data, values);

    // Clear the bss
    const bss: [*]u8 = @ptrCast(&_bss);
    const bss_size = @intFromPtr(&_ebss) - @intFromPtr(&_bss);
    const bss_region = bss[0..bss_size];
    @memset(bss_region, 0);

    // Call contained in main.zig
    main();

    unreachable;
}
