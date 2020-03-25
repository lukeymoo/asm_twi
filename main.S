#include <avr/io.h>
#include "twi.S"
#include "lcd.S"

.data

.text
.global main

main: ; Entry point
    ; Power on LED
    sbi _SFR_IO_ADDR(DDRD), PD2
    sbi _SFR_IO_ADDR(PORTD), PD2

    call INIT ; Initialization function
    
    ; Function set
    ldi r26, 0x30
    ldi r27, 0
    call SEND_BYTE_CMD

    ; 5 ms delay, 24999 found using util/delay and gcc -O1
    ldi r24, lo8(24999)
    ldi r25, hi8(24999)
DELAY1: sbiw r24, 1
    brne DELAY1
    nop

    ; Function set
    ldi r26, 0x30
    ldi r27, 0
    call SEND_BYTE_CMD

; 5 ms delay
    ldi r24, lo8(24999)
    ldi r25, hi8(24999)
DELAY2: sbiw r24, 1
    brne DELAY2
    nop

    ; Function set
    ldi r26, 0x30
    ldi r27, 0
    call SEND_BYTE_CMD

    ; 150 us delay
    ldi r24, lo8(749)
    ldi r25, hi8(749)
DELAY3: sbiw r24, 1
    brne DELAY3
    rjmp . ; 100 ns
    nop ; 50 ns

    ; 8 Bit request for 4-Bit Function set
    ldi r26, 0x20
    ldi r27, 0
    call SEND_BYTE_CMD

    ; 4 Bit request for function set || 4-bits, 2 lines, ? font mode
    ldi r26, 0x2c
    ldi r27, 0
    call SEND_NIBBLE_CMD

    ; display function || display on, cursor on, blink on
    ldi r26, 0x0f
    ldi r27, 0
    call SEND_NIBBLE_CMD

    ; Send letter A
    ldi r26, 0x41
    ldi r27, 0
    call SEND_NIBBLE_DATA
    
L1:
    rjmp L1 ; Loop indefinitely
