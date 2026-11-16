; post2c.asm - MUL / DIV: calculadora de un digito
; Juan Diego Rojas Rey - 1152512
; Lee dos digitos (0-9) y un operador (* o /), muestra el resultado.
; Compilar: nasm -f bin post2c.asm -o post2c.com
ORG 100h

%macro imprimir 1
  mov ah, 09h
  mov dx, %1
  int 21h
%endmacro

section .text
start:
  ; ---- operando A ----
  imprimir pA
  call leerDigito         ; AL = digito en binario, CF=1 si no era digito
  jc .invalido
  mov bl, al              ; BL = A

  ; ---- operando B ----
  imprimir pB
  call leerDigito
  jc .invalido
  mov cl, al              ; CL = B

  ; ---- operador ----
  imprimir pOper
  mov ah, 01h
  int 21h                 ; AL = '*' o '/'
  mov bh, al              ; BH = operador

  imprimir msgR

  cmp bh, '*'             ; 2Ah
  je .multiplicar
  cmp bh, '/'             ; 2Fh
  je .dividir
  imprimir msgOpInv
  jmp .fin

.multiplicar:
  mov al, bl
  mul cl                  ; AX = AL * CL (maximo 9*9 = 81)
  aam                     ; AL / 10: AH = decenas, AL = unidades
  mov bx, ax              ; BH = decenas, BL = unidades
  cmp bh, 0
  je .soloUnidades        ; no imprimir un cero a la izquierda
  mov dl, bh
  add dl, 30h
  mov ah, 02h
  int 21h
.soloUnidades:
  mov dl, bl
  add dl, 30h
  mov ah, 02h
  int 21h
  jmp .fin

.dividir:
  cmp cl, 0
  je .divCero
  xor ah, ah              ; AX = A (para dividir 16/8 bits)
  mov al, bl
  div cl                  ; AL = cociente, AH = residuo
  mov [cociente], al
  mov [residuo], ah
  xor ax, ax
  mov al, [cociente]
  call imprimirAX         ; imprime el cociente en decimal
  imprimir msgResto
  xor ax, ax
  mov al, [residuo]
  call imprimirAX
  jmp .fin

.divCero:
  imprimir msgErr
  jmp .fin

.invalido:
  imprimir msgInv

.fin:
  imprimir crlf
  mov ah, 4Ch
  xor al, al
  int 21h

; leerDigito: lee una tecla con eco (INT 21h/AH=01h)
; Sale con AL = valor 0-9 y CF=0, o CF=1 si la tecla no es un digito.
leerDigito:
  mov ah, 01h
  int 21h
  cmp al, '0'
  jb .malo
  cmp al, '9'
  ja .malo
  sub al, 30h             ; ASCII -> binario
  clc
  ret
.malo:
  stc
  ret

; imprimirAX: imprime AX como numero decimal con DIV repetido
imprimirAX:
  mov bx, 10
  xor cx, cx
.divide:
  xor dx, dx
  div bx                  ; AX = cociente, DX = digito
  push dx
  inc cx
  test ax, ax
  jnz .divide
.sacar:
  pop dx
  add dl, 30h
  mov ah, 02h
  int 21h
  loop .sacar
  ret

section .data
  pA      db "Primer operando (0-9): $"
  pB      db 0Dh, 0Ah, "Segundo operando (0-9): $"
  pOper     db 0Dh, 0Ah, "Operacion (* o /): $"
  msgR    db 0Dh, 0Ah, "Resultado: $"
  msgResto db "  Resto: $"
  msgErr  db "Division por cero.$"
  msgInv  db 0Dh, 0Ah, "Entrada no valida: se esperaba un digito.$"
  msgOpInv db "Operacion no valida.$"
  cociente db 0
  residuo  db 0
  crlf    db 0Dh, 0Ah, "$"
