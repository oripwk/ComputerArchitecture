; Computer Architecture and System Programming Laboratory
; Assignemnt 2
; Author: Ori Popowski

%define MAXLINE 80
%define HEX 0
%define BIN 1
%define MAXVAL 5
%define NULL 0

section .rodata

prompt:
	db	"calc: ", 0
inv:
	db	"Error: Invalid input.", 10, 0
not_en:
	db	"Error: Not enough arguments on stack.", 10, 0
div_zer:
	db	"Error: Division by zero.", 10, 0
so:
	db	"Error: Stack overflow.", 10, 0
strn:
	db	"%s", 10, 0
str:
	db	"%s", 0
newline:
	db	10, 0

section .bss

line:
	resb	MAXLINE
stack:
	resd	MAXVAL

section .data

base:
	db	HEX
sp_: ; Stack pointer
	db	0

section .text

	extern malloc
	extern printf
	extern gets
	extern free
	global main

main:
	call	my_calc
end_main:
	mov     eax,1
	int     0x80

; <int my_calc()>
my_calc:
	push 	ebp
	mov	ebp, esp
	sub	esp, 4
	mov	dword [ebp-4], 1	; Count of operations
	
	push	prompt
	call	printf
	add     esp, 4

	push	line
	call	gets
	add	esp, 4

loop1_cond:
	cmp	byte [line], 'q'
	jne	loop1
	cmp	byte [line+1], 0
	je	end_my_calc
loop1:

is_add:
	cmp	byte [line], '+' 
	jne	is_print
	cmp	byte [line+1], 0
	jne	is_print

	inc	dword [ebp-4]
	call	add 
	jmp	loop1_end
is_print:
	cmp	byte [line], 'p'
	jne	is_dup
	cmp	byte [line+1], 0
	jne	is_dup
	
	inc	dword [ebp-4]
	call	pop_print
	jmp	loop1_end
is_dup:
	cmp	byte [line], 'd'
	jne	is_div
	cmp	byte [line+1], 0
	jne	is_div 

	inc	dword [ebp-4]
	call	duplicate
	jmp	loop1_end
is_div:
	cmp	byte [line], '/'
	jne	is_bin
	cmp	byte [line+1], 0
	jne	is_bin

	inc	dword [ebp-4]
	call	divide
	jmp	loop1_end
is_bin:
	cmp	byte [line], 'b'
	jne	is_hex
	cmp	byte [line+1], 0
	jne	is_hex

	inc	dword [ebp-4]
	mov	byte [base], BIN
	jmp	loop1_end
is_hex:
	cmp	byte [line], 'h'
	jne	is_number
	cmp	byte [line+1], 0
	jne	is_number

	inc	dword [ebp-4]
	mov	byte [base], HEX
	jmp	loop1_end
is_number:
	push	line
	call	isnumber
	add	esp, 4

	cmp	eax, 1
	jne	else_		; Not a number

	push	line
	call	asc2bytes
	add	esp, 4

	push	eax
	call	push_
	add	esp, 4
	jmp	loop1_end

else_:
	push	inv
	call	printf
	add	esp, 4

loop1_end:
	push	prompt
	call	printf
	add     esp, 4

	push	line
	call	gets
	add	esp, 4

	jmp	loop1_cond
end_my_calc:
	call	freestack
	mov	eax, [ebp-4]	; Put return val in EAX

	mov	esp, ebp
	pop     ebp             
	ret                     
; <void add()>
; Adds two top-most operands in the stack
add:
	push	ebp
	mov	ebp, esp
	sub	esp, 32		; Save space for local vars

	mov	dword [ebp-4], 0
	mov	dword [ebp-24], NULL
	mov	dword [ebp-28], NULL
	mov	dword [ebp-32], NULL

	cmp	byte [sp_], 2	; If stack has less than 2 items...
	jge	cont_add
	push	not_en		; ...then print error
	call	printf
	add     esp, 4          
	jmp	exit_add
cont_add:
	mov	ebx, [sp_]		
	mov	eax, [stack + (ebx-1)*4]
	mov	[ebp-16], eax		; Set local var to operand1

	mov	eax, [stack + (ebx-2)*4]
	mov	[ebp-20], eax		; Set local var to operand2
loop2_cond:
	cmp	dword [ebp-16], NULL	; While not end of both operands linked lists
	jne	loop2
	cmp	dword [ebp-20], NULL
	je	after_loop2
loop2:
	push 	5
	call	malloc
	add	esp, 4
	mov	[ebp-28], eax

	mov	dword [ebp-8], 0
	mov	dword [ebp-12], 0

	cmp	dword [ebp-16], NULL
	je	L0
	mov	ebx, [ebp-16]
	xor	eax, eax
	mov	al, byte [ebx]		
	mov	dword [ebp-8], eax
L0:
	cmp	dword [ebp-20], NULL
	je	L1
	mov	ebx, [ebp-20]
	xor	eax, eax
	mov	al, byte [ebx]
	mov	dword [ebp-12], eax
L1:
	xor	eax, eax
	add	eax, [ebp-4]
	add	eax, [ebp-8]
	add	eax, [ebp-12]
	xor	ecx, ecx
	mov	ecx, eax

	shr	eax, 8
	mov	[ebp-4], eax
	shl	eax, 8
	sub	ecx, eax
	mov	ebx, [ebp-28]
 	mov	byte [ebx], cl
 	mov	dword [ebx+1], NULL

	cmp	dword [ebp-32], NULL
	jne	L2
	mov	eax, dword [ebp-28]
	mov	[ebp-24], eax
	jmp	L3
L2:
	mov	ebx, [ebp-32]
	mov	eax, [ebp-28]
	mov	[ebx+1], eax
L3:
	mov	eax, [ebp-28]
	mov	[ebp-32], eax

	cmp	dword [ebp-16], NULL
	je	L4
	mov	ebx, [ebp-16]
	mov	eax, [ebx+1]
	mov	[ebp-16], eax
L4:
	cmp	dword [ebp-20], NULL
	je	L5
	mov	ebx, [ebp-20]
	mov	eax, [ebx+1]
	mov	[ebp-20], eax
L5:
	jmp	loop2_cond
after_loop2:
	cmp	dword [ebp-4], 0
	je	L6
	push 	5
	call	malloc
	add	esp, 4

	mov	[ebp-28], eax
	mov	ebx, [ebp-28]
	mov	byte [ebx], 1
	mov	dword [ebx+1], NULL
	mov	ebx, [ebp-32]
	mov	eax, [ebp-28]
	mov	[ebx+1], eax
L6:
	dec	byte [sp_]
	mov	ebx, [sp_]
	push	dword [stack + ebx*4]
	call	freelist
	add	esp, 4

	dec	byte [sp_]
	mov	ebx, [sp_]
	push	dword [stack + ebx*4]
	call	freelist
	add	esp, 4

	push 	dword [ebp-24]
	call	push_
	add	esp, 4
exit_add:
	mov	esp, ebp
	pop 	ebp
	ret
; <void pop-print()>
; Pops the top-most operand from the stack and prints it.    
pop_print:
	push	ebp
	mov	ebp, esp

	cmp	byte [sp_], 1
	jge	cont_pop_print

	push	not_en
	call	printf
	add     esp, 4          
	jmp	exit_add
cont_pop_print:
	dec	byte [sp_]
	mov	ebx, [sp_]
	push 	dword [stack + ebx*4]
	call	print
	call	freelist
	add	esp, 4
exit_pop_print:
	mov	esp, ebp
	pop 	ebp
	ret
; <void duplicate()>
; Duplicates the top-most operand in the stack.
duplicate:
	push	ebp
	mov	ebp, esp
	sub	esp, 16

	mov	dword [ebp-4], NULL
	mov	dword [ebp-8], NULL
	mov	dword [ebp-12], NULL
	mov	dword [ebp-16], NULL

	cmp	byte [sp_], MAXVAL
	jl	cont_duplicate
	push	so
	call	printf
	add	esp, 4
	jmp	duplicate_exit
cont_duplicate:
	cmp	byte [sp_], 1
	jge	cont2_duplicate
	push	not_en
	call	printf
	add	esp, 4
	jmp	duplicate_exit
cont2_duplicate:
	mov	ebx, [sp_]
	mov	eax, [stack + (ebx-1)*4]
	mov	[ebp-4], eax
loop3:
	cmp	dword [ebp-4], NULL
	je	after_loop3

	push	5
	call	malloc
	add	esp, 4

	mov	[ebp-16], eax
	mov	ebx, [ebp-4]
	mov	al, [ebx]
	mov	ebx, [ebp-16]
	mov	byte [ebx], al
	mov	dword [ebx+1], NULL

	cmp	dword [ebp-8], NULL
	jne	L7
	mov	eax, [ebp-16]
	mov	[ebp-8], eax
	jmp	L8
L7:
	mov	ebx, [ebp-12]
	mov	eax, [ebp-16]
	mov	[ebx+1], eax
L8:
	mov	eax, [ebp-16]
	mov	[ebp-12], eax

	mov	ebx, [ebp-4]
	mov	eax, [ebx+1]
	mov	[ebp-4], eax

	jmp	loop3
after_loop3:
	mov	eax, [ebp-8]
	mov	ebx, [sp_]
	mov	[stack + ebx*4], eax

	inc	byte [sp_]
duplicate_exit:
	mov	esp, ebp
	pop 	ebp
	ret
; <void divide()>
; Divides the second to top-most operand by the top-most operand in the
; stack.
divide:
	push 	ebp
	mov	ebp, esp

	sub	esp, 28

	mov	dword [ebp-8], NULL
	mov	dword [ebp-16], NULL
	mov	dword [ebp-20], NULL
	mov	dword [ebp-28], 0

	cmp	byte [sp_], 2	; If stack has less than 2 items...
	jge	cont_divide
      
	push	not_en		; ...then print error
	call	printf
	add     esp, 4          
	jmp	exit_divide
cont_divide:
	mov	ebx, [sp_]
	cmp	dword [stack + (ebx-1)*4], NULL
	jne	cont2_divide
	push 	div_zer
	call	printf
	add	esp, 4
	jmp	exit_divide
cont2_divide:
	mov	ebx, [sp_]
	mov	eax, [stack + (ebx-1)*4]
	mov	[ebp-4], eax

	mov	ebx, [stack + (ebx-2)*4]
	mov	al, byte [ebx]
	mov	byte [ebp-24], al

	push 	dword [ebp-4]
	call	reverse
	add	esp, 4
	mov	[ebp-4], eax
	
	mov	[ebp-12], eax
loop4:
	cmp	dword [ebp-12], NULL
	je	after_loop4

	push	5
	call	malloc
	add	esp, 4
	mov	[ebp-16], eax

	mov	eax, dword [ebp-28]
	div 	byte [ebp-24]

	xor	edx, edx
	mov	dl, ah
	shl	edx, 8
	mov	ebx, [ebp-12]
	xor	ecx, ecx
	mov	cl, byte [ebx]
	add	edx, ecx
	mov	[ebp-28], edx

	mov	eax, [ebp-28]
	div	byte [ebp-24]
	mov	ebx, [ebp-16]
	mov	byte [ebx], al
	mov	dword [ebx+1], NULL

	cmp	dword [ebp-8], NULL
	jne	L9
	mov	eax, [ebp-16]
	mov	[ebp-8], eax
	jmp	L10
L9:
	mov	eax, [ebp-16]
	mov	ebx, [ebp-20]
	mov	[ebx+1], eax
L10:	
	mov	eax, [ebp-16]
	mov	[ebp-20], eax

	mov	ebx, [ebp-12]
	mov	eax, [ebx+1]
	mov	[ebp-12], eax
	jmp	loop4
after_loop4:
	mov	ebx, [sp_]
	push	dword [stack + (ebx-2)*4]
	call	freelist
	add	esp, 4

	push	dword [ebp-4]
	call	freelist
	add	esp, 4

	dec	byte [sp_]
	dec	byte [sp_]

	push 	dword [ebp-8]
	call	reverse
	add	esp, 4

	push 	eax
	call	push_
	add	esp, 4
exit_divide:
	mov	esp, ebp
	pop 	ebp
	ret
; <struct node *asc2bytes(char *s)>
; Take a string 's' representing a number and turns it into a linked-list
; that represents this number in base 256 in reversed order.
asc2bytes:
	push 	ebp
	mov	ebp, esp
	sub	esp, 28 

	mov	dword [ebp-4], NULL
	mov	dword [ebp-8], NULL
	mov	dword [ebp-12], NULL
	mov	dword [ebp-16], 0
	mov	dword [ebp-20], 0
	mov	dword [ebp-24], 0

	cmp	byte [base], HEX
	jne	L11
	mov	dword [ebp-28], 1
	jmp	L12
L11:
	mov	dword [ebp-28], 7
L12:
loop5:
	mov	ebx, [ebp+8]
	mov	eax, [ebp-20]
	cmp	byte [eax+ebx], 0
	je	after_loop5

	inc	dword [ebp-20]
	jmp	loop5
after_loop5:
	dec	dword [ebp-20]

loop6:
	cmp	dword [ebp-20], -1
	jle	after_loop6
	mov	eax, [ebp-20]
	sub	eax, [ebp-28]

	cmp	eax, 0
	jge	L13
	xor	eax, eax
L13:
	mov	[ebp-24], eax
	
	mov	eax, [ebp-20]
	sub	eax, [ebp-24]
	inc	eax
	push	eax

	mov	eax, [ebp+8]
	add	eax, [ebp-24]
	push	eax
	call	asc2int
	add	esp, 8
	mov	[ebp-16], eax

	mov	eax, [ebp-24]
	dec	eax
	mov	[ebp-20], eax

	push 	5
	call	malloc
	add	esp, 4
      
	mov	[ebp-8], eax
	mov	ebx, [ebp-8]
	mov	eax, [ebp-16]
	mov	byte [ebx], al
	mov	dword [ebx+1], NULL

	cmp	dword [ebp-12], NULL
	je	L14
	mov	ebx, [ebp-12]
	mov	eax, [ebp-8]
	mov	dword [ebx+1], eax
	jmp	L15
L14:
	mov	eax, [ebp-8]
	mov	[ebp-4], eax
L15:
	mov	eax, [ebp-8]
	mov	[ebp-12], eax
	jmp	loop6
after_loop6:
	mov	eax, [ebp-4]
	
	mov	esp, ebp
	pop 	ebp
	ret
; <int asc2int(char *s, int q)>
; Takes a string 's' representing a number in a base which specified by
; global variable 'base' and returns it's equivalent integer. It considers
; only the portion of 's' within s[1..q].
asc2int:
	push	ebp
	mov	ebp, esp
	sub	esp, 16
	
	mov	dword [ebp-4], 0

	cmp	byte [base], HEX
	jne	L24
	mov	dword [ebp-12], 4
	jmp	L25
L24:
	mov	dword [ebp-12], 1
L25:
	mov	dword [ebp-16], 0
loop11:
	mov	eax, [ebp-16]
	cmp	eax, [ebp+12]
	jge	after_loop11
	mov	ebx, [ebp-16]
	mov	ecx, [ebp+8]
	xor	eax, eax
	mov	al, byte [ebx+ecx]
	sub	eax, '0'
	cmp	eax, 9
	jle	L26
	sub	eax, 7 
L26:
	mov	ebx, [ebp-4]
	mov	cl, byte [ebp-12]
	shl	ebx, cl
	add	ebx, eax
	mov	[ebp-4], ebx
	inc	dword [ebp-16]
	jmp	loop11
after_loop11:
	mov	eax, [ebp-4]
	mov	esp, ebp
	pop 	ebp
	ret
; <void push(struct node *num)>
; Takes a number in a linked-list representation and pushes it into the stack.
push_:
	push 	ebp
	mov	ebp, esp
	
	cmp	byte [sp_], MAXVAL
	jge	L20
	mov	ebx, [sp_]
	mov	eax, [ebp+8]
	mov	[stack + ebx*4], eax
	inc	byte [sp_]
	jmp	push_exit
L20:
	push	so
	call	printf
	add	esp, 4
push_exit:
	mov	esp, ebp
	pop 	ebp
	ret
; <void print(struct node *head)>
; Takes a number in a linked-list representation and prints its value.
print:
	push	ebp
	mov	ebp, esp

	cmp	dword [ebp+8], NULL
	jne	L22
	push	0
	call	int2asc
	add	esp, 4

	push 	eax
	push 	strn
	call	printf
	add	esp, 8
  
	mov	esp, ebp
	pop 	ebp
	ret
L22:
	push 	dword [ebp+8]
	call	printrec
	add	esp, 4

	push 	newline
	call	printf
	add	esp, 4

	mov	esp, ebp
	pop 	ebp
	ret
; <void printrec(struct node *head)>
; Used by function print to recursively print the number. The recursion here
; is for the convenience of printing the linked-list in reverse order
; (because it is represented in reverse)
printrec:
	push 	ebp
	mov	ebp, esp
	sub	esp, 4

	mov	ebx, [ebp+8]
	xor	eax, eax
	mov	al, byte [ebx]
	push 	eax
	call	int2asc
	add	esp, 4
	mov	[ebp-4], eax

	mov	ebx, [ebp+8]
	cmp	dword [ebx+1], NULL
	je	printrec_exit

	push 	dword [ebx+1]
	call	printrec
	add	esp, 4
printrec_exit:
	push	dword [ebp-4]
	push	str
	call	printf
	add	esp, 8

	push 	dword [ebp-4]
	call	free
	add	esp, 4

	mov	esp, ebp
	pop 	ebp
	ret
; <unsigned char *int2asc(unsigned char n)>
; Takes a byte sized integer and returns an ASCII string which representes it
; according to global variable 'base'.
int2asc:
	push 	ebp
	mov	ebp, esp
	sub	esp, 16

	mov	dword [ebp-16], NULL

	cmp	byte [base], HEX
	jne	L16
	push 	3
	call	malloc
	add	esp, 4
	mov	[ebp-16], eax
	mov	byte [eax+2], 0
	mov	dword [ebp-8], 2
	mov	dword [ebp-12], 16
	jmp	L17
L16:
	push 	9
	call	malloc
	add	esp, 4
	mov	[ebp-16], eax
	mov	byte [eax+8], 0
	mov	dword [ebp-8], 8
	mov	dword [ebp-12], 2
L17:
	mov	dword [ebp-4], 0
loop7:
	mov	ebx, [ebp-4]
	cmp	ebx, [ebp-8]
	jge	after_loop7
	mov	eax, [ebp-16]
	mov	byte [eax+ebx], '0'
	inc	dword [ebp-4]
	jmp	loop7
after_loop7:
	mov	eax, [ebp-8]
	dec	eax
	mov	[ebp-4], eax
loop8:
	cmp	dword [ebp+8], 0
	je	after_loop8
	mov	eax, [ebp+8]
	div 	byte [ebp-12]
	mov	byte [ebp+8], al
	add	ah, '0'
	cmp	ah, '9'
	jle	L18
	add	ah, 7
L18:
	mov	ebx, [ebp-4]
	mov	ecx, [ebp-16]
	mov	byte [ecx+ebx], ah
	dec	dword [ebp-4]
	jmp	loop8
after_loop8:
	mov	eax, [ebp-16]
	mov	esp, ebp
	pop 	ebp
	ret
; <void freelist (struct node *head)>
; Frees the memory used by the list.
freelist:
	push 	ebp
	mov	ebp, esp
	mov	ebx, [ebp+8]
	cmp	dword [ebx+1], NULL
	jne	L21
	push 	dword [ebp+8]
	call	free
	add	esp, 4
	
	mov	esp, ebp
	pop 	ebp
	ret
L21:
	mov	ebx, [ebp+8]
	push	dword [ebx+1]
	call	freelist
	add	esp, 4
	push	dword [ebp+8]
	call	free
	add	esp, 4
	mov	esp, ebp
	pop 	ebp
	ret
; <struct node *reverse(struct node *head)>
; Takes a list and recursively reverses it.
reverse:
	push 	ebp
	mov	ebp, esp
	sub	esp, 8
	
	mov	ebx, [ebp+8]
	cmp	dword [ebx+1], NULL
	jne	L23
	mov	eax, [ebp+8]
	mov	esp, ebp
	pop 	ebp
	ret
L23:
	mov	ebx, [ebp+8]
	mov	eax, [ebx+1]
	mov	[ebp-4], eax
	mov	dword [ebx+1], NULL
	push	dword [ebp-4]
	call	reverse
	add	esp, 4
	mov	[ebp-8], eax
	mov	ebx, [ebp-4]
	mov	eax, [ebp+8]
	mov	[ebx+1], eax
	mov	eax, [ebp-8]

	mov	esp, ebp
	pop 	ebp
	ret
; <int isnumber(char *s)>
; Takes a string 's' and return 1 if it represents a valid number. Otherwise
; returns 0.
isnumber:
	push	ebp
	mov	ebp, esp
loop9:
	mov	ebx, [ebp+8]
	cmp	byte [ebx], 0
	je	isnumber_true
	cmp	byte [ebx], '0'
	jl	isnumber_false
	cmp	byte [ebx], '9'
	jg	L19
	jmp	loop9_cont
L19:
	cmp	byte [ebx], 'A'
	jl	isnumber_false
	cmp	byte [ebx], 'F'
	jg	isnumber_false
loop9_cont:
	inc	dword [ebp+8]
	jmp	loop9

isnumber_true:
	mov	eax, 1
	jmp	isnumber_exit
isnumber_false:
	mov	eax, 0
isnumber_exit:
	mov	esp, ebp
	pop 	ebp
	ret
; <void freestack()>
; Frees the memory used by the stack, if any.
freestack:
	push 	ebp
	mov	ebp, esp
loop10:
	dec	byte [sp_]
	cmp	byte [sp_], 0
	jle	exit_freestack
	mov	ebx, [sp_]
	push	dword [stack + ebx*4]
	call	freelist
	add	esp, 4
	jmp	loop10
exit_freestack:
	mov	esp, ebp
	pop	ebp
	ret