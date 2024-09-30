const regs = @import("registers.zig");

pub fn usbInit() void { //base on HAL_PCD_Init
    //enable clocks and pins
    hardwareInit();
    //mask interrupts before starting
    regs.OTG_FS_GLOBAL.OTG_FS_GAHBCFG.modify(.{ .GINT = 0 });
    //Init the core
    //Setup embedded FS PHY
    //for FS this bit is always 1 with RO access, but do it anyways?
    regs.OTG_FS_GLOBAL.OTG_FS_GUSBCFG.modify(.{ .PHYSEL = 1 });
    //Reset the core after phy sel
    resetCore();
    //enable transceiver
    regs.OTG_FS_GLOBAL.OTG_FS_GCCFG.modify(.{ .PWRDWN = 1 });
    //enable DMA if used (not used in this case)
    //Force to device mode regardless of ID pin
    regs.OTG_FS_GLOBAL.OTG_FS_GUSBCFG.modify(.{ .FHMOD = 0, .FDMOD = 1 });
    //poll the GINTSTS CMOD bit to ensure it's device
    var gintstsState = regs.OTG_FS_GLOBAL.OTG_FS_GINTSTS.read();
    while (gintstsState.CMOD != 0) {
        gintstsState = regs.OTG_FS_GLOBAL.OTG_FS_GINTSTS.read();
    }
    //Init endpoint structures, in and out
    //start with ep0?

    //Init device
    devInit();
    //clear any pending interrupts and init the base EP controls
    //open up all the masks
    regs.OTG_FS_DEVICE.OTG_FS_DIEPMSK.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DOEPMSK.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DAINTMSK.write_raw(0);
    epInInit();
    epOutInit();

    //set common endpoint interrupt mask
    regs.OTG_FS_DEVICE.OTG_FS_DIEPMSK.modify(.{ .TXFURM = 0 });
    //disable all interrupts
    regs.OTG_FS_GLOBAL.OTG_FS_GINTMSK.write_raw(0);
    //clear all int flags.
    regs.OTG_FS_GLOBAL.OTG_FS_GINTSTS.write_raw(0xFFFFFFFF);
    //enable interrupts which match device mode
    regs.OTG_FS_GLOBAL.OTG_FS_GINTMSK.modify(.{
        .SRQIM = 1,
        .USBRST = 1,
        .ENUMDNEM = 1,
        .ESUSPM = 1,
        .USBSUSPM = 1,
        .SOFM = 1,
        //.RXFLVLM = 1, //if dma disabled only?
        //.IEPINT = 1,
        //.OEPINT = 1,
        //.IISOIXFRM = 1,
        //.IPXFRM_IISOOXFRM = 1,
        //.WUIM = 1,
    });
    //enable SoF and vbus sense interrupt if needed
    //enable link power management (LPM) if needed
    //'Disconnect' the device?
    deviceDisconnect();
    //Setup PCD RX and TX fifos. Sizes straight for default stm32 hal
    //rx fifo starts at base, tx fifo 0 starts at base+RxSize, tx fifo 1 starts at base+RxSize+Tx0Size
    const DEFAULT_RX_SIZE: u16 = 0x0080;
    const DEFAULT_TX0_SIZE: u16 = 0x0040;
    const DEFAULT_TX1_SIZE: u16 = 0x0080;
    regs.OTG_FS_GLOBAL.OTG_FS_GRXFSIZ.modify(.{ .RXFD = DEFAULT_RX_SIZE });
    regs.OTG_FS_GLOBAL.OTG_FS_DIEPTXF0_Device.modify(.{
        .TX0FD = DEFAULT_TX0_SIZE,
        .TX0FSA = DEFAULT_RX_SIZE,
    });
    regs.OTG_FS_GLOBAL.OTG_FS_DIEPTXF1.modify(.{
        .INEPTXFD = DEFAULT_TX1_SIZE,
        .INEPTXSA = DEFAULT_RX_SIZE + DEFAULT_TX0_SIZE,
    });
}

pub fn registerClass() void {
    //Skipping this for now since it's just a lot of const struct constructiong (I think).
    //If everything else works, windows should recognize a USB device but it will be unknown.
}

pub fn start() void {
    //enable otg interrupts
    regs.OTG_FS_GLOBAL.OTG_FS_GAHBCFG.modify(.{ .GINT = 1 });
    //Start connect device
    deviceConnect();
}

fn hardwareInit() void {
    //set usb core clk48 source from main pll
    regs.RCC.DKCFGR2.modify(.{ .CK48MSEL = 0 });
    //enable GPIOA clock
    regs.RCC.AHB1ENR.modify(.{ .GPIOAEN = 1 });
    regs.GPIOA.MODER.modify(.{ //pin mode
        .MODER8 = 0b10, //SOF, 10 = alternate function
        .MODER9 = 0b00, //VBUS, 00 = input
        .MODER10 = 0b10, //ID
        .MODER11 = 0b10, //DM
        .MODER12 = 0b10, //DP
    });
    regs.GPIOA.PUPDR.modify(.{ //pull settings
        .PUPDR8 = 0b00, //00 = no pullup or down
        .PUPDR9 = 0b00,
        .PUPDR10 = 0b00,
        .PUPDR11 = 0b00,
        .PUPDR12 = 0b00,
    });
    regs.GPIOA.OTYPER.modify(.{ //output type
        .OT8 = 0b0, //0 = push-pull
        .OT10 = 0b0,
        .OT11 = 0b0,
        .OT12 = 0b0,
    });
    regs.GPIOA.OSPEEDR.modify(.{ //output speed
        .OSPEEDR8 = 0b11, //11 = very fast
        .OSPEEDR10 = 0b11,
        .OSPEEDR11 = 0b11,
        .OSPEEDR12 = 0b11,
    });
    regs.GPIOA.AFRH.modify(.{ //alternate function sel
        .AFRH8 = 0xA, //0xA = AF10 = USBOTGFS
        .AFRH10 = 0xA,
        .AFRH11 = 0xA,
        .AFRH12 = 0xA,
    });
    //rcc usb enable
    regs.RCC.AHB2ENR.modify(.{ .OTGFSEN = 1 });
    //nvic interrupt, OTG_FS is position 16, prio is 0 (highest)
    regs.NVIC.IPR16.modify(.{ .PRIN67 = 0x00 });
    regs.NVIC.ISER2.modify(.{ .SETENA67 = 1 });
}

fn resetCore() void {
    //wait for AHB idle
    //var grstctlState = regs.OTG_FS_GLOBAL.OTG_FS_GRSTCTL.read();
    //while (grstctlState.AHBIDL != 0) {
    //    grstctlState = regs.OTG_FS_GLOBAL.OTG_FS_GRSTCTL.read();
    //}
    //core soft reset. Self clearing when done
    regs.OTG_FS_GLOBAL.OTG_FS_GRSTCTL.modify(.{ .CSRST = 1 });
    var grstctlState = regs.OTG_FS_GLOBAL.OTG_FS_GRSTCTL.read();
    while (grstctlState.CSRST != 0) {
        grstctlState = regs.OTG_FS_GLOBAL.OTG_FS_GRSTCTL.read();
    }
}

fn devInit() void {
    //We will write valid values to these later
    regs.OTG_FS_GLOBAL.OTG_FS_DIEPTXF0_Device.write_raw(0);
    regs.OTG_FS_GLOBAL.OTG_FS_DIEPTXF1.write_raw(0);
    regs.OTG_FS_GLOBAL.OTG_FS_DIEPTXF2.write_raw(0);
    regs.OTG_FS_GLOBAL.OTG_FS_DIEPTXF3.write_raw(0);
    regs.OTG_FS_GLOBAL.OTG_FS_DIEPTXF4.write_raw(0);
    regs.OTG_FS_GLOBAL.OTG_FS_DIEPTXF5.write_raw(0);
    //assert soft disconnect
    regs.OTG_FS_DEVICE.OTG_FS_DCTL.modify(.{ .SDIS = 1 });
    //enable vbus sensing
    regs.OTG_FS_GLOBAL.OTG_FS_GCCFG.modify(.{ .VBDEN = 1 });
    //override the Bvalid signal with '1'
    regs.OTG_FS_GLOBAL.OTG_FS_GOTGCTL.modify(.{ .BVALOEN = 1, .BVALOVAL = 1 });
    //restart phy clock. Little confused about this, but just follow the stm32 hal
    regs.OTG_FS_PWRCLK.OTG_FS_PCGCCTL.write_raw(0);
    //device mode configuration
    regs.OTG_FS_DEVICE.OTG_FS_DCFG.modify(.{ .DSPD = 0b11 });
    //flush TX FIFOs
    flushTxFIFOs();
    //flush RX FIFOs
    flushRxFIFOs();
}

fn flushTxFIFOs() void {
    //wait for AHB idle
    //var grstctlState = regs.OTG_FS_GLOBAL.OTG_FS_GRSTCTL.read();
    //while (grstctlState.AHBIDL != 0) {
    //    grstctlState = regs.OTG_FS_GLOBAL.OTG_FS_GRSTCTL.read();
    //}
    //set flush all FIFOs
    regs.OTG_FS_GLOBAL.OTG_FS_GRSTCTL.modify(.{ .TXFNUM = 0b10000 });
    //start flush
    regs.OTG_FS_GLOBAL.OTG_FS_GRSTCTL.modify(.{ .TXFFLSH = 1 });
    //wait for core to clear the bit
    var grstctlState = regs.OTG_FS_GLOBAL.OTG_FS_GRSTCTL.read();
    while (grstctlState.TXFFLSH != 0) {
        grstctlState = regs.OTG_FS_GLOBAL.OTG_FS_GRSTCTL.read();
    }
}

fn flushRxFIFOs() void {
    //wait for AHB idle
    //var grstctlState = regs.OTG_FS_GLOBAL.OTG_FS_GRSTCTL.read();
    //while (grstctlState.AHBIDL != 0) {
    //    grstctlState = regs.OTG_FS_GLOBAL.OTG_FS_GRSTCTL.read();
    //}
    //This bit flushes all RX FIFOs
    regs.OTG_FS_GLOBAL.OTG_FS_GRSTCTL.modify(.{ .RXFFLSH = 1 });
    //wait for core to clear the bit
    var grstctlState = regs.OTG_FS_GLOBAL.OTG_FS_GRSTCTL.read();
    while (grstctlState.RXFFLSH != 0) {
        grstctlState = regs.OTG_FS_GLOBAL.OTG_FS_GRSTCTL.read();
    }
}

fn epInInit() void {
    //clear IN endpoint control registers
    //stm32 hal checks for enabled endpoints here, we can safely skip that for now.
    regs.OTG_FS_DEVICE.OTG_FS_DIEPCTL0.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DIEPCTL1.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DIEPCTL2.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DIEPCTL3.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DIEPCTL4.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DIEPCTL5.write_raw(0);
    //clear IN endpoint transfer size registers
    regs.OTG_FS_DEVICE.OTG_FS_DIEPTSIZ0.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DIEPTSIZ1.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DIEPTSIZ2.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DIEPTSIZ3.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DIEPTSIZ4.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DIEPTSIZ55.write_raw(0); //is it a bug in registers that there is an extra 5?
    //clear IN endpoint interrupts. Magic value taken from stm32 hal. Makes no sense to me yet.
    regs.OTG_FS_DEVICE.OTG_FS_DIEPINT0.write_raw(0x0000FB7F);
    regs.OTG_FS_DEVICE.OTG_FS_DIEPINT1.write_raw(0x0000FB7F);
    regs.OTG_FS_DEVICE.OTG_FS_DIEPINT2.write_raw(0x0000FB7F);
    regs.OTG_FS_DEVICE.OTG_FS_DIEPINT3.write_raw(0x0000FB7F);
    regs.OTG_FS_DEVICE.OTG_FS_DIEPINT4.write_raw(0x0000FB7F);
    regs.OTG_FS_DEVICE.OTG_FS_DIEPINT5.write_raw(0x0000FB7F);
}

fn epOutInit() void {
    //clear OUT endpoint control registers
    //stm32 hal checks for enabled endpoints here, we can safely skip that for now.
    regs.OTG_FS_DEVICE.OTG_FS_DOEPCTL0.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DOEPCTL1.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DOEPCTL2.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DOEPCTL3.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DOEPCTL4.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DOEPCTL5.write_raw(0);
    //clear IN endpoint transfer size registers
    regs.OTG_FS_DEVICE.OTG_FS_DOEPTSIZ0.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DOEPTSIZ1.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DOEPTSIZ2.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DOEPTSIZ3.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DOEPTSIZ4.write_raw(0);
    regs.OTG_FS_DEVICE.OTG_FS_DOEPTSIZ5.write_raw(0);
    //clear IN endpoint interrupts. Magic value taken from stm32 hal. Makes no sense to me yet.
    regs.OTG_FS_DEVICE.OTG_FS_DOEPINT0.write_raw(0x0000FB7F);
    regs.OTG_FS_DEVICE.OTG_FS_DOEPINT1.write_raw(0x0000FB7F);
    regs.OTG_FS_DEVICE.OTG_FS_DOEPINT2.write_raw(0x0000FB7F);
    regs.OTG_FS_DEVICE.OTG_FS_DOEPINT3.write_raw(0x0000FB7F);
    regs.OTG_FS_DEVICE.OTG_FS_DOEPINT4.write_raw(0x0000FB7F);
    regs.OTG_FS_DEVICE.OTG_FS_DOEPINT5.write_raw(0x0000FB7F);
}

fn deviceDisconnect() void {
    //in case the phy is disabled, make sure the clocks are enabled
    regs.OTG_FS_PWRCLK.OTG_FS_PCGCCTL.modify(.{ .STPPCLK = 0, .GATEHCLK = 0 });
    //assert soft disconnect
    regs.OTG_FS_DEVICE.OTG_FS_DCTL.modify(.{ .SDIS = 1 });
}

fn deviceConnect() void {
    //in case the phy is disabled, make sure the clocks are enabled
    regs.OTG_FS_PWRCLK.OTG_FS_PCGCCTL.modify(.{ .STPPCLK = 0, .GATEHCLK = 0 });
    //release soft disconnect
    regs.OTG_FS_DEVICE.OTG_FS_DCTL.modify(.{ .SDIS = 0 });
}

//endpoint struct
const ep_enum = enum(u2) {
    EP_TYPE_CTRL = 0,
    EP_TYPE_ISOC = 1,
    EP_TYPE_BULK = 2,
    EP_TYPE_INTR = 3,
    EP_TYPE_MSK = 3,
};

const EP = struct {
    num: u4, //endpoint number, possible values to 1-15
    is_in: bool, //true if IN endpoint, false if OUT.
    is_stall: bool, //true if endpoint is stalled
    is_iso_incomplete: bool, //true if isochronous transaction is incomplete
    ep_type: ep_enum, //enumerated type of endpoint
    data_pid_start: u1, //inital data PID
    even_odd_frame: u1, //0 if even, 1 if odd frame
    tx_fifo_num: u4, //tx fifo used by this EP, 1-15
    max_packet: u32, //up to 64KB packet size
    xfer_buff: *u8, //pointer to transfer buffer of bytes
    dma_addr: u32, //address of dma transfer buffer
    xfer_len: u32, //length of current dma transfer
    xfer_size: u32, //requested dma transfer size
    xfer_count: u32, //partial transfer length in case of multi packet transfer
};

const setup8B = packed struct {
    var bmRequestType = packed struct {
        Recipient: u5,
        Type: u2,
        DataPhase: u1,
    };
    bRequest: u8,
    wValue: u16,
    wIndex: u16,
    wLength: u16,
};

var ep_ctrl_in = EP{
    .num = 0, //ep0 is the control endpoint
    .is_in = true, //control endpoint is IN from host
    .is_stall = false,
    .is_iso_incomplete = false,
    .ep_type = ep_enum.EP_TYPE_CTRL,
    .data_pid_start = 0, //inital data PID
    .even_odd_frame = 0, //0 if even, 1 if odd frame
    .tx_fifo_num = 0, //tx fifo used by this EP, 1-15
    .max_packet = 0, //up to 64KB packet size
    .xfer_buff = 0, //pointer to transfer buffer of bytes
    .dma_addr = 0, //address of dma transfer buffer
    .xfer_len = 0, //length of current dma transfer
    .xfer_size = 0, //requested dma transfer size
    .xfer_count = 0, //partial transfer length in case of multi packet transfer
};

var ep_ctrl_out = EP{
    .num = 0, //ep0 is the control endpoint
    .is_in = false, //control endpoint is IN from host
    .is_stall = false,
    .is_iso_incomplete = false,
    .ep_type = ep_enum.EP_TYPE_CTRL,
    .data_pid_start = 0, //inital data PID
    .even_odd_frame = 0, //0 if even, 1 if odd frame
    .tx_fifo_num = 0, //tx fifo used by this EP, 1-15
    .max_packet = 0, //up to 64KB packet size
    .xfer_buff = 0, //pointer to transfer buffer of bytes
    .dma_addr = 0, //address of dma transfer buffer
    .xfer_len = 0, //length of current dma transfer
    .xfer_size = 0, //requested dma transfer size
    .xfer_count = 0, //partial transfer length in case of multi packet transfer
};
