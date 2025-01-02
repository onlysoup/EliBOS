org 0x7C00
bits 16


%define ENDL 0x0D, 0x0A


;
; FAT12 header
; 
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'           ; 8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880                 ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type:  db 0F0h                 ; F0 = 3.5" floppy disk
bdb_sectors_per_fat:        dw 9                    ; 9 sectors/fat
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; extended boot record
ebr_drive_number:           db 0                    ; 0x00 floppy, 0x80 hdd, useless
                            db 0                    ; reserved
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h   ; serial number, value doesn't matter
ebr_volume_label:           db 'NANOBYTE OS'        ; 11 bytes, padded with spaces
ebr_system_id:              db 'FAT12   '           ; 8 bytes

;
; Code goes here
;

start:
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
	
	;read from disk
	;bios should set DL to drive number
	mov	[ebr_drive_number], dl

	mov	ax, 1	;LBA = 1, second sector from disk
	mov	cl, 1	; 1 sector to read
	mov	bx, 0x7E00	;data should be after the bootloader
	call 	read_disk

	mov	si, msg_hello
	call	savs
	
readstuff:
	mov	ah, 0
	int	0x16
	mov	ah, 0x0E
	int	0x10
	jmp	readstuff
	cli			;disables interrupts
	hlt

;
; errror handlers
;

floppy_error_display:
	mov	si, err_msg_disk_read
	call	savs
	jmp	wait_key_and_reboot

wait_key_and_reboot:
	mov	ah, 0
	int	0x16
	jmp 0x0FFF:0	;jmp to beginning of bios 

.halt:
	cli
	hlt


; LBA_TO_CHS
; converts lba address to CHS for the bootloader to read from
; ax contains lba address
lba_to_chs:
	push 	ax
	push	dx				; we will only preserve dl as dh will have our head

	xor	dx, dx
	div	word [bdb_sectors_per_track]	; ax = lba / sectors_per_track
	inc	dx				; dx = sector = lba % sectors_per_track + 1
	mov	cx, dx				; cx = sector

	xor	dx, dx				
	div	word [bdb_heads]		;ax(lba/sectspertrack) / heads
						;ax = cylinder = (lba/sectspertrack) / heads
						;dx = head = (lba/sectspertrack) % heads
	mov	dh, dl				;put head in dh
	mov	ch, al				;ch = lower 8 bits of cylinder
	shl	ah, 6				; get the lowest 2 bits of ah
	or	cl, ah				; put those bits into cl
	
	pop	ax
	mov	dl, al				;only preserving dl
	pop	ax
	ret


;	Reads from disk
;	expects: ax = LBA address
;		 cl = number of sectors to read (up to 128)
; 		 dl = drive number
;		 es:bx = memory address to store read data
read_disk:
	push	ax
	push	bx
	push	cx
	push	dx
	push	di

	push	cx
	call	lba_to_chs
	pop	ax
	mov	ah, 0x02
	mov	di, 3 ;		give 3 tries to read from disc

.retry:
	pusha
	stc
	int	0x13
	jnc	.done
	;		failed read
	popa
	call	disk_reset

	dec 	di
	test	di, di
	jnz	.retry

.fail:
	;after all attempts are exaughsted 
	jmp	floppy_error_display
.done:
	popa
	
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax

	ret


disk_reset:
	pusha
	mov	ah, 0
	stc
	int	0x13
	jc	floppy_error_display
	popa
	ret
		

msg_hello db 'Success!', 10, 0
err_msg_disk_read	db 'failed to read disc', 10, 0

times 510-($-$$) db 0
dw 0AA55h
