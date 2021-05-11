; _____           _    
;|  ___|   _  ___| | __
;| |_ | | | |/ __| |/ /
;|  _|| |_| | (__|   < 
;|_|   \__,_|\___|_|\_\
;                      
;     _                                       _        _   _             
;  __| | ___   ___ _   _ _ __ ___   ___ _ __ | |_ __ _| |_(_) ___  _ __  
; / _` |/ _ \ / __| | | | '_ ` _ \ / _ \ '_ \| __/ _` | __| |/ _ \| '_ \ 
;| (_| | (_) | (__| |_| | | | | | |  __/ | | | || (_| | |_| | (_) | | | |
; \__,_|\___/ \___|\__,_|_| |_| |_|\___|_| |_|\__\__,_|\__|_|\___/|_| |_|
;

CHAR_COUNT EQU 69H
INPUT_ADDR EQU 38h

precision  equ 4

developer_mode equ 1

; How to hack this program:
; Step 1) Dump contents of program memory (use your imagination to find the correct sequence of bytes)
; Step 2) Bypass our incredibly secure obfuscation thechnique
; Step 2) ???
; Step 3) Profit

	org	0
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

cje macro arg1, arg2, label
	LOCAL dont_jump
	cjne arg1, arg2, dont_jump
	ljmp label
	dont_jump:
endm
	

passwd: db 11,8,1,5,0
ascii_values: db 48,49,50,51,52,53,54,55,56,57,69,48

start:
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
	println '1) Calculator'
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
	jmp calculator
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
	println 'Please enter first number: '
	mov R2, #00h
	mov R3, #00h
next_digit:
	call get_character
	mov DPTR, #ascii_values
	mov 40h, A
	cje A, #0ch, select_operator
	call print_character
	mov R6, #00h
	mov R7, #0ah
	movr R4, R2
	movr R5, R3
	call MUL16_16
	mov A, 40h
	cjne A, #0bh, not_zero_first
	mov A, #00h
not_zero_first:
	mov R6, #00h
	mov R7, A
	movr R4, R2
	movr R5, R3
	call ADD16_16
	jmp next_digit
select_operator:
	mov 38h, R2
	mov 39h, R3
	println '1\x3a +   2\x3a -   3\x3a *   4\x3a /'
	call get_character
	mov 3ah, A
second_number:
	println 'Please enter second number: '
	mov R2, #00h
	mov R3, #00h
second_number_next_digit:
	call get_character
	mov DPTR, #ascii_values
	mov 40h, A
	cje A, #0ch, calculate
	call print_character
	mov R6, #00h
	mov R7, #0ah
	movr R4, R2
	movr R5, R3
	call MUL16_16
	mov A, 40h
	cjne A, #0bh, not_zero
	mov A, #00h
not_zero:
	mov R6, #00h
	mov R7, A
	movr R4, R2
	movr R5, R3
	call ADD16_16
	jmp second_number_next_digit
calculate:
	movr R4, R2
	movr R5, R3
	mov R6, 38h
	mov R7, 39h
	mov A, 3ah
	cje A, #01h, add
	cje A, #02h, sub
	cje A, #03h, mul
	cje A, #04h, div

add:
	call ADD16_16
	jmp print_res
sub:
	call SUB16_16
	jmp print_res
mul:
	call MUL16_16
	jmp print_res
div:
	movr R1, R6
	movr R0, R7
	movr R3, R4
	movr R2, R5
	call DIV16_16
	movr R3, R4
	movr R2, R5
	mov R0, #00h
	mov R1, #00h
	jmp print_res

print_res:
	mov 38h, R3
	mov 39h, R2
	mov 3ah, R1
	mov 3bh, R0
	println 'Result\x3a '
	mov DPTR, #ascii_values
	mov R7, #00h
bin_to_dec:
	call adivr10
	push A
	inc R7
	mov A, #00h
	ORL A, 38h
	ORL A, 39h
	ORL A, 3ah
	ORL A, 3bh
	cje A, #00h, stop
	jmp bin_to_dec
stop:
	pop A
	call print_character
	djnz R7, stop
	print ' ... Press any key to continue'
	call get_character
	jmp menu

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

SUB16_16:
  ;Step 1 of the process
  MOV A,R7  ;Move the low-byte into the accumulator
  CLR C     ;Always clear carry before first subtraction
  SUBB A,R5 ;Subtract the second low-byte from the accumulator
  MOV R3,A  ;Move the answer to the low-byte of the result

  ;Step 2 of the process
  MOV A,R6  ;Move the high-byte into the accumulator
  SUBB A,R4 ;Subtract the second high-byte from the accumulator
  MOV R2,A  ;Move the answer to the low-byte of the result

  ;Return - answer now resides in R2, and R3.
  RET

div16_16:
  CLR C       ;Clear carry initially
  MOV R4,#00h ;Clear R4 working variable initially
  MOV R5,#00h ;CLear R5 working variable initially
  MOV B,#00h  ;Clear B since B will count the number of left-shifted bits
div1:
  INC B      ;Increment counter for each left shift
  MOV A,R2   ;Move the current divisor low byte into the accumulator
  RLC A      ;Shift low-byte left, rotate through carry to apply highest bit to high-byte
  MOV R2,A   ;Save the updated divisor low-byte
  MOV A,R3   ;Move the current divisor high byte into the accumulator
  RLC A      ;Shift high-byte left high, rotating in carry from low-byte
  MOV R3,A   ;Save the updated divisor high-byte
  JNC div1   ;Repeat until carry flag is set from high-byte
div2:        ;Shift right the divisor
  MOV A,R3   ;Move high-byte of divisor into accumulator
  RRC A      ;Rotate high-byte of divisor right and into carry
  MOV R3,A   ;Save updated value of high-byte of divisor
  MOV A,R2   ;Move low-byte of divisor into accumulator
  RRC A      ;Rotate low-byte of divisor right, with carry from high-byte
  MOV R2,A   ;Save updated value of low-byte of divisor
  CLR C      ;Clear carry, we don't need it anymore
  MOV 07h,R1 ;Make a safe copy of the dividend high-byte
  MOV 06h,R0 ;Make a safe copy of the dividend low-byte
  MOV A,R0   ;Move low-byte of dividend into accumulator
  SUBB A,R2  ;Dividend - shifted divisor = result bit (no factor, only 0 or 1)
  MOV R0,A   ;Save updated dividend 
  MOV A,R1   ;Move high-byte of dividend into accumulator
  SUBB A,R3  ;Subtract high-byte of divisor (all together 16-bit substraction)
  MOV R1,A   ;Save updated high-byte back in high-byte of divisor
  JNC div3   ;If carry flag is NOT set, result is 1
  MOV R1,07h ;Otherwise result is 0, save copy of divisor to undo subtraction
  MOV R0,06h
div3:
  CPL C      ;Invert carry, so it can be directly copied into result
  MOV A,R4 
  RLC A      ;Shift carry flag into temporary result
  MOV R4,A   
  MOV A,R5
  RLC A
  MOV R5,A		
  DJNZ B,div2 ;Now count backwards and repeat until "B" is zero
  MOV R3,05h  ;Move result to R3/R2
  MOV R2,04h  ;Move result to R3/R2
  RET

adivr10:
  mov  r2, #precision
  clr  a
  mov  r0, #3ch
ad101:  dec  r0
  xch  a, @r0
  xchd  a, @r0
  swap  a
  mov  b, #10
  div  ab      ;H-Digit /10
  swap  a
  xch  a, @r0
  swap  a
  add  a, b
  swap  a
  mov  b, #10
  div  ab      ;L-Digit /10
  xchd  a, @r0
  mov  a, @r0
  jz  ad102
  clr  f0
ad102:  mov  a, b
  djnz  r2, ad101
  ret

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

print_character:
	mov D, #0

	mov R1, CHAR_COUNT
	cjne R1, #28h, global_line_limit_not_reached_print_char
	mov R2, #0
spacing_loop_print_char:
	cmd A
	inc R2
	cjne R2, #18h, spacing_loop_print_char
	mov R1, #00h
global_line_limit_not_reached_print_char:
	movc	A, @A+DPTR
	cmd	A
	inc R1
	mov CHAR_COUNT, R1
	ret

eop:
	nop

	end