;----------------------------------------------------------------------------------
;-- (c) Rajesh Panicker
;--	License terms :
;--	You are free to use this code as long as you
;--		(i) DO NOT post it on any public repository;
;--		(ii) use it only for educational purposes;
;--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of ARM Holdings or other entities.
;--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
;--		(v) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
;--		(vi) retain this notice in this file or any files derived from this.
;----------------------------------------------------------------------------------

	AREA    MYCODE, CODE, READONLY, ALIGN=9 
   	  ENTRY
	  
; ------- <code memory (ROM mapped to Instruction Memory) begins>
; Total number of instructions should not exceed 127 (126 excluding the last line 'halt B halt').

; This sample program prints "Welcome to CG3207" in response to "A\r" (A+Enter) received from Console. There should be sufficient time gap between the press of 'A' and '\r'
		LDR R6, ZERO	; R6 stores the constant 0, which we need frequently as we do not have MOV implemented. Hence, something like MOV R1, #4 is accomplished by ADD R1, R6, #4
		LDR R7, LSB_MASK ; A mask for extracting out the LSB to check for '\0'
		LDR R8, CONSOLE_OUT_ready	; UART ready for output flag
		LDR R9, CONSOLE_IN_valid	; UART new data flag
		LDR R10, CONSOLE		; UART
		LDR R11, SEVENSEG
		LDR R12, LEDS
		
WAIT_A	
		LDR R3, [R10, #4]	; read the new character flag | Basic: Load with positive immediate
		ADD R2, R3, R6		; R2 = R3 + 0 | Basic: DP with register 
		CMP R2, #0 		; check if there is a new character
		BEQ	WAIT_A		; go back and wait if there is no new character
		LDR R3, [R10]	; read UART (first character. 'A' - 0x41 expected)
		
ECHO_A
		LDR R4, [R8]
		AND R2, R4, #0x01 ; R2 = R4 | Basic: DP with immediate
		CMP R2, #0
		BEQ ECHO_A
		STR R3, [R12, #0x0C]	; echo received character to the console | Basic: Store with positive immediate
		STR R3, [R11]	; show received character (ASCII) on the 7-Seg display
		CMN R3, #'A'	; Improvement: CMN
		BNE WAIT_A		; not 'A'. Continue waiting
		
WAIT_CR					; 'A' received. Need to wait for '\r' (Carriage Return - CR).
		LDR R3, [R8, #-4]	; read the new character flag | Improvement: Load with negative offset
		CMP R3, #0 		; check if there is a new character
		BEQ	WAIT_CR		; go back and wait if there is no new character
		LDR R3, [R10] 	; read UART (second character. '\r' expected)
		
		ADD R2, R1, R9, ROR #0x01	; Improvement: DP with immediate-shifted register
		ORR R1, R2, R5, ASR #0x02	; Improvement: DP with immediate-shifted register
		AND R2, R3, R5, LSL #0x04	; Improvement: DP with immediate-shifted register
		
ECHO_CR
		LDR R4, [R8]
		CMP R4, #0
		BEQ ECHO_CR
		STR R3, [R9, #-4]	; echo received character to the console | Improvement: Store with negative offset
		STR R3, [R11]	; show received character (ASCII) on the 7-Seg display
		CMP R3, #'A'	; perhaps the user is trying again before completing the pervious attempt, or 'A' was repeated. Just a '\r' needed as we already got an 'A'
		BEQ WAIT_CR		; wait for '\r' 
		CMP R3, #'\r'	; Check if the second character is '\r'
		LDR R0, stringptr	; R0 stores the value to be displayed. This is the argument passed to PRINT_S
		ADD R14, R15, #0 ; Storing the return value manually since we do not have BL
		BEQ PRINT_S		; "A\r" received. Call PRINT_S subroutine
		B WAIT_A		; not the correct pattern. try again.
		
; P the null-terminated string at a location pointed to be R0 onto the console.
; It is a good idea to 'push' the registers used by this function to the 'stack'.
; A stack can be simulated by using R13 as a stack pointer. Loading and storing should be accompanied by manually decrementing/incrementing R13. Only one value can be 'push'ed or 'pop'ed at a time.
PRINT_S					
		LDR R1, [R0]	; load the word (4 characters) to be displayed
		;STR	R1, [R11]	; write to seven segment display
		ADD R3, R6, #4	; byte counter
NEXTCHAR
		LDR R4, [R8]	; check if CONSOLE is ready to send a new character
		CMP R4, #0
		BEQ NEXTCHAR	; not ready, continue waiting
		ANDS R2, R1, R7 ; apply LSB_MASK
		BEQ DONE_PRINT_S ; null terminator ('\0') detected
		STR	R1, [R10]	; write to UART the Byte[4-R3] of the original word (composed of 4 characters) in [7:0] of the word to be written (remember, we can only write words, and LEDs/UART displays only [7:0] of the written word)
		;STR	R1, [R12]	; write to LEDS
		ADD R1, R6, R1, LSR #8 ; shift so that the next character comes into LSB
		SUBS R3, #1
		BNE NEXTCHAR	; check and print the next character
		ADD R0, #4	; point to next word (4 characters)
		B PRINT_S
DONE_PRINT_S
		ADD R15, R14, #0 ; return from the subroutine

halt	
		B    halt           ; infinite loop to halt computation. // A program should not "terminate" without an operating system to return control to
							; keep halt	B halt as the last line of your code.
; ------- <\code memory (ROM mapped to Instruction Memory) ends>


	AREA    CONSTANTS, DATA, READONLY, ALIGN=9 
; ------- <constant memory (ROM mapped to Data Memory) begins>
; All constants should be declared in this section. This section is read only (Only LDR, no STR).
; Total number of constants should not exceed 128 (124 excluding the 4 used for peripheral pointers).
; If a variable is accessed multiple times, it is better to store the address in a register and use it rather than load it repeatedly.

;Peripheral pointers
LEDS
		DCD 0x00000C00		; Address of LEDs. //volatile unsigned int * const LEDS = (unsigned int*)0x00000C00;  
DIPS
		DCD 0x00000C04		; Address of DIP switches. //volatile unsigned int * const DIPS = (unsigned int*)0x00000C04;
PBS
		DCD 0x00000C08		; Address of Push Buttons. Used only in Lab 2
CONSOLE
		DCD 0x00000C0C		; Address of UART. Used only in Lab 2 and later
CONSOLE_IN_valid
		DCD 0x00000C10		; Address of UART. Used only in Lab 2 and later
CONSOLE_OUT_ready
		DCD 0x00000C14		; Address of UART. Used only in Lab 2 and later
SEVENSEG
		DCD 0x00000C18		; Address of 7-Segment LEDs. Used only in Lab 2 and later

; Rest of the constants should be declared below.
ZERO
		DCD 0x00000000		; constant 0
LSB_MASK
		DCD 0x000000FF		; constant 0xFF
DELAY_VAL
		DCD 0x00000002		; delay time.
variable1_addr
		DCD variable1		; address of variable1. Required since we are avoiding pseudo-instructions // unsigned int * const variable1_addr = &variable1;
constant1
		DCD 0xABCD1234		; // const unsigned int constant1 = 0xABCD1234;
string1   
		DCB  "\r\nWelcome to CG3207..\r\n",0	; // unsigned char string1[] = "Hello World!"; // assembler will issue a warning if the string size is not a multiple of 4, but the warning is safe to ignore
stringptr
		DCD string1			;
		
; ------- <constant memory (ROM mapped to Data Memory) ends>	


	AREA   VARIABLES, DATA, READWRITE, ALIGN=9
; ------- <variable memory (RAM mapped to Data Memory) begins>
; All variables should be declared in this section. This section is read-write.
; Total number of variables should not exceed 128. 
; No initialization possible in this region. In other words, you should write to a location before you can read from it (i.e., write to a location using STR before reading using LDR).

variable1
		DCD 0x00000000		;  // unsigned int variable1;
; ------- <variable memory (RAM mapped to Data Memory) ends>	

		END	
		
;const int* x;         // x is a non-constant pointer to constant data
;int const* x;         // x is a non-constant pointer to constant data 
;int*const x;          // x is a constant pointer to non-constant data
		