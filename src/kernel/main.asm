ORG 0x7C00

BITS 16

go:
	jmp	main

savs:
	push	si
	push	ax

loop:
	lodsb	;loads next char into al
	or	al, al	;sets ZF if al is 0
	jz	done
	mov	ah, 0x0E
	int	0x10
	jmp	loop

done:
	pop	ax
	pop	si
	ret
main:

	mov	ax, 0 ;intermediary step to write to ds/es
	mov	ds, ax
	mov	es, ax
	;Setting up stack
	mov	ss, ax
	mov	sp, 0x7C00 ; put the stack pointer at the start of the OS since it grows downwards
	mov	si, msg_hello
	call	savs
	hlt

.halt:
	jmp	.halt



msg_hello db 'Hello World!', 10, 0
times 510-($-$$) db 0
dw 0AA55h
