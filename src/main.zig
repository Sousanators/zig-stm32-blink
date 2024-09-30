const regs = @import("registers.zig");
const usb = @import("usb.zig");

pub fn main() void {
    initSystem();
    usb.usbInit();
    //usb.registerClass();
    usb.start();
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
    //Enable tim2 interrupt in NVIC. Shmould work on registers to make this more clear
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

export fn otg_fsHanlder() callconv(.C) void {
    //from system reset with no USB connected:  0x0400 0020
    //+NPTXFE -> not enabled or used
    //+PTXFE -> not enabled or used

    //get to main and do nothing for a bit

    //upon connecting, first interrupt we get: 0x0480 1020
    //+USBRST -> device specific reset detecetd, expected first event.
    //+RSTDET -> anothe reset detect, specific for partial power down?

    //First time we see ENUMDNE: 0x0400 2020
    //+ENUMDNE, of course

    //SoF next? If break on it, We get: 0x0400 0028
    //+SOF -> expected next intr. RXFLVL next?

    //Do we get a SET_ADDRESS request first?
    //that would be:
    //bmRequestType=0b0000000
    //bRequest=0x05
    //wValue = 0x---- (Device Address)
    //wIndex = 0x0000
    //wLength = 0x0000
    //Data = Null

    const gintState = regs.OTG_FS_GLOBAL.OTG_FS_GINTSTS.read();
    const daintState = regs.OTG_FS_DEVICE.OTG_FS_DAINT.read();
    if (gintState.USBRST == 1) {
        //reset detected, will enumerate speed next
        //clear flag before leaving
        //set SNAK of all out endpoints
        regs.OTG_FS_DEVICE.OTG_FS_DOEPCTL0.modify(.{ .SNAK = 1 });
        regs.OTG_FS_DEVICE.OTG_FS_DOEPCTL1.modify(.{ .SNAK = 1 });
        regs.OTG_FS_DEVICE.OTG_FS_DOEPCTL2.modify(.{ .SNAK = 1 });
        regs.OTG_FS_DEVICE.OTG_FS_DOEPCTL3.modify(.{ .SNAK = 1 });
        regs.OTG_FS_DEVICE.OTG_FS_DOEPCTL4.modify(.{ .SNAK = 1 });
        regs.OTG_FS_DEVICE.OTG_FS_DOEPCTL5.modify(.{ .SNAK = 1 });
        //unmask enumeration related interrupt masks
        regs.OTG_FS_DEVICE.OTG_FS_DAINTMSK.modify(.{
            .IEPM = 0x0001, //enable ep0IN interrupts
            .OEPINT = 0x0001, //enable ep0OUT interrupts
        });
        regs.OTG_FS_DEVICE.OTG_FS_DOEPMSK.modify(.{
            .STUPM = 1, //setup phase done
            .XFRCM = 1, //OUT xfer complete
        });
        regs.OTG_FS_DEVICE.OTG_FS_DIEPMSK.modify(.{
            .XFRCM = 1, //IN xfer complete
            .TOM = 1, //timeout
        });
        //setup data FIFO RAM for each FIFO
        //FIFO sizes done in usbInit
        //prepare ep0OUT for setup packets
        regs.OTG_FS_DEVICE.OTG_FS_DOEPTSIZ0.modify(.{ .STUPCNT = 0b11 });
        regs.OTG_FS_GLOBAL.OTG_FS_GINTSTS.modify(.{ .USBRST = 1 });
    }
    if (gintState.ENUMDNE == 1) {
        //speed enumeration complete, prepare for setup
        const speed = regs.OTG_FS_DEVICE.OTG_FS_DSTS.read();
        if (speed.ENUMSPD == 0b11) { //valid full-speed value
            //set the max packet size of ep0 (control) to 64B (0b00)
            regs.OTG_FS_DEVICE.OTG_FS_DIEPCTL0.modify(.{ .MPSIZ = 0b00 });
            regs.OTG_FS_DEVICE.OTG_FS_DOEPCTL0.modify(.{ .MPSIZ = 0b00 });
        }
        regs.OTG_FS_GLOBAL.OTG_FS_GINTSTS.modify(.{ .ENUMDNE = 1 });
        //while (true) {}
    }
    if (gintState.RXFLVL == 1) {
        regs.OTG_FS_GLOBAL.OTG_FS_GINTSTS.modify(.{ .RXFLVL = 1 });
    }

    if (gintState.SRQINT == 1) {
        //write 1 to clear the flag
        regs.OTG_FS_GLOBAL.OTG_FS_GINTSTS.modify(.{ .SRQINT = 1 });
    }
    if (gintState.ESUSP == 1) {
        regs.OTG_FS_GLOBAL.OTG_FS_GINTSTS.modify(.{ .ESUSP = 1 });
    }
    if (gintState.USBSUSP == 1) {
        regs.OTG_FS_GLOBAL.OTG_FS_GINTSTS.modify(.{ .USBSUSP = 1 });
    }
    if (gintState.SOF == 1) {
        regs.OTG_FS_GLOBAL.OTG_FS_GINTSTS.modify(.{ .SOF = 1 });
    }

    if (daintState.OEPINT & 0x0001 == 0x0001) {
        //ep0OUT interrupt event
    }
}
