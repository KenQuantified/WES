;
; MainBoardCode.asm
;
; Created: 2022-04-01 7:13:18 PM
; Author : kenqu
;

;define SRAM storage locations for sensor data
.equ TEMP_1 = 0x6000 ;three bytes PT
.equ TEMP_2 = 0x6003 ;three bytes HT
.equ PRESSURE = 0x6006 ;six bytes
.equ HUMIDITY = 0x600D ;three bytes
.equ CURRENT = 0x6011 ;two bytes
.equ PT_Address = 0x63
.equ HT_Address = 0x44

;define SPI data storage locations
.equ SPI_TX = 0x6050
.equ SPI_RX = 0x6060

;setup interrupt vectors
.org 0x0000
rjmp init
.org NMI_vect
reti
.org BOD_VLM_vect
reti
.org RTC_CNT_vect
reti
.org RTC_PIT_vect
reti
.org CCL_CCL_vect
reti
.org PORTA_PORT_vect
reti
.org TCA0_OVF_vect
reti
.org TCA0_HUNF_vect
reti
.org TCA0_LCMP0_vect
reti
.org TCA0_LCMP1_vect
reti
.org TCA0_LCMP2_vect
reti
.org TCB0_INT_vect
reti
.org TCB1_INT_vect
reti
.org TCD0_OVF_vect
reti
.org TCD0_TRIG_vect
reti
.org TWI0_TWIS_vect
reti
.org TWI0_TWIM_vect
rjmp twiinterrupt
.org SPI0_INT_vect
reti
.org USART0_RXC_vect
reti
.org USART0_DRE_vect
reti
.org USART0_TXC_vect
reti
.org PORTD_PORT_vect
reti
.org AC0_AC_vect
reti
.org ADC0_RESRDY_vect
rjmp readadcresult
.org ADC0_WCMP_vect
reti
.org ZCD0_ZCD_vect
reti
.org PTC_PTC_vect
reti
.org AC1_AC_vect
reti
.org PORTC_PORT_vect
reti
.org TCB2_INT_vect
reti
.org USART1_RXC_vect
reti
.org USART1_DRE_vect
reti
.org USART1_TXC_vect
reti
.org PORTF_PORT_vect
reti
.org NVMCTRL_EE_vect
reti
.org SPI1_INT_vect
reti
.org USART2_RXC_vect
reti
.org USART2_DRE_vect
reti
.org USART2_TXC_vect
reti
.org AC2_AC_vect
reti

;initialize controller at start
init:
	;configure PORT A
	ldi r16, 0b00000100 ;disable input
	ldi XH, High(PORTA_PINCONFIG)
	ldi XL, Low(PORTA_PINCONFIG)
	st X, r16
	ldi r16, 0b00000011 ;disable ports PA0 and PA1
	ldi XH, High(PORTA_PINCTRLUPD)
	ldi XL, Low(PORTA_PINCTRLUPD)
	st X, r16
	;PA7 PA6 PA4 PA3 and PA2 are outputs
	ldi r16, 0b11011100
	ldi XH, High(PORTA_DIRSET)
	ldi XL, Low(PORTA_DIRSET)
	st X, r16

	;configure PORT C
	;nothing on PORT C
	ldi r16, 0b11111111
	ldi XH, High(PORTC_PINCTRLUPD)
	ldi XL, Low(PORTC_PINCTRLUPD)
	st X, r16

	;configure PORT D
	;PORT D has the current sensor on PD2 and nothing else.
	ldi r16, 0b11111011 ;disable all except PD2
	ldi XH, High(PORTD_PINCTRLUPD)
	ldi XL, Low(PORTD_PINCTRLUPD)
	st X, r16

	;configure PORT F
	;nothing on PORT F
	ldi r16, 0b11111111 ;disable all
	ldi XH, High(PORTF_PINCTRLUPD)
	ldi XL, Low(PORTF_PINCTRLUPD)
	st X, r16

	;configure ADC
	;Configure CTRLA
	ldi r16, 0b00000000 ;stby off, single ended, RA, 12-bit, on-command, disabled (for now)
	ldi XH, High(ADC0_CTRLA)
	ldi XL, Low(ADC0_CTRLA)
	st X, r16
	;CTRLB is default, no accumulation
	;Configure CTRLC
	ldi r16, 0x0D ;slow down the clock, divide by 256 for ADC
	ldi XH, High(ADC0_CTRLC)
	ldi XL, Low(ADC0_CTRLC)
	st X, r16
	;CTRLD is default, no delay in init or sampling
	;CTRLE is default, no window comparison
	;SAMPCTRL is default
	;PD2 is AIN2
	ldi r16, 0x02 ;Set AIN2 to the ADC +input
	ldi XH, High(ADC0_MUXPOS)
	ldi XL, Low(ADC0_MUXPOS)
	st X, r16
	ldi r16, 0x40 ;Set GND to the ADC -input
	ldi XH, High(ADC0_MUXNEG)
	ldi XL, Low(ADC0_MUXNEG)
	st X, r16
	;enable debug mode
	ldi r16, 0x01
	ldi XH, High(ADC0_DBGCTRL)
	ldi XL, Low(ADC0_DBGCTRL)
	st X, r16
	;enable result interrupt
	ldi r16, 0x01 ;set the result interrupt on
	ldi XH, High(ADC0_INTCTRL)
	ldi XL, Low(ADC0_INTCTRL)
	st X, r16
	;Enable ADC
	ldi r16, 0b00000001 ;stby off, single ended, RA, 12-bit, on-command, Enable
	ldi XH, High(ADC0_CTRLA)
	ldi XL, Low(ADC0_CTRLA)
	st X, r16

	;configure TWI(I2C)
	;setup SDASETUP and SDAHOLD in CTRLA
	ldi r16, 0b00000000 ;i2c mode, 4cycle SDA Setup, no SDA Hold, FM+ Disabled
	ldi XH, High(TWI0_CTRLA)
	ldi XL, Low(TWI0_CTRLA)
	st X, r16
	;enable debug mode
	ldi r16, 0x01
	ldi XH, High(TWI0_DBGCTRL)
	ldi XL, Low(TWI0_DBGCTRL)
	st X, r16
	;set MBAUD ;400 kHz, SM/FM/FM+, BAUD of 2 should be okay?
	ldi r16, 0x02
	ldi XH, High(TWI0_MBAUD)
	ldi XL, Low(TWI0_MBAUD)
	st X, r16

	sei
	rjmp runloop

runloop:
	rjmp runloop

enabletwi:
	;enable r/w interrupts and master
	cli
	ldi r16, 0b11000001 ;interrupts on, QC off, timeout off, SM disabled, Enable master
	ldi XH, High(TWI0_MCTRLA)
	ldi XL, Low(TWI0_MCTRLA)
	st X, r16
	;Idle the bus (set MSTATUS BUSSTATE to 0x01)
	ldi r16, 0b00000001
	ldi XH, High(TWI0_MSTATUS)
	ldi XL, Low(TWI0_MSTATUS)
	st X, r16
	sei

	ret
    
disabletwi:
	cli
	ldi r16, 0b00000000 ;interrupts off, QC off, timeout off, SM disabled, disable master
	ldi XH, High(TWI0_MCTRLA)
	ldi XL, Low(TWI0_MCTRLA)
	st X, r16
	sei

	ret

twiinterrupt:
	cli
	ldi XH, High(TWI0_MSTATUS)
	ldi XL, Low(TWI0_MSTATUS)
	ld r17, X
	sbrc r17, 7
	call readtwi
	sbrc r17, 6
	call writetwi
	sei

	reti

readtwi:
	ldi XH, High(TWI0_MDATA)
	ldi XL, Low(TWI0_MDATA)
	ld r16, X

	ret

writetwi:
	ldi r16, 0xFD
	ldi XH, High(TWI0_MDATA)
	ldi XL, Low(TWI0_MDATA)
	ld r16, X
	
	ret

runadc:
	ldi r16, 0x01 ;start conversion
	ldi XH, High(ADC0_COMMAND)
	ldi XL, Low(ADC0_COMMAND)
	st X, r16

	ret

readadcresult:
	push r16
	push XH
	push XL

	;read results to SRAM
	ldi XH, High(ADC0_RESL)
	ldi XL, Low(ADC0_RESL)
	ld r16, X
	ldi XH, High(ADC0_RESH)
	ldi XL, Low(ADC0_RESH)
	ld r17, X
	ldi XH, High(CURRENT)
	ldi XL, Low(CURRENT)
	st X+, r17
	st X, r16

	pop XL
	pop XH
	pop r16

	reti