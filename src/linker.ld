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

/* Linker script for ST STM32F4DISCOVERY (STM32F407VG, 1024K flash, 128K RAM,
 * 64K Core Coupled Memory RAM).
 */

/* Modified linker script for STM32F3DISCOVERY (STM32F303VC)
*/

/* Define memory regions. */
MEMORY
{
  rom (rx) : ORIGIN = 0x08000000, LENGTH = 256K
  ram (rwx) : ORIGIN = 0x20000000, LENGTH = 40K
  ccm (rwx) : ORIGIN = 0x10000000, LENGTH = 8K
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
PROVIDE(wwdgHandler = blockingHandler);
PROVIDE(pvdHandler = blockingHandler);
PROVIDE(tamperStampHandler = blockingHandler);
PROVIDE(rtcWakeupHandler = blockingHandler);
PROVIDE(flashHandler = blockingHandler);
PROVIDE(rccHandler = blockingHandler);
PROVIDE(exti0Handler = blockingHandler);
PROVIDE(exti1Handler = blockingHandler);
PROVIDE(exti2_tsHandler = blockingHandler);
PROVIDE(exti3Handler = blockingHandler);
PROVIDE(exti4Handler = blockingHandler);
PROVIDE(dma1_1Handler = blockingHandler);
PROVIDE(dma1_2Handler = blockingHandler);
PROVIDE(dma1_3Handler = blockingHandler);
PROVIDE(dma1_4Handler = blockingHandler);
PROVIDE(dma1_5Handler = blockingHandler);
PROVIDE(dma1_6Handler = blockingHandler);
PROVIDE(dma1_7Handler = blockingHandler);
PROVIDE(adc1_2Handler = blockingHandler);
PROVIDE(usb_hpHandler = blockingHandler);
PROVIDE(usb_lpHandler = blockingHandler);
PROVIDE(can_rx1Handler = blockingHandler);
PROVIDE(can_sceHandler = blockingHandler);
PROVIDE(exti9_5Handler = blockingHandler);
PROVIDE(tim15Handler = blockingHandler);
PROVIDE(tim16Handler = blockingHandler);
PROVIDE(tim17Handler = blockingHandler);
PROVIDE(tim1_ccHandler = blockingHandler);
PROVIDE(tim2Handler = test_handler);
PROVIDE(tim3Handler = blockingHandler);
PROVIDE(tim4Handler = blockingHandler);

/* Define sections. */
SECTIONS
{
  .text : {
    KEEP (*(.vectors*)) /* Vector table */
    *(.text*)  /* Program code */
    *(.rodata*)  /* Read-only data */
    . = ALIGN(4);
  } >rom

  /* C++ Static constructors/destructors, also used for __attribute__
   * ((constructor)) and the likes */
  .preinit_array : {
    . = ALIGN(4);
    __preinit_array_start = .;
    KEEP (*(.preinit_array))
    __preinit_array_end = .;
  } >rom
  .init_array : {
    . = ALIGN(4);
    __init_array_start = .;
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array))
    __init_array_end = .;
  } >rom
  .fini_array : {
    . = ALIGN(4);
    __fini_array_start = .;
    KEEP (*(.fini_array))
    KEEP (*(SORT(.fini_array.*)))
    __fini_array_end = .;
  } >rom

  /*
   * Another section used by C++ stuff, appears when using newlib with
   * 64bit (long long) printf support
   */
  .ARM.extab : {
    *(.ARM.extab*)
  } >rom
  .ARM.exidx : {
    __exidx_start = .;
    *(.ARM.exidx*)
    __exidx_end = .;
  } >rom

  . = ALIGN(4);
  _etext = .;

  /* ram, but not cleared on reset, eg boot/app comms */
  .noinit (NOLOAD) : {
    *(.noinit*)
  } >ram
  . = ALIGN(4);

  .data : {
    _data = .;
    *(.data*)  /* Read-write initialized data */
    *(.ramtext*)    /* "text" functions to run in ram */
    . = ALIGN(4);
    _edata = .;
  } >ram AT >rom
  _data_loadaddr = LOADADDR(.data);

  .bss : {
    _bss = .;
    *(.bss*)  /* Read-write zero initialized data */
    *(COMMON)
    . = ALIGN(4);
    _ebss = .;
  } >ram

  /*
   * The .eh_frame section appears to be used for C++ exception handling.
   * You may need to fix this if you're using C++.
   */
  /DISCARD/ : { *(.eh_frame) }

  . = ALIGN(4);
  end = .;
}

PROVIDE(_stack = ORIGIN(ram) + LENGTH(ram));
