CLOCK_SPEED = -D F_CPU=20000000UL


default: compile

clean:
	rm *.hex *.o *.elf *.s

main.hex: compile

learn:
	avr-gcc -c -mmcu=atmega328p -o main.o main.S $(CLOCK_SPEED) -save-temps -O2

compile: main.S twi.S
	avr-gcc -c -mmcu=atmega328p main.S $(CLOCK_SPEED)
	avr-gcc -mmcu=atmega328p -o main.elf main.o
	avr-objcopy -j .data -j .text -O ihex main.elf main.hex

upload: main.hex
	avrdude -c stk500v1 -p atmega328p -P /dev/ttyACM0 -b 19200 -v -U flash:w:main.hex:i

erase:
	avrdude -c stk500v1 -p atmega328p -P /dev/ttyACM0 -b 19200 -v -U flash:w:0x00:m

c-test:
	avr-gcc -c -mmcu=atmega328p -o main.o main.c -save-temps
	avr-gcc -mmcu=atmega328p -o main.elf main.o 
	avr-objcopy -j .data -j .text -O ihex main.elf main.hex