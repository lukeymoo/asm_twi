
.GLOBAL SEND_BYTE_CMD
.GLOBAL SEND_NIBBLE_CMD 
.GLOBAL DELAY_ENABLE
.GLOBAL DELAY_INIT
.GLOBAL SEND_NIBBLE_DATA

.DATA

.EQU LCD_ADDR, 0x27 ; address on bus of LCD
;.EQU DISPLAY_CONTROL, 0x300 ; We will store configuration of display in SRAM
; 7 6 5 4  3 2 1 0
; Bit 0 - PCF Register Select
; Bit 1 - PCF R/W pin, never used
; Bit 2 - PCF Enable Pin
; Bit 3 - PCF Backlight Control
; Control these bits with SBI/cbi
.EQU PCF_RS, 0x01
.EQU PCF_RW, 0x02
.EQU PCF_ENABLE, 0x04
.EQU PCF_BACKLIGHT, 0x08
; We cannot use decimal as a bit #
; After debugging with oscillscope, discovered these representations are binary MASKS
; So foolishly our `bit 3` became a mask of 0000 0011
; I should have read avr instructions datasheet more carefully

.TEXT 

; Only used in byte commAND because the number of instructions
; used to transmit in 4-BIT mode takes >= 450 ns
; no sense adding another arbritary 450 ns delay
; Each clock cycle is 50 ns at 20 MHz, we have 9 NOPs
DELAY_ENABLE: ; configured for 20 MHz clock 450 ns enable pulse width
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    RET


SEND_BYTE_CMD: ; CMD is stored in R26
    ; data stored in high bytes, control is low bytes
    SBR R26, PCF_ENABLE ; set enable pin
    SBR R26, PCF_BACKLIGHT ; set backlight on

    ; Start condition
    CALL TWI_START

    ; Send SLA+W
    PUSH R26 ; preserve bus config
    
    LDI R26, LCD_ADDR
    CALL SLA_W

    POP R26 ; restore bus config
    
    ; Send byte, uses X register
    CALL SEND_BYTE
    
    ; wait at least 450 ns
    CALL DELAY_ENABLE

    ; Start condition
    CALL TWI_START

    ; Send SLA+W
    PUSH R26 ; preserve bus config
    
    LDI R26, LCD_ADDR
    CALL SLA_W

    POP R26 ; restore bus config

    CBR R26, PCF_ENABLE ; Clear enable pin AND resend
    CALL SEND_BYTE

    ; Send stop condition
    CALL TWI_STOP
    RET

; This function makes 4 transmissions to the bus
SEND_NIBBLE_CMD: ; Send byte in 2 part Nibbles || Data to send is in R26

    LDI R20, 0xf0 ; high mask
    AND R20, R26 ; grab bits store in R20

    LDI R21, 0x0f ; low mask
    AND R21, R26 ; grab bits store in R21
    ; Shift low bits to high(non control bits)
    LSL R21 
    LSL R21 
    LSL R21 
    LSL R21 

    ; Start condition
    CALL TWI_START

    ; Send SLA + W
    LDI R26, LCD_ADDR
    CALL SLA_W

    ; High bytes ENABLE
    SBR R20, PCF_BACKLIGHT
    SBR R20, PCF_ENABLE
    MOV R26, R20 ; R26 for function ( we dont need to preserve byte )
    CALL SEND_BYTE
    CALL TWI_STOP ; Stop

    ; Start condition
    CALL TWI_START ; uses R24 internally

    PUSH R26 ; save byte config

    ; Send SLA+W
    LDI R26, LCD_ADDR
    CALL SLA_W

    POP R26 ; restore byte config

    ; High bytes NOT ENABLE
    CBR R26, PCF_ENABLE
    CALL SEND_BYTE
    CALL TWI_STOP ; Stop

    ; Start condition
    CALL TWI_START ; uses R24 internally

    ; We do not preserve R26 as we are done using
    ; the high byte configuration

    ; Send SLA+W
    LDI R26, LCD_ADDR
    CALL SLA_W 

    ; Low bytes ENABLE
    SBR R21, PCF_ENABLE
    SBR R21, PCF_BACKLIGHT
    MOV R26, R21
    CALL SEND_BYTE
    CALL TWI_STOP ; Stop

    ; Send start
    CALL TWI_START

    PUSH R26 ; save low byte config

    ; Send SLA+W
    LDI R26, LCD_ADDR
    CALL SLA_W

    POP R26 ; restore byte config

    ; Low bytes NOT ENABLE 
    CBR R26, PCF_ENABLE 
    CALL SEND_BYTE
    CALL TWI_STOP ; Stop
    RET

; Sends byte of data in 2 parts(4 bit mode)
SEND_NIBBLE_DATA:
    ; create masks
    LDI R20, 0xf0 ; high mask
    AND R20, R26 ; grab bits store in R20

    LDI R21, 0x0f ; low mask
    AND R21, R26 ; grab bits store in R21
    ; MOVe low bits to high(non control) bits
    LSL R21
    LSL R21
    LSL R21
    LSL R21

    ; Start condition
    CALL TWI_START

    ; Send SLA+W
    LDI R26, LCD_ADDR
    CALL SLA_W

    ; High byte ENABLE/RS/BACKLIGHT
    MOV R26, R20
    SBR R26, PCF_ENABLE
    SBR R26, PCF_RS
    SBR R26, PCF_BACKLIGHT
    CALL SEND_BYTE

    ; Send Start
    CALL TWI_START

    PUSH R26 ; Preserve high byte config

    ; Send SLA+W
    LDI R26, LCD_ADDR
    CALL SLA_W

    POP R26 ; Restore high byte config

    ; high byte BACKLIGHT/RS/NOT ENABLE
    CBR R26, PCF_ENABLE ; Clear enable
    CALL SEND_BYTE
    CALL TWI_STOP 

    ; Start condition
    CALL TWI_START

    ; Done with high byte so don't PUSH R26
    ; Send SLA+W
    LDI R26, LCD_ADDR
    CALL SLA_W

    ; low byte BACKLIGHT/RS/ENABLE
    MOV R26, R21
    SBR R26, PCF_BACKLIGHT
    SBR R26, PCF_ENABLE
    SBR R26, PCF_RS
    CALL SEND_BYTE
    CALL TWI_STOP 

    ; Start condition
    CALL TWI_START

    PUSH R26 ; preserve low byte config

    ; Send SLA+W
    LDI R26, LCD_ADDR
    CALL SLA_W

    POP R26 ; restore low byte config

    ; low byte BACKLIGHT/RS/NOT ENABLE
    CBR R26, PCF_ENABLE
    CALL SEND_BYTE

    ; Send stop
    CALL TWI_STOP
    RET
