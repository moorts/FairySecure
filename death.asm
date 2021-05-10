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

developer_mode equ 1

; How to hack this program:
; Step 1) Dump contents of program memory (use your imagination to find the correct sequence of bytes)
; Step 2) Bypass our incredibly secure obfuscation thechnique
; Step 2) ???
; Step 3) Profit

	org	0
	mov	CNTF, #0
	jmp	start

RS	bit	P3.0
RW	bit	P3.1
E	bit	P3.2
D	equ	P1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;      REAL SHIT                                      ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

movr macro reg1, reg2
	mov B, A
	mov A, reg2
	mov reg1, A
	mov A, B
endm

passwd: db 11,8,1,5,0

start:
ifdef developer_mode
	jmp calculator
endif
	; Load password to program memory
	mov R0, #10h
	mov R1, #00h
	mov DPTR, #passwd
read_passwd_character:
	mov A, R1
	movc A, @A+DPTR
	mov @R0, A
	inc R0
	inc R1
	cjne A, #0, read_passwd_character
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;      LOGIN SYSTEM                                   ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

login:
	call choice_waiting_for_unpress
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
	mov R0, #10h
	mov R1, #20h
compare_passwd_loop:
	mov A, @R0
	cjne A, #00h, next
	jmp correct_password
next:
	mov B, @R1
	cjne A, B, wrong_passwd
	inc R0
	inc R1
	jmp compare_passwd_loop

correct_password:
println 'Welcome to FairySecures secret data depot! Select your desired option.'
jmp menu

wrong_passwd:
println 'Try again!'
jmp login

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;      USER MENU                                      ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menu:
call choice_waiting_for_unpress
first_option:
	println '1) Do stuff'
	call get_character
	cjne A, #02h, first_check_down
	jmp third_option
first_check_down:
	cjne A, #08h, first_check_execute
	jmp second_option
first_check_execute:
	cjne A, #0ch, first_option
	jmp execute_first

second_option:
	println '2) Change password'
	call get_character
	cjne A, #02h, second_check_down
	jmp first_option
second_check_down:
	cjne A, #08h, second_check_execute
	jmp third_option
second_check_execute:
	cjne A, #0ch, second_option
	jmp execute_second

third_option:
	println '3) Logout'
	call get_character
	cjne A, #02h, third_check_down
	jmp second_option
third_check_down:
	cjne A, #08h, third_check_execute
	jmp first_option
third_check_execute:
	cjne A, #0ch, third_option
	jmp execute_third

execute_first:
nop
execute_second:
	println 'Enter new password: '
	mov R0, #10h
enter_character:
	call get_character
	cjne A, #0ch, save_character
	jmp passwd_entered
save_character:
	mov R7, A
	mov A, R0
	mov R6, A
	print '*'
	mov A, R6
	mov R0, A
	mov A, R7
	mov @R0, A
	inc R0
	jmp enter_character

passwd_entered:
	mov @R0, #00h
	println 'Password successfully changed!'
	jmp menu
execute_third:
jmp login


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;      CALCULATOR                                     ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

calculator:
	println 'Please enter first number to add: '
	mov R2, #00h
	mov R3, #00h
next_digit:
	call get_character
	mov R6, #00h
	mov R7, A
	movr R4, R2
	movr R5, R3
	call ADD16_16
	jmp next_digit
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;      16 Bit Mathamphetamine                                     ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MUL16_16: 
 ;Multiply R5 by R7
 MOV A,R5 ;Move the R5 into the Accumulator
 MOV B,R7 ;Move R7 into B
 MUL AB   ;Multiply the two values
 MOV R2,B ;Move B (the high-byte) into R2
 MOV R3,A ;Move A (the low-byte) into R3

 ;Multiply R5 by R6
 MOV A,R5    ;Move R5 back into the Accumulator
 MOV B,R6    ;Move R6 into B
 MUL AB      ;Multiply the two values
 ADD A,R2    ;Add the low-byte into the value already in R2
 MOV R2,A    ;Move the resulting value back into R2
 MOV A,B     ;Move the high-byte into the accumulator
 ADDC A,#00h ;Add zero (plus the carry, if any)
 MOV R1,A    ;Move the resulting answer into R1
 MOV A,#00h  ;Load the accumulator with  zero
 ADDC A,#00h ;Add zero (plus the carry, if any)
 MOV R0,A    ;Move the resulting answer to R0.

 ;Multiply R4 by R7
 MOV A,R4   ;Move R4 into the Accumulator
 MOV B,R7   ;Move R7 into B
 MUL AB     ;Multiply the two values
 ADD A,R2   ;Add the low-byte into the value already in R2
 MOV R2,A   ;Move the resulting value back into R2
 MOV A,B    ;Move the high-byte into the accumulator
 ADDC A,R1  ;Add the current value of R1 (plus any carry)
 MOV R1,A   ;Move the resulting answer into R1.
 MOV A,#00h ;Load the accumulator with zero
 ADDC A,R0  ;Add the current value of R0 (plus any carry)
 MOV R0,A   ;Move the resulting answer to R1.

 ;Multiply R4 by R6
 MOV A,R4  ;Move R4 back into the Accumulator
 MOV B,R6  ;Move R6 into B
 MUL AB    ;Multiply the two values
 ADD A,R1  ;Add the low-byte into the value already in R1
 MOV R1,A  ;Move the resulting value back into R1
 MOV A,B   ;Move the high-byte into the accumulator
 ADDC A,R0 ;Add it to the value already in R0 (plus any carry)
 MOV R0,A  ;Move the resulting answer back to R0

 ;Return - answer is now in R0, R1, R2, and R3
 RET

 ADD16_16:
    ;Step 1 of the process
    MOV A,R7     ;Move the low-byte into the accumulator
    ADD A,R5     ;Add the second low-byte to the accumulator
    MOV R3,A     ;Move the answer to the low-byte of the result

    ;Step 2 of the process
    MOV A,R6     ;Move the high-byte into the accumulator
    ADDC A,R4    ;Add the second high-byte to the accumulator, plus carry.
    MOV R2,A     ;Move the answer to the high-byte of the result

    ;Step 3 of the process
    MOV A,#00h   ;By default, the highest byte will be zero.
    ADDC A,#00h  ;Add zero, plus carry from step 2. 
    MOV R1,A ;Move the answer to the highest byte of  the result

    ;Return - answer now resides in R1, R2, and R3.
    RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;      HELPER / IO FUNCTIONS                          ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

get_character:
	mov P2, #0F0h
	mov A, P2
	cjne A, #0f0h, choice_entered
	jmp get_character

choice_entered:
	call	read_keypad
	mov	A, R5
	mov B, A
	call choice_waiting_for_unpress
	mov A, B
	ret

choice_waiting_for_unpress:
	mov P2, #0F0h
	mov A, P2
	cjne A, #0f0h, choice_waiting_for_unpress
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