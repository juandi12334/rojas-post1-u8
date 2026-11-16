# Post-contenido Unidad 8 — Operaciones con cadenas y aritmética en NASM sobre DOSBox

**Estudiante:** Juan Diego Rojas Rey — código 1152512
**Materia:** Arquitectura de Computadores — Ingeniería de Sistemas, UFPS
**Repositorio:** `rojas-post1-u8` (una sola entrega para las dos partes)

Este repositorio reúne los programas del laboratorio guiado de la Unidad 8. La Parte 1 trabaja las instrucciones de cadena de la arquitectura x86 (`REP MOVSB/MOVSW`, `REPNE SCASB`, `REPE CMPSB`, `LODSB/STOSB`) y la Parte 2 la aritmética de precisión múltiple y BCD (`ADC/SBB`, `DAA/DAS`, `MUL/DIV` con `AAM`, `AAA/AAS`). Todo está escrito para NASM en formato `.com` (`ORG 100h`) y fue ensamblado y ejecutado dentro de DOSBox.

## Entorno de trabajo

- DOSBox 0.74-3.
- NASM 2.15.05 para DOS (`nasm.exe`, que usa `cwsdpmi.exe`), copiado en `C:\NASM` dentro de DOSBox. Así la compilación de las capturas se hizo en el propio DOSBox con el comando de la guía:
  `nasm -f bin programa.asm -o programa.com`
- Los `.com` que están en el repositorio son los generados dentro de DOSBox.

## Contenido del repositorio

| Archivo | Qué hace |
|---|---|
| `post1.asm` / `.com` | Parte 1, Pasos 1 y 2: copia de 13 bytes con `REP MOVSB` y con `REP MOVSW` + `MOVSB` |
| `post1c.asm` / `.com` | Parte 1, Paso 3: búsqueda de un carácter con `REPNE SCASB` |
| `post1d.asm` / `.com` | Parte 1, Paso 4: comparación de cadenas con `REPE CMPSB` (más una demostración del riesgo de usar CX fijo) |
| `post1e.asm` / `.com` | Parte 1, Paso 5: copia a mayúsculas con bucle `LODSB` + `STOSB` |
| `post2.asm` / `.com` | Parte 2, Pasos 1 y 2: suma y resta de 32 bits con `ADC` y `SBB` |
| `post2b.asm` / `.com` | Parte 2, Pasos 3 y 4: suma y resta BCD empaquetada con `DAA` y `DAS` |
| `post2c.asm` / `.com` | Parte 2, Paso 5: calculadora de un dígito con `MUL`, `DIV` y `AAM` |
| `post2d.asm` / `.com` | Parte 2, Paso 6: suma y resta BCD desempaquetada con `AAA` y `AAS` |
| `post2e.asm` / `.com` | Complemento de la Parte 2: suma de 64 bits con un bucle de `ADC` (apoyo a la decisión técnica 4) |
| `capturas/` | Capturas de DOSBox de cada checkpoint (`parte1/` y `parte2/`) |

Algunos programas aceptan un parámetro opcional en la línea de comandos para ejecutar solo una parte (así cada checkpoint se pudo capturar por separado): `post1 b` / `post1 w`, `post2 s` / `post2 r` y `post2b s` / `post2b r`. Sin parámetro hacen todo.

---

# Parte 1 — Instrucciones de cadena

## Diseño de las rutinas

### El rol del flag DF

Todas las instrucciones de cadena (`MOVSB/W`, `SCASB`, `CMPSB`, `LODSB`, `STOSB`) usan SI y/o DI de forma implícita y los actualizan solos después de cada elemento. El flag de dirección DF decide el sentido: con `CLD` (DF=0) los punteros se **incrementan** y la cadena se recorre de dirección baja a alta; con `STD` (DF=1) se **decrementan**. En todos los programas se ejecuta `cld` antes de la primera instrucción de cadena porque DOS no garantiza el valor inicial de DF, y si quedara en 1 la copia se haría hacia atrás y escribiría fuera del buffer. En las capturas se ve el efecto: después de copiar 13 bytes, SI y DI avanzaron exactamente 13 posiciones y CX llegó a 0.

También hay que cargar ES igual a DS (`mov ax, ds` / `mov es, ax`), porque `MOVSB`, `SCASB`, `CMPSB` y `STOSB` escriben o leen en `ES:DI`, y en un `.com` todos los segmentos son el mismo.

### `post1.asm` — REP MOVSB y REP MOVSW

- **Paso 1 (MOVSB):** SI = origen, DI = destino1, CX = 13, `rep movsb`. El prefijo `REP` repite la instrucción mientras CX ≠ 0 y lo decrementa en cada vuelta.
- **Paso 2 (MOVSW):** como cada `MOVSW` mueve 2 bytes, CX se divide entre 2 (`shr cx, 1` → 6 palabras = 12 bytes). Se guarda la longitud en AX y con `and ax, 1` se detecta si es impar; si lo es, un `movsb` final copia el byte sobrante (aquí el nulo, byte 13).
- Al final compara cada copia contra el origen con `repe cmpsb` y muestra el mensaje de verificación.

### `post1c.asm` — REPNE SCASB

`scasb` compara AL con `[ES:DI]` y avanza DI. Con `repne` sigue mientras no haya coincidencia (ZF=0) y CX > 0. Al salir hay dos posibilidades: ZF=1 (se encontró; DI quedó un byte después del hallazgo, por eso la posición es `DI - cadena - 1`) o ZF=0 (CX llegó a 0 sin encontrarlo). El programa busca `d` (que sí está) y `z` (que no está) en `"Arquitectura de Computadores"` y muestra además DI y CX al terminar.

### `post1d.asm` — REPE CMPSB

`cmpsb` compara `[DS:SI]` con `[ES:DI]`; con `repe` sigue mientras sean iguales (ZF=1) y CX > 0. Compara `cad1` con `cad2` (iguales) y `cad1` con `cad3` (distintas), y en el segundo caso calcula en qué índice difieren a partir de SI. Se agregaron dos casos extra para la decisión técnica 2: el caso 3 usa `repe cmpsb` con CX=8 sobre dos cadenas iguales de solo 4 letras, y el caso 4 las compara con una rutina manual (`comparaZ`) que se detiene en el nulo.

### `post1e.asm` — copia con transformación (LODSB/STOSB)

Bucle de 13 vueltas: `lodsb` carga el carácter en AL, dos comparaciones (`cmp al,'a'` / `jb`, `cmp al,'z'` / `ja`) deciden si es minúscula, y en ese caso `sub al, 20h` la pasa a mayúscula; `stosb` guarda AL en el destino y `loop` repite. Los caracteres que no son letras (la coma, el espacio, `!` y el nulo) pasan sin cambio.

## Checkpoints de la Parte 1 (capturas)

Cada checkpoint tiene dos capturas en `capturas/parte1/`.

| Checkpoint | Captura 1 | Captura 2 |
|---|---|---|
| 1 — Copia con REP MOVSB | [compilación](capturas/parte1/cp1_compilacion.png) | [ejecución `post1 b`](capturas/parte1/cp1_ejecucion_movsb.png) |
| 2 — Copia con REP MOVSW | [ejecución `post1 w`](capturas/parte1/cp2_ejecucion_movsw.png) | [ejecución completa](capturas/parte1/cp2_ejecucion_completa.png) |
| 3 — REPNE SCASB | [compilación](capturas/parte1/cp3_compilacion.png) | [ejecución (busca `d` y `z`)](capturas/parte1/cp3_ejecucion.png) |
| 4 — REPE CMPSB | [compilación](capturas/parte1/cp4_compilacion.png) | [ejecución](capturas/parte1/cp4_ejecucion.png) |
| 5 — LODSB/STOSB | [compilación](capturas/parte1/cp5_compilacion.png) | [ejecución](capturas/parte1/cp5_ejecucion.png) |
| 6 — Decisiones técnicas | [bucle manual frente a REP](capturas/parte1/cp6_bucle_vs_rep.png) | [tamaños de los `.com` y CX fijo](capturas/parte1/cp6_tamanos_y_cx_fijo.png) |

Resultados observados:

- Checkpoint 1 y 2: `Copiado (MOVSB): HOLA, MUNDO!` y `Copiado (MOVSW): HOLA, MUNDO!`, con SI y DI avanzando 13 y CX final 0 en MOVSB; la verificación contra el origen da "idéntica".
- Checkpoint 3: `Hallado en posicion: 13` para `d`, con DI en el índice 14 y CX restante 15 (29 − 14), y `No encontrado.` para `z`.
- Checkpoint 4: `Iguales.` para `cad1`/`cad2` y `Diferentes.` para `cad1`/`cad3`; la diferencia está en el índice 5 y CX queda en 2.
- Checkpoint 5: `Original: hola, mundo!` → `Transformado: HOLA, MUNDO!`.
- Checkpoint 6: caso 3 de `post1d` da `Diferentes.` aunque las cadenas son iguales (riesgo de CX fijo) y el caso 4 con la rutina manual da `Iguales.`.
