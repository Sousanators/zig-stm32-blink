/*
 * This file is part of the libopencm3 project.
 *
 * Copyright (C) 2009 Uwe Hermann <uwe@hermann-uwe.de>
 * Copyright (C) 2011 Stephen Caudle <scaudle@doceme.com>
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

/* Modified linker script for STM32F3DISCOVERY (STM32F303VC) */

/* Define memory regions. */
MEMORY
{
  rom (rx) : ORIGIN = 0x08000000, LENGTH = 2048K
  ram (rwx) : ORIGIN = 0x20000000, LENGTH = 512K
}

/* Define the entry point of the output file. */
/* ENTRY(resetHandler) */

/* This provide weak linking to empty handlers, which can be overridden */
PROVIDE(nmiHandler = nullHandler);
PROVIDE(hardFaultHandler = blockingHandler);
PROVIDE(memoryManagementFaultHandler = blockingHandler);
PROVIDE(busFaultHandler = blockingHandler);
PROVIDE(usageFaultHandler = blockingHandler);
PROVIDE(svCallHandler = nullHandler);
PROVIDE(debugMonitorHandler = nullHandler);
PROVIDE(pendSVHandler = nullHandler);
PROVIDE(sysTickHandler = nullHandler);
PROVIDE(wwdgHandler = nullHandler);
PROVIDE(pvdHandler = nullHandler);
PROVIDE(tamperStampHandler = nullHandler);
PROVIDE(rtcWakeupHandler = nullHandler);
PROVIDE(flashHandler = nullHandler);
PROVIDE(rccHandler = nullHandler);
PROVIDE(exti0Handler = nullHandler);
PROVIDE(exti1Handler = nullHandler);
PROVIDE(exti2Handler = nullHandler);
PROVIDE(exti3Handler = nullHandler);
PROVIDE(exti4Handler = nullHandler);
PROVIDE(dma1_0Handler = nullHandler);
PROVIDE(dma1_1Handler = nullHandler);
PROVIDE(dma1_2Handler = nullHandler);
PROVIDE(dma1_3Handler = nullHandler);
PROVIDE(dma1_4Handler = nullHandler);
PROVIDE(dma1_5Handler = nullHandler);
PROVIDE(dma1_6Handler = nullHandler);
PROVIDE(adc1_2_3Handler = nullHandler);
PROVIDE(can1_txHandler = nullHandler);
PROVIDE(can1_rx0Handler = nullHandler);
PROVIDE(can1_rx1Handler = nullHandler);
PROVIDE(can1_sceHandler = nullHandler);
PROVIDE(exti9_5Handler = nullHandler);
PROVIDE(tim1_brk_tim9Handler = nullHandler);
PROVIDE(tim1_up_tim10Handler = nullHandler);
PROVIDE(tim1_trg_com_tim11Handler = nullHandler);
PROVIDE(tim1_ccHandler = nullHandler);
PROVIDE(tim2Handler = nullHandler);
PROVIDE(tim3Handler = nullHandler);
PROVIDE(tim4Handler = nullHandler);
PROVIDE(i2c1_evHandler = nullHandler);
PROVIDE(i2c1_erHandler = nullHandler);
PROVIDE(i2c2_evHandler = nullHandler);
PROVIDE(inc2_erHandler = nullHandler);
PROVIDE(spi1Handler = nullHandler);
PROVIDE(spi2Handler = nullHandler);
PROVIDE(usart1Handler = nullHandler);
PROVIDE(usart2Handler = nullHandler);
PROVIDE(usart3Handler = nullHandler);
PROVIDE(exti15_10Handler = nullHandler);
PROVIDE(rtc_alarmHandler = nullHandler);
PROVIDE(otg_fs_wkupHandler = nullHandler);
PROVIDE(tim8_brk_tim12Hanlder = nullHandler);
PROVIDE(tim8_up_tim13Handler = nullHandler);
PROVIDE(tim8_trg_com_tim14Hanlder = nullHandler);
PROVIDE(tim8_ccHandler = nullHandler);
PROVIDE(dma1_stream7Handler = nullHandler);
PROVIDE(fsmcHanlder = nullHandler);
PROVIDE(sdmmc1Handler = nullHandler);
PROVIDE(tim5Hanlder = nullHandler);
PROVIDE(spi3Hanlder = nullHandler);
PROVIDE(uart4Handler = nullHandler);
PROVIDE(uart5Handler = nullHandler);
PROVIDE(tim6_dacHanlder = nullHandler);
PROVIDE(tim7Handler = nullHandler);
PROVIDE(dma2_stream0Handler = nullHandler);
PROVIDE(dma2_stream1Hanlder = nullHandler);
PROVIDE(dma2_stream2Hanlder = nullHandler);
PROVIDE(dma2_stream3Handler = nullHandler);
PROVIDE(dma2_stream4Handler = nullHandler);
PROVIDE(ethHandler = nullHandler);
PROVIDE(eth_wkupHandler = nullHandler);
PROVIDE(can2_txHandler = nullHandler);
PROVIDE(can2_rx0Handler = nullHandler);
PROVIDE(can2_rx1Handler = nullHandler);
PROVIDE(can2_sceHanlder = nullHandler);
PROVIDE(otg_fsHanlder = nullHandler);

/* Define sections. */
SECTIONS
{
  .vectors : {
    . = ALIGN(4);
    KEEP (*(.vectors*)) /* Vector table */
    . = ALIGN(4);
  } >rom

  .text :
  {
    . = ALIGN(4);
    *(.text)           /* .text sections (code) */
    *(.text*)          /* .text* sections (code) */
    *(.glue_7)         /* glue arm to thumb code */
    *(.glue_7t)        /* glue thumb to arm code */
    *(.eh_frame)

    KEEP (*(.init))
    KEEP (*(.fini))

    . = ALIGN(4);
    _etext = .;        /* define a global symbols at end of code */
  } >rom

  /* Constant data into "FLASH" Rom type memory */
  .rodata :
  {
    . = ALIGN(4);
    *(.rodata)         /* .rodata sections (constants, strings, etc.) */
    *(.rodata*)        /* .rodata* sections (constants, strings, etc.) */
    . = ALIGN(4);
  } >rom

  .ARM.extab : 
  {
    . = ALIGN(4);
    *(.ARM.extab*)
    . = ALIGN(4);
  } >rom

  .ARM :
  {
    . = ALIGN(4);
    __exidx_start = .;
    *(.ARM.exidx*)
    __exidx_end = .;
    . = ALIGN(4);
  } >rom

  .preinit_array :
  {
    . = ALIGN(4);
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array*))
    PROVIDE_HIDDEN (__preinit_array_end = .);
    . = ALIGN(4);
  } >rom

  .init_array :
  {
    . = ALIGN(4);
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array*))
    PROVIDE_HIDDEN (__init_array_end = .);
    . = ALIGN(4);
  } >rom

  .fini_array :
  {
    . = ALIGN(4);
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT(.fini_array.*)))
    KEEP (*(.fini_array*))
    PROVIDE_HIDDEN (__fini_array_end = .);
    . = ALIGN(4);
  } >rom

  /* Used by the startup to initialize data */
   _data_loadaddr = LOADADDR(.data);

  /* Initialized data sections into "RAM" Ram type memory */
  .data :
  {
    . = ALIGN(4);
    _data = .;        /* create a global symbol at data start */
    *(.data)           /* .data sections */
    *(.data*)          /* .data* sections */
    *(.RamFunc)        /* .RamFunc sections */
    *(.RamFunc*)       /* .RamFunc* sections */

    . = ALIGN(4);
    _edata = .;        /* define a global symbol at data end */

  } >ram AT> rom

  /* Uninitialized data section into "RAM" Ram type memory */
  . = ALIGN(4);
  .bss :
  {
    /* This is used by the startup in order to initialize the .bss section */
    _bss = .;         /* define a global symbol at bss start */
    __bss_start__ = _bss;
    *(.bss)
    *(.bss*)
    *(COMMON)

    . = ALIGN(4);
    _ebss = .;         /* define a global symbol at bss end */
    __bss_end__ = _ebss;
  } >ram
}
PROVIDE(_stack = ORIGIN(ram) + LENGTH(ram));