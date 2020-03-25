; Contains TWI specific functions
; This includes initialization, outputting/reading data bus
; Start/Stop conditions etc

.global INIT
.global TWI_START
.global SLA_W 
.global SEND_BYTE
.global TWI_STOP

.text

INIT: ; Sets up and enables TWI Hardware
    ldi r16, 0x11
    sts TWBR, r16 ; Set TWBR(Bit Rate divisor) to decimal 17 @ 20 MHz to achieve 400 kHz Baud

    ldi r16, (1 << TWINT) | (1 << TWEN) ; Mask for enable TWI Hardware
    sts TWCR, r16 ; Enable TWI Hardware via indirect addressing `ST`
    ret

TWI_START:
    ; Call TWI interrupt to generate start condition
    ldi r16, (1 << TWINT) | (1 << TWEN) | (1 << TWSTA)
    sts TWCR, r16 ; Interrupt called
LOOP_TWI_START:
    ; wait for clear -- using method I found with gcc -O3
    lds r24, TWCR ; Grab control register
    sbrs r24, TWINT ; Test TWINT bit
    rjmp LOOP_TWI_START
    ret

SLA_W: ; Uses r26/27 for arguments || Should contain unprepared I2C address
    ; Grab desired address from r26
    lsl r26 ; Shift left, leave trailing 0 as `WRITE` bit
    sts TWDR, r26 ; Load SLA_W into TWI Data register

    ; Call TWI interrupt to send addr with write bit on bus
    ldi r16, (1 << TWINT) | (1 << TWEN) | (1 << TWSTA)
    sts TWCR, r16 ; Interrupt called

LOOP_SLA_W:
    ; wait for clear -- using method I found with gcc -O3
    lds r24, TWCR ; Grab control register
    sbrs r24, TWINT ; Test TWINT bit
    rjmp LOOP_SLA_W
    ret

SEND_BYTE: ; Sends a byte of data on the I2C data bus || uses R26/R27 (X register)
    sts TWDR, r26 ; Store address from X register into TWDR

    ldi r16, (1 << TWINT) | (1 << TWEN)
    sts TWCR, r16 ; Invoke TWI interrupt
LOOP_SEND_BYTE:
    lds r24, TWCR
    sbrs r24, TWINT
    rjmp LOOP_SEND_BYTE
    ret

TWI_STOP:
    ldi r16, (1 << TWINT) | (1 << TWEN) | (1 << TWSTO)
    sts TWCR, r16 ; Invoke TWI interrupt with stop condition
    ret