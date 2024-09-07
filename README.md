# Nametag

This is initial firmware for Lee Hart's name tag with 14-segment displays. Some information on the hardware can be found here:

https://groups.io/g/cosmacelf/message/45282

This version of the firmware does not require RAM, using only the 1802 registers for all storage. It supports a 32-character message which can be set either from the pushbuttons on the tag, or by connecting a serial terminal. This firmware supports the non-volatile persistence of the message as designed into the hardware. This firmware should be programmed at address 0000 of the ROM.

> ![short video](https://github.com/dmadole/Nametag/blob/main/photos/nametag-v0-vcfmidwest.gif?raw=true)

To set the message using the buttons, hold the SET to freeze the display, then use the UP and DOWN buttons to change the right-most character. On initial power-on the message buffer will have junk in it, hold UP and DOWN at the same time to clear it. To easily set the message from the very beginning, hold SET while powering on. When SET is released, the display will scroll again and you can stop at another character to change it. Release set briefly to advance to the next character.

To set via terminal, connect a terminal to RX, TX, and GND that is setup for 9600 baud and 8 data bits. Then power the tag on while holding the DOWN button. A prompt and very brief instructions will be output. The message is saved as it is entered, so simply turn the tag off to reset when done entering.

The character set supported has 64 characters and includes upper and lower case as well as digits and some punctuation. However, due to the limited number of characters, some have been omitted that are similar looking to others, so you need to use those substitutes. For the following digits, use "O" for "0", "l" for "1", and "S" for "5", additionally, there is no lower-case "X" so use the upper-case version (there isn't really a way to make a lower-case one on a 14-segment display).

Lee created this hardware for the Vintage Computer Fest Midwest 19 on September 7-9, 2024, and there was just a short lead time to put this together. This is the initial version to support kits that Lee brought to the show. Future versons will have more features, incluing support for RAM if installed, which will allow a full ASCII character set. This version was to support the lowest-cost form of the kit and show how much could be done with very minimal hardware.

This is intended to be assembled using Mike Riley's Asm/02 assembler.
