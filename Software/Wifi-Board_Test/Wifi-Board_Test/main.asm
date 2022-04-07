;
; Wifi-Board_Test.asm
;
; Created: 2022-03-25 8:13:25 PM
; Author : kenqu
;

.org 0x0000
rjmp mainloop
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
reti
rjmp receivecharimmediate
reti
rjmp sendcharacter

; Replace with your application code

mainloop:
	call config
	call loadmessage
	rjmp wait

wait:
	sleep
	rjmp wait
	
config:
    ;clock is 4 MHz, prescaler is /1, clk_per is 4 MHz
	;baudrate = 115200, BAUD = 138.8
	ldi r16, low(138)
	ldi r17, high(138)
	ldi XH, High(USART0_BAUDL)
	ldi XL, Low(USART0_BAUDL)
	st X+, r16
	st X, r17

	;set tx pin PA0 to output
	ldi r16, 0b00000001
	ldi XH, High(PORTA_DIRSET)
	ldi XL, Low(PORTA_DIRSET)
	st X, r16

	;set debug run
	ldi r16, 0b00000001
	ldi XH, High(USART0_DBGCTRL)
	ldi XL, Low(USART0_DBGCTRL)
	st X, r16

	;setup transmit pointer to tx SRAM space 0x6000
	ldi YH, high(SRAM_START)
	ldi YL, low(SRAM_START)

	;setup receive pointer to receive SRAM space 0x6040
	ldi ZH, high(0x6040)
	ldi ZL, low(0x6040)

	;receive size counter set to zero
	ldi r21, 0x00

	;enable tx rx
	ldi r16, 0b11000000
	ldi XH, High(USART0_CTRLB)
	ldi XL, Low(USART0_CTRLB)
	st X, r16

    ret
	
loadmessage:
	;WTG1<CR><LF>
	;load message to SRAM Tx message space, 0x6000-0x603F
	ldi XH, high(SRAM_START)
	ldi XL, low(SRAM_START)
	ldi r16, 'W'

	st X+, r16
	ldi r16, 'I'
	st X+, r16
	ldi r16, 'S'
	st X+, r16
	ldi r16, 'C'
	st X+, r16
	ldi r16, 0x0D
	st X+, r16
	ldi r16, 0x0A
	st X+, r16

	;setup message length counter (r20)
	ldi r20, 0x06

	;enable dreie, rxcie and lbme
	;ldi r16, 0b10101000
	;enable dreie and rxsie
	ldi r16, 0b10100000
	ldi XH, High(USART0_CTRLA)
	ldi XL, Low(USART0_CTRLA)
	st X, r16
	
	;enable global interrupts
	sei

	;return
	ret

removetxinterrupt:
	ldi r16, 0b10000000
	ldi XH, High(USART0_CTRLA)
	ldi XL, Low(USART0_CTRLA)
	st X, r16
	ret

sendcharacter:
	;load tx buffer
	ldi XH, High(USART0_TXDATAL)
	ldi XL, Low(USART0_TXDATAL)
	ld r16, Y+
	st X, r16

	;decrement length counter
	dec r20

	;disable tx interrupt if no tx characters remain
	cpi r20, 0x00
	breq removetxinterrupt

	;return
	reti

receivecharimmediate:
	;shove everything on the stack
	push XH
	push XL
	push r16

	;store the character
	ldi XH, High(USART0_RXDATAL)
	ldi XL, Low(USART0_RXDATAL)
	ld r16, X
	st Z+, r16
	inc r21

	;read everything off the stack
	pop r16
	pop XL
	pop XH

	;return
	reti

receivemessage:
	;read character from rx buffer
	ldi XH, High(USART0_RXDATAL)
	ldi XL, Low(USART0_RXDATAL)
	ld r16, X
	st Z+, r16
	inc r21

	;return if the buffer is empty
	ldi XH, High(USART0_STATUS)
	ldi XL, Low(USART0_STATUS)
	ld r16, X
	sbrs r16, 7
	ret

	;if the buffer is not empty keep reading.
	rjmp receivemessage