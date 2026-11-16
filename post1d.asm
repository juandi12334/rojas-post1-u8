; post1d.asm - REPE CMPSB: comparar cadenas
; Juan Diego Rojas Rey - 1152512
; Compilar: nasm -f bin post1d.asm -o post1d.com
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

  ; ---- Caso 1: cad1 vs cad2 (iguales) ----
  mov si, cad1
  mov di, cad2
  mov cx, 8
  repe cmpsb
  je .iguales1
  imprimir msgDif
  jmp .caso2
.iguales1:
  imprimir msgIg
.caso2:
  imprimir crlf

  ; ---- Caso 2: cad1 vs cad3 (difieren en el indice 5) ----
  mov si, cad1
  mov di, cad3
  mov cx, 8
  repe cmpsb
  mov [cxRest], cx
  mov [siFin], si
  je .iguales2
  imprimir msgDif
  imprimir crlf
  imprimir msgPos
  mov ax, [siFin]
  sub ax, cad1
  dec ax                  ; SI quedo un byte despues del primer distinto
  call imprimirAX
  imprimir msgCX
  mov ax, [cxRest]
  call imprimirAX
  jmp .caso3
.iguales2:
  imprimir msgIg
.caso3:
  imprimir crlf
  imprimir crlf

  ; ---- Caso 3: demostracion del riesgo de CX fijo ----
  ; cad4 y cad5 son iguales ("NASM"), pero CX=8 es mayor que su longitud
  imprimir msgC3
  mov si, cad4
  mov di, cad5
  mov cx, 8
  repe cmpsb
  je .iguales3
  imprimir msgDif
  jmp .caso4
.iguales3:
  imprimir msgIg
.caso4:
  imprimir crlf

  ; ---- Caso 4: las mismas cadenas con la comparacion manual hasta el nulo ----
  imprimir msgC4
  mov si, cad4
  mov di, cad5
  call comparaZ
  je .iguales4
  imprimir msgDif
  jmp .fin
.iguales4:
  imprimir msgIg
.fin:
  imprimir crlf
  mov ah, 4Ch
  xor al, al
  int 21h

; comparaZ: compara dos cadenas terminadas en nulo, SI = cadena1, DI = cadena2
; Devuelve ZF=1 si son iguales y ZF=0 si difieren. Se detiene en el primer nulo.
comparaZ:
.siguiente:
  lodsb                   ; AL = [SI], SI avanza
  mov ah, [di]            ; AH = [DI]
  inc di
  cmp al, ah
  jne .termina            ; distintos: ZF=0
  test al, al             ; iguales: ¿son el nulo?
  jnz .siguiente          ; no, seguir
.termina:
  ret                     ; si salio por el nulo, ZF=1 (test dio cero)

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
  cad1    db "NASM x86", 0
  cad2    db "NASM x86", 0
  cad3    db "NASM ARM", 0
  cad4    db "NASM", 0
  cad5    db "NASM", 0
  cad6    db "XYZ12345", 0        ; datos que quedan justo despues de cad5
  cxRest  dw 0
  siFin   dw 0
  msgIg   db "Iguales.$"
  msgDif  db "Diferentes.$"
  msgPos  db "  Primera diferencia en el indice: $"
  msgCX   db "  CX restante: $"
  msgC3   db "Caso 3 (REPE CMPSB, CX=8, cadenas de 4 letras): $"
  msgC4   db "Caso 4 (comparacion manual hasta el nulo): $"
  crlf    db 0Dh, 0Ah, "$"
