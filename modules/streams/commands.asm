;The MIT License
;
;Copyright (c) 2009 Dylan Smith
;
;Permission is hereby granted, free of charge, to any person obtaining a copy
;of this software and associated documentation files (the "Software"), to deal
;in the Software without restriction, including without limitation the rights
;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:
;
;The above copyright notice and this permission notice shall be included in
;all copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;THE SOFTWARE.

; BASIC extensions

;--------------------------------------------------------------------------
; F_connect: Receives the %connect command, opens a socket,
; and connects it to a host.
; Syntax is %connect stream,"hostname",port
F_connect
	rst CALLBAS
	defw ZX_NEXT_CHAR
	cp '#'				; # means channel number
	jp nz, PARSE_ERROR
	rst CALLBAS
	defw ZX_NEXT_CHAR		; advance to channel number

        rst CALLBAS
        defw ZX_EXPT1_NUM               ; stream number to open
	cp ','
	jp nz, PARSE_ERROR
	rst CALLBAS
	defw ZX_NEXT_CHAR

        rst CALLBAS
        defw ZX_EXPT_EXP                ; string parameter - hostname
	cp ','
	jp nz, PARSE_ERROR
	rst CALLBAS
	defw ZX_NEXT_CHAR

	rst CALLBAS
	defw ZX_EXPT1_NUM		; check for port number

        call STATEMENT_END

        ;-------- runtime --------
        rst CALLBAS
        defw ZX_FIND_INT2		; port number
	push bc				; save it

	rst CALLBAS
	defw ZX_STK_FETCH		; hostname
	push bc				; save length
	push de				; and source

        rst CALLBAS
        defw ZX_FIND_INT2		; stream
	push bc				; save stream
        jp F_connect_impl

;--------------------------------------------------------------------------
; F_listen
; Opens a socket that listens.
; %listen #n,port
F_listen
        rst CALLBAS
        defw ZX_NEXT_CHAR
        cp '#'                          ; # means channel number
        jp nz, PARSE_ERROR

	rst CALLBAS
	defw ZX_NEXT2_NUM		; test parameters
	call STATEMENT_END

	;-------------- runtime ------------
	rst CALLBAS
	defw ZX_FIND_INT2		; port number
	push bc
	
	rst CALLBAS
	defw ZX_FIND_INT2		; stream number
	push bc
	jp F_listen_impl

;-------------------------------------------------------------------------
; F_accept
; Accepts an incoming connection
F_accept
	rst CALLBAS
        defw ZX_NEXT_CHAR
        cp '#'                          ; # means channel number
        jp nz, PARSE_ERROR

	rst CALLBAS
	defw ZX_NEXT2_NUM		; test parameters
	call STATEMENT_END

	;-------------- runtime ------------
	rst CALLBAS
	defw ZX_FIND_INT2		; port number
	push bc
	
	rst CALLBAS
	defw ZX_FIND_INT2		; stream number
	push bc
	jp F_accept_impl

;-------------------------------------------------------------------------
; F_fopen: Opens a file
; Syntax is %fopen #stream, "filename","filemode"
F_fopen
        rst CALLBAS
        defw ZX_NEXT_CHAR
        cp '#'                          ; # means channel number
        jp nz, PARSE_ERROR
        rst CALLBAS
        defw ZX_NEXT_CHAR               ; advance to channel number

        rst CALLBAS
        defw ZX_EXPT1_NUM               ; stream number to open
        cp ','
        jp nz, PARSE_ERROR
        rst CALLBAS
        defw ZX_NEXT_CHAR

        rst CALLBAS
        defw ZX_EXPT_EXP                ; string parameter - filename
        cp ','
        jp nz, PARSE_ERROR
        rst CALLBAS
        defw ZX_NEXT_CHAR

        rst CALLBAS
        defw ZX_EXPT_EXP		; string parameter - file mode

        call STATEMENT_END

	;---------- runtime ---------
	rst CALLBAS
	defw ZX_STK_FETCH		; file mode and flags
	push bc
	push de

	rst CALLBAS
	defw ZX_STK_FETCH		; filename
	push bc				; save length
	push de				; and source

        rst CALLBAS
        defw ZX_FIND_INT2		; stream
	push bc				; save stream
	jp F_fileopen_impl

;------------------------------------------------------------------------
; F_opendir: Opens a directory
; Syntax is %opendir #stream, "dirname"
F_opendir
	rst CALLBAS
        defw ZX_NEXT_CHAR
        cp '#'                          ; # means channel number
        jp nz, PARSE_ERROR
        rst CALLBAS
        defw ZX_NEXT_CHAR               ; advance to channel number

        rst CALLBAS
        defw ZX_EXPT1_NUM               ; stream number to open
        cp ','
        jp nz, PARSE_ERROR
        rst CALLBAS
        defw ZX_NEXT_CHAR

        rst CALLBAS
        defw ZX_EXPT_EXP                ; string parameter - directory

	call STATEMENT_END

	;---------- runtime ----------
	rst CALLBAS
	defw ZX_STK_FETCH		; directory name
	push bc				; save length and string ptr
	push de
	
	rst CALLBAS
	defw ZX_FIND_INT2		; stream
	push bc
	jp F_opendir_impl
	
;-------------------------------------------------------------------------
; F_close: Closes an open stream.
; Syntax is %close stream
F_close
	rst CALLBAS
	defw ZX_NEXT_CHAR
	cp '#'			; expect channel number
	jp nz, PARSE_ERROR
	rst CALLBAS
	defw ZX_NEXT_CHAR	; advance to channel number

	rst CALLBAS
	defw ZX_EXPT1_NUM	; Check for a number
	call STATEMENT_END	; followed by the end of the command

	; Runtime
	rst CALLBAS
	defw ZX_FIND_INT2	; Get the 16 bit integer (stream number)
	push bc			; save it on the stack
	jp F_close_impl		; Jump to the meat of the routine

;------------------------------------------------------------------------
; F_oneof: Sets the line number to go to on EOF.
; Syntax is %oneof linenumber
F_oneof
	rst CALLBAS
	defw ZX_EXPT1_NUM	; Line number
	call STATEMENT_END

	; Runtime
	call F_fetchpage
	jr c, .memerr
	rst CALLBAS
	defw ZX_FIND_INT2	; get the line number
	ld (oneof_line), bc	; set the line number
	ld a, (v_pgb)		; get our page number
	ld (v_eofrom), a	; and set the sysvar
	ld hl, F_eofhandler
	ld (v_eofaddr), hl	; and the address to call
	call F_leave
	jp EXIT_SUCCESS
.memerr
	call F_leave
	ld hl, STR_nomem
	jp REPORTERR

;--------------------------------------------------------------------------
; Copy a BASIC string to a C string.
; BASIC string in DE, C string (dest) in HL
F_basstrcpy 
        ld a, b                         ; end of string?
        or c
        jr z, .terminate
        ld a, (de)
        ld (hl), a
        inc hl 
        inc de 
        dec bc 
        jr F_basstrcpy
.terminate
        xor a                           ; put the null on the end
        ld (hl), a
        inc hl
        ret

