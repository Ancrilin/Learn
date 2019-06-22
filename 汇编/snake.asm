data segment
	up db 0;1
	down db 0;2
	left db 0;3
	right db 1;4
	;food
	fh db 03h
	fl db 07h
	food db 2ah;'*'
	isFood db 0
	w db 80
	m db 2
	len dw 5
	;position
	score dw 0
	s db "Score: $"
	ending db "You are dead, your score is $"
	sy db 28
	body dw 0606h,0607h,0608h,0609h,060ah,0FFh dup(?)
data ends

stack segment 
	dw 30 dup(?)
	top label word
stack ends

code segment
assume ds:data,cs:code,ss:stack
main proc far
	mov ax,data
	mov ds,ax
	mov ax,stack
	mov ss,ax
	lea sp,top
	mov ax,0b800h;
	mov es,ax
	;row:0,col:0
	;col:22,row:21
	call init
	call updateFood
L:	call input
	call move
	call waits
	jmp L
E:	mov ah,4ch
	int 21h
main endp

frame proc near
;input: BH=row,BL=column
;input: DL=char,DH=property
	mov dl,' '
    mov dh,71h
    mov bl,0
    mov bh,0
    mov cx,22
row:push cx
	push bx
	call print
	pop bx
	push bx
	add bh,21
	call print
	pop bx
	inc bl
	pop cx
	loop row
	mov bx,0
	mov cx,22
col:push cx
	push bx
	call print
	pop bx
	push bx
	add bl,22
	call print
	pop bx
	inc bh
	pop cx
	loop col
	ret
frame endp

;char_offset = ((row*width)+column)*2
;input: BH=row,BL=column
;input: dl:char,dh:property
print proc near
	push ax
	mov al,w
    mul bh
    mov bh,0
    add bl,bl
    add ax,bx
    push di
    mov di,ax
    add di,di
    mov es:[di],dl
    mov es:[di+1],dh
    mov es:[di+2],dl
    mov es:[di+3],dh
    pop di
    pop ax
	ret
print endp

init proc near
	call frame
	call updateSnake
	call setScore
	call getScore
	push ax
	push dx
	push bx
	mov bh,0
	mov dh,30
	mov dl,57
	mov ah,2
	int 10h
	pop bx
	pop dx
	pop ax
	ret
init endp

move proc near
	push bp
	push ax
	push bx
	push cx
	mov ax,len
	dec ax
	mul m
	mov bp,ax
	mov bx,body[bp]
	cmp up,1
	jne L1
	dec bh
	jmp J
L1:	cmp down,1
	jne L2
	inc bh
	jmp J
L2:	cmp left,1
	jne L3
	dec bl
	jmp J
L3:	cmp right,1
	jne J
	inc bl
J:	call judge
	add bp,2
	mov body[bp],bx
	cmp isFood,0
	jne F
	xor bp,bp
	push dx
	mov bx,body[bp]
	mov dx,0
	call print
	pop dx
	mov cx,len
L:	mov ax,body[bp+2]
	mov body[bp],ax
	add bp,2
	loop L
	jmp E
F:	push ax
	mov ax,len
	inc ax
	mov len,ax
	pop ax
	call updateSnake
E:	pop cx
	pop bx
	pop ax
	pop bp
	call updateSnake
	ret
move endp

judge proc near
	push bx
	push ax
	cmp bh,0
	jne L1
	call clear
	call final
	mov ah,4ch
	int 21h
L1:	cmp bh,21
	jne L2
	call clear
	call final
	mov ah,4ch
	int 21h
L2:	cmp bl,0
	jne L3
	call clear
	call final
	mov ah,4ch
	int 21h
L3:	cmp bl,22
	jne J
	call clear
	call final
	mov ah,4ch
	int 21h
J:	push cx
	push bp
	push dx
	push si
	mov cx,len
	dec cx
	xor bp,bp
L:	xor si,si
	mov dx,body[bp]
	add bp,2
	cmp dh,bh
	jne L4
	inc si
L4:	cmp dl,bl
	jne L5
	inc si
L5:	cmp si,2
	jne L6
	call clear
	call final
	mov ah,4ch
	int 21h
L6:	loop L
F:	pop si
	pop dx
	pop bp
	pop cx
	cmp bh,fh
	jne E1
	cmp bl,fl
	jne E1
	mov al,1
	mov isFood,al
	call updateFood
	push si
	mov si,score
	inc si
	mov score,si
	push ax
	push dx
	push bx
	mov bh,0
	mov dh,8
	mov dl,57
	mov ah,2
	int 10h
	pop bx
	pop dx
	pop ax
	call getScore
	pop si
	push ax
	push dx
	push bx
	mov bh,0
	mov dh,30
	mov dl,57
	mov ah,2
	int 10h
	pop bx
	pop dx
	pop ax
	jmp E2
E1:	mov al,0
	mov isFood,al
E2:	pop ax
	pop bx
	ret
judge endp

updateSnake proc near
	push bx
	push dx
	push ax
	push bp
	mov dl,' '
    mov dh,31h
    lea si,body
    mov bx,[si]
    call print
    add si,2
    mov cx,len
    dec cx
L1:	mov bx,[si]
	call print
	add si,2
	loop L1
	mov ax,len
	dec ax
	mul m
	mov bp,ax
	mov bx,body[bp]
	mov dh,11h
	mov dl,' '
	call print
	pop bp
	pop ax
	pop dx
	pop bx
	ret
updateSnake endp

waitf proc near
	push cx
	push ax
	mov cx,33144
L:	in al,61h
	and al,10h
	cmp al,ah
	je L
	mov ah,al
	loop L
	pop ax
	pop cx
	ret
waitf endp

waits proc near
	push cx
	push ax
	mov ax,score
	cmp ax,3
	ja L1
	mov cx,5
	jmp N
L1:	cmp ax,10
	ja L2
	mov cx,4
	jmp N
L2:	cmp ax,15
	ja L3
	mov cx,3
	jmp N
L3:	cmp ax,25
	ja L4
	mov cx,2
	jmp N
L4:	mov cx,1
N:	call waitf
	loop N
	pop ax
	pop cx
	ret
waits endp

input proc near
	push ax
	mov ah,0bh
	int 21h
	cmp al,00
	je L1
	mov ah,1
	int 16h
	cmp ah,1
	mov ah,0
	int 16h
	cmp ah,48h;up
	jne L2
	cmp down,1
	je L1
	mov up,1
	mov down,0
	mov left,0
	mov right,0
	;mov dl,30h
	;mov ah,2
	;int 21h
	jmp L1
L2:	cmp ah,50h;down
	jne L3
	cmp up,1
	je L1
	mov down,1
	mov up,0
	mov left,0
	mov right,0
	;mov dl,31h
	;mov ah,2
	;int 21h
	jmp L1
L3:	cmp ah,4bh;left
	jne L4
	cmp right,1
	je L1
	mov left,1
	mov up,0
	mov down,0
	mov right,0
	;mov dl,32h
	;mov ah,2
	;int 21h
	jmp L1
L4:	cmp ah,4dh;right
	jne L1
	cmp left,1
	je L1
	mov right,1
	mov up,0
	mov down,0
	mov left,0
	;mov dl,33h
	;mov ah,2
	;int 21h
	;call waits
L1:	pop ax
	ret
input endp

updateFood proc near
	push dx
	push bx
	mov bh,fh
	mov bl,fl
	mov dx,0
	call print
	call createFood
	mov bh,fh
	mov bl,fl
	mov dh,4h
	mov dl,food
	call printStr
	pop bx
	pop dx
	ret
updateFood endp

rand proc near
	push ax
	mov ah,0
    int 1ah
    mov ah,0
    int 1ah
    mov ax,dx
    and ah,3
    mov dl,21
    div dl
    mov bl,ah
    pop ax
	ret
rand endp

createFood proc near
	push bx
	push bp
	push ax
	push dx
	push si
L1:	xor bx,bx
	call rand
	mov ah,bl
	cmp ah,0
	je L1
	cmp ah,20
	je L1
L2:	xor bx,bx
	call rand
	mov al,bl
	cmp al,0
	je L2
	cmp al,21
	je L2
L3:	mov cx,len
	xor bp,bp
L4:	xor si,si
	mov dx,body[bp]
	cmp ah,dh
	jne L5
	inc si
L5:	cmp al,dl
	jne L6
	inc si
L6:	cmp si,2
	je L1
	add bp,2
	loop L4
	mov fh,ah
	mov fl,al
	pop si
	pop dx
	pop ax
	pop bp
	pop bx
	ret
createFood endp

clear proc near
	push ax
	mov ax,3h
	int 10h
	pop ax
	ret
clear endp

printStr proc near
	push ax
	push di
	mov al,w
    mul bh
    mov bh,0
    add bl,bl;
    add ax,bx
    mov di,ax
    add di,di
    mov es:[di],dl
    mov es:[di+1],dh
    pop di
    pop ax
	ret
printStr endp

setScore proc near
	push bx
	push bp
	push dx
	push ax
	mov bh,0
	mov dh,8
	mov dl,50
	mov ah,2
	int 10h
	lea dx,s
	mov ah,9
	int 21h
	;mov bh,0
	;mov dh,23
	;mov dl,0
	;mov ah,2
	;int 10h
	;row:8,col:28
	pop ax
	pop dx
	pop bp
	pop bx
	ret
setScore endp

getScore proc near
	push dx
	push bx
	push ax
	push si
	push cx
	mov bh,0
	mov si,10
	xor cx,cx
	mov ax,score
L1:	xor dx,dx
	div si
	add dx,30h
	push dx
	inc cx
	cmp ax,0
	je L2
	jmp L1
L2:	pop dx
	mov ah,2
	int 21h
	inc dl
	loop L2
	pop cx
	pop si
	pop ax
	pop bx
	pop dx
	ret
getScore endp

final proc near
	push ax
	push bx
	push cx
	push dx
	mov bh,0
	mov dh,8
	mov dl,13
	mov ah,2
	int 10h
	lea dx,ending
	mov ah,9
	int 21h
	call getScore
	mov dl,'!'
	mov ah,2
	int 21h
	pop dx
	pop cx
	pop bx
	pop ax
	ret
final endp

code ends
end main

























