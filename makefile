
all: nametag.asm
	asm02 -L -b nametag.asm
	@rm nametag.build

clean:
	@rm -f mbios.bin mbios.lst

