;/*
; *  armboot - Startup Code for ARM926EJS CPU-core
; *
; *  Copyright (c) 2003  Texas Instruments
; *
; *  ----- Adapted for OMAP1610 OMAP730 from ARM925t code ------
; *
; *  Copyright (c) 2001	Marius Gröger <mag@sysgo.de>
; *  Copyright (c) 2002	Alex Züpke <azu@sysgo.de>
; *  Copyright (c) 2002	Gary Jennejohn <gj@denx.de>
; *  Copyright (c) 2003	Richard Woodruff <r-woodruff2@ti.com>
; *  Copyright (c) 2003	Kshitij <kshitij@ti.com>
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


CONFIG_USE_IRQ				equ		0	
CONFIG_SKIP_LOWLEVEL_INIT	equ 	0
CONFIG_SKIP_RELOCATE_UBOOT	equ 	0

CFG_MALLOC_LEN				equ		0x2c000
CFG_GBL_DATA_SIZE			equ		128			;/* 128 bytes for initial data */
CONFIG_STACKSIZE			equ		(32*1024)	;/* regular stack */

TEXT_BASE					equ		0x73f00000

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

		export _start
_start
		b	reset
		ldr	pc, _undefined_instruction
		ldr	pc, _software_interrupt
		ldr	pc, _prefetch_abort
		ldr	pc, _data_abort
		ldr	pc, _not_used
		ldr	pc, _irq
		ldr	pc, _fiq

_undefined_instruction
		dcd undefined_instruction
_software_interrupt
		dcd software_interrupt
_prefetch_abort
		dcd prefetch_abort
_data_abort
		dcd data_abort
_not_used
		dcd not_used
_irq
		dcd irq
_fiq
		dcd fiq

;/*
; *************************************************************************
; *
; * Startup Code (reset vector)
; *
; * do important init only if we don't start from memory!
; * setup Memory and board specific bits prior to relocation.
; * relocate armboot to ram
; * setup stack
; *
; *************************************************************************
; */

_TEXT_BASE
		dcd	TEXT_BASE

		export _armboot_start
_armboot_start
		dcd _start

;/*
; * These are defined in the board-specific linker script.
; */
		import ||Image$$E_ZI$$ZI$$Base||
		export _bss_start
_bss_start
		dcd	||Image$$E_ZI$$ZI$$Base||

		import ||Image$$E_ZI$$ZI$$Limit||
		export _bss_end
_bss_end
		dcd ||Image$$E_ZI$$ZI$$Limit||

		IF	CONFIG_USE_IRQ = 1
;/* IRQ stack memory (calculated at run-time) */
		export IRQ_STACK_START
IRQ_STACK_START
		dcd	0x0badc0de

;/* IRQ stack memory (calculated at run-time) */
		export FIQ_STACK_START
FIQ_STACK_START
		dcd 0x0badc0de
		ENDIF


;/*
; * the actual reset code
; */

reset
;	/*
;	 * set the cpu to SVC32 mode
;	 */
		mrs	r0,cpsr
		bic	r0,r0,#0x1f
		orr	r0,r0,#0xd3
		msr	cpsr_cxsf,r0

;	/*
;	 * we do sys-critical inits only at reboot,
;	 * not when booting from ram!
;	 */
		IF CONFIG_SKIP_LOWLEVEL_INIT = 0
		bl	cpu_init_crit
		ENDIF

		IF CONFIG_SKIP_RELOCATE_UBOOT = 0
relocate						;/* relocate U-Boot to RAM	    	 */
		adr	r0, _start				;/* r0 <- current position of code   */
		ldr	r1, _TEXT_BASE			;/* test if we run from flash or RAM */
		cmp r0, r1              	;/* don't reloc during debug         */
		beq stack_setup
	
		ldr	r2, _armboot_start
		ldr	r3, _bss_start
		sub	r2, r3, r2				;/* r2 <- size of armboot            */
		add	r2, r0, r2				;/* r2 <- source end address         */

copy_loop
		ldmia	r0!, {r3-r10}		;/* copy from source address [r0]    */
		stmia	r1!, {r3-r10}		;/* copy to   target address [r1]    */
		cmp	r0, r2					;/* until source end addreee [r2]    */
		ble	copy_loop
		ENDIF						;/* CONFIG_SKIP_RELOCATE_UBOOT */

	;/* Set up the stack						    */
stack_setup
		ldr	r0, _TEXT_BASE				;/* upper 128 KiB: relocated uboot   */
		sub	r0, r0, #CFG_MALLOC_LEN		;/* malloc area                      */
		sub	r0, r0, #CFG_GBL_DATA_SIZE 	;/* bdinfo                        */
		IF CONFIG_USE_IRQ = 1
		sub	r0, r0, #(CONFIG_STACKSIZE_IRQ+CONFIG_STACKSIZE_FIQ)
		ENDIF
		sub	sp, r0, #12					;/* leave 3 words for abort-stack    */

clear_bss
		ldr	r0, _bss_start		;/* find start of bss segment        */
		ldr	r1, _bss_end		;/* stop here                        */
		mov	r2, #0x00000000		;/* clear                            */

clbss_l
		str	r2, [r0]			;/* clear loop...                    */
		add	r0, r0, #4
		cmp	r0, r1
		ble	clbss_l

		;bl coloured_LED_init
		;bl red_LED_on
	
		ldr	pc, _start_armboot

		import start_armboot
_start_armboot	
		dcd start_armboot


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
		;import lowlevel_init
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
		bic	r0, r0, #0x00002300		;/* clear bits 13, 9:8 (--V- --RS) */
		bic	r0, r0, #0x00000087		;/* clear bits 7, 2:0 (B--- -CAM) */
		orr	r0, r0, #0x00000002		;/* set bit 2 (A) Align */
		orr	r0, r0, #0x00001000		;/* set bit 12 (I) I-Cache */
		mcr	p15, 0, r0, c1, c0, 0
	
		;/*
		; * Go setup Memory and board specific bits prior to relocation.
		; */
		mov	ip, lr					;/* perserve link reg across call */
		;bl	lowlevel_init			;/* go setup pll,mux,memory */
		;lowlevel_init is handled by at91bootstrap 
		mov	lr, ip					;/* restore link */					
		bx	lr						;/* back to my caller */
		ENDIF 						;/* CONFIG_SKIP_LOWLEVEL_INIT */

;/*
; *************************************************************************
; *
; * Interrupt handling
; *
; *************************************************************************
; */

;
; IRQ stack frame.
;
;#define S_FRAME_SIZE	72
S_FRAME_SIZE	equ	71

;#define S_OLD_R0	68
S_OLD_R0		equ	68
;#define S_PSR		64
S_PSR			equ	64
;#define S_PC		60
S_PC			equ	60
;#define S_LR		56
S_LR			equ	56
;#define S_SP		52
S_SP			equ	52
;#define S_IP		48
S_IP			equ	48
;#define S_FP		44
S_FP			equ 44
;#define S_R10		40
S_R10			equ	40
;#define S_R9		36
S_R9			equ 36
;#define S_R8		32
S_R8			equ 32
;#define S_R7		28
S_R7			equ 28
;#define S_R6		24
S_R6			equ 24
;#define S_R5		20
S_R5			equ 20
;#define S_R4		16
S_R4			equ 16
;#define S_R3		12
S_R3			equ 12
;#define S_R2		8
S_R2			equ 8
;#define S_R1		4
S_R1			equ 4
;#define S_R0		0
S_R0			equ 0

;#define MODE_SVC 0x13
MODE_SVC		equ 0x13
;#define I_BIT	 0x80
I_BIT			equ 0x80

;/*
; * use bad_save_user_regs for abort/prefetch/undef/swi ...
; * use irq_save_user_regs / irq_restore_user_regs for IRQ/FIQ handling
; */

	;MACRO
	;bad_save_user_regs
	; carve out a frame on current user stack
	sub	sp, sp, #S_FRAME_SIZE
	stmia	sp, {r0 - r12}	; Save user registers (now in svc mode) r0-r12

	ldr	r2, _armboot_start
	sub	r2, r2, #(CONFIG_STACKSIZE+CFG_MALLOC_LEN)
	sub	r2, r2, #(CFG_GBL_DATA_SIZE+8)  ; set base 2 words into abort stack
	; get values for "aborted" pc and cpsr (into parm regs)
	ldmia	r2, {r2 - r3}
	add	r0, sp, #S_FRAME_SIZE		; grab pointer to old stack
	add	r5, sp, #S_SP
	mov	r1, lr
	stmia	r5, {r0 - r3}	; save sp_SVC, lr_SVC, pc, cpsr
	mov	r0, sp		; save current stack into r0 (param register)
	;MEND

	;MACRO
	;irq_save_user_regs
	sub	sp, sp, #S_FRAME_SIZE
	stmia	sp, {r0 - r12}			; Calling r0-r12
	; !!!! R8 NEEDS to be saved !!!! a reserved stack spot would be good.
	add	r8, sp, #S_PC
	stmdb	r8, {sp, lr}^		; Calling SP, LR
	str	lr, [r8, #0]		; Save calling PC
	mrs	r6, spsr
	str	r6, [r8, #4]		; Save CPSR
	str	r0, [r8, #8]		; Save OLD_R0
	mov	r0, sp
	;MEND

	;MACRO
	;irq_restore_user_regs
	ldmia	sp, {r0 - lr}^			; Calling r0 - lr
	mov	r0, r0
	ldr	lr, [sp, #S_PC]			; Get PC
	add	sp, sp, #S_FRAME_SIZE
	subs	pc, lr, #4		; return & move spsr_svc into cpsr
	;MEND

	;MACRO
	;get_bad_stack
	ldr	r13, _armboot_start		; setup our mode stack
	sub	r13, r13, #(CONFIG_STACKSIZE+CFG_MALLOC_LEN)
	sub	r13, r13, #(CFG_GBL_DATA_SIZE+8) ; reserved a couple spots in abort stack

	str	lr, [r13]	; save caller lr in position 0 of saved stack
	mrs	lr, spsr	; get the spsr
	str	lr, [r13, #4]	; save spsr in position 1 of saved stack
	mov	r13, #MODE_SVC	; prepare SVC-Mode
	msr	spsr_c, r13
	;msr	spsr, r13	; switch modes, make sure moves will execute
	mov	lr, pc		; capture return pc
	movs pc, lr		; jump to next instruction & switch modes.
	;MEND
			; setup IRQ stack
	;MACRO
	;get_irq_stack
	;ldr	sp, IRQ_STACK_START
	;MEND
			; setup FIQ stack
	;MACRO
	;get_fiq_stack
	;ldr	sp, FIQ_STACK_START
	;MEND

;/*
; * exception handlers
; */
undefined_instruction
	;get_bad_stack
	;bad_save_user_regs
	;bl	do_undefined_instruction

software_interrupt
	;get_bad_stack
	;bad_save_user_regs
	;bl	do_software_interrupt

prefetch_abort
	;get_bad_stack
	;bad_save_user_regs
	;bl	do_prefetch_abort

data_abort
	;get_bad_stack
	;bad_save_user_regs
	;bl	do_data_abort

not_used
	;get_bad_stack
	;bad_save_user_regs
	;bl	do_not_used

	IF CONFIG_USE_IRQ = 1

irq
	;get_irq_stack
	;irq_save_user_regs
	;bl	do_irq
	;irq_restore_user_regs

fiq
	;get_fiq_stack
	;/* someone ought to write a more effiction fiq_save_user_regs */
	;irq_save_user_regs
	;bl	do_fiq
	;irq_restore_user_regs

	ELSE

irq
	;get_bad_stack
	;bad_save_user_regs
	;bl	do_irq

fiq
	;get_bad_stack
	;bad_save_user_regs
	;bl	do_fiq

	ENDIF

	end
