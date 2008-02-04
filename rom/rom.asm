;The MIT License
;
;Copyright (c) 2008 Dylan Smith
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

; The Spectranet ROM.
;--------------------
; The following files must be included in order, the others don't matter
; which order:
;   zeropage.asm - sets ORG to 0x0000 and provides restart entry points.
;   jumptable.asm - sets ORG to 0x3E00
;   sysvars.asm - sets ORG to 0x3F00
;
; Until w5100_defines is changed to be equ instead of defines, this should
; be included before any of the network library code.

	; Routines for ROM page 0 (chip 0 page 0, lower fixed page)
	include "zeropage.asm"		; Restarts
	include "reset.asm"		; Initialization routines
	include "pager.asm"		; Memory paging routines
	include "w5100_defines.asm"	; Definitions for network hardware
	include "sockdefs.asm"		; Definitions for socket library
	include "w5100_genintfunc.asm"	; general internal functions
	include "w5100_buffer.asm"	; Transmit and receive buffers
	include "w5100_sockalloc.asm"	; socket, accept, close
	include "w5100_sockctrl.asm"	; bind, connect
	include "w5100_rxtx.asm"	; send, recv, sendto, recvfrom, poll

	; Memory map for upper fixed page (chip 3 page 0)
	include "jumptable.asm"		; Jump table (sets org)
	include "sysvars.asm"		; System variables (sets org)
	include "sysdefs.asm"		; General definitions