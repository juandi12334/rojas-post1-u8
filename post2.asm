; post2.asm - ADC / SBB: suma y resta de 32 bits
; Juan Diego Rojas Rey - 1152512
; Arquitectura de Computadores - Unidad 8 - Parte 2 (Pasos 1 y 2)
; Compilar: nasm -f bin post2.asm -o post2.com
; Uso: post2.com      -> suma y resta
;      post2.com s    -> solo la suma (Checkpoint 1)
;      post2.com r    -> solo la resta (Checkpoint 2)
ORG 100h

%macro imprimir 1
  mov ah, 09h
  mov dx, %1
  int 21h
%endmacro

section .text
start:
  ; parametro opcional de la linea de comandos (PSP: 80h = longitud, 82h = 1er caracter)
  cmp byte [0080h], 0
  je .sinParametro
  mov al, [0082h]
  or al, 20h
  cmp al, 's'
  jne .noEsS
  mov byte [modo], 1
  jmp .sinParametro
.noEsS:
  cmp al, 'r'
  jne .sinParametro
  mov byte [modo], 2
.sinParametro:
  cmp byte [modo], 2
  je .resta               ; modo 2: saltar la suma

  ; ================= Suma: A + B con ADD + ADC =================
  imprimir tituloSuma

  imprimir txtA
  mov ax, [aLo]
  mov dx, [aHi]
  call imprimirDXAX
  imprimir crlf
  imprimir txtB
  mov ax, [bLo]
  mov dx, [bHi]
  call imprimirDXAX
  imprimir crlf

  mov ax, [aLo]           ; DX:AX = A
  mov dx, [aHi]
  mov bx, [bLo]           ; CX:BX = B
  mov cx, [bHi]

  add ax, bx              ; partes bajas, puede generar acarreo
  mov byte [cfBajo], 0    ; MOV no modifica CF
  jnc .sinAcarreoSuma
  mov byte [cfBajo], 1
.sinAcarreoSuma:
  adc dx, cx              ; partes altas + CF de la suma anterior
  mov [resLo], ax
  mov [resHi], dx

  imprimir txtCF
  mov dl, [cfBajo]
  add dl, 30h
  mov ah, 02h
  int 21h
  imprimir crlf
  imprimir txtRes
  mov ax, [resLo]
  mov dx, [resHi]
  call imprimirDXAX
  imprimir crlf

  cmp word [resLo], 0000h
  jne .errorSuma
  cmp word [resHi], 0003h
  jne .errorSuma
  imprimir msgSumaOk
  jmp .despuesSuma
.errorSuma:
  imprimir msgSumaErr
.despuesSuma:
  cmp byte [modo], 1
  je .fin                 ; modo 1: no hacer la resta

  ; ================= Resta: C - D con SUB + SBB =================
.resta:
  imprimir crlf
  imprimir tituloResta

  imprimir txtC
  mov ax, [cLo]
  mov dx, [cHi]
  call imprimirDXAX
  imprimir crlf
  imprimir txtD
  mov ax, [dLo]
  mov dx, [dHi]
  call imprimirDXAX
  imprimir crlf

  mov ax, [cLo]           ; DX:AX = C
  mov dx, [cHi]
  mov bx, [dLo]           ; CX:BX = D
  mov cx, [dHi]

  sub ax, bx              ; 0000h - 0001h = FFFFh, hay prestamo (CF=1)
  mov byte [cfBajo], 0
  jnc .sinPrestamo
  mov byte [cfBajo], 1
.sinPrestamo:
  sbb dx, cx              ; 0003h - 0001h - CF = 0001h
  mov [resLo], ax
  mov [resHi], dx

  imprimir txtCFr
  mov dl, [cfBajo]
  add dl, 30h
  mov ah, 02h
  int 21h
  imprimir crlf
  imprimir txtRes
  mov ax, [resLo]
  mov dx, [resHi]
  call imprimirDXAX
  imprimir crlf

  cmp word [resLo], 0FFFFh
  jne .errorResta
  cmp word [resHi], 0001h
  jne .errorResta
  imprimir msgRestaOk
  jmp .fin
.errorResta:
  imprimir msgRestaErr

.fin:
  imprimir crlf
  mov ah, 4Ch
  xor al, al
  int 21h

; ---------- subrutinas ----------
; imprimirDXAX: muestra DX:AX en hexadecimal como HHHH:LLLL
imprimirDXAX:
  push ax
  mov ax, dx
  call imprimirHex16
  mov dl, ':'
  mov ah, 02h
  int 21h
  pop ax
  call imprimirHex16
  ret

; imprimirHex16: muestra AX en hexadecimal (4 digitos)
imprimirHex16:
  push ax
  mov al, ah
  call imprimirHex8
  pop ax
  call imprimirHex8
  ret

; imprimirHex8: muestra AL en hexadecimal (2 digitos)
imprimirHex8:
  push ax
  shr al, 4
  call imprimirNibble
  pop ax
  and al, 0Fh
  call imprimirNibble
  ret

; imprimirNibble: AL (0-15) -> caracter '0'-'9' o 'A'-'F'
imprimirNibble:
  cmp al, 9
  jbe .digito
  add al, 7               ; salta de '9' a 'A'
.digito:
  add al, 30h
  mov dl, al
  mov ah, 02h
  int 21h
  ret

section .data
  ; A = 0x0001FFFF = 131071, B = 0x00010001 = 65537, A + B = 0x00030000
  aLo   dw 0FFFFh
  aHi   dw 0001h
  bLo   dw 0001h
  bHi   dw 0001h
  ; C = 0x00030000, D = 0x00010001, C - D = 0x0001FFFF
  cLo   dw 0000h
  cHi   dw 0003h
  dLo   dw 0001h
  dHi   dw 0001h
  resLo dw 0
  resHi dw 0
  cfBajo db 0
  modo   db 0             ; 0 = suma y resta, 1 = solo suma, 2 = solo resta
  tituloSuma  db "== Suma de 32 bits (ADD + ADC) ==", 0Dh, 0Ah, "$"
  tituloResta db "== Resta de 32 bits (SUB + SBB) ==", 0Dh, 0Ah, "$"
  txtA    db "A = $"
  txtB    db "B = $"
  txtC    db "C = $"
  txtD    db "D = $"
  txtCF   db "CF tras ADD de las partes bajas = $"
  txtCFr  db "CF tras SUB de las partes bajas = $"
  txtRes  db "Resultado DX:AX = $"
  msgSumaOk   db "Suma OK: 0003:0000$"
  msgSumaErr  db "Error en suma.$"
  msgRestaOk  db "Resta OK: 0001:FFFF$"
  msgRestaErr db "Error en resta.$"
  crlf    db 0Dh, 0Ah, "$"
