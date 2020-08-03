data:   equ     0

        org     0ff00h
return: sep     r5
call:   smi     01h          ; check for type  (01)
        lbz     type         ; jump to type6 routine
        smi     01h          ; check for get char (02)
        lbz     read
        smi     01h          ; check for type message (03)
        lbz     typemsg
        smi     01h          ; check for type6 (04)
        lbz     type6        ; jump to type6 routine
        smi     01h          ; check for input (05)
        lbz     input        ; jump to input routine
        smi     01h          ; check for string compare (06)
        lbz     strcmp       ; jump to string compare routine
        smi     01h          ; check for ltrim function (07)
        lbz     ltrim        ; jump if found
        smi     01h          ; check for strcpy function (08)
        lbz     strcpy       ; jump if found
        smi     01h          ; check for memcpy function (09)
        lbz     memcpy       ; jump if found
        smi     01h          ; check for write sector function (10)
        lbz     wrtsec       ; jump if found
        smi     01h          ; check for read sector function (11)
        lbz     rdsec        ; jump if found
        smi     01h          ; check for track 0 function  (12)
        lbz     trk0         ; jump if found
        smi     01h          ; check for track seek function  (13)
        lbz     seek         ; jump if found
        smi     01h          ; check for select drive function  (14)
        lbz     drvsel       ; jump if found

        lbr     return       ; return to caller

return4: ldi   high ret4
         phi   r3
         ldi   low ret4
         plo   r3
         sep   r3
ret4:    glo   r4
         plo   r5
         ghi   r4
         phi   r5
         br   return

         org     0fe00h
; **** Write sector to disk, R(6) points to data
; ****    R(6) must point to an even 256 byte boundary
; ****    RC.0 = sector
; ****  Returns: D - write status
wrtsec:  ldi     low data    ; get address of scratchpad
         adi     4           ; point to end of command
         plo     rf          ; register to use to write temp data
         ldi     high data   ; get high address of scratchpad
         phi     rf          ; write to register
         sex     rf          ; point data register to command buffer
         ldi     3           ; data register address
         stxd                ; write to command
         ldi     0a4h        ; command to initiate writing
         stxd                ; write to command
         ldi     0           ; command register address
         stxd                ; write to command
         glo     rc          ; get sector
         stxd                ; write to command
         ldi     2           ; sector register address
         str     rf          ; write to command port
         out     2           ; write sector register to selector
         out     3           ; send sector
         out     2           ; write command register to selector
         out     3           ; send write command
         out     2           ; select data port
         sex     r6          ; point data register to data
wrtlp:   b2      $           ; wait til disk controller has a byte
         out     3           ; write data to disk controller
         glo     r6          ; get low byte
         bnz     wrtlp       ; loop until 256 bytes read
dskstat: ldi     0           ; status port
         str     rf          ; write to scratchpad
         sex     rf          ; point data register to scratchpad
         out     2           ; select status port
         dec     rf          ; point to scratch area
statlp:  inp     3           ; read status
         shr                 ; shift busy bit into DF
         bdf     statlp      ; loop until no longer busy
         shl                 ; shift back into position
         lbr     return      ; return status code

; **** Read sector from disk, R(6) points to buffer
; ****    R(6) must point to an even 256 byte boundary
; ****    RC.0 = sector
; ****  Returns: D - read status
rdsec:   ldi     low data    ; get address of scratchpad
         adi     4           ; point to end of command
         plo     rf          ; register to use to write temp data
         ldi     high data   ; get high address of scratchpad
         phi     rf          ; write to register
         sex     rf          ; point data register to command buffer
         ldi     3           ; data register address
         stxd                ; write to command
         ldi     084h        ; command to initiate reading
         stxd                ; write to command
         ldi     0           ; command register address
         stxd                ; write to command
         glo     rc          ; get sector
         stxd                ; write to command
         ldi     2           ; sector register address
         str     rf          ; write to command port
         out     2           ; write sector register to selector
         out     3           ; send sector
         out     2           ; write command register to selector
         out     3           ; send write command
         out     2           ; select data port
         sex     r6          ; point data register to data
rdlp:    b2      $           ; wait til disk controller has a byte
         inp     3           ; read data from disk controller
         irx                 ; increment data pointer
         glo     r6          ; get low byte
         bnz     rdlp        ; loop until 256 bytes read
         br      dskstat     ; jump to get status

; **** Select Drive
; ****   RC.0 = drive (1=drive 1,2=drive 2,4=drive 3,8=drive 4)
drvsel:  ldi     low data    ; get address of scratchpad
         adi     4           ; point to end of command
         plo     rf          ; register to use to write temp data
         ldi     high data   ; get high address of scratchpad
         phi     rf          ; write to register
         sex     rf          ; point data register to command buffer
         glo     rc          ; get requested drive
         stxd                ; store into command buffer
         ldi     4           ; drive select register
         str     rf          ; store into command buffer
         out     2           ; write drive select to selector
         out     3           ; write drive select register
         br      return      ; return to caller

; **** Restore to track 0
trk0:    ldi     low data    ; get address of scratchpad
         adi     4           ; point to end of command
         plo     rf          ; register to use to write temp data
         ldi     high data   ; get high address of scratchpad
         phi     rf          ; write to register
         sex     rf          ; point data register to command buffer
         ldi     09          ; command to do a disk restore
         stxd                ; write to command buffer
         ldi     0           ; command port
         str     rf          ; write to command port
         out     2           ; write command register to selector
         out     3           ; issue restore command
         br      dskstat     ; branch to get diskstat

; **** Seek to track
; ****    RC.0 = track
; ****  Returns: D - read status
seek:    ldi     low data    ; get address of scratchpad
         adi     4           ; point to end of command
         plo     rf          ; register to use to write temp data
         ldi     high data   ; get high address of scratchpad
         phi     rf          ; write to register
         sex     rf          ; point data register to command buffer
         ldi     19h         ; command to do a disk seek
         stxd                ; write to command buffer
         ldi     0           ; command port
         stxd                ; write to command buffer
         glo     rc          ; get passed track
         stxd                ; write to command buffer
         ldi     3           ; data register selector
         str     rf          ; write to command port
         out     2           ; write data port to selector
         out     3           ; write track to data register
         out     2           ; write command port to selector
         out     3           ; output the command
         br      dskstat     ; branch to get command status

         org     0fd00h
; **** Strcmp compares the strings pointing to by R(6) and R(X)
; **** Returns:
; ****    R(6) = R(X)     0
; ****    R(6) < R(X)     -1 (255)
; ****    R(6) > R(X)     1
strcmp:  lda     r6          ; get next byte in string
         ani     0ffh        ; check for zero
         bz      strcmpe     ; found end of first string
         sm                  ; subtract 2nd byte from it
         irx                 ; point to next character
         bz      strcmp      ; so far a match, keep looking
         bnf     strcmp1     ; jump if first string is smaller
         ldi     1           ; indicate first string is larger
         lskp                ; and return to caller
strcmp1: ldi     255         ; return -1, first string is smaller
         lbr     return      ; return to calelr
strcmpe: ldx                 ; get byte from second string
         bz      strcmpm     ; jump if also zero
         ldi     255         ; first string is smaller (returns -1)
         lbr     return      ; return to caller
strcmpm: ldi     0           ; strings are a match
         lbr     return      ; return to caller

; **** ltrim trims leading white space from string pointed to by R[X]
; **** Returns:
; ****    R(X) pointing to non-whitespace portion of string
ltrim:   ldx                 ; get next byte from string
         lbz     return      ; return if at end of string
         smi     ' '+1       ; looking for anthing <= space
         lbdf    return      ; found first non white-space
         irx                 ; point to next character
         br      ltrim       ; keep looking

; **** strcpy copies string pointed to by R[X] to R[6]
strcpy:  ldxa                ; get byte from source string
         str    r6           ; store into destination
         lbz    return       ; return if copied terminator
         inc    r6           ; increment destination pointer
         br     strcpy       ; continue looping

; **** memcpy copies R[F] bytes from R[X] to R[6]
memcpy:  glo    rf           ; get low count byte
         bnz    memcpy1      ; jump if not zero
         ghi    rf           ; get high count byte
         lbz    return       ; return if zero
memcpy1: ldxa                ; get byte from source
         str    r6           ; store into destination
         inc    r6           ; point to next destination position
         dec    rf           ; decrement count
         br     memcpy       ; and continue copy

	org	0fc00h
; *** Software uart is adapted from that found in IDIOT/4
; *** I will probably have to change this in the future.
; Baud needs to have the high value set as follows
;      75 baud = 0a2h
;     110 baud = 06ch
;     300 baud = 026h
;     600 baud = 012h
;    1200 baud = 008h
; Add 1 for half duplex

delay:  equ     rc           ; register holding address for delay routine
char:   equ     rd
baud:   equ     re           ; register holding baud information
ascii:  equ     rf           ; register for ascii
typexit: lbr     return       ; return to caller
type6:  lda     r6           ; get byte from m(r6) and advance
        skp
type:   glo     ascii        ; get low byte of ascii
        plo     char         ; place byte into register D
        xri     0ah          ; check for linefeed
        bnz     ty2          ; jump if not
        ldi     5bh          ; more bits if need to wait
        lskp                 ; jump
ty2:    ldi     0bh          ; 11 bits to write
        plo     ascii
        ldi     delay1.1
        phi     delay
        ldi     delay1.0
        plo     delay
begin:  glo     baud         ; get baud delay flag
        lsz                  ; skip if no need to wait
        sep     delay        ; call delay routine
        db      23           ; 3 bit times
        seq                  ; begin start bit
nxtbit: sep     delay        ; call delay routine
        db      7            ; wait 1 bit time
        nop                  ; wait
        nop                  ; wait
        nop                  ; wait
        nop                  ; wait
        nop                  ; wait
        nop                  ; wait
        dec     ascii        ; decrement number of bits
        sdi     0
        glo     char         ; get next bit of character
        shrc                 ; lease significant bit first
        plo     char         ; put back
        lsdf                 ; long skip if bit =0
        seq                  ;   set q=1 - "space"
        lskp                 ; skip next 2 bytes
        req                  ; if bit = 1,
        nop                  ;    set q=0 = "mark"
        glo     ascii        ; until #bits = 0
        ani     0fh
        bnz     nxtbit       ; loop if more to go
        glo     ascii        ; get code byte
        adi     0fbh         ; decrement code
        plo     ascii        ; set #bits
        bnf     typexit      ; jump if no more
        smi     01bh         ; if code = 1
        bz      typexit      ; then was last null, exit
zer:    ldi     0            ; if code > 1
        plo     char         ; load byte
        br      begin        ; and type it

delext: sep     r3           ; return from delay routine
delay1: ghi     baud         ; get baud constant
        shr                  ; remove echo flag
        plo     baud         ; repeat
dellp2: dec     baud         ;   decrement baud
        lda     r3           ;   get #bits
dellp1: smi     1            ;   decrement until zero
        bnz     dellp1       ;
        glo     baud         ;   until baud = 0
        bz      delext       ; return if done
        dec     r3
        br      dellp2

rexit:  ghi     ascii        ; get character
        lbr     return       ; return to caller
read:  ldi     0            ; flag for terminal control
        plo     ascii        ; save entry flag
read2:  ldi     80h          ; set #bits in character = 7
        phi     ascii        ; (7 shift changes 80 into 01)
        ldi     delay1.1
        phi     delay
        ldi     delay1.0
        plo     delay
        sex     r3
        out     7            ; turn reader on
        db      80h
        bn4     $            ; wait while stop bit
tty1:   b4      $
        sep     delay        ; delay 1/2 bit time
        db      2
        b4      tty1
        out     7
        db      40h
nobit:  sex     r2           ; equalize delays
        sex     r2
bit:    ghi     baud
        shr
        bdf     noecho       ; check if need to echo
        b4      outbit
        seq                  ; set q if bit = 1
        lskp                 ; reset q if bit=0
outbit: req
noecho: nop                  ; equalize delays
        lsnf
        sex    r2
        sex    r2
        sex    r2
        nop
        nop
        sep    delay         ; wait 1 bit time
        db     7
        inc    baud          ; set delay flag = 1
        ghi    ascii         ; shift by 1 bit
        shr
        phi    ascii
        bdf    stop
        ori    80h
        bn4    nobit
        phi    ascii         ; continue loop
        br     bit
stop:   req                  ; set stop bit
        bz     read2         ; repeat if 00=null
        br     rexit         ; done

typemsg: glo   r5            ; get callers address
         plo   r4            ; save for later
         ghi   r5            ; high part
         phi   r4
         ldi   low typelp    ; get type loop address
         plo   r5            ; and place into r5
         ldi   high typelp
         phi   r5
         sep   r5
typelp:  ldn   6             ; load byte from message
         lbz   return4       ; return if last byte
         ldi   high call     ; get address of call routine
         phi   r3            ; place into register 3
         ldi   low  call     ; get low portion of address
         plo   r3
         ldi   4             ; function to use type4
         sep   r3            ; perform the function
         br    typelp        ; loop until a zero found

input:   glo   r5            ; get callers address
         plo   r4            ; save for later
         ghi   r5            ; high part
         phi   r4
         ldi   low inplp     ; get type loop address
         plo   r5            ; and place into r5
         ldi   high inplp
         phi   r5
         ldi   0             ; byte count
         plo   r2            ; store into counter
         sep   r5
inplp:   ldi   high call     ; get address of call routine
         phi   r3            ; place into register 3
         ldi   low  call     ; get low portion of address
         plo   r3
         ldi   2             ; function to read key
         sep   r3            ; perform the function
         str   r6            ; store byte
         inc   r6            ; point to next position
         smi   08            ; look for backspace
         bnz   nobs          ; jump if not a backspace
         glo   r2            ; get input count
         bz    inplp         ; disregard if string is empty
         dec   r2            ; decrement the count
         dec   r6            ; decrement buffer position
         dec   r6
         br    inplp         ; and loop back for more
nobs:    smi   05            ; check for CR
         bz    inpdone       ; loop back if not
         inc   r2            ; increment input count
         br    inplp         ; and then loop back
inpdone: ldi   0             ; need a zero terminator
         str   r6            ; store into buffer
         lbr   return4       ; return to caller

