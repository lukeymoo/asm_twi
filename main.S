#include <avr/io.h>
#include "twi.S"
#include "lcd.S"

.DATA

.TEXT
.GLOBAL main

main: ; Entry point
    ; Power on LED
    SBI _SFR_IO_ADDR(DDRD), PD2
    SBI _SFR_IO_ADDR(PORTD), PD2

    CALL INIT ; Initialization function
    
    ; Function set
    LDI R26, 0x30
    LDI R27, 0
    CALL SEND_BYTE_CMD

    ; 5 ms delay, 24999 found using util/delay and gcc -O1
    LDI R24, lo8(24999)
    LDI R25, hi8(24999)
DELAY1: SBIW R24, 1
    BRNE DELAY1
    NOP

    ; Function set
    LDI R26, 0x30
    LDI R27, 0
    CALL SEND_BYTE_CMD

; 5 ms delay
    LDI R24, lo8(24999)
    LDI R25, hi8(24999)
DELAY2: SBIW R24, 1
    BRNE DELAY2
    NOP

    ; Function set
    LDI R26, 0x30
    LDI R27, 0
    CALL SEND_BYTE_CMD

    ; 150 us delay
    LDI R24, lo8(749)
    LDI R25, hi8(749)
DELAY3: SBIW R24, 1
    BRNE DELAY3
    RJMP . ; 100 ns
    NOP ; 50 ns

    ; 8 Bit request for 4-Bit Function set
    LDI R26, 0x20
    LDI R27, 0
    CALL SEND_BYTE_CMD

    ; 4 Bit request for function set || 4-bits, 2 lines, ? font mode
    LDI R26, 0x2c
    LDI R27, 0
    CALL SEND_NIBBLE_CMD

    ; display function || display on, cursor on, blink on
    LDI R26, 0x0f
    LDI R27, 0
    CALL SEND_NIBBLE_CMD

    LDI R26, 0x01 ; Clear screen function, takes 5ms to execute
    LDI R27, 0
    CALL SEND_NIBBLE_CMD

    ; 5 ms delay, 24999 found using util/delay and gcc -O1
    LDI R24, lo8(24999)
    LDI R25, hi8(24999)
DELAY4: SBIW R24, 1
    BRNE DELAY4
    NOP

    ; Send letter A
    LDI R26, 0x41
    LDI R27, 0
    CALL SEND_NIBBLE_DATA
    
L1:
    RJMP L1 ; Loop indefinitely
