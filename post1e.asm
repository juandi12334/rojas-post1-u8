; post1e.asm - LODSB + STOSB: copia con transformacion a mayusculas
; Juan Diego Rojas Rey - 1152512
; Compilar: nasm -f bin post1e.asm -o post1e.com
ORG 100h

section .text
start:
  mov ax, ds
  mov es, ax

  mov si, origen
  mov di, destino
  mov cx, longOrigen
  cld

.bucle:
  lodsb                   ; AL = [DS:SI], SI avanza solo
  cmp al, 'a'
  jb .escribir            ; menor que 'a': no es minuscula, se deja igual
  cmp al, 'z'
  ja .escribir            ; mayor que 'z': tampoco
  sub al, 20h             ; 'a'-'z' -> 'A'-'Z'
.escribir:
  stosb                   ; [ES:DI] = AL, DI avanza solo
  loop .bucle

  mov ah, 09h
  mov dx, msgOrig
  int 21h
  mov dx, origen
  int 21h
  mov dx, crlf
  int 21h
  mov dx, msgCop
  int 21h
  mov dx, destino
  int 21h
  mov dx, crlf
  int 21h

  mov ah, 4Ch
  xor al, al
  int 21h

section .data
  origen  db "hola, mundo!", 0
  longOrigen equ $ - origen          ; 13 bytes
          db "$"                     ; para poder imprimir el origen con AH=09h
  destino times 13 db 0
          db "$"
  msgOrig db "Original:     $"
  msgCop  db "Transformado: $"
  crlf    db 0Dh, 0Ah, "$"
