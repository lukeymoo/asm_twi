
.global SEND_BYTE_CMD
.global SEND_NIBBLE_CMD 
.global DELAY_ENABLE
.global DELAY_INIT
.global SEND_NIBBLE_DATA

.data

.equ LCD_ADDR, 0x27 ; address on bus of LCD
;.equ DISPLAY_CONTROL, 0x300 ; We will store configuration of display in SRAM
; 7 6 5 4  3 2 1 0
; Bit 0 - PCF Register Select
; Bit 1 - PCF R/W pin, never used
; Bit 2 - PCF Enable Pin
; Bit 3 - PCF Backlight Control
; Control these bits with sbi/cbi
.equ PCF_RS, 0x01
.equ PCF_RW, 0x02
.equ PCF_ENABLE, 0x04
.equ PCF_BACKLIGHT, 0x08
; We cannot use decimal as a bit #
; After debugging with oscillscope, discovered these representations are binary MASKS
; So foolishly our `bit 3` became a mask of 0000 0011
; I should have read avr instructions datasheet more carefully

.text 

; Only used in byte command because the number of instructions
; used to transmit in 4-BIT mode takes >= 450 ns
; no sense adding another arbritary 450 ns delay
; Each clock cycle is 50 ns at 20 MHz, we have 9 nops
DELAY_ENABLE: ; configured for 20 MHz clock 450 ns enable pulse width
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ret


SEND_BYTE_CMD: ; CMD is stored in r26
    ; data stored in high bytes, control is low bytes
    sbr r26, PCF_ENABLE ; set enable pin
    sbr r26, PCF_BACKLIGHT ; set backlight on

    ; Start condition
    call TWI_START

    ; Send SLA+W
    push r26 ; preserve bus config
    
    ldi r26, LCD_ADDR
    call SLA_W

    pop r26 ; restore bus config
    
    ; Send byte, uses X register
    call SEND_BYTE
    
    ; wait at least 450 ns
    call DELAY_ENABLE

    ; Start condition
    call TWI_START

    ; Send SLA+W
    push r26 ; preserve bus config
    
    ldi r26, LCD_ADDR
    call SLA_W

    pop r26 ; restore bus config

    cbr r26, PCF_ENABLE ; Clear enable pin and resend
    call SEND_BYTE

    ; Send stop condition
    call TWI_STOP
    ret

; This function makes 4 transmissions to the bus
SEND_NIBBLE_CMD: ; Send byte in 2 part Nibbles || Data to send is in r26

    ldi r20, 0xf0 ; high mask
    and r20, r26 ; grab bits store in r20

    ldi r21, 0x0f ; low mask
    and r21, r26 ; grab bits store in r21
    ; Shift low bits to high(non control bits)
    lsl r21 
    lsl r21 
    lsl r21 
    lsl r21 

    ; Start condition
    call TWI_START

    ; Send SLA + W
    ldi r26, LCD_ADDR
    call SLA_W

    ; High bytes ENABLE
    sbr r20, PCF_BACKLIGHT
    sbr r20, PCF_ENABLE
    mov r26, r20 ; r26 for function ( we dont need to preserve byte )
    call SEND_BYTE
    call TWI_STOP ; Stop

    ; Start condition
    call TWI_START ; uses r24 internally

    push r26 ; save byte config

    ; Send SLA+W
    ldi r26, LCD_ADDR
    call SLA_W

    pop r26 ; restore byte config

    ; High bytes NOT ENABLE
    cbr r26, PCF_ENABLE
    call SEND_BYTE
    call TWI_STOP ; Stop

    ; Start condition
    call TWI_START ; uses r24 internally

    ; We do not preserve r26 as we are done using
    ; the high byte configuration

    ; Send SLA+W
    ldi r26, LCD_ADDR
    call SLA_W 

    ; Low bytes ENABLE
    sbr r21, PCF_ENABLE
    sbr r21, PCF_BACKLIGHT
    mov r26, r21
    call SEND_BYTE
    call TWI_STOP ; Stop

    ; Send start
    call TWI_START

    push r26 ; save low byte config

    ; Send SLA+W
    ldi r26, LCD_ADDR
    call SLA_W

    pop r26 ; restore byte config

    ; Low bytes NOT ENABLE 
    cbr r26, PCF_ENABLE 
    call SEND_BYTE
    call TWI_STOP ; Stop
    ret

; Sends byte of data in 2 parts(4 bit mode)
SEND_NIBBLE_DATA:
    ; create masks
    ldi r20, 0xf0 ; high mask
    and r20, r26 ; grab bits store in r20

    ldi r21, 0x0f ; low mask
    and r21, r26 ; grab bits store in r21
    ; move low bits to high(non control) bits
    lsl r21
    lsl r21
    lsl r21
    lsl r21

    ; Start condition
    call TWI_START

    ; Send SLA+W
    ldi r26, LCD_ADDR
    call SLA_W

    ; High byte ENABLE/RS/BACKLIGHT
    mov r26, r20
    sbr r26, PCF_ENABLE
    sbr r26, PCF_RS
    sbr r26, PCF_BACKLIGHT
    call SEND_BYTE

    ; Send Start
    call TWI_START

    push r26 ; Preserve high byte config

    ; Send SLA+W
    ldi r26, LCD_ADDR
    call SLA_W

    pop r26 ; Restore high byte config

    ; high byte BACKLIGHT/RS/NOT ENABLE
    cbr r26, PCF_ENABLE ; Clear enable
    call SEND_BYTE
    call TWI_STOP 

    ; Start condition
    call TWI_START

    ; Done with high byte so don't push r26
    ; Send SLA+W
    ldi r26, LCD_ADDR
    call SLA_W

    ; low byte BACKLIGHT/RS/ENABLE
    mov r26, r21
    sbr r26, PCF_BACKLIGHT
    sbr r26, PCF_ENABLE
    sbr r26, PCF_RS
    call SEND_BYTE
    call TWI_STOP 

    ; Start condition
    call TWI_START

    push r26 ; preserve low byte config

    ; Send SLA+W
    ldi r26, LCD_ADDR
    call SLA_W

    pop r26 ; restore low byte config

    ; low byte BACKLIGHT/RS/NOT ENABLE
    cbr r26, PCF_ENABLE
    call SEND_BYTE

    ; Send stop
    call TWI_STOP
    ret
