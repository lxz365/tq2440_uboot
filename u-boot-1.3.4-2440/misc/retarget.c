/* ----------------------------------------------------------------------------
 *         ATMEL Microcontroller Software Support 
 * ----------------------------------------------------------------------------
 * Copyright (c) 2008, Atmel Corporation
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the disclaimer below.
 *
 * Atmel's name may not be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * DISCLAIMER: THIS SOFTWARE IS PROVIDED BY ATMEL "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT ARE
 * DISCLAIMED. IN NO EVENT SHALL ATMEL BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * ----------------------------------------------------------------------------
 */

//------------------------------------------------------------------------------
/// \unit
///
/// !Purpose
///
/// This file Configures the target-dependent low level functions for character I/O.
///
/// !Contents
/// The code implement the lower-level functions as follows:
///    - fputc
///    - ferror
///    - _ttywrch
///    - _sys_exit
///
///
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//         Headers
//------------------------------------------------------------------------------
#include <serial.h>
#include <stdio.h>

// Disable semihosting
#pragma import(__use_no_semihosting_swi) 

struct __FILE { int handle;} ;
FILE __stdout;
FILE __stderr;

//------------------------------------------------------------------------------
///  Outputs a character to a file.
//------------------------------------------------------------------------------
//int fputc(int ch, FILE *f) {
//    if ((f == stdout) || (f == stderr)) {
//        serial_putc(ch);
//        return ch;
//    }
//    else {
//        return EOF;
//    }
//}

//------------------------------------------------------------------------------
///  Returns the error status accumulated during file I/O.
//------------------------------------------------------------------------------
int ferror(FILE *f) {
    return EOF;
}

extern void serial_putc(char c);
void _ttywrch(int ch) {
    serial_putc((unsigned char)ch);
}


void _sys_exit(int return_code) {
    label:  goto label;  /* endless loop */
}
