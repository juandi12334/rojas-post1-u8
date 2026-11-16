; post2e.asm - complemento de la Parte 2: suma de 64 bits con un bucle de ADC
; Juan Diego Rojas Rey - 1152512
; Generaliza la suma de post2.asm a N palabras (aqui N = 4, o sea 64 bits).
; Sirve de apoyo a la decision tecnica "ADC fijo o ADC en bucle".
; Compilar: nasm -f bin post2e.asm -o post2e.com
ORG 100h

NPAL equ 4                ; numero de palabras de 16 bits de cada operando

%macro imprimir 1
  mov ah, 09h
  mov dx, %1
  int 21h
%endmacro

section .text
start:
  ; ---- suma de A + B, palabra por palabra, de menor a mayor peso ----
  mov si, numA
  mov di, numB
  mov bx, numR
  mov cx, NPAL
  clc                     ; CF=0: la primera palabra no tiene acarreo previo
.sumar:                   ; (equivale a que la primera suma sea un ADD)
  mov ax, [si]
  adc ax, [di]            ; ADC incorpora el CF de la palabra anterior
  mov [bx], ax
  inc si                  ; INC no modifica CF (ADD si,2 si lo haria)
  inc si
  inc di
  inc di
  inc bx
  inc bx
  loop .sumar             ; LOOP tampoco toca los flags

  ; ---- mostrar A, B y el resultado ----
  imprimir txtA
  mov si, numA
  call imprimirNum
  imprimir txtB
  mov si, numB
  call imprimirNum
  imprimir txtR
  mov si, numR
  call imprimirNum

  ; ---- verificacion contra el valor esperado ----
  mov si, numR
  mov di, esperado
  mov cx, NPAL
  mov ax, ds
  mov es, ax
  cld
  repe cmpsw
  jne .mal
  imprimir msgOk
  jmp .fin
.mal:
  imprimir msgMal
.fin:
  mov ah, 4Ch
  xor al, al
  int 21h

; imprimirNum: SI apunta a NPAL palabras (little endian); se muestra la
; palabra de mayor peso primero, separadas por ':'
imprimirNum:
  mov cx, NPAL
  mov bx, NPAL
  dec bx
  shl bx, 1               ; BX = desplazamiento de la ultima palabra
.palabra:
  mov ax, [si+bx]
  push cx
  push bx
  call imprimirHex16
  pop bx
  pop cx
  cmp cx, 1
  je .ultima
  mov dl, ':'
  mov ah, 02h
  int 21h
.ultima:
  sub bx, 2
  loop .palabra
  imprimir crlf
  ret

imprimirHex16:
  push ax
  mov al, ah
  call imprimirHex8
  pop ax
  call imprimirHex8
  ret

imprimirHex8:
  push ax
  shr al, 4
  call imprimirNibble
  pop ax
  and al, 0Fh
  call imprimirNibble
  ret

imprimirNibble:
  cmp al, 9
  jbe .digito
  add al, 7
.digito:
  add al, 30h
  mov dl, al
  mov ah, 02h
  int 21h
  ret

section .data
  ; cada numero se guarda con la palabra de menor peso primero
  numA     dw 0FFFFh, 0FFFFh, 0FFFFh, 0000h   ; 0000:FFFF:FFFF:FFFF
  numB     dw 0001h, 0000h, 0000h, 0000h      ; 0000:0000:0000:0001
  numR     dw 0, 0, 0, 0
  esperado dw 0000h, 0000h, 0000h, 0001h      ; 0001:0000:0000:0000
  txtA     db "A = $"
  txtB     db "B = $"
  txtR     db "A + B = $"
  msgOk    db "Suma de 64 bits OK: el acarreo se propago por las 4 palabras.$"
  msgMal   db "Error en la suma de 64 bits.$"
  crlf     db 0Dh, 0Ah, "$"
