const Vector align(8) = *const fn () callconv(.C) void;

// These two are the default empty implementations for exception handlers used by PROVIDE()
export fn blockingHandler() callconv(.C) void {
    while (true) {}
}

export fn nullHandler() callconv(.C) void {
    while (true) {}
}

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
extern fn exti2Handler() void;
extern fn exti3Handler() void;
extern fn exti4Handler() void;
extern fn dma1_0Handler() void;
extern fn dma1_1Handler() void;
extern fn dma1_2Handler() void;
extern fn dma1_3Handler() void;
extern fn dma1_4Handler() void;
extern fn dma1_5Handler() void;
extern fn dma1_6Handler() void;
extern fn adc1_2_3Handler() void;
extern fn can1_txHandler() void;
extern fn can1_rx0Handler() void;
extern fn can1_rx1Handler() void;
extern fn can1_sceHandler() void;
extern fn exti9_5Handler() void;
extern fn tim1_brk_tim9Handler() void;
extern fn tim1_up_tim10Handler() void;
extern fn tim1_trg_com_tim11Handler() void;
extern fn tim1_ccHandler() void;
extern fn tim2Handler() void;
extern fn tim3Handler() void;
extern fn tim4Handler() void;
extern fn i2c1_evHandler() void;
extern fn i2c1_erHandler() void;
extern fn i2c2_evHandler() void;
extern fn inc2_erHandler() void;
extern fn spi1Handler() void;
extern fn spi2Handler() void;
extern fn usart1Handler() void;
extern fn usart2Handler() void;
extern fn usart3Handler() void;
extern fn exti15_10Handler() void;
extern fn rtc_alarmHandler() void;
extern fn otg_fs_wkupHandler() void;
extern fn tim8_brk_tim12Hanlder() void;
extern fn tim8_up_tim13Handler() void;
extern fn tim8_trg_com_tim14Hanlder() void;
extern fn tim8_ccHandler() void;
extern fn dma1_stream7Handler() void;
extern fn fsmcHanlder() void;
extern fn sdmmc1Handler() void;
extern fn tim5Hanlder() void;
extern fn spi3Hanlder() void;
extern fn uart4Handler() void;
extern fn uart5Handler() void;
extern fn tim6_dacHanlder() void;
extern fn tim7Handler() void;
extern fn dma2_stream0Handler() void;
extern fn dma2_stream1Hanlder() void;
extern fn dma2_stream2Hanlder() void;
extern fn dma2_stream3Handler() void;
extern fn dma2_stream4Handler() void;
extern fn ethHandler() void;
extern fn eth_wkupHandler() void;
extern fn can2_txHandler() void;
extern fn can2_rx0Handler() void;
extern fn can2_rx1Handler() void;
extern fn can2_sceHanlder() void;
extern fn otg_fsHanlder() void;

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
    exti2Handler,
    exti3Handler,
    exti4Handler,
    dma1_0Handler,
    dma1_1Handler,
    dma1_2Handler,
    dma1_3Handler,
    dma1_4Handler,
    dma1_5Handler,
    dma1_6Handler,
    adc1_2_3Handler,
    can1_txHandler,
    can1_rx0Handler,
    can1_rx1Handler,
    can1_sceHandler,
    exti9_5Handler,
    tim1_brk_tim9Handler,
    tim1_up_tim10Handler,
    tim1_trg_com_tim11Handler,
    tim1_ccHandler,
    tim2Handler,
    tim3Handler,
    tim4Handler,
    i2c1_evHandler,
    i2c1_erHandler,
    i2c2_evHandler,
    inc2_erHandler,
    spi1Handler,
    spi2Handler,
    usart1Handler,
    usart2Handler,
    usart3Handler,
    exti15_10Handler,
    rtc_alarmHandler,
    otg_fs_wkupHandler,
    tim8_brk_tim12Hanlder,
    tim8_up_tim13Handler,
    tim8_trg_com_tim14Hanlder,
    tim8_ccHandler,
    dma1_stream7Handler,
    fsmcHanlder,
    sdmmc1Handler,
    tim5Hanlder,
    spi3Hanlder,
    uart4Handler,
    uart5Handler,
    tim6_dacHanlder,
    tim7Handler,
    dma2_stream0Handler,
    dma2_stream1Hanlder,
    dma2_stream2Hanlder,
    dma2_stream3Handler,
    dma2_stream4Handler,
    ethHandler,
    eth_wkupHandler,
    can2_txHandler,
    can2_rx0Handler,
    can2_rx1Handler,
    can2_sceHanlder,
    otg_fsHanlder,
};
