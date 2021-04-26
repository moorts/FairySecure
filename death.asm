CNTA	EQU	00H		;judge whether 4 cols have shown completely
CNTB	EQU	01H		;number in second bit
CNTC	EQU	02H		;number in first bit
Binit	EQU	03H		;judge whether 4 cols have shown completely
Cinit	EQU	04H		;judge whether 4 cols have shown completely
numR	EQU	05H		; first number in LED
numL	EQU	06H		;second number in LED
CNTF	EQU	07H		;0 for first bit, 1 for second bit

	org	0
	mov	CNTF, #0
	jmp	start


start:
mov R0, #20h
waiting_for_input:
	mov P2, #0F0h
	mov A, P2
	cjne A, #0f0h, key_pressed
	sjmp waiting_for_input

key_pressed:
	lcall	read_keypad
	mov	A, R5
	mov @R0, A
	inc R0

waiting_for_unpress:
	mov P2, #0F0h
	mov A, P2
	cjne A, #0f0h, waiting_for_unpress
	sjmp waiting_for_input

; Reads currently pressed key, stores result in R5
read_keypad:
	mov	R5, #0h
	mov	a, #0feh
	mov	R7, #0h
loop:
	mov	P2, a
	mov	B, P2
	mov	C, B.4
	jc	check_second
	mov	R4, #1h
	jmp	after
check_second:
	mov	C, B.5
	jc	check_third
	mov	R4, #2h
	jmp	after
check_third:
	mov	C, B.6
	jc	no_keypress
	mov	R4, #3h
	jmp	after
no_keypress:
	inc	R7
	inc	R7
	inc	R7
	rl	a
	cjne	a, #0efh, loop
	ret
after:
	mov	b, a
	mov	a, R7
	add	a, R4
	mov	R5, a
	mov	a, b
	ret

eop:
	nop

	end