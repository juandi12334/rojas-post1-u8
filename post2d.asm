; post2d.asm - AAA / AAS: ajuste de BCD desempaquetado
; Juan Diego Rojas Rey - 1152512
; Suma desempaquetada: 7 + 8 = 15 (AH=1 decena, AL=5 unidades)
; Resta desempaquetada: 13 - 8 = 5
; Compilar: nasm -f bin post2d.asm -o post2d.com
ORG 100h

; digitos desempaquetados usados en las pruebas
DIG_SIETE  equ 07h
DIG_OCHO   equ 08h

%macro imprimir 1
  mov ah, 09h
  mov dx, %1
  int 21h
%endmacro

section .text
start:
  ; ---------- Suma desempaquetada con AAA ----------
  imprimir msgSuma

  mov ax, DIG_SIETE      ; AH=0 (importante: AAA le suma el acarreo), AL=7
  add al, DIG_OCHO        ; AL = 0Fh, no es BCD desempaquetado valido
  mov [crudo], al
  aaa                     ; AL = 05h, AH = AH + 1 = 01h, CF=1
  mov [decena], ah
  mov [unidad], al

  call imprimirResultado  ; imprime AH (si no es 0) y AL
  imprimir msgSin
  mov al, [crudo]
  call imprimirHex8
  imprimir msgCon
  mov al, [decena]
  call imprimirHex8
  mov al, [unidad]
  call imprimirHex8
  imprimir msgFinSuma

  ; ---------- Resta desempaquetada con AAS: 13 - 8 ----------
  imprimir msgResta

  mov ax, 0103h           ; AH=1 (decena de "13"), AL=3 (unidad de "13")
  sub al, DIG_OCHO        ; AL = 03h - 08h = FBh, hay prestamo
  mov [crudo], al
  aas                     ; AL = 05h, AH = AH - 1 = 00h, CF=1
  mov [decena], ah
  mov [unidad], al

  call imprimirResultado
  imprimir msgSin
  mov al, [crudo]
  call imprimirHex8
  imprimir msgCon
  mov al, [decena]
  call imprimirHex8
  mov al, [unidad]
  call imprimirHex8
  imprimir msgFinSuma

  ; ---------- Pruebas extra: por que importa el formato ----------
  imprimir crlf
  imprimir msgExtra

  ; (a) ASCII '7' + '8' directamente con AAA: AAA solo mira el nibble bajo
  mov ax, 0000h
  mov al, '7'             ; 37h
  add al, '8'             ; 37h + 38h = 6Fh
  aaa                     ; AL = 05h, AH = 01h
  or ax, 3030h            ; de vuelta a ASCII: AH='1', AL='5'
  mov [decena], ah
  mov [unidad], al
  imprimir msgAscii
  mov dl, [decena]
  mov ah, 02h
  int 21h
  mov dl, [unidad]
  mov ah, 02h
  int 21h
  imprimir crlf

  ; (b) DAA sobre un resultado desempaquetado: 07h + 08h = 0Fh
  mov ax, 0000h
  mov al, 07h
  add al, 08h             ; 0Fh
  daa                     ; AL = 15h (empaquetado), AH sigue en 0
  mov [decena], ah
  mov [unidad], al
  imprimir msgDaaMal
  mov al, [decena]
  call imprimirHex8
  mov al, [unidad]
  call imprimirHex8
  imprimir msgDaaMal2
  mov dl, [unidad]        ; si se trata como digito desempaquetado: AL + 30h
  add dl, 30h
  mov ah, 02h
  int 21h
  imprimir crlf

  ; (c) AAA sobre un byte empaquetado 47h: pierde la decena
  mov ax, 0000h
  mov al, 47h
  add al, 00h             ; deja AF=0 y AL=47h
  aaa                     ; solo ajusta el nibble bajo y pone en cero el alto
  mov [unidad], al
  imprimir msgAaaMal
  mov al, [unidad]
  call imprimirHex8
  imprimir crlf

  mov ah, 4Ch
  xor al, al
  int 21h

; imprimirResultado: muestra [decena][unidad] como numero decimal,
; omitiendo la decena cuando es cero
imprimirResultado:
  cmp byte [decena], 0
  je .soloUnidad
  mov dl, [decena]
  add dl, 30h
  mov ah, 02h
  int 21h
.soloUnidad:
  mov dl, [unidad]
  add dl, 30h
  mov ah, 02h
  int 21h
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
  crudo   db 0
  decena  db 0
  unidad  db 0
  msgSuma  db "AAA: 7 + 8 = $"
  msgResta db "AAS: 13 - 8 = $"
  msgSin   db "   (sin ajuste AL=$"
  msgCon   db "h, con ajuste AH:AL=$"
  msgFinSuma db "h)", 0Dh, 0Ah, "$"
  msgExtra db "--- contraejemplos ---", 0Dh, 0Ah, "$"
  msgAscii db "ASCII '7' + '8' con AAA y OR 3030h = $"
  msgDaaMal db "DAA sobre 07h+08h: AH:AL=$"
  msgDaaMal2 db "h, y como digito desempaquetado se imprimiria: $"
  msgAaaMal db "AAA sobre 47h: AL=$"
  crlf    db 0Dh, 0Ah, "$"
