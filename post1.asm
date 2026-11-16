; post1.asm - REP MOVSB / REP MOVSW: copia de cadenas
; Juan Diego Rojas Rey - 1152512
; Arquitectura de Computadores - Unidad 8 - Parte 1 (Pasos 1 y 2)
; Compilar: nasm -f bin post1.asm -o post1.com
; Uso: post1.com      -> hace las dos copias (MOVSB y MOVSW)
;      post1.com b    -> solo el Paso 1 (REP MOVSB)
;      post1.com w    -> solo el Paso 2 (REP MOVSW + MOVSB)
ORG 100h

; macro para imprimir una cadena terminada en '$' (INT 21h, AH=09h)
%macro imprimir 1
  mov ah, 09h
  mov dx, %1
  int 21h
%endmacro

section .text
start:
  ; leer el parametro de la linea de comandos (PSP: longitud en 80h, texto desde 81h)
  cmp byte [0080h], 0
  je .sinParametro
  mov al, [0082h]         ; primer caracter despues del espacio
  or al, 20h              ; a minuscula
  cmp al, 'b'
  jne .esW
  mov byte [modo], 1
  jmp .sinParametro
.esW:
  cmp al, 'w'
  jne .sinParametro
  mov byte [modo], 2
.sinParametro:
  ; ES = DS (en un .com todo cabe en un solo segmento)
  mov ax, ds
  mov es, ax
  cld                     ; DF=0: SI y DI avanzan de direccion baja a alta

  ; ---------- Paso 1: REP MOVSB (13 bytes) ----------
  cmp byte [modo], 2
  je .paso2               ; modo 2: saltar el Paso 1
  mov si, origen
  mov di, destino1
  mov cx, longOrigen
  rep movsb
  ; guardamos los registros ahora, antes de que otra interrupcion los toque
  mov [regSI], si
  mov [regDI], di
  mov [regCX], cx

  imprimir msgMovsb
  imprimir destino1
  imprimir crlf
  imprimir msgSI
  mov ax, [regSI]
  sub ax, origen          ; cuanto avanzo SI desde el inicio de origen
  call imprimirAX
  imprimir msgDI
  mov ax, [regDI]
  sub ax, destino1
  call imprimirAX
  imprimir msgCX
  mov ax, [regCX]
  call imprimirAX
  imprimir crlf

  ; ---------- Paso 2: REP MOVSW + MOVSB para el byte impar ----------
.paso2:
  cmp byte [modo], 1
  je .verificar           ; modo 1: saltar el Paso 2
  mov si, origen
  mov di, destino2
  mov cx, longOrigen      ; longitud total en bytes
  mov ax, cx              ; AX = copia de la longitud para probar paridad
  shr cx, 1               ; CX = 13 / 2 = 6 words
  rep movsw               ; copia 12 bytes
  and ax, 1               ; 13 AND 1 = 1 -> hay un byte sobrante
  jz .sinImpar
  movsb                   ; copia el byte 13 (el terminador nulo)
.sinImpar:
  mov [regSI], si
  mov [regDI], di

  imprimir msgMovsw
  imprimir destino2
  imprimir crlf
  imprimir msgSI
  mov ax, [regSI]
  sub ax, origen
  call imprimirAX
  imprimir msgDI
  mov ax, [regDI]
  sub ax, destino2
  call imprimirAX
  imprimir crlf

  ; ---------- Verificacion: comparar origen con cada copia (REPE CMPSB) ----------
.verificar:
  cld
  cmp byte [modo], 2
  je .compara2            ; modo 2: no hay copia 1 que verificar
  mov si, origen
  mov di, destino1
  mov cx, longOrigen
  repe cmpsb
  jne .fallo
.compara2:
  cmp byte [modo], 1
  je .todoOk              ; modo 1: no hay copia 2 que verificar
  mov si, origen
  mov di, destino2
  mov cx, longOrigen
  repe cmpsb
  jne .fallo
.todoOk:
  imprimir msgOk
  jmp .fin
.fallo:
  imprimir msgFallo
.fin:
  mov ah, 4Ch
  xor al, al
  int 21h

; Subrutina: imprime AX como numero decimal (sin signo)
imprimirAX:
  mov bx, 10
  xor cx, cx
.divide:
  xor dx, dx
  div bx                  ; AX = cociente, DX = residuo (un digito)
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
  origen    db "HOLA, MUNDO!", 0
  longOrigen equ $ - origen          ; 13 bytes contando el nulo
  destino1  times 13 db 0
            db "$"                   ; terminador para INT 21h/09h
  destino2  times 13 db 0
            db "$"
  regSI     dw 0
  regDI     dw 0
  regCX     dw 0
  modo      db 0                     ; 0 = ambas, 1 = solo MOVSB, 2 = solo MOVSW
  msgMovsb  db "Copiado (MOVSB): $"
  msgMovsw  db "Copiado (MOVSW): $"
  msgSI     db "  SI avanzo: $"
  msgDI     db "  DI avanzo: $"
  msgCX     db "  CX final: $"
  msgOk     db "Verificacion: la copia es identica al origen.$"
  msgFallo  db "Verificacion: ERROR, las copias no coinciden.$"
  crlf      db 0Dh, 0Ah, "$"
