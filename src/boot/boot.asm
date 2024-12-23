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
	mov	si, msg_hello
	call	savs
	hlt

.halt:
	jmp	.halt



msg_hello db 'Success!', 10, 0
times 510-($-$$) db 0
dw 0AA55h
