
WDT_MR						equ		0xFFFFFD44
WDT_MR_WDDIS				equ		(1 << 15)


CONFIG_USE_IRQ				equ		0	
CONFIG_SKIP_LOWLEVEL_INIT	equ 	0
CONFIG_SKIP_RELOCATE_UBOOT	equ 	0

CFG_MALLOC_LEN				equ		0x2d000
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
		entry

_start
		b 	reset
		ldr	pc, _undefined_instruction
		ldr	pc, _software_interrupt
		ldr	pc, _prefetch_abort
		ldr	pc, _data_abort
		ldr	pc, _not_used
		ldr	pc, _irq
		ldr	pc, _fiq

		ltorg

_undefined_instruction
		dcd reset
_software_interrupt
		dcd reset
_prefetch_abort
		dcd reset
_data_abort
		dcd reset
_not_used
		dcd reset
_irq
		dcd reset
_fiq
		dcd reset

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
;	 * disable watchdog
;	 */
		ldr		r0,=WDT_MR
		ldr		r1,=WDT_MR_WDDIS
		str		r1,[r0]
;	/*
;	 * set the cpu to SVC32 mode
;	 */
		mrs		r0,cpsr
		bic		r0,r0,#0x1f
		orr		r0,r0,#0xd3
		msr		cpsr_cxsf,r0

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
		;ldr     r0, = ||Image$$ARM_LIB_STACK$$ZI$$Limit||
        ;mov     sp, r0

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

		end
