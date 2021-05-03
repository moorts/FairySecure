CNTA	EQU	00H		;judge whether 4 cols have shown completely
CNTB	EQU	01H		;number in second bit
CNTC	EQU	02H		;number in first bit
Binit	EQU	03H		;judge whether 4 cols have shown completely
Cinit	EQU	04H		;judge whether 4 cols have shown completely
numR	EQU	05H		; first number in LED
numL	EQU	06H		;second number in LED
CNTF	EQU	07H		;0 for first bit, 1 for second bit

CHAR_COUNT EQU 69H
INPUT_ADDR EQU 38h



	org	0
	mov	CNTF, #0
	jmp	start

RS	bit	P3.0
RW	bit	P3.1
E	bit	P3.2
D	equ	P1

cmd	macro	cmd_code
	setb	E
	mov	D, cmd_code
	clr	E
endm

println macro string
	LOCAL message
	LOCAL jmp_over
	jmp jmp_over
	message: db string,0
	jmp_over:
	mov DPTR, #message
	call print_message
endm

print macro string
	LOCAL message
	LOCAL jmp_over
	jmp jmp_over
	message: db string,0
	jmp_over:
	mov DPTR, #message
	call append_message
endm

passwd: db 11,8,1,5,0
spacing: db '000000000000000000000000'

start:
mov CHAR_COUNT, #00h
mov INPUT_ADDR, #20h
println 'Please enter a password: '
mov R0, #20h
waiting_for_input:
	mov P2, #0F0h
	mov A, P2
	cjne A, #0f0h, key_pressed
	sjmp waiting_for_input

key_pressed:
	lcall	read_keypad
	mov	A, R5
	cjne A, #0ch, continue
	jmp check_passwd
	continue:
	mov R0, INPUT_ADDR
	mov @R0, A
	print '*'
	inc INPUT_ADDR

waiting_for_unpress:
	mov P2, #0F0h
	mov A, P2
	cjne A, #0f0h, waiting_for_unpress
	sjmp waiting_for_input

check_passwd:
	mov DPTR, #passwd
	mov R0, #00h
	mov R1, #20h
compare_passwd_loop:
	mov A, R0
	movc A, @A+DPTR
	cjne A, #00h, next
	jmp correct_password
next:
	mov B, @R1
	cjne A, B, wrong_passwd
	inc R0
	inc R1
	jmp compare_passwd_loop

correct_password:
println 'Welcome to FairySecures secret data depot!'
jmp eop

wrong_passwd:
println 'Sorry, wrong password. Fuck off!'
jmp eop



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

print_message:
mov CHAR_COUNT, #00h
mov D, #0
clr RW

main: clr	RS
	cmd	#00000001b	; Clear display
	cmd	#00000010b	; Cursor home
	cmd	#00000110b	; Entry mode set
	cmd	#00001111b	; Display ON/OFF control
	cmd	#00011110b	; Cursor/display shift
	cmd	#00111100b	; Function set
	cmd	#10000001b	; Set DDRAM address

setb RS
mov R0, #0
mov R1, CHAR_COUNT
println:
	cjne R1, #28h, line_limit_not_reached
	mov R2, #0
spacing_loop_println:
	cmd A
	inc R2
	cjne R2, #18h, spacing_loop_println
	mov R1, #00h
line_limit_not_reached:
	mov	A, R0
	inc	R0
	movc	A, @A+DPTR
	cjne 	A, #0, println_char
	mov CHAR_COUNT, R1
	ret
	println_char:
	cmd	A
	inc R1
	jmp println


append_message:
mov D, #0

mov R0, #0
mov R1, CHAR_COUNT
print:
	cjne R1, #28h, global_line_limit_not_reached
	mov R2, #0
spacing_loop_print:
	cmd A
	inc R2
	cjne R2, #18h, spacing_loop_print
	mov R1, #00h
global_line_limit_not_reached:
	mov	A, R0
	inc	R0
	movc	A, @A+DPTR
	cjne	A, #0, print_char
	mov CHAR_COUNT, R1
	ret
print_char:
	cmd	A
	inc R1
	jmp print

eop:
	nop

	end