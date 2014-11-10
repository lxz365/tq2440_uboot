;/*
; * Memory Setup stuff - taken from blob memsetup.S
; *
; * Copyright (C) 1999 2000 2001 Erik Mouw (J.A.K.Mouw@its.tudelft.nl) and
; *                     Jan-Derk Bakker (J.D.Bakker@its.tudelft.nl)
; *
; * Modified for the Samsung SMDK2410 by
; * (C) Copyright 2002
; * David Mueller, ELSOFT AG, <d.mueller@elsoft.ch>
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


;#include <config.h>
;#include <version.h>


;/* some parameters for the board */

;/*
; *
; * Taken from linux/arch/arm/boot/compressed/head-s3c2410.S
; *
; * Copyright (C) 2002 Samsung Electronics SW.LEE  <hitchcar@sec.samsung.com>
; *
; */

CONFIG_133MHZ_SDRAM	equ	0
CONFIG_128MB_SDRAM	equ	0

BWSCON		equ		0x48000000

;/* BWSCON */
DW8			equ 	(0x0)
DW16		equ 	(0x1)
DW32		equ 	(0x2)
WAIT		equ 	(0x1<<2)
UBLB		equ 	(0x1<<3)

B1_BWSCON	equ  	(DW16)
B2_BWSCON	equ  	(DW16)
B3_BWSCON	equ  	(DW16 + WAIT + UBLB)
B4_BWSCON	equ  	(DW16)
B5_BWSCON	equ  	(DW8)
B6_BWSCON	equ  	(DW32)
B7_BWSCON	equ  	(DW32)

;/* BANK0CON */
B0_Tacs		equ 	0x0	;/*  0clk */
B0_Tcos		equ 	0x0	;/*  0clk */
B0_Tacc		equ 	0x7	;/* 14clk */
B0_Tcoh		equ 	0x0	;/*  0clk */
B0_Tah		equ 	0x0	;/*  0clk */
B0_Tacp		equ 	0x0
B0_PMC		equ 	0x0	;/* normal */

;/* BANK1CON */
B1_Tacs		equ 	0x0	;/*  0clk */
B1_Tcos		equ 	0x0	;/*  0clk */
B1_Tacc		equ 	0x7	;/* 14clk */
B1_Tcoh		equ 	0x0	;/*  0clk */
B1_Tah		equ 	0x0	;/*  0clk */
B1_Tacp		equ 	0x0
B1_PMC		equ 	0x0

B2_Tacs		equ 	0x0
B2_Tcos		equ 	0x0
B2_Tacc		equ 	0x7
B2_Tcoh		equ 	0x0
B2_Tah		equ 	0x0
B2_Tacp		equ 	0x0
B2_PMC		equ 	0x0

B3_Tacs		equ 	0x0	;/*  0clk */
B3_Tcos		equ 	0x3	;/*  4clk */
B3_Tacc		equ 	0x7	;/* 14clk */
B3_Tcoh		equ 	0x1	;/*  1clk */
B3_Tah		equ 	0x0	;/*  0clk */
B3_Tacp		equ 	0x3 ;/*  6clk */
B3_PMC		equ 	0x0	;/* normal */

B4_Tacs		equ 	0x0	;/*  0clk */
B4_Tcos		equ 	0x0	;/*  0clk */
B4_Tacc		equ 	0x7	;/* 14clk */
B4_Tcoh		equ 	0x0	;/*  0clk */
B4_Tah		equ 	0x0	;/*  0clk */
B4_Tacp		equ 	0x0
B4_PMC		equ 	0x0	;/* normal */

B5_Tacs		equ 	0x0	;/*  0clk */
B5_Tcos		equ 	0x0	;/*  0clk */
B5_Tacc		equ 	0x7	;/* 14clk */
B5_Tcoh		equ 	0x0	;/*  0clk */
B5_Tah		equ 	0x0	;/*  0clk */
B5_Tacp		equ 	0x0
B5_PMC		equ 	0x0	;/* normal */

B6_MT		equ 	0x3	;/* SDRAM */
;/* B6_Trcd	 	 	0x1	*//* 3clk */	/*HJ_del	100MHz */
;/* B6_SCAN		0x1	*//* 9bit */	/*HJ_del 64MB SDRAM */
;/* B6_Trcd	 	 	0x0	*//* 2clk */	/*HJ_del 133MHz */
;/* B6_SCAN		0x2	*//* 10bit */	/*HJ_del 128MB SDRAM */
	IF CONFIG_133MHZ_SDRAM = 1
B6_Trcd	 	equ 	0x0
	ELSE
B6_Trcd		equ	0x1
	ENDIF

	IF CONFIG_128MB_SDRAM = 1
B6_SCAN		equ 	0x2
	ELSE
B6_SCAN		equ		0x1
	ENDIF

B7_MT		equ 	0x3	;/* SDRAM */
;/* B7_Trcd		 	0x1	*//* 3clk */	/*HJ_del	100MHz */
;/* B7_SCAN		0x1	*//* 9bit */	/*HJ_del 64MB SDRAM */
;/* B7_Trcd	 	 	0x0	*//* 2clk */	/*HJ_add 133MHz */
;/* B7_SCAN		0x2	*//* 10bit */	/*HJ_del 128MB SDRAM */
	IF CONFIG_133MHZ_SDRAM = 1
B7_Trcd	 	equ 	0x0
	ELSE
B7_Trcd		equ		0x1
	ENDIF

	IF CONFIG_128MB_SDRAM = 1
B7_SCAN		equ 	0x2
	ELSE
B7_SCAN		equ	0x1
	ENDIF

;/* REFRESH parameter */
REFEN		equ 	0x1	;/* Refresh enable */
TREFMD		equ 	0x0	;/* CBR(CAS before RAS)/Auto refresh */
;/* Trp		 	0x0	*//* 2clk */						/* HJ_del 100MHz */
;/* Trc		    	0x3	*//* 7clk */						/* HJ_del 100MHz */
;/* Tchr		 	0x2	*//* 3clk */						/* HJ_del 100MHz */
;/* REFCNT		 	0x4f4	*//* period=7.8125us, HCLK=100Mhz, (2048+1-7.8125*100) */	/* HJ_del 100MHz */
;/* Trp		 	0x1	*//* 3clk */						/* HJ_del 133MHz */
;/* Tsrc		    	0x3	*//* 7clk */						/* HJ_del 133MHz */
;/* REFCNT		 	0x3f4	*//* period=7.8125us, HCLK=133Mhz, (2048+1-7.8125*133) */	/* HJ_del 133MHz */
	IF CONFIG_133MHZ_SDRAM = 1
Trp		  equ		0x1
Tsrc	  equ	    0x3
REFCNT	  equ	 	0x3f4
	ELSE
Trp		  equ		0x0
Trc		  equ   	0x3
Tchr	  equ	 	0x2
REFCNT	  equ	 	0x4f4
	ENDIF
;/**************************************/

		;preserve8
		;area    lowlevel, code
        ;arm
		
lowlevel_init
		;/* memory control configuration */
		;/* make r0 relative the current location so that it */
		;/* reads SMRDATA out of FLASH rather than memory ! */
		ldr     r0, =SMRDATA
		ldr		r1, _TEXT_BASE
		sub		r0, r0, r1
		ldr		r1, =BWSCON	;/* Bus Width Status Controller */
		add     r2, r0, #13*4
loop
		ldr     r3, [r0], #4
		str     r3, [r1], #4
		cmp     r2, r0
		bne     loop
	
		;/* everything is fine now */
		bx		lr

		ltorg
;/* the literal pools origin */

SMRDATA
	    dcd (0+(B1_BWSCON<<4)+(B2_BWSCON<<8)+(B3_BWSCON<<12)+(B4_BWSCON<<16)+(B5_BWSCON<<20)+(B6_BWSCON<<24)+(B7_BWSCON<<28))
	    dcd ((B0_Tacs<<13)+(B0_Tcos<<11)+(B0_Tacc<<8)+(B0_Tcoh<<6)+(B0_Tah<<4)+(B0_Tacp<<2)+(B0_PMC))
	    dcd ((B1_Tacs<<13)+(B1_Tcos<<11)+(B1_Tacc<<8)+(B1_Tcoh<<6)+(B1_Tah<<4)+(B1_Tacp<<2)+(B1_PMC))
	    dcd ((B2_Tacs<<13)+(B2_Tcos<<11)+(B2_Tacc<<8)+(B2_Tcoh<<6)+(B2_Tah<<4)+(B2_Tacp<<2)+(B2_PMC))
	    dcd ((B3_Tacs<<13)+(B3_Tcos<<11)+(B3_Tacc<<8)+(B3_Tcoh<<6)+(B3_Tah<<4)+(B3_Tacp<<2)+(B3_PMC))
	    dcd ((B4_Tacs<<13)+(B4_Tcos<<11)+(B4_Tacc<<8)+(B4_Tcoh<<6)+(B4_Tah<<4)+(B4_Tacp<<2)+(B4_PMC))
	    dcd ((B5_Tacs<<13)+(B5_Tcos<<11)+(B5_Tacc<<8)+(B5_Tcoh<<6)+(B5_Tah<<4)+(B5_Tacp<<2)+(B5_PMC))
	    dcd ((B6_MT<<15)+(B6_Trcd<<2)+(B6_SCAN))
	    dcd ((B7_MT<<15)+(B7_Trcd<<2)+(B7_SCAN))
	;/*    dcd ((REFEN<<23)+(TREFMD<<22)+(Trp<<20)+(Trc<<18)+(Tchr<<16)+REFCNT)	*/	/* HJ_del 100MHz */
	;/*    dcd 0x32		*/							/* HJ_del 100MHz */
	;/*    dcd 0x30		*/							/* HJ_del 100MHz */	
	;/*    dcd 0x30		*/							/* HJ_del 100MHz */
	;/*    dcd ((REFEN<<23)+(TREFMD<<22)+(Trp<<20)+(Tsrc<<18)+REFCNT)	*/		/* HJ_del 133MHz */
	;/*    dcd 0xB2		*/							/* HJ_del 133MHz */
	;/*    dcd 0x20		*/							/* HJ_del 133MHz */	
	;/*    dcd 0x20		*/							/* HJ_del 133MHz */
	    dcd ((REFEN<<23)+(TREFMD<<22)+(Trp<<20)+(Trc<<18)+(Tchr<<16)+REFCNT)
	    dcd 0x32
	    dcd 0x30
	    dcd 0x30
	
		END
