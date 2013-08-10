%define x 2
%define m 2
%define SRCH_UNSTND 1
%define SRCH_REGULER 0

CODEP	equ	0	; Offset of code in a coroutine struct.
FLAGSP	equ	4	; Offset of flags in a coroutine struct.
SPP	equ	8	; Offset of SP in a co-routine struct.
TYPEP	equ	12	; Offset of the type letter in co-routine struct.
INDEXP	equ	16	; Offset of the index in co-routine struct.
STKP	equ	18	; Offset of stack itself.
STKSZ	equ	16*1024	; Stack size.
DEAD	equ	0
ALIVE	equ	1
STUND	equ	3


section .bss
	align 16
	global	tabSize
	global 	table
	global 	SPT
tabSize:resd	1
table:	resd	1
CURR:	resd	1	; Pointer to current co-routine being run.
SPT:	resd	1	; Backup for caller SP.



section .text
	align 16
	global	init_co_from_c
	global	resume
	global	do_resume



; 1st arg: co-routine index.
; 2nd arg: co-routine's type in ASCII char ('d'/'k'/'s').
init_co_from_c:
	pusha
	mov	ebp, esp
	
	add 	ebp, 4*9		; Get pointer to 1st argument.
	mov	ebx, dword [ebp]	; EBX gets co-routine's index/team (assume 0-255)
	mov	eax, [ebp+4]		; EAX gets co-routine's type.

	mov	edx, [table]		; EDX gets pointer to table.
	mov	ebx, [edx+ebx*4]	; EBX gets pointer to a co-routine
	
	cmp	eax, 0xFF		; Is co-routine a dummy?
	jne	not_dummy
	mov	dword [ebx+FLAGSP], 0	; If it is, mark as dead and finish {
	jmp	init_done		; }
not_dummy:
	mov	[ebx+TYPEP], eax	; Store type.
	mov	ecx, [ebp]		; ECX gets co-routine's index/team
	mov	[ebx+INDEXP], ecx	; Store index.
	
	call	get_code
	mov	[ebx+CODEP], eax	; Store code address.

	shl	ecx, 2*8		; Put team number in 2nd byte
	and	ecx, 0x00FFFFFF		
	or	ecx, 0x01000000		; Put value for 'alive' in 1st byte
	mov	[ebx+FLAGSP], ecx	; Store flags.

	mov	[SPT], esp		; Backup original SP.

	mov	esp, ebx		
	add 	esp, STKP+STKSZ-4	; Get co-routine's initial SP.
;	mov	ebp, esp        	; Set co-routine's EBP.

	push 	eax             	; Push the code address into co-routine's stack.
	pushf                   	; Push flag into co-routine's stack.
	pusha                   	; Push all other regs into co-routine's stack.

	mov	[ebx+SPP], esp    	; Store SP.
	mov	esp, [SPT]      	; Restore original SP
init_done:
	popa
	ret 





; EBX is pointer to co-init structure of co-routine to be resumed.
; CURR holds a pointer to co-init structure of the curent co-routine.
resume:
	pushf			; Save state of caller
	pusha
	mov	edx, [CURR]
	mov	[edx+SPP], esp	; Save current SP
do_resume:
	mov	esp, [ebx+SPP]  ; Load SP for resumed co-routine
	mov	[CURR], ebx
	popa			; Restore resumed co-routine state
	popf
	ret                     ; "return" to resumed co-routine!




; EAX is co-routine's type in ASCII char.
; Return: pointer to the right function.
get_code:
	cmp	eax, 'd'
	jne	maybe_killer
	mov	eax, duplicator
	jmp	exit_get_code
maybe_killer:
	cmp	eax, 'k'
	jne	_stunner
	mov	eax, killer
	jmp	exit_get_code
_stunner:
	mov	eax, stunner
exit_get_code:
	ret

; Args: None.
; Return: None.
duplicator:
	push 	ecx			; Save used registers.
	push 	edx

	push 	dword [CURR]		; Try to duplicate current co-routine.
	call	duplicate
	add 	esp, 4			

	cmp	eax, -1
	je	duplicator_nuke		; If can't duplicate, then nuke.
	
	jmp	exit_duplicator		; If duplicated then finish.
duplicator_nuke:
	push	dword SRCH_UNSTND	; First, search for unstunned enemies.
	push	dword [CURR]
	call	next_living_enemy
	add 	esp, 8

	cmp	eax, -1
	jne	dup_nuke		; If found unstunned enemis, then nuke. Else:
didnt_find:
	push 	dword SRCH_REGULER	; Try finding also stunned enemies.
	push 	dword [CURR]
	call	next_living_enemy
	add 	esp, 8			
	cmp	eax, -1
	je	exit_duplicator		; If haven't found stunned enemis, then exit. Else:
dup_nuke:
	push	eax			; Nuke.
	call	nuke
	add	esp, 4
exit_duplicator:
	mov	ebx, [table]
	mov	ebx, [ebx]		; Set EBX to point to the scheduler.
	mov	eax, [CURR]		; Set EAX to be the pointer to beginning of code
	mov	eax, [eax]		;  as return address.
 
	pop 	edx
	pop 	ecx
	
	push 	eax
	jmp	resume




killer:
	push 	ecx
	push 	edx

	push 	dword SRCH_REGULER	; Search for living enemies.
	push 	dword [CURR]
	call 	next_living_enemy
	add 	esp, 8
      
	cmp 	eax, -1
	je	exit_killer		; If there are no living enemies, then exit.

	push 	eax			; If there are living enemies, nuke.
	call 	nuke
	add 	esp, 4
exit_killer:
	mov	ebx, [table]
	mov	ebx, [ebx]		; Set EBX to point to the scheduler.
	mov	eax, [CURR]		; Set EAX to be the pointer to beginning of code
	mov	eax, [eax]		;  as return address.

	pop 	edx
	pop 	ecx
	
	push 	eax
	jmp	resume


; Args: None.
; Return: None.
stunner:
	push 	ebp
	push 	ecx
	push 	edx
	mov 	ebp, esp
	
	sub 	esp, 4			; local var: counter
	mov 	[ebp-4], dword 0

	push 	dword SRCH_UNSTND	; Search for living unstunned enemies.
	push 	dword [CURR]
	call 	next_living_enemy
	add 	esp, 8
	
	cmp	eax, -1
	je	_try_duplicate		; If there aren't living unstunned enemies, then try duplicate.

	mov	ebx, [table]
loop4:
	mov	ecx, [ebp-4]
	cmp	ecx, m
	jge	exit_stunner		; If we finished m enemies, exit.

	push 	dword SRCH_UNSTND	; Search for living unstunned enemies.
	push 	dword [CURR]
	call 	next_living_enemy
	add 	esp, 8
	
	cmp	eax, -1
	je	exit_stunner		; No more unstunned enemies: exit.
stun:
	mov	edx, [ebx+eax*4]	; Get pointer to unstunned enemy.
	mov	eax, edx
	mov	edx, [edx+FLAGSP]	; Get his flags.
	and	edx, 0x00FFFFFF		; Turn off status.
	or 	edx, 0x03000000		; Make new status: stunned.
	and	edx, 0xFFFF0000		; Initialize stun counter.
	or	edx, dword x		; Add stun counter.
	mov	[eax+FLAGSP], edx	; Save changes.
	
	inc	dword [ebp-4]
	jmp	loop4
_try_duplicate:
	push 	dword [CURR]
	call	duplicate
	add 	esp, 4			; Try to duplicate.
	
	cmp	eax, -1
	jne	exit_stunner		; If duplication succeeds, exit. Else:
_try_nuke:
	push 	dword SRCH_REGULER	; Search for living enemies.
	push 	dword [CURR]
	call 	next_living_enemy
	add 	esp, 8
      
	cmp 	eax, -1
	je	exit_stunner		; If there are no living enemies, exit. Else:

	push 	eax
	call 	nuke
	add 	esp, 4
exit_stunner:
	mov	ebx, [table]
	mov	ebx, [ebx]		; Set EBX to point to the scheduler.
	mov	eax, [CURR]		; Set EAX to be the pointer to beginning of code
	mov	eax, [eax]		;  as return address.

	mov 	esp, ebp
	pop 	edx
	pop 	ecx
	pop 	ebp

	push 	eax
	jmp	resume


; 1st arg: Pointer to co-routine to be duplicated.
; Return: Index of the duplicant if success,
;	  -1 otherwise.
duplicate:
	push	ebp
	push 	ebx
	push	ecx
	push	edx
	mov	ebp, esp

	push 	dword [ebp+4*5]		; Push duplicator
	call	find_vacant
	add 	esp, 4

	cmp	eax, -1
	je	exit_duplicate		; If no vacant place, exit.
_duplicate:
	mov	ebx, [table]
	mov	ebx, [ebx+eax*4]	; EBX points to duplicant.
	mov	edx, [ebp+4*5]		; EDX points to duplicator.

	mov	[ebx+INDEXP], eax	; Copy index
	
	mov	ecx, [edx+CODEP]
	mov	[ebx+CODEP], ecx	; Copy the code.

	mov	ecx, [edx+TYPEP]
	mov	[ebx+TYPEP], ecx	; Copy the type.
	
	mov	ecx, [edx+FLAGSP]
	and	ecx, 0xFFFF0000		; Get rid of stun counter
	mov	[ebx+FLAGSP], ecx	; Store flags.

	mov	[SPT], esp		; Backup original SP.

	mov	esp, ebx		
	add 	esp, STKP+STKSZ-4	; Initialize co-routine's SP.
;	mov	ebp, esp        	; Set co-routine's EBP.

	push 	dword [ebx+CODEP]	; Push the code address into co-routine's stack.
	pushf                   	; Push flag into co-routine's stack.
	pusha                   	; Push all other regs into co-routine's stack.

	mov	[ebx+SPP], esp    	; Store SP.
	mov	esp, [SPT]      	; Restore original 
exit_duplicate:
	mov	esp, ebp
	pop 	edx
	pop 	ecx
	pop 	ebx
	pop 	ebp
	ret 

; 1st arg: Index of the target co-routine.
nuke:
	push 	eax
	push	ebx

	mov	eax, [esp+4]	; Get target index.
	mov	ebx, [table]
	mov	ebx, [ebx+eax*4]; Get pointer to target.
	mov	[ebx+FLAGSP], dword 0	; Nuke.

	pop 	ebx
	pop 	eax
	ret



; Finds first vacant position in the table.
; Return its index in EAX.
find_vacant:
	push 	ebx
	
	mov	eax, 1		; EAX is position in table
loop2:
	cmp	eax, [tabSize]
	jge	no_vacant

	mov	ebx, [table]	; EBX gets pointer to table.
	mov	ebx, [ebx+eax*4] ; EBX gets pointer to a co-routine
	
	mov	ebx, [ebx+FLAGSP]
	shr	ebx, 3*8	; Get the status flag
	cmp	ebx, DEAD
	je	exit_loop2
	inc	eax
	jmp	loop2
no_vacant:
	mov	eax, -1
exit_loop2:
	pop 	ebx
	ret



; i = (pos + 1) mod tabSize
; while (i != pos)
;     do stuff;
;     i = (i+1) mod tabSize;
; 1st arg: Pointer to caller co-routine.
; 2nd arg: Prefer stunned or not: 1 for stunned, 0 for not.
; If arg2 = 0, searches for the first living enemy,
; If arg2 = 1, searches for the first un-stunned living enemy.
; Returns the index of the found enemy, or -1 of there isn't.
next_living_enemy:
	push 	ebp
	push 	ebx
	push	ecx
	push 	edx
	mov	ebp, esp
	
	sub	esp, 8			; Local var1: index

	mov	ebx, [ebp+4*5]		; EBX is pointer to calling co-routine.

	mov	eax, [ebx+FLAGSP]
	mov	[ebp-8], eax		; Local var is flags of caller.

	mov	eax, [ebx+INDEXP]	;
	mov	[ebp-4], eax		; Local var is index of caller.

	inc	eax			; We start one index after, because one cannot be
					;  an enemy of itself.
	xor	edx, edx
	div	dword [tabSize]
	mov	eax, edx		; EAX = (position+1) mod tabSize.
loop3:	; EAX is constant through out the loop and is the pointer to candidate co-routine.
	cmp	eax, [ebp-4]		; If we wrapped around, then haven't found.
	je	not_found

	mov	edx, [table]
	mov	edx, [edx+eax*4]	; EDX points to candidate co-routine.
	mov	ecx, [edx+FLAGSP]	; ECX is the flags of the candidate co-routine.
	shr	ecx, 3*8		; Get status
	cmp	ecx, DEAD
	je	loop3_next_iter
not_dead:
	mov	ecx, [edx+FLAGSP]	; ECX is flags of candidate.
	shr	ecx, 2*8		; Get candidate team number.
	and	ecx, 0x000000FF		; Ignore other portion of register.
	mov	edx, [ebp+4*5]		; EDX is pointer to calling co-routine.
	mov	edx, [ebp-8]		; EDX is flags of caller.
	shr	edx, 2*8		; Get caller team number.
	and	edx, 0x000000FF		; Ignore other portion of register.
	
	cmp	ecx, edx		; Compare team numbers.	
	je	loop3_next_iter		; If not an enemy, keep searching. Else:
enemy:	
	cmp	[ebp+4*6], dword SRCH_UNSTND	; Prefer unstunned?
	jne	found			; If not, then finish.
prefer_unstunned:
	mov	edx, [table]
	mov	edx, [edx+eax*4]	; EDX points to candidate co-routine
	mov	edx, [edx+FLAGSP]
	and	edx, 0x0000FFFF		; Get candidate stun counter.
	jz	found			; If zero then we've found unstunned. 
loop3_next_iter:
	inc	eax
	xor	edx, edx
	div	dword [tabSize]
	mov	eax, edx		; EAX = (position+1) mod tabSize.
	cmp	eax, 0			; We don't want to check tab[0] because it's the scheduler's slot.
	je	loop3_next_iter
	jmp	loop3
not_found:
	mov	eax, -1
found:
	mov	esp, ebp
	pop 	edx
	pop 	ecx
	pop 	ebx
	pop 	ebp
	ret

;   ___________________________
;  |status| team |stun counter |
;  |______|______|_____________|
;
