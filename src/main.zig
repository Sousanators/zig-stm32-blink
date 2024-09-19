const regs = @import("registers.zig");

pub fn main() void {
    // Red LED on PE9
    // Enable GPIOE port
    regs.RCC.AHBENR.modify(.{ .IOPEEN = 0b1 });
    //Configure GPIOE9 for LED drive. Defaults are mostly ok, but verbose for learning.
    regs.GPIOE.MODER.modify(.{ .MODER9 = 0b01 });
    regs.GPIOE.OTYPER.modify(.{ .OT9 = 0b0 });
    regs.GPIOE.OSPEEDR.modify(.{ .OSPEEDR9 = 0b00 });
    regs.GPIOE.PUPDR.modify(.{ .PUPDR9 = 0b00 });

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
    //enable TIM2 count
    regs.TIM2.CR1.modify(.{ .CEN = 0b1 });

    //infinite do nothing while tim2 counts and toggles led
    while (true) {}
}

export fn tim2Handler() callconv(.C) void {
    //Read LED state
    const led_state = regs.GPIOE.ODR.read();
    //Invert LED state
    regs.GPIOE.ODR.modify(.{ .ODR9 = ~led_state.ODR9 });
    //Clear TIM2 update interrupt flag
    regs.TIM2.SR.modify(.{ .UIF = 0 });
}
