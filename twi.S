; Contains TWI specific functions
; This includes initialization, outputting/reading data bus
; Start/Stop conditions etc

.GLOBAL INIT
.GLOBAL TWI_START
.GLOBAL SLA_W 
.GLOBAL SEND_BYTE
.GLOBAL TWI_STOP

.TEXT

INIT: ; Sets up and enables TWI Hardware
    LDI R16, 92
    ; Was using decimal 17 before to achieve 400 KHz, however that exceeds the backpack the LCD is using
    ; We are using 100 kHz via TWBR @ decimal 92
    STS TWBR, R16 ; Set TWBR(Bit Rate divisor) to decimal 92 @ 20 MHz to achieve 100 kHz Baud Formula(F_CPU/(16+(2*TWBR*Prescaler))
    ; We are not using prescaler, so in formula that is set to 1, F_CPU is 20 000 000 Hz
    ; Solved for TWBR, we arrived at decimal 92

    LDI R16, (1 << TWINT) | (1 << TWEN) ; Mask for enable TWI Hardware
    STS TWCR, R16 ; Enable TWI Hardware
    RET

TWI_START:
    ; invoke TWI interrupt to generate start condition
    LDI R16, (1 << TWINT) | (1 << TWEN) | (1 << TWSTA)
    STS TWCR, R16 ; Interrupt CALLed
LOOP_TWI_START:
    ; wait for clear -- using method I found with gcc -O3
    LDS R24, TWCR ; Grab control register
    SBRS R24, TWINT ; Test TWINT bit
    RJMP LOOP_TWI_START
    RET

SLA_W: ; Uses R26/27 for arguments || Should contain unprepared I2C address
    ; Grab desired address from R26
    LSL R26 ; Shift left, leave trailing 0 as `WRITE` bit
    STS TWDR, R26 ; Load SLA_W into TWI Data register

    ; CALL TWI interrupt to send addr with write bit on bus
    LDI R16, (1 << TWINT) | (1 << TWEN)
    STS TWCR, R16 ; Interrupt called

LOOP_SLA_W:
    ; wait for clear -- using method I found with gcc -O3
    LDS R24, TWCR ; Grab control register
    SBRS R24, TWINT ; Test TWINT bit
    RJMP LOOP_SLA_W
    RET

SEND_BYTE: ; Sends a byte of data on the I2C data bus || uses R26/R27 (X register)
    STS TWDR, R26 ; Store address from X register into TWDR

    LDI R16, (1 << TWINT) | (1 << TWEN)
    STS TWCR, R16 ; Invoke TWI interrupt
LOOP_SEND_BYTE:
    LDS R24, TWCR
    SBRS R24, TWINT
    RJMP LOOP_SEND_BYTE
    RET

TWI_STOP:
    LDI R16, (1 << TWINT) | (1 << TWEN) | (1 << TWSTO)
    STS TWCR, R16 ; Invoke TWI interrupt with stop condition
    RET
