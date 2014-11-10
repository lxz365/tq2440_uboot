
		preserve8
        AREA    start, CODE, readonly
        ARM	
fiqHandler
        SUB     lr, lr, #4
        STMFD   sp!, {lr}
        MRS     lr, SPSR
        STMFD   sp!, {r0,r1,lr}
		b fiqHandler
        END			