#include <avr/io.h>

#include "twi.S"

.section .text
.global main

main: ; Entry point
    ; Power on LED
    sbi _SFR_IO_ADDR(DDRD), PD2
    sbi _SFR_IO_ADDR(PORTD), PD2

    call INIT ; Initialization function

    call TWI_START ; Generate Start condition

    ldi r26, 0x27
    ldi r27, 0
    call SLA_W ; Generate SLA+W for LCD || this routine uses X register r26/27 for addressing

    ; Turn off LCD
    ldi r26, 0
    ldi r27, 0
    call SEND_BYTE
    
L1:
    rjmp L1 ; Loop indefinitely