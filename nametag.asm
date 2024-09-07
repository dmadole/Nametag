          ; Copyright 2024 by David S. Madole <david@madole.net>
          ;
          ; This program is free software: you can redistribute it and/or
          ; modify it under the terms of the GNU General Public License as
          ; published by the Free Software Foundation, either version 3 of
          ; the License, or (at your option) any later version.
          ;
          ; This program is distributed in the hope that it will be useful,
          ; but WITHOUT ANY WARRANTY; without even the implied warranty of
          ; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
          ; General Public License for more details.
          ;
          ; You should have received a copy of the GNU General Public License
          ; along with this program. If not, see http://www.gnu.org/licenses


          ; This code is firmware for Lee Hart's newer Nametag wth 14-segment
          ; displays. For more information on the hardware, please reference
          ; the discussion here: https://groups.io/g/cosmacelf/message/45282

            org   0                     ; start from reset in rom 


          ; We will mostly use R1 for memory arithmetic operations, so go
          ; ahead and set X to 1 here, and disable any interrupts.

begin:      dis                         ; disable interrupts and set x to 1
            db    10h


          ; If the tag is powered off while in the rotate message code, then
          ; it will leave the message in a partially-rotated corrupt state.
          ; So test if that happened (if R1 points into the rotate subroutine)
          ; and continue the rotation where it left off if so.

            ghi   r1                    ; check if r1.1 points to subroutine
            smi   rotator.1
            bnz   norecov

            glo   r1                    ; if r1.0 not in rotate then skip
            smi   rotator.0
            bnf   norecov

            glo   r1                    ; if r1.0 not in rotate then skip
            smi   rotaend.0
            bdf   norecov


          ; The rotate routine is written in a series of restart checkpoints
          ; each ending with a register put instruction. So we look back for
          ; the prior put instruction and restart from just after it.

recover:    dec   r1                    ; scan backwards for a phi or plo
            ldn   r1
            ani   %11100000
            xri   %10100000
            bnz   recover

            inc   r1                    ; call from just after the put
            sep   r1


          ; Now that we have potentially completed a partial shift operation,
          ; we also need to restore the message to its starting position with
          ; with the first character at the top of the shift register.

norecov:    ghi   r3                    ; if position 0-8 then already aligned
            sdi   8
            bdf   aligned

            ldi   rotator.1             ; set subroutine pointer register
            phi   r1
            ldi   rotator.0
            plo   r1

until32:    ghi   r3                    ; shift until at 32 or negative
            ani   32
            bnz   above31

            sep   r1                    ; shift and repeat until count is 32
            br    until32

above31:    ghi   r3                    ; if -8 to 0 then leave as is
            adi   8
            bdf   negativ
 
            ldi   0-8                   ; else set to -8
            phi   r3

negativ:    sep   r1

            ghi   r3
            bnz   negativ

aligned:    ldi   0
            phi   r3

            bn1   startup
            lbr   console

startup:    lbr   refresh


          ; The following tables are all in the same page as they are all used
          ; in the inner display refresh loop, or the character update code,
          ; and this way the high byte of the pointer register only needs to be
          ; set once.

          ; This is a table of one-instruction subroutines to retreive one
          ; character of the message. The pre- and postamble sections always
          ; return zero and are used to synthetically generate the blanks
          ; before and after the message when scrolled. Note that the two high
          ; bits need to be masked off before using the six-bit value that is
          ; returned. This table in in page zero so that GHI R1 can be used to
          ; return a zero value with one insutruction byte.

            org   128                   ; start address of table is %10000000

            ghi   r1                    ; first 8 entry points return zero
            sep   r0
            ghi   r1
            sep   r0
            ghi   r1
            sep   r0
            ghi   r1
            sep   r0
            ghi   r1
            sep   r0
            ghi   r1
            sep   r0
            ghi   r1
            sep   r0
            ghi   r1
            sep   r0

getchar:    glo   r4                    ; next 8 are top 8 message characters
            sep   r0
            ghi   r4
            sep   r0
            glo   r5
            sep   r0
            ghi   r5
            sep   r0
            glo   r6
            sep   r0
            ghi   r6
            sep   r0
            glo   r7
            sep   r0
            ghi   r7
            sep   r0

            ghi   r1                    ; last 7 entry points return zero
            sep   r0
            ghi   r1
            sep   r0
            ghi   r1
            sep   r0
            ghi   r1
            sep   r0
            ghi   r1
            sep   r0
            ghi   r1
            sep   r0
            ghi   r1
            sep   r0
            ghi   r1
            sep   r0


          ; This is a table of subroutines to put values into the top of the
          ; message buffer. Note that it's necessary to call GETCHAR first to
          ; retrieve and then preserve the two high bits of the register byte.

putchar:    plo   r4
            sep   r0
            phi   r4
            sep   r0
            plo   r5
            sep   r0
            phi   r5
            sep   r0
            plo   r6
            sep   r0
            phi   r6
            sep   r0
            plo   r7
            sep   r0
            phi   r7
            sep   r0


          ; This is a table of starting subroutines to refresh characters of
          ; the display starting from a given scroll position in the message.
          ; The first and last eight positions include the synthetic blank
          ; positions before and after, repectively, the message characters.
          ; The starting address of the table is chosen so that an entry's
          ; address can be created by setting the two high bits of the index.

            org   192                   ; start address of table is %11000000

indexes:    db    getchar-16,getchar-14,getchar-12,getchar-10
            db    getchar-8,getchar-6,getchar-4,getchar-2
            db    getchar,getchar,getchar,getchar
            db    getchar,getchar,getchar,getchar
            db    getchar,getchar,getchar,getchar
            db    getchar,getchar,getchar,getchar
            db    getchar,getchar,getchar,getchar
            db    getchar,getchar,getchar,getchar
            db    getchar+0,getchar+2,getchar+4,getchar+6
            db    getchar+8,getchar+10,getchar+12,getchar+14


          ; This is a table of shifting bit positions to enable each one of
          ; the multiplexed digits in the display based on the index position.
          ; The starting address of the table is chosen so that an entry's
          ; address can be created by setting the five high bits of the index.

            org   248                   ; start address of table is %11111000

muxbits:    db    %10000000,%01000000,%00100000,%00010000
            db    %00001000,%00000100,%00000010,%00000001



          ; The following tables are all in the same page as they are all used
          ; The two tables here are both used for mapping output characters
          ; to the display so they are stored in the same page so the high
          ; byte of the address pointer can be set only once.

            org   (($-1)|255)+1         ; start new page


          ; The following table maps between the 6-bit character code (which
          ; is the index of the table) and the 7-bit ASCII character set.
          ; Some characters have been omitted because of the limited set size
          ; and they can be substituted with similar-looking ones instead.

chartab:    db    ' ','A','B','C','D','E','F','G','H','I','J','K'
            db    'L','M','N','O','P','Q','R','S','T','U','V','W','X'
            db    'Y','Z','a','b','c','d','e','f','g','h','i','j','k'
            db    'l','m','n','o','p','q','r','s','t','u','v','w','y'
            db    'z','2','3','4','6','7','8','9','.','/','-','@',127


          ; Following is the definition of the ASCII character set in the
          ; 14-segment display format. The segments are connected to the
          ; address lines as in the diagram below. Note that the address
          ; lines connect to the cathodes so a zero bit lights the segment.
          ;
          ;    -----8-----
          ;   | \   |   / |
          ;   13 2  3  4  9 
          ;   |   \ | /   |
          ;    -14-- --0--
          ;   |   / | \   |
          ;   12 7  6  5 10
          ;   | /   |   \ |
          ;    -----11----    1
          ;
          ; By happy coincidence, the address of each entry is simply twice
          ; the ASCII code since this table starts 64 bytes into the page
          ; which is twice the code for space which is the first character.

            dw    %01111111_11111111    ; SPC
            dw    %01111001_11111101    ; !
            dw    %01111101_11110111    ; "
            dw    %00110001_10110110    ; #
            dw    %00010010_10110111    ; $
            dw    %00011011_00000010    ; %
            dw    %00100110_11010011    ; &
            dw    %01111111_11110111    ; '
            dw    %01111111_11001111    ; (
            dw    %01111111_01101111    ; )
            dw    %00111111_00000010    ; *
            dw    %00111111_10110110    ; +
            dw    %01111111_01111110    ; ,
            dw    %00111111_11111110    ; -
            dw    %01111111_11111101    ; .
            dw    %01111111_01101111    ; /

            dw    %01000000_01101111    ; 0
            dw    %01111001_11101111    ; 1
            dw    %00100100_11111110    ; 2
            dw    %00110000_11111110    ; 3
            dw    %00011001_11111110    ; 4
            dw    %00010010_11011111    ; 5
            dw    %00000010_11111110    ; 6
            dw    %01111000_11111111    ; 7
            dw    %00000000_11111110    ; 8
            dw    %00010000_11111110    ; 9
            dw    %01111111_10110111    ; :
            dw    %01111111_01110111    ; ;
            dw    %01111111_11001111    ; <
            dw    %00110111_10110110    ; =
            dw    %01111111_01111010    ; >
            dw    %01111100_10111100    ; ?

            dw    %01000100_11110110    ; @
            dw    %00001000_11111110    ; A
            dw    %01110000_10110110    ; B
            dw    %01000110_11111111    ; C
            dw    %01110000_10110111    ; D
            dw    %00000110_11111110    ; E
            dw    %00001110_11111110    ; F
            dw    %01000010_11111110    ; G
            dw    %00001001_11111110    ; H
            dw    %01110110_10110111    ; I
            dw    %01100001_11111111    ; J
            dw    %00001111_11001111    ; K
            dw    %01000111_11111111    ; L
            dw    %01001001_11101011    ; M
            dw    %01001001_11011011    ; N
            dw    %01000000_11111111    ; O
            dw    %00001100_11111110    ; P
            dw    %01000000_11011111    ; Q
            dw    %00001100_11011110    ; R
            dw    %00010010_11111110    ; S
            dw    %01111110_10110111    ; T
            dw    %01000001_11111111    ; U
            dw    %01001111_01101111    ; V
            dw    %01001001_01011111    ; W
            dw    %01111111_01001011    ; X
            dw    %01111111_10101011    ; Y
            dw    %01110110_01101111    ; Z
            dw    %01000110_11111111    ; [
            dw    %01111111_11011011    ; \
            dw    %01110000_11111111    ; ]
            dw    %01111111_01011111    ; ^
            dw    %01110111_11111111    ; _

            dw    %01111111_11111011    ; `
            dw    %00100111_10111111    ; a
            dw    %00000111_11011111    ; b
            dw    %01110111_01111110    ; c
            dw    %01110001_01111110    ; d
            dw    %00100111_01111111    ; e
            dw    %00111111_10101110    ; f
            dw    %01110001_11101110    ; g
            dw    %01001011_01111110    ; h
            dw    %01111111_10111111    ; i
            dw    %01101111_01110111    ; j
            dw    %01111111_10000111    ; k
            dw    %01111111_10110111    ; l
            dw    %00101011_10111110    ; m
            dw    %01101011_01111110    ; n
            dw    %01110011_01111110    ; o
            dw    %00001111_11111011    ; p
            dw    %01111001_11101110    ; q
            dw    %01101111_01111110    ; r
            dw    %01110111_11011110    ; s
            dw    %00111111_10110110    ; t
            dw    %01100011_11111111    ; u
            dw    %01101111_01111111    ; v
            dw    %01101011_01011111    ; w
            dw    %01111111_01001011    ; x
            dw    %01110001_11110110    ; y
            dw    %00110111_01111111    ; z
            dw    %00110110_01111011    ; {
            dw    %01111111_10110111    ; |
            dw    %01110110_11001110    ; }
            dw    %00111111_01101110    ; ~
            dw    %01000000_01001011    ; END


          ; Register R3.1 is used to track the display scroll position and
          ; the shift position of the message buffer. The buffer holds 32
          ; characters but is prefixed and suffixed with 8 blanks when
          ; scrolled so that the end doesn't run into the beginning of the
          ; message. This gives a total of 40 possible scroll positions.
          ;
          ; R3 ranges from 0 to 39 as the message is scrolled, with 0 being
          ; the display all blank, 1 being the first character scrolled in
          ; on the right, 2 being two characters scrolled in, etc. Through
          ; position 7 these are all "synthetic" as the blanks don't exist in
          ; the buffer, and the display position does not align with the
          ; message scroll position. For these positions, the buffer window
          ; remains aligned at the beginning of the message and does not move,
          ; and crolling is performed by changing the buffer start address.
          ;
          ; For positions 8-31, the message in the buffer is shifted one 
          ; position for each step and the mapping of the display to the
          ; buffer window is one-to-one. For position 32, the alignment is
          ; still one-to-one, but the buffer is not shifted after.
          ;
          ; Positions 33-39 are again synthetic, and the buffer does not move,
          ; but the start address is changed to effect scrolling. In total,
          ; positions 32 through 7 (wrapping around) do not scroll the buffer,
          ; excepting that after position 39 it is necessary to reset the 
          ; buffer window from being positioned on the last 8 charcters to be
          ; positioned on the first 8 characters, which takes 8 shifts.
          ;
          ; The following represents the cycle count to display and shift
          ; mapping, with a '.' representing a blank in the display and '<'
          ; representing a shift operation after that display cycle, for
          ; the message contents 'ABDEFGHIJKLMNOPRQSTUVWXYZ012345':
          ;
          ;   0 - ........
          ;   1 - .......A
          ;   2 - ......AB
          ;   3 - .....ABC
          ;   4 - ....ABCD
          ;   5 - ...ABCDE
          ;   6 - ..ABCDEF
          ;   7 - .ABCDEFG
          ;   8 - ABCDEFGH
          ;   9 - BCDEFGHI <
          ;  10 - CDEFGHIJ <
          ;  --
          ;  30 - WXYZ0123 <
          ;  31 - XYZ01234 <
          ;  32 - YZ012345
          ;  33 - Z012345.
          ;  34 - 012345..
          ;  35 - 12345...
          ;  36 - 2345....
          ;  37 - 345.....
          ;  38 - 45......
          ;  39 - 5....... <<<<<<<<
          ;
          ; There is one additional complexity to this, which is that the
          ; scroll position to buffer shift position must be maintained,
          ; even across power-off or reset of the tag. To failitate this,
          ; there are an additional eight scroll count positions -1 to -8
          ; that are used while performing the eight scrolls after position
          ; 39 so that this can be detected and continued after a reset.

            org   (($-1)|255)+1         ; start new page


          ; Perform one refresh cycle of the display, which is counter by
          ; R3.0 with bits 2-0 being the digit being refereshed, and bit
          ; 7-3 being a counter for how many times the display is updated
          ; with the same scroll position. This counter determins the scroll
          ; speed as each time it overflows, the scroll position is updated.

refresh:    ldi   getchar.1             ; preset msb of lookup tables
            phi   r1

            ldi   16<<3                 ; set timing constant in high bits
            plo   r3


          ; Here is where we loop back for each digit in the cycle of the
          ; 8-digit display, and also to repeat the whole display refresh
          ; for the number of times in r3.0 bits 7-3.

nextdig:    ghi   r3                    ; get start entry from char position
            ori   %11000000
            plo   r1

            glo   r3                    ; add digit index to get subroutine
            ani   %00000111
            shl
            add
            plo   r1

            sep   r1                    ; call subroutine and get low 6 bits
            ani   %00111111
            plo   r2

            ldi   chartab.1             ; make pointer into character table
            phi   r2

            ldn   r2                    ; convert ascii to font table index
            shl
            plo   r2

            lda   r2                    ; get character definition into r2
            plo   r1
            ldn   r2
            plo   r2
            glo   r1
            phi   r2

            glo   r3                    ; digit counter into multiplex index
            ori   %11111000
            plo   r1

            ldn   r1                    ; store multiplex bit to write display
            str   r2

            ldi   %01111111             ; disable stronger high address lines
            phi   r2

            ldn   r1                    ; output low lines again to equalize
            str   r2

            glo   r3                    ; instead of inc so no affect on r3.1
            adi   1
            plo   r3

            bnz   nextdig               ; repeat until timer counter overflow


          ; After each refresh period, we need to update the scroll position
          ; of the message, and allow editing of the current character if
          ; the set button is being pressed.

            ghi   r3                    ; if before message just increment
            bz    incposi

            smi   33                    ; edit if in message and set pressed
            lsdf
            b4    setmesg

            ghi   r3                    ; if position under 8 just increment
            smi   8
            bnf   incposi

            ghi   r3
            smi   32                    ; else if under 32 then shift message
            bnf   doshift

            ghi   r3
            smi   39                    ; else if under 39 then increment
            bdf   restart


          ; If we are in positions 0-7 or 32-38 then the message is scrolled
          ; virtually so we update the counter without shifting the message.

incposi:    ghi   r3                    ; increment scroll position
            adi   1
            phi   r3

            br    refresh               ; continue display refresh


          ; If we are in positions 8-31 then the message is scrolled by 
          ; shifting the message buffer one character. The rotate code also 
          ; increments R3.1 so that it is restartable with the shift.

doshift:    ldi   rotator.1             ; set rotator subroutine address
            phi   r1
            ldi   rotator.0
            plo   r1

            sep   r1                    ; call and then resume refresh
            br    refresh


          ; After position 39, we need to advance the message buffer 8
          ; positions to get it reset back to the starting position. When
          ; doing this, we iterate the position from -8 to -1 so that the
          ; operation is restartable if the machine is reset.

restart:    ldi   0-8                   ; set position counter to -8
            phi   r3

            ldi   rotator.1             ; set rotator subroutine address
            phi   r1
            ldi   rotator.0
            plo   r1

resloop:    sep   r1                    ; shift until counter reaches zero
            ghi   r3                    
            bnz   resloop

            br    refresh               ; continue display refresh


          ; If the SET button is pressed then do not scroll the display,
          ; instead check the UP and DOWN buttons to allow changing the
          ; current character (the rightmost display digit). Start by
          ; getting the current character since this is needed either way,
          ; then check the buttons.

setmesg:    smi   8-33                  ; if position is above 7, use 7
            lsnf
            ldi   0

            shl                         ; get index into get subroutines
            adi   (7*2)+getchar
            plo   r1

            sep   r1                    ; get current character value
            plo   r2

            glo   r1                    ; change subroutine to put character
            adi   putchar-getchar-2
            plo   r1

            b1    decchar               ; is up or down button pressed
            b2    incchar

            br    refresh               ; if not, just wait in place


          ; If the DOWN button is pressed, decrement the current character,
          ; wrapping it around within the low 6 bits only as the high 2 bits
          ; belong to a different character position. If the UP button is
          ; pressed also (both pressed) then clear the message.

decchar:    b2    zeromsg               ; if both pressed clear message

            ani   %00111111             ; clear df if underflow will occur
            smi   1

            glo   r2                    ; decrement only lowest 6 bits
            lsdf
            adi   %01000000
            smi   1

            sep   r1                    ; update value and continue
            br    refresh


          ; If the UP button is pressed, increment the current character,
          ; again, affecting only the 6 low bits if it overflows.

incchar:    ori   %11000000             ; set df if overflow will occur
            adi   1

            glo   r2                    ; increment only lowest 6 bits
            lsnf
            smi   %01000000
            adi   1

            sep   r1                    ; update value and continue
            br    refresh


          ; Zero all message storage if both buttons pressed. This is spaces.

zeromsg:    ldi   0

            plo   r4
            phi   r4
            plo   r5
            phi   r5
            plo   r6
            phi   r6
            plo   r7
            phi   r7
            plo   r8
            phi   r8
            plo   r9
            phi   r9
            plo   ra
            phi   ra
            plo   rb
            phi   rb
            plo   rc
            phi   rc
            plo   rd
            phi   rd
            plo   re
            phi   re
            plo   rf
            phi   rf

            br    refresh


            org   (($-1)|255)+1         ; start new page

          ; The message is stored as 6-bit characters packed into in registers
          ; R4-RF. Sets of three half-registers (8 bits) are used to each
          ; store four 6-bit character codes. There are eight of these sets
          ; available (24 total half-registers) so enough for 32 characters.
          ;
          ; The message storage is treated as nested shift registers. Each
          ; register set is rotated two bits to align the next 6-bit code into
          ; the low 6 bits of the next register. At the same time, the 
          ; registers are also rotated the opposite direction byte-wise so
          ; that the aligned character is always in the same register.
          ;
          ; For example, here is one register set storing four bytes A-D,
          ; starting with byte A properly aligned for easy access:
          ;
          ;   D D A A A A A A   B B B B B B C C    C C C C D D D D
          ;   0 1 5 4 3 2 1 0   5 4 3 2 1 0 5 4    3 2 1 0 5 4 3 2
          ; 
          ; After shifting right two bits, this right-aligns byte B:
          ;
          ;   D D D D A A A A   A A B B B B B B    C C C C C C D D
          ;   3 2 0 1 5 4 3 2   1 0 5 4 3 2 1 0    5 4 3 2 1 0 5 4
          ; 
          ; Then the byte rotation brings byte B into the first register:
          ;
          ;   A A B B B B B B    C C C C C C D D   D D D D A A A A
          ;   1 0 5 4 3 2 1 0    5 4 3 2 1 0 5 4   3 2 0 1 5 4 3 2
          ;
          ; As these two operations are repeated, each of the four 6-bit codes
          ; cycle through alignment in the first byte giving a fixed point
          ; of access to subsequent bytes.
          ;
          ; The message is actually stored striped across the eight sets of
          ; three half-registers, with the first byte in the first register
          ;
          ; This makes the "top" of each register set contain 8 consecutive
          ; characters of the message, which aligns with the 8 digits of the
          ; display, making refresh simple.
          ;
          ; Here is an example showing the message through three shifts:
          ;
          ;   A I Q Y     B J R Z     C K S 0
          ;   B J R Z     C K S 0     D L T 1
          ;   C K S 0     D L T 1     E M U 2
          ;   D L T 1     E M U 2     F N V 3
          ;   E M U 2     F N V 3     G O W 4
          ;   F N V 3     G O W 4     H P X 5
          ;   G O W 4     H P X 5     I Q Y A
          ;   H P X 5     I Q Y A     J R Z B


          ; Rotate the message "left' by one 6-bit character. Note that the
          ; hardware maintains state when powered off (even 1802 register
          ; contents) so that the message may be preserved. But if it is
          ; powered off in the middle of a rotate operation, the message will
          ; be partially corrupted. So this code is written to be resumable
          ; by being written in a series of checkpoints. If interrupted by
          ; a reset, then the operation may be resumed by restarting the 
          ; current checkpoint from it's beginning, which will be just after
          ; the most recent PLO or PHI instructions.
          ;
          ; The key here is that each segment ending in a PLO or PHI must not
          ; depend on the value of the register that it is updating. This
          ; makes the code just a little more verbose than it should be.

rotaret:    sep   r0                    ; return from rotator subroutine

rotator:    plo   r2                    ; this is a dummy instruction

            ghi   r3                    ; split to two parts so restartable
            adi   1
            plo   r2

            glo   r2                    ; finish the position increment
            phi   r3

            glo   r8                    ; perform the 2-bits right shift
            plo   r2

            glo   r4
            shrc
            glo   r2
            shrc
            plo   r8

            glo   rc
            phi   r2

            glo   r2
            shrc
            ghi   r2
            shrc
            plo   rc

            glo   r4
            plo   r2

            ghi   r2
            shrc
            glo   r2
            shrc
            plo   r4


            glo   r8
            plo   r2

            glo   r4
            shrc
            glo   r2
            shrc
            plo   r8

            glo   rc
            phi   r2

            glo   r2
            shrc
            ghi   r2
            shrc
            plo   rc

            glo   r4
            plo   r2

            ghi   r2
            shrc
            glo   r2
            shrc
            plo   r4

            glo   r4                    ; perform the one-byte left shift
            plo   r2

            ghi   r4
            plo   r4

            glo   r5
            phi   r4

            ghi   r5
            plo   r5

            glo   r6
            phi   r5

            ghi   r6
            plo   r6

            glo   r7
            phi   r6

            ghi   r7
            plo   r7

            glo   r8
            phi   r7

            ghi   r8
            plo   r8

            glo   r9
            phi   r8

            ghi   r9
            plo   r9

            glo   ra
            phi   r9

            ghi   ra
            plo   ra

            glo   rb
            phi   ra

            ghi   rb
            plo   rb

            glo   rc
            phi   rb

            ghi   rc
            plo   rc

            glo   rd
            phi   rc

            ghi   rd
            plo   rd

            glo   re
            phi   rd

            ghi   re
            plo   re

            glo   rf
            phi   re

            ghi   rf
            plo   rf

            glo   r2
            phi   rf

rotaend:    br    rotaret


          ; Output a character through the serial line on Q at 9600 baud,
          ; assuming a 2 megahertz clock frequency. Data format is 8 bits,
          ; no parity (or equivalently, 7 bits, space parity). This uses
          ; R3.0 to hold and shift the character bits, and also the stop
          ; bit, which is shifted in on the first shift. Since zeroes are
          ; shifted in after it, when the register is zero, we are done.

typeret:    sep   r0                    ; return with r1 is reset to start

typechr:    plo   r3                    ; save output character

            ldi   0-3                   ; delay for stop bit, 14 cycles
typestp:    adi   1
            bnf   typestp

            req                         ; send start bit

            ldi   0-3                   ; delay for start bit, set df=1
typestr:    adi   1
            bnf   typestr

            br    typefst               ; go shift in the stop bit

typebit:    ldi   3-1                   ; delay for bit time
typedly:    smi   1
            bdf   typedly

typefst:    glo   r3                    ; shift character data one bit
            shrc
            plo   r3

            bdf   typemrk               ; if a mark (one) bit

            req                         ; else set a space (zero) bit
            br    typebit

typemrk:    seq                         ; set mark, done if value is zero
            bnz   typebit

            br    typeret               ; jump to beginning to return


          ; Input a character through the serial line on EF3 at 9600 baud,
          ; assuming a 2 megahertz clock frequency. Data format is 8 bits,
          ; no parity (or equivalently, 7 bits, space parity). This uses
          ; R3.0 both to assemble the received character and to count the
          ; bits since we initially shift a one in with all other zeros,
          ; so when the one shifts out we know it's been eight bits.

readchr:    bn3   readchr               ; Wait for start bit

            ldi   0-3                   ; extra delay to make 1.5 bit times
readstr:    adi   1
            bnf   readstr

readmrk:    shrc                        ; shift in a one bit for mark
            bdf   readstp

readbit:    plo   r3                    ; do this twice for timing
            plo   r3

            ldi   0-3                   ; delay to make a bit time
readdly:    adi   1
            bnf   readdly

            glo   r3                    ; get value, check input line
            bn3   readmrk

            shr                         ; shift in a zero since a space
            bnf   readbit

readstp:    b3    readstp               ; wait for stop bit if needed

            sep   r0                    ; return here


          ; These are the power-on message in serial mode, and the prompt
          ; string that is displayed after the message is output. Note that
          ; these cross a page boundary, but that's fine since they are
          ; just strings that are read sequentially.

banners:    db    13,10,10
            db    '1802 Name Tag V.0 by Lee Hart & David Madole',13,10
            db    'TAB to skip ahead, RETURN to blank to end.',13,10
            db    '> ',0
prompts:    db    ' <',13,'> ',0


          ; The serial console mode is activated when the DOWN key is pressed
          ; during power-on. This allows setting the message via a terminal
          ; attached to the I/O and power header. Since the transmit data
          ; line idle state is the opposite of the reset state, we need to
          ; set the idle state and delay a little to prevent garbage from
          ; being output to the terminal.

console:    seq                         ; set the idle state of the line

            sex   r2                    ; we will use r2 to index data

            ldi   50                    ; delay for a short time to settle
            phi   r2

stall:      dec   r2                    ; this is about 300 milliseconds
            ghi   r2
            bnz   stall


          ; Display the power-on banner message with (extremely) brief
          ; instructions.

            ldi   typechr.1             ; set subroutine pointer for output
            phi   r1
            ldi   typechr.0
            plo   r1

            ldi   banners.1             ; get pointer to banner message
            phi   r2
            ldi   banners.0
            plo   r2

            lda   r2                    ; prime the pump with first char

conloop:    sep   r1                    ; output the message up to null
            lda   r2
            bnz   conloop


          ; Next display the message, getting the data from the buffer
          ; and translating to ASCII as we go.

            ldi   8                     ; set restartable start position
            phi   r3

msgloop:    ldi   typechr.0             ; point to serial output routine
            plo   r1

            ldi   chartab.1             ; pointer msb to character table
            phi   r2

            glo   r4                    ; get top character set as index
            ani   %00111111
            plo   r2

            ldn   r2                    ; lookup ascii and transmit it
            sep   r1

            ldi   rotator.0             ; rotate message one position
            plo   r1
            sep   r1

            ghi   r3                    ; stop at the end of message
            bz    mesgend

            smi   32                    ; continue until position 32
            bnz   msgloop

            ldi   0-8                   ; then resume from position -8
            phi   r3
            br    msgloop
            

          ; Now output the prompt which puts > < around the message and
          ; moves the cursor to the first position.

mesgend:    ldi   typechr.0             ; set subroutine to serial output
            plo   r1

            ldi   prompts.1             ; get pointer to prompt message
            phi   r2
            ldi   prompts.0
            plo   r2

            lda   r2                    ; prime the pump with first char

proloop:    sep   r1                    ; output the message up to null
            lda   r2
            bnz   proloop


          ; Get key input from the console and process each one.

            ldi   8                     ; reset to restartable position
            phi   r3

updloop:    ldi   readchr.1             ; address of input subroutine
            phi   r1
            ldi   readchr.0
            plo   r1

            sep   r1                    ; get next input character
            plo   r3


          ; Check for a few control characters and handle appropriately.

            smi   8                     ; if backspace then go backwards
            bz    backspc

            smi   13-8                  ; if return then blank rest of line
            bz    creturn

            smi   127-13                ; also treat delete as a backspace
            bz    backspc


          ; Next deal with any printable characters input, or a tab, which
          ; is treated like the current character was typed. First check
          ; that we are not at the end of the message, ignore if so.

            ghi   r3                    ; ignore any if at end of message
            bz    updloop

            ldi   chartab.1             ; needed for both lookup and tab
            phi   r2

            glo   r3                    ; if tab key then skip ahead
            smi   9
            bz    tabchar


          ; Scan the ASCII to 6-bit table looking for the input character
          ; so that we knwo it's code, which will be the table index.

            ldi   chartab.0             ; set lsb of pointer to table start
            plo   r2

findchr:    glo   r3                    ; if we found the character here
            sm
            bz    gotchar

            inc   r2                    ; else move to next and check end
            glo   r2
            smi   64
            bnz   findchr

            br    updloop               ; not found, get next input char


          ; Since we found the character and it's valid, echo it back now.

gotchar:    ldi   typechr.0             ; subroutine pointer to transmit
            plo   r1

            glo   r3                    ; output the character to terminal
            sep   r1


          ; Replace the six low bits in R4.0 with the six low bits in R1.0
          ; without changing the two high bits in R4.0. This will update the
          ; character at the current scroll position.

            glo   r2                    ; left align bits 5:0 of r1 to r2
            shlc
            shlc
            plo   r2

            glo   r4                    ; shift bit 5 of r4 into r2 copy
            shlc
            shlc
            glo   r2
            shrc
            plo   r2

            glo   r4                    ; shift bit 6 into r2 move to r4
            shlc
            glo   r2
            shrc
            plo   r4


          ; Rotate the message buffer one character to move to next position,
          ; then go back and get another input character.

            ldi   rotator.0             ; rotate message buffer one position
            plo   r1
            sep   r1

            ghi   r3                    ; if position is not 32 get next
            smi   32
            bnz   updloop

            ldi   0-8                   ; else set to -8 for realignment
            phi   r3
            br    updloop


          ; If tab was pressed, get the character code from the current
          ; position and lookup the ASCII in the table so we can echo it.
          ; Then go and treat just like any other character.

tabchar:    glo   r4                    ; set lsb of 6-bit table index
            ani   %00111111
            plo   r2

            ldn   r2                    ; get ascii corresponding to code
            plo   r3

            br    gotchar               ; handle just like it was typed


          ; If a backspace (or delete) is typed, move the cursor left if not
          ; at the beginning and rotate the message back a position by
          ; actually rotating it forward 31 positions.

backspc:    ghi   r3                    ; if at beginning then do nothing
            smi   8
            bz    updloop

            ldi   typechr.0             ; point to serial output routine
            plo   r1

            ldi   8                     ; send backspace to move cursor
            sep   r1

            ldi   31                    ; counter 31 shifts to go back 1
            plo   r3

            ldi   rotator.0             ; pointer to message rotate routine
            plo   r1

bsploop:    ghi   r3                    ; if pointer is zero (past end)
            bnz   notzero

            ldi   8                     ; then reset to 8 (at start)
            phi   r3

notzero:    glo   r3                    ; if 31 rotates then we are done
            bz    updloop

            sep   r1                    ; rotate one position and count
            dec   r3

            ghi   r3                    ; if position is 32
            smi   32
            bnz   bsploop

            ldi   0-8                   ; then set to -8 to make resettable
            phi   r3
            br    notzero


          ; If return is pressed, erase the message from the current position
          ; by outputting spaces and clearing the first byte, while shifting
          ; message at the same time to reset to the first position.

creturn:    ghi   r3                    ; if at end just display prompt
            bz    mesgend

            ldi   typechr.0             ; point to serial output routine
            plo   r1

            ldi   ' '                   ; send a space to erase character
            sep   r1

            glo   r4                    ; change character on top to space
            ani   %11000000
            plo   r4

            ldi   rotator.0             ; rotate message one character
            plo   r1
            sep   r1

            ghi   r3                    ; if not at 32 then continue loop
            smi   32
            bnz   creturn

            ldi   0-8                   ; make 32 into -8 so its resetable
            phi   r3
            br    creturn

            end   begin
