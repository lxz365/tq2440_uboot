;/*
; *  armboot - Startup Code for ARM920T CPU-core
; *
; *  Copyright (c) 2012  luoqindong<luoqindong123@163.com>
; *
; * See file CREDITS for list of people who contributed to this
; * project.
; *
; * This program is free software; you can redistribute it and/or
; * modify it under the terms of the GNU General Public License as
; * published by the Free Software Foundation; either version 2 of
; * the License, or (at your option) any later version.
; *
; * This program is distributed in the hope that it will be useful,
; * but WITHOUT ANY WARRANTY; without even the implied warranty of
; * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; * GNU General Public License for more details.
; *
; * You should have received a copy of the GNU General Public License
; * along with this program; if not, write to the Free Software
; * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
; * MA 02111-1307 USA
; */

; *************************************************************************
; * config
; *************************************************************************

CONFIG_START_FROM_RAM		equ		1
CONFIG_S3C2440				equ		1
CONFIG_TQ2440 				equ		1
CONFIG_S3C2400				equ		0
CONFIG_S3C2410				equ		0

CONFIG_USE_IRQ				equ		0	
CONFIG_SKIP_LOWLEVEL_INIT	equ 	0
CONFIG_SKIP_RELOCATE_UBOOT	equ 	0

; must be same as in tq2440.h
CFG_MALLOC_LEN				equ		0x30000
CFG_GBL_DATA_SIZE			equ		128			;/* 128 bytes for initial data */
CONFIG_STACKSIZE			equ		(32*1024)	;/* regular stack */
 
TEXT_BASE					equ		0x33d00000


; *************************************************************************
; * import
; *************************************************************************
		import  start_armboot
		import ||Image$$E_ZI$$ZI$$Base||
		import ||Image$$E_ZI$$ZI$$Limit||
		import	clock_init	


; *************************************************************************
; * export
; *************************************************************************
		export _armboot_start
		export _bss_start
	
		IF	CONFIG_USE_IRQ = 1
	
		export IRQ_STACK_START
		export FIQ_STACK_START
	
		ENDIF



;/*
; *************************************************************************
; *
; * Jump vector table as in table 3.1 in [1]
; *
; *************************************************************************
; */
		preserve8
		area    start, code
        arm
		entry		
_start
		b       start_code
		ldr	pc, _undefined_instruction
		ldr	pc, _software_interrupt
		ldr	pc, _prefetch_abort
		ldr	pc, _data_abort
		ldr	pc, _not_used
		ldr	pc, _irq
		ldr	pc, _fiq

		ltorg

_undefined_instruction	dcd start_code
_software_interrupt	  	dcd start_code
_prefetch_abort		  	dcd start_code
_data_abort			  	dcd start_code
_not_used			  	dcd start_code
_irq				  	dcd start_code
_fiq				  	dcd start_code


;/*
; *************************************************************************
; *
; * Startup Code (called from the ARM reset exception vector)
; *
; * do important init only if we don't start from memory!
; * relocate armboot to ram
; * setup stack
; * jump to second stage
; *
; *************************************************************************
; */
		
_TEXT_BASE
		dcd	TEXT_BASE		
_armboot_start
		dcd _start

;/*
; * These are defined in the board-specific linker script.
; */				
_bss_start
		dcd	||Image$$E_ZI$$ZI$$Base||		
_bss_end
		dcd ||Image$$E_ZI$$ZI$$Limit||

		IF	CONFIG_USE_IRQ = 1
;/* IRQ stack memory (calculated at run-time) */
IRQ_STACK_START
		dcd	0x0badc0de

;/* IRQ stack memory (calculated at run-time) */
FIQ_STACK_START
		dcd 0x0badc0de

		ENDIF


;/*
; * the actual start code
; */

start_code
		;/*
		; * set the cpu to SVC32 mode
		; */
		mrs		r0,cpsr
		bic		r0,r0,#0x1f
		orr		r0,r0,#0xd3
		msr		cpsr_cxsf,r0
	
		;bl coloured_LED_init
		;bl red_LED_on

		IF (CONFIG_S3C2400 = 1) || (CONFIG_S3C2410 = 1) || (CONFIG_S3C2440 = 1)

		IF (CONFIG_S3C2400 = 1)
pWTCON		equ	0x15300000
INTMSK		equ	0x14400008
CLKDIVN		equ 0x14800014
		ELSE
pWTCON		equ	0x53000000
INTMSK		equ	0x4A000008
INTSUBMSK 	equ 0x4A00001C
CLKDIVN		equ	0x4C000014
		ENDIF
		; disable watchdog
		ldr     r0, =pWTCON
		mov     r1, #0x0
		str     r1, [r0]

		;/*
		; * mask all IRQs by setting all bits in the INTMR - default
		; */
		mov	r1, #0xffffffff
		ldr	r0, =INTMSK
		str	r1, [r0]

		IF CONFIG_S3C2410 = 1

		ldr	r1, =0x3ff
		ldr	r0, =INTSUBMSK
		str	r1, [r0]

		ENDIF

		IF	CONFIG_S3C2440 = 1

		ldr	r1, =0x7fff
		ldr	r0, =INTSUBMSK
		str	r1, [r0]

		ENDIF	

		;/* FCLK:HCLK:PCLK = 1:2:4 */
		;/* default FCLK is 120 MHz ! */
		;ldr	r0, =CLKDIVN
		;mov	r1, #3
		;str	r1, [r0]
		ENDIF ;/* IF (CONFIG_S3C2400 = 1) || (CONFIG_S3C2410 = 1) || (CONFIG_S3C2440 = 1) */

		;/*
		; * we do sys-critical inits only at reboot,
		; * not when booting from ram!
		; */
		IF CONFIG_SKIP_LOWLEVEL_INIT = 0

		bl		cpu_init_crit

		ENDIF
		
        ;/* Set up the stack  */
stack_setup
		ldr     r0, _TEXT_BASE          	;/* upper 128 KiB: relocated uboot	*/
		sub     r0, r0, #CFG_MALLOC_LEN 	;/* malloc area                     */
		sub     r0, r0, #CFG_GBL_DATA_SIZE 	;/* bdinfo							*/
	
		IF	CONFIG_USE_IRQ = 1

		sub     r0, r0, #(CONFIG_STACKSIZE_IRQ+CONFIG_STACKSIZE_FIQ)

		ENDIF

		sub     sp, r0, #12             	;/* leave 3 words for abort-stack   */	
		bl 		clock_init					;/* setup system clock 		    	*/


		IF CONFIG_SKIP_RELOCATE_UBOOT = 0

relocate						;/* relocate U-Boot to RAM	    	 */
		adr		r0, _start		;/* r0 <- current position of code   */
		ldr		r1, _TEXT_BASE	;/* test if we run from flash or RAM */
		cmp     r0, r1          ;/* don't reloc during debug         */
		beq     clear_bss
	
		ldr		r2, _armboot_start
		ldr		r3, _bss_start
		sub		r2, r3, r2		;/* r2 <- size of armboot            */
		add		r2, r0, r2		;/* r2 <- source end address         */

copy_loop
		ldmia	r0!, {r3-r10}	;/* copy from source address [r0]    */
		stmia	r1!, {r3-r10}	;/* copy to   target address [r1]    */
		cmp		r0, r2			;/* until source end addreee [r2]    */
		ble		copy_loop

		ENDIF	;/* CONFIG_SKIP_RELOCATE_UBOOT = 0 */

clear_bss
		ldr		r0, _bss_start	;/* find start of bss segment        */
		ldr		r1, _bss_end	;/* stop here                        */
		mov		r2, #0x00000000	;/* clear                            */

clbss_l
		str		r2, [r0]		;/* clear loop...                    */
		add		r0, r0, #4
		cmp		r0, r1
		ble		clbss_l
	
		ldr		pc, =start_armboot
;/*
; *************************************************************************
; *
; * CPU_init_critical registers
; *
; * setup important registers
; * setup memory timing
; *
; *************************************************************************
; */

		IF CONFIG_SKIP_LOWLEVEL_INIT = 0
cpu_init_crit
		;/*
		; * flush v4 I/D caches
		; */
		mov	r0, #0
		mcr	p15, 0, r0, c7, c7, 0	;/* flush v3/v4 cache */
		mcr	p15, 0, r0, c8, c7, 0	;/* flush v4 TLB */
	
		;/*
		; * disable MMU stuff and caches
		; */
		mrc	p15, 0, r0, c1, c0, 0
		bic	r0, r0, #0x00002300	;@ clear bits 13, 9:8 (--V- --RS)
		bic	r0, r0, #0x00000087	;@ clear bits 7, 2:0 (B--- -CAM)
		orr	r0, r0, #0x00000002	;@ set bit 2 (A) Align
		orr	r0, r0, #0x00001000	;@ set bit 12 (I) I-Cache
		mcr	p15, 0, r0, c1, c0, 0
	
		;/*
		; * before relocating, we have to setup RAM timing
		; * because memory timing is board-dependend, you will
		; * find a lowlevel_init.S in your board directory.
		; */

		IF	CONFIG_START_FROM_RAM = 0

		mov		ip, lr
		bl		lowlevel_init
		mov		lr, ip

		ENDIF

		bx		lr

		ENDIF ;/* CONFIG_SKIP_LOWLEVEL_INIT */

		IF 	CONFIG_TQ2440 = 1

		INCLUDE ..\u-boot\board\samsung\tq2440\lowlevel_init.S

		ENDIF
;/*
; *************************************************************************
; *
; * Interrupt handling
; *
; *************************************************************************
; */
		END

