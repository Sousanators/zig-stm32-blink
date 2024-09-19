const Vector align(8) = *const fn () callconv(.C) void;

// These two are the default empty implementations for exception handlers used by PROVIDE()
export fn blockingHandler() callconv(.C) void {
    while (true) {}
}

export fn nullHandler() callconv(.C) void {}

// This comes from the linker script and represents the initial stack pointer address.
// Not a function, but pretend it is to suppress type error
extern fn _stack() callconv(.C) void;

// These are the exception handlers, which are weakly linked to the default handlers
// in the linker script. We can export our own handler somewhere in our code which
// will be implemented in the vector table instead of the linker PROVIDE().
extern fn resetHandler() void;
extern fn nmiHandler() void;
extern fn hardFaultHandler() void;
extern fn memoryManagementFaultHandler() void;
extern fn busFaultHandler() void;
extern fn usageFaultHandler() void;
extern fn svCallHandler() void;
extern fn debugMonitorHandler() void;
extern fn pendSVHandler() void;
extern fn sysTickHandler() void;
extern fn wwdgHandler() void;
extern fn tim2Handlder() void;
extern fn pvdHandler() void;
extern fn tamperStampHandler() void;
extern fn rtcWakeupHandler() void;
extern fn flashHandler() void;
extern fn rccHandler() void;
extern fn exti0Handler() void;
extern fn exti1Handler() void;
extern fn exti2_tsHandler() void;
extern fn exti3Handler() void;
extern fn exti4Handler() void;
extern fn dma1_1Handler() void;
extern fn dma1_2Handler() void;
extern fn dma1_3Handler() void;
extern fn dma1_4Handler() void;
extern fn dma1_5Handler() void;
extern fn dma1_6Handler() void;
extern fn dma1_7Handler() void;
extern fn adc1_2Handler() void;
extern fn usb_hpHandler() void;
extern fn usb_lpHandler() void;
extern fn can_rx1Handler() void;
extern fn can_sceHandler() void;
extern fn exti9_5Handler() void;
extern fn tim15Handler() void;
extern fn tim16Handler() void;
extern fn tim17Handler() void;
extern fn tim1_ccHandler() void;
extern fn tim2Handler() void;
extern fn tim3Handler() void;
extern fn tim4Handler() void;

// The vector table
export const vector_table linksection(".vectors") = [_]?Vector{
    _stack,
    resetHandler, // Reset
    nmiHandler, // NMI
    hardFaultHandler, // Hard fault
    memoryManagementFaultHandler, // Memory management fault
    busFaultHandler, // Bus fault
    usageFaultHandler, // Usage fault
    null, // Reserved 1
    null, // Reserved 2
    null, // Reserved 3
    null, // Reserved 4
    svCallHandler, // SVCall
    debugMonitorHandler, // Debug monitor
    null, // Reserved 5
    pendSVHandler, // PendSV
    sysTickHandler, // SysTick
    //New
    wwdgHandler, //window watchdog
    pvdHandler,
    tamperStampHandler,
    rtcWakeupHandler,
    flashHandler,
    rccHandler,
    exti0Handler,
    exti1Handler,
    exti2_tsHandler,
    exti3Handler,
    exti4Handler,
    dma1_1Handler,
    dma1_2Handler,
    dma1_3Handler,
    dma1_4Handler,
    dma1_5Handler,
    dma1_6Handler,
    dma1_7Handler,
    adc1_2Handler,
    usb_hpHandler,
    usb_lpHandler,
    can_rx1Handler,
    can_sceHandler,
    exti9_5Handler,
    tim15Handler,
    tim16Handler,
    tim17Handler,
    tim1_ccHandler,
    tim2Handler,
    tim3Handler,
    tim4Handler,
};
