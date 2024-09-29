const regs = @import("registers.zig");
const usb = @import("usb.zig");

pub fn main() void {
    initSystem();
    usb.usbInit();
    initLED();
    initTim2();
    //enable TIM2 count
    regs.TIM2.CR1.modify(.{ .CEN = 1 });
    while (true) {}
}

fn initSystem() void {
    //enable access to the rtc, backup registers and sram
    regs.PWR.CR1.modify(.{ .DBP = 1 });
    //power interface clock enable
    regs.RCC.APB1ENR.modify(.{ .PWREN = 1 });
    //default but write anyways
    regs.PWR.CR1.modify(.{ .VOS = 0b11 });
    //Set state HSEBypass
    regs.RCC.CR.modify(.{ .HSEBYP = 1, .HSEON = 1 });
    //wait for hse on and ready
    var crState = regs.RCC.CR.read();
    while (crState.HSEON != 1) {
        crState = regs.RCC.CR.read();
    }
    while (crState.HSERDY != 1) {
        crState = regs.RCC.CR.read();
    }
    //disable pll
    regs.RCC.CR.modify(.{ .PLLON = 0 });
    //wait for PLL to be in reset
    crState = regs.RCC.CR.read();
    while (crState.PLLRDY != 0) {
        crState = regs.RCC.CR.read();
    }
    //set pll to use hse
    regs.RCC.PLLCFGR.modify(.{
        //src = hse
        .PLLSRC = 1,
        //m = 4 (/4)
        .PLLM0 = 0,
        .PLLM1 = 0,
        .PLLM2 = 1,
        .PLLM3 = 0,
        .PLLM4 = 0,
        .PLLM5 = 0,
        //n = c0 (x192)
        .PLLN0 = 0,
        .PLLN1 = 0,
        .PLLN2 = 0,
        .PLLN3 = 0,
        .PLLN4 = 0,
        .PLLN5 = 0,
        .PLLN6 = 1,
        .PLLN7 = 1,
        .PLLN8 = 0,
        //p = 0 (/2)
        .PLLP0 = 0,
        .PLLP1 = 0,
        //q = 8 (/8)
        .PLLQ0 = 0,
        .PLLQ1 = 0,
        .PLLQ2 = 0,
        .PLLQ3 = 1,
        //r = 2 (reset val, must be true)
        //error in registers having this as 'PPL'?
        .PPLR0 = 0,
        .PPLR1 = 1,
        .PPLR2 = 0,
    });
    //enable pll
    regs.RCC.CR.modify(.{ .PLLON = 1 });
    //wait for PLL to be in reset
    crState = regs.RCC.CR.read();
    while (crState.PLLRDY != 1) {
        crState = regs.RCC.CR.read();
    }
    //set pwren again and check?
    regs.RCC.APB1ENR.modify(.{ .PWREN = 1 });
    var apb1enrState = regs.RCC.APB1ENR.read();
    while (apb1enrState.PWREN != 1) {
        apb1enrState = regs.RCC.APB1ENR.read();
    }
    //enable overdrive
    regs.PWR.CR1.modify(.{ .ODEN = 1 });
    var pwrCsr1Val = regs.PWR.CSR1.read();
    while (pwrCsr1Val.ODRDY != 1) {
        pwrCsr1Val = regs.PWR.CSR1.read();
    }
    //enable overdrive switch and wait for ready
    regs.PWR.CR1.modify(.{ .ODSWEN = 1 });
    pwrCsr1Val = regs.PWR.CSR1.read();
    while (pwrCsr1Val.ODSWRDY != 1) {
        pwrCsr1Val = regs.PWR.CSR1.read();
    }
    //set new flash latency
    regs.Flash.ACR.modify(.{ .LATENCY = 0x6 });
    //set system clock to pll
    regs.RCC.CFGR.modify(.{ .SW0 = 0, .SW1 = 1 });

    //set system clock dividers
    regs.RCC.CFGR.modify(.{
        .PPRE1 = 4, //apb1 limit to 54MHz, divide by 4
        .HPRE = 0, //no sysclk divider
        .PPRE2 = 2, //apb2 limit to 108MHz, divide by 2
    });

    var sysClkSw = regs.RCC.CFGR.read();
    while ((sysClkSw.SWS0 != 0) and (sysClkSw.SWS1 != 1)) {
        sysClkSw = regs.RCC.CFGR.read();
    }
}

fn initLED() void {
    // LED on PB0
    // Enable GPIOB port
    regs.RCC.AHB1ENR.modify(.{ .GPIOBEN = 0b1 });
    //Configure GPIOE9 for LED drive. Defaults are mostly ok, but verbose for learning.
    regs.GPIOB.MODER.modify(.{ .MODER0 = 0b01 });
    regs.GPIOB.OTYPER.modify(.{ .OT0 = 0b0 });
    regs.GPIOB.OSPEEDR.modify(.{ .OSPEEDR0 = 0b00 });
    regs.GPIOB.PUPDR.modify(.{ .PUPDR0 = 0b00 });
}

fn initTim2() void {
    //de-assert TIM2 reset
    regs.RCC.APB1RSTR.modify(.{ .TIM2RST = 0 });
    //enable TIM2 clock
    regs.RCC.APB1ENR.modify(.{ .TIM2EN = 1 });
    //set the reload value of tim2
    //CNT starts at 0 and counts up to preload, then the update event occurs.
    regs.TIM2.ARR.write_raw(0x0400000);
    //enable tim2 auto-reload buffering
    regs.TIM2.CR1.modify(.{ .ARPE = 1 });
    //Enable tim2 interrupt in NVIC. Should work on registers to make this more clear
    regs.NVIC.ISER0.modify(.{ .SETENA28 = 1 });
    //enable tim2 update interrupt
    regs.TIM2.DIER.modify(.{ .UIE = 1 });
}

export fn tim2Handler() callconv(.C) void {
    //Read LED state
    const led_state = regs.GPIOB.ODR.read();
    //Invert LED state
    regs.GPIOB.ODR.modify(.{ .ODR0 = ~led_state.ODR0 });
    //Clear TIM2 update interrupt flag
    regs.TIM2.SR.modify(.{ .UIF = 0 });
}
