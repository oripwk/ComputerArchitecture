STKSZ	equ	16*1024	; Stack size.

CODEP	equ	0	; Offset of code in a scheduler struct.
FLAGSP	equ	4	; Offset of flags in a scheduler struct.
SPP	equ	8	; Offset of SP in a scheduler struct.

TYPEP	equ	12	; Offset of the type letter in non-scheduler co-routine.
STKP	equ	18	; Offset of stack in a non-scheduler co-routine.

DEAD	equ	0
ALIVE	equ	1
STUND	equ	3
ROUNDS	equ 	100



section .rodata
	align 16
_round:	db	"%d)", 0
_team:	db	"%d", 0
_dead:	db	"* ", 0
winner:	db	"Winning team: %d", 10, 0
newline:db	10, 0


section .data
	align 16
	extern 	table
	extern 	tabSize

; Scheduler struct.
SCHED:	dd	schedule
FLAGS:	dd	0
SP_:	dd	STK + STKSZ	; Stack pointer.

round:	dd	0		; Round number.
i:	dd	1		; Turn inside a round. (0 for scheduler).



section .bss
	align 	16
	extern 	SPT
STK:	resd	STKSZ
SPMAIN:	resd	1	; Backup for main SP.


TYPE:	resb	2	; Temporary storage for printf




section .text
	align 	16
	global	allocate_table
	global	free_table
	global	init_sched_from_c
	global	start_sched_from_c
	extern	printf
	extern	resume
	extern	do_resume
	extern	malloc
	extern	free

init_sched_from_c:
	pusha
	mov	[SPT], esp	; Backup original SP.
	mov	ebx, SCHED	
	mov	esp, [ebx+SPP]  ; Get (initial) co-routine SP.

	mov	ebp, esp        ; Set co-routine's EBP.
	push	schedule        ; Push the code address into co-routine's stack.
	pushf                   ; Push flag into co-routine's stack.
	pusha                   ; Push all other regs into co-routine's stack.
	mov	[ebx+SPP],esp   ; Save new co-routine's SP in structure.
	mov	esp, [SPT]      ; restore original SP.
init_done:
	popa
	ret




; C-callable start of the first co-routine
start_sched_from_c:
	push	ebp
	mov	ebp, esp
	pusha
	mov	[SPMAIN], esp	; Save SP of main code

	mov	ebx, SCHED 	; Get pointer to co-routine struct
	jmp	do_resume

; End co-routine mechanism, back to C main
end_sched:
	mov	esp, [SPMAIN] 	; Restore state of main code
	popa
	pop	ebp
	ret




; Allocate memory for the table.
allocate_table:
	push 	ebp
	mov	ebp, esp
	
	mov	eax, dword [tabSize]
	shl	eax, 4			; Multiply by 4 for dword length.
	push 	eax
	call	malloc
	add	esp, 4

	mov	[table], eax		; Let [table] be the pointer to beginning of table.
	mov	[eax], dword SCHED	; Let the first entry point to the scheduler.
	mov	ebx, dword 1		; EBX: index in table - 'i'.
loop1:
	cmp	ebx, [tabSize]		; i < [tabSize]?
	jge	loop1_exit

	push 	STKP + STKSZ		; Push size of a co-routine structure.
	call	malloc
	add 	esp, 4
	
	mov	edx, dword [table]	; EDX gets pointer to table.
	mov	dword [edx+ebx*4], eax	; table[i] = (pointer to co-routine).
	inc	ebx			; ++i
	jmp	loop1
loop1_exit:
	mov	esp, ebp
	pop 	ebp
	ret


free_table:
	mov	ecx, 1
	mov	ebx, [table]
	add 	ebx, 4
loop6:
	cmp	ecx, [tabSize]
	jge	exit_loop6

	push	dword [ebx]
	call	free
	add 	esp, 4
	
	inc	ecx
	add 	ebx, 4
	jmp	loop6
exit_loop6:
	push 	dword [table]
	call 	free
	add 	esp, 4

	ret


; TODO: Make global variables local.
schedule:
	push 	ebp
	mov	ebp, esp

	call	print_stat		; Print initial status.
	inc 	dword [round]

outer_loop:
	mov	ecx, [round]
	cmp	ecx, ROUNDS
	jg	print_winner
table_loop:
	mov	ebx, [i]
	cmp	ebx, [tabSize]		; End of table?
	jge	print_status

	mov	edx, [table]		; EDX gets pointer to table.
	mov	ebx, [edx+ebx*4]	; EBX gets pointer to a co-routine

	mov	eax, [ebx+FLAGSP]	; Get flags.
	shr	eax, 3*8		; Get the status field.

	cmp	eax, DEAD
	je	next_iter
	cmp	eax, STUND
	je	stunned
alive:
	call	resume			
	jmp	next_iter
stunned:
	mov	eax, [ebx+FLAGSP]	; Get flags.
	mov	ecx, eax		; We use ECX only to check of a decrement will lead to zero.
	and	ecx, 0x0000FFFF		; Leave only stun counter on.
	dec 	ecx			; Decrement stun counter
	jnz	pre_next_iter		; If not zero, continue. Else:

	and	eax, 0x00FFFFFF		; Unset the status byte.
	or	eax, 0x01000000		; Set the status byte to alive.
pre_next_iter:
	dec	eax
	mov	[ebx+FLAGSP], eax	; Save the flags.
next_iter:
	inc	dword [i]
	jmp	table_loop
print_status:
	call	print_stat
	mov	dword [i], 1
	inc	dword [round]
	jmp	outer_loop
print_winner:
	call 	print_win
	; TODO: free table
	jmp	end_sched




print_stat:
	pusha
	mov	ebp, esp
	sub	esp, 4		; local var: status of co-routine being examined.
	sub	esp, 4		; local var: counter.
	mov	[ebp-8], dword 1	

	push 	dword [round]
	push 	dword _round
	call	printf
	add 	esp, 8		; Printed round number.
	
	mov	ecx, dword [ebp-8]	; ECX: index into the table.
loop2:
	cmp	ecx, [tabSize]
	jge	exit_print_stat

	mov	eax, [table]		; EAX gets pointer to table.
	mov	ebx, [eax+ecx*4]	; EBX gets pointer to a co-routine

	mov	edx, [ebx+FLAGSP]
	shr	edx, 3*8		; Get status.
	mov	[ebp-4], edx		; Backup status.
	cmp	edx, DEAD
	jne	not_dead
dead:
	push	_dead
	call	printf
	add 	esp, 4
	jmp	pt_next_iter
not_dead:
	mov	eax, [ebx+TYPEP]
	cmp	dword [ebp-4], STUND
	jne	_print

	sub 	eax, 0x20		; Convert to uppercase
_print:
	mov	byte [TYPE], al
	mov	byte [TYPE+1], 0
	push 	TYPE
	call	printf
	add 	esp, 4			; Print type.

	mov	edx, [ebx+FLAGSP]
	shr	edx, 2*8		; Get team number.
	and	edx, 0x000000FF		; Unset other fields
	
	push 	edx
	push	_team
	call	printf
	add 	esp, 8
pt_next_iter:
	inc	dword [ebp-8]
	mov	ecx, dword [ebp-8]
	jmp	loop2
exit_print_stat:
	push 	newline
	call	printf
	add 	esp, 4

	mov	esp, ebp
	popa
	ret


print_win:
	pusha

	push 	256
	call 	malloc
	add 	esp, 4			; Allocate array, such that array[i] 
					;   is number of wins of team i.
	xor 	ebx, ebx		; EBX is index into the array.
loop3:	; Initialize the array
	cmp 	ebx, 256
	jge	exit_loop3

	mov	byte [eax+ebx], 0
	inc 	ebx
	jmp 	loop3
exit_loop3:
	mov	ecx, 1			; ECX is index in table.
	mov	edx, [table]		; EDX points to beginning of table.

loop4:	; Fill array with numbers of alive members per team.
	cmp	ecx, [tabSize]
	jge	exit_loop4

	mov	ebx, [edx+ecx*4]	; EBX is a pointer co-routine.
	mov	ebx, [ebx+FLAGSP]	; EBX is the flags.
	shr	ebx, 3*8		; Get status.
	cmp	ebx, DEAD
	je	loop4_next_iter
_not_dead:
	mov	ebx, [edx+ecx*4]	; EBX is a pointer co-routine.
	mov	ebx, [ebx+FLAGSP]	; EBX is the flags.
	shr	ebx, 2*8		; Get team number.
	and	ebx, 0x000000FF		; Unset other fields.

	inc 	byte [eax+ebx]		; Increment array at index <team number>
loop4_next_iter:
	inc 	ecx
	jmp	loop4
exit_loop4:
	xor 	ebx, ebx		; EBX is index into the array.
	xor	edx, edx		; EDX is max value.
	xor 	ecx, ecx		; ECX is index of max value.
loop5:	; Find maximum value in the array.
	cmp	ebx, 256
	jge	loop5_exit

	cmp	byte [eax+ebx], dl
	jle	loop5_next_iter

	mov	dl, byte [eax+ebx]
	mov	ecx, ebx
loop5_next_iter:
	inc 	ebx
	jmp	loop5
loop5_exit:
	push 	ecx	; Backup
	push 	eax
	call	free 
	add 	esp, 4			; Free memory of array.
	pop 	ecx 	; Restore.

	push 	ecx
	push 	winner
	call 	printf
	add 	esp, 8			; Print winning team.

	popa
	ret