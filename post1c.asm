; post1c.asm - REPNE SCASB: buscar un caracter en una cadena
; Juan Diego Rojas Rey - 1152512
; Compilar: nasm -f bin post1c.asm -o post1c.com
ORG 100h

%macro imprimir 1
  mov ah, 09h
  mov dx, %1
  int 21h
%endmacro

section .text
start:
  mov ax, ds
  mov es, ax
  cld

  ; ---- Busqueda 1: la letra 'd' (si esta) ----
  mov di, cadena
  mov al, "d"             ; caracter a buscar
  mov cx, longCad
  repne scasb
  mov [cxRest], cx        ; CX restante: cuantos bytes quedaron sin revisar
  jne .noEncontrado1      ; ZF=0 -> se acabo CX sin coincidencia

  mov bx, di
  sub bx, cadena
  dec bx                  ; DI quedo un byte despues del hallazgo
  mov [posicion], bx      ; imprimirAX usa BX, asi que guardamos la posicion
  imprimir msgHall
  mov ax, [posicion]
  call imprimirAX
  imprimir crlf
  imprimir msgDI
  mov ax, [posicion]
  inc ax
  call imprimirAX
  imprimir msgCX
  mov ax, [cxRest]
  call imprimirAX
  imprimir crlf
  jmp .busqueda2

.noEncontrado1:
  imprimir msgNoH
  imprimir crlf

  ; ---- Busqueda 2: la letra 'z' (no existe en la cadena) ----
.busqueda2:
  mov di, cadena
  mov al, "z"
  mov cx, longCad
  repne scasb
  jne .noEncontrado2
  imprimir msgHall
  imprimir crlf
  jmp .fin
.noEncontrado2:
  imprimir msgBuscaZ
  imprimir msgNoH
  imprimir crlf

.fin:
  mov ah, 4Ch
  xor al, al
  int 21h

; Subrutina: imprime AX como numero decimal
imprimirAX:
  mov bx, 10
  xor cx, cx
.divide:
  xor dx, dx
  div bx
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
  cadena   db "Arquitectura de Computadores", 0
  longCad  equ $ - cadena            ; 29 bytes contando el nulo
  cxRest   dw 0
  posicion dw 0
  msgHall  db "Hallado en posicion: $"
  msgDI    db "  DI quedo en el indice: $"
  msgCX    db "  CX restante: $"
  msgBuscaZ db "Buscando 'z'... $"
  msgNoH   db "No encontrado.$"
  crlf     db 0Dh, 0Ah, "$"
