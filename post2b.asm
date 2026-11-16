; post2b.asm - DAA / DAS: aritmetica BCD empaquetada
; Juan Diego Rojas Rey - 1152512
; Sumas: 47 + 38 = 85 y 99 + 01 = 100 (con acarreo)
; Restas: 73 - 28 = 45 y 20 - 01 = 19
; Compilar: nasm -f bin post2b.asm -o post2b.com
; Uso: post2b.com     -> sumas y restas
;      post2b.com s   -> solo las sumas con DAA (Checkpoint 3)
;      post2b.com r   -> solo las restas con DAS (Checkpoint 4)
ORG 100h

; operandos BCD empaquetado usados en las pruebas
BCD_NOVENTA_Y_NUEVE equ 99h
BCD_UNO             equ 01h
BCD_SETENTA_Y_TRES  equ 73h
BCD_VEINTIOCHO      equ 28h
BCD_VEINTE          equ 20h
BCD_ESPERADO_73_28  equ 45h
BCD_ESPERADO_20_01  equ 19h

%macro imprimir 1
  mov ah, 09h
  mov dx, %1
  int 21h
%endmacro

section .text
start:
  ; parametro opcional de la linea de comandos
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
  je .restas              ; modo 2: saltar las sumas

  ; ---------- Suma 47 + 38 ----------
  mov al, [bcd1]
  add al, [bcd2]          ; AL = 47h + 38h = 7Fh, no es BCD valido
  mov [crudo], al
  daa                     ; nibble bajo F > 9: suma 6 -> AL = 85h
  mov [ajustado], al

  imprimir msgSuma
  mov al, [ajustado]
  call imprimirHex8       ; en BCD cada nibble ya es un digito decimal
  imprimir crlf
  imprimir msgSin
  mov al, [crudo]
  call imprimirHex8
  imprimir msgCon
  mov al, [ajustado]
  call imprimirHex8
  imprimir crlf

  ; ---------- Suma 99 + 01 (acarreo al siguiente byte BCD) ----------
  mov al, BCD_NOVENTA_Y_NUEVE
  add al, BCD_UNO             ; AL = 9Ah
  mov [crudo], al
  daa                     ; 9Ah -> A0h -> 00h con CF=1
  mov [ajustado], al
  mov byte [cfBcd], 0
  jnc .sinAcarreo
  mov byte [cfBcd], 1
.sinAcarreo:
  imprimir msgPrueba99
  imprimir msgSin
  mov al, [crudo]
  call imprimirHex8
  imprimir msgCon
  mov al, [ajustado]
  call imprimirHex8
  imprimir msgCF
  mov dl, [cfBcd]
  add dl, 30h
  mov ah, 02h
  int 21h
  imprimir crlf
  cmp byte [modo], 1
  je .terminar            ; modo 1: no hacer las restas

  ; ---------- Resta 73 - 28 ----------
.restas:
  mov al, BCD_SETENTA_Y_TRES
  sub al, BCD_VEINTIOCHO             ; AL = 4Bh, no es BCD valido
  mov [crudo], al
  das                     ; nibble bajo B > 9: resta 6 -> AL = 45h
  mov [ajustado], al
  cmp al, BCD_ESPERADO_73_28
  jne .errDas1
  imprimir msgDasOk
  mov al, [ajustado]
  call imprimirHex8
  jmp .detalle1
.errDas1:
  imprimir msgDasErr
.detalle1:
  imprimir crlf
  imprimir msgSinDas
  mov al, [crudo]
  call imprimirHex8
  imprimir msgConDas
  mov al, [ajustado]
  call imprimirHex8
  imprimir crlf

  ; ---------- Resta 20 - 01 (caso con prestamo en el nibble bajo) ----------
  mov al, BCD_VEINTE
  sub al, BCD_UNO             ; AL = 1Fh: nibble bajo = Fh > 9
  mov [crudo], al
  das                     ; AL = 19h, CF=0
  mov [ajustado], al
  cmp al, BCD_ESPERADO_20_01
  jne .errDas2
  imprimir msgDasOk
  mov al, [ajustado]
  call imprimirHex8
  jmp .detalle2
.errDas2:
  imprimir msgDasErr
.detalle2:
  imprimir crlf
  imprimir msgSinDas
  mov al, [crudo]
  call imprimirHex8
  imprimir msgConDas
  mov al, [ajustado]
  call imprimirHex8
  imprimir crlf

.terminar:
  mov ah, 4Ch
  xor al, al
  int 21h

; imprimirHex8: muestra AL como dos digitos (nibble alto y nibble bajo)
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
  add al, 7               ; para mostrar A-F del resultado sin ajustar (7Fh, 9Ah...)
.digito:
  add al, 30h
  mov dl, al
  mov ah, 02h
  int 21h
  ret

section .data
  bcd1      db 47h        ; BCD empaquetado "47"
  bcd2      db 38h        ; BCD empaquetado "38"
  crudo     db 0          ; resultado antes del ajuste
  ajustado  db 0          ; resultado despues de DAA / DAS
  cfBcd     db 0
  modo      db 0          ; 0 = todo, 1 = solo sumas, 2 = solo restas
  msgSuma   db "BCD suma: $"
  msgSin    db "  sin DAA: $"
  msgCon    db "   con DAA: $"
  msgPrueba99 db "Prueba 99 + 01:$"
  msgCF     db "   CF=$"
  msgDasOk  db "DAS OK: $"
  msgDasErr db "DAS ERROR: $"
  msgSinDas db "  sin DAS: $"
  msgConDas db "   con DAS: $"
  crlf      db 0Dh, 0Ah, "$"
