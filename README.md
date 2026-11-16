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

---

# Parte 2 — Aritmética de precisión múltiple y BCD

## Diseño de la lógica aritmética

### El acarreo en las operaciones de precisión múltiple (`post2.asm`)

Un número de 32 bits se guarda en un par de registros (DX = parte alta, AX = parte baja). La suma se hace en dos pasos: `ADD ax, bx` suma las partes bajas y deja en CF el acarreo que sale del bit 15, y `ADC dx, cx` suma las partes altas **más** ese CF. Con `A = 0001:FFFF` y `B = 0001:0001`, la parte baja da `FFFF + 0001 = 0000` con CF=1, y la parte alta da `0001 + 0001 + 1 = 0003`, así que el resultado es `0003:0000`. La resta es igual pero con `SUB` y `SBB`: `0000 - 0001 = FFFF` con CF=1 (préstamo) y `0003 - 0001 - 1 = 0001`, resultado `0001:FFFF`. El programa guarda el CF de la primera operación en una variable (con `mov` y `jnc`, que no alteran CF) para poder imprimirlo, y muestra los valores en hexadecimal con una subrutina propia.

### BCD empaquetado: DAA y DAS (`post2b.asm`)

En BCD empaquetado cada nibble es un dígito decimal (47h representa "47"). Después de un `ADD`, el resultado binario puede tener un nibble mayor que 9; `DAA` lo corrige mirando el nibble bajo y el flag AF (acarreo auxiliar, el que sale del bit 3) y el nibble alto y CF: si el nibble bajo es mayor que 9 o AF=1 suma 6, y si el nibble alto es mayor que 9 o CF=1 suma 60h y activa CF. `DAS` hace lo mismo después de un `SUB`, restando en lugar de sumar. Casos probados:

- `47h + 38h = 7Fh` y `DAA` lo deja en `85h`.
- `99h + 01h = 9Ah` y `DAA` lo deja en `00h` con CF=1 (acarreo hacia el siguiente byte BCD).
- `73h - 28h = 4Bh` y `DAS` lo deja en `45h`.
- `20h - 01h = 1Fh` y `DAS` lo deja en `19h`.

### Calculadora con MUL, DIV y AAM (`post2c.asm`)

Lee con `INT 21h / AH=01h` dos dígitos y un operador, y convierte cada dígito de ASCII a binario restando 30h (con una subrutina `leerDigito` que además rechaza lo que no sea 0-9). Para `*` usa `mul cl` (AX = AL × CL, máximo 81) y después `aam`, que divide AL entre 10 y deja las decenas en AH y las unidades en AL, que ya son los dos dígitos para imprimir (se omite el cero a la izquierda). Para `/` revisa primero que el divisor no sea cero, hace `div cl` (AL = cociente, AH = residuo) y muestra el cociente con la subrutina `imprimirAX`, que convierte binario a decimal dividiendo entre 10 repetidamente y apilando los residuos. También se muestra el resto de la división.

### BCD desempaquetado: AAA y AAS (`post2d.asm`)

En BCD desempaquetado cada byte guarda un solo dígito en el nibble bajo y el nibble alto en cero, que es lo que queda al leer un carácter y restarle 30h. `AAA` ajusta AL después de una suma: si el nibble bajo es mayor que 9 o AF=1, suma 6 a AL, **suma 1 a AH** y pone CF=1, y siempre deja el nibble alto de AL en cero. `AAS` hace lo equivalente después de una resta: resta 6 a AL, **resta 1 a AH** y pone CF=1 (préstamo). Resultados:

- `07h + 08h = 0Fh` → `AAA` → `AH:AL = 01:05` (el "15").
- `03h - 08h = FBh` (con AH=01 como la decena de "13") → `AAS` → `AH:AL = 00:05` (el "5").

Un detalle que no venía en la guía: AAA le suma el acarreo a AH, así que AH tiene que estar en 0 antes de la suma. En la guía se llamaba a `int 21h / AH=09h` justo antes, con lo que AH valía 09h, AAA lo subía a 0Ah y la decena se habría impreso como `:` (0Ah + 30h) en lugar de `1`. En `post2d.asm` se inicializa `AX` explícitamente (`mov ax, 0007h`).

## Checkpoints de la Parte 2 (capturas)

Cada checkpoint tiene dos capturas en `capturas/parte2/`.

| Checkpoint | Captura 1 | Captura 2 |
|---|---|---|
| 1 — Suma de 32 bits con ADC | [compilación](capturas/parte2/cp1_compilacion.png) | [ejecución `post2 s`](capturas/parte2/cp1_ejecucion_suma.png) |
| 2 — Resta de 32 bits con SBB | [ejecución `post2 r`](capturas/parte2/cp2_ejecucion_resta.png) | [ejecución completa](capturas/parte2/cp2_ejecucion_completa.png) |
| 3 — Suma BCD con DAA | [compilación](capturas/parte2/cp3_compilacion.png) | [ejecución `post2b s`](capturas/parte2/cp3_ejecucion_daa.png) |
| 4 — Resta BCD con DAS | [ejecución `post2b r`](capturas/parte2/cp4_ejecucion_das.png) | [ejecución completa](capturas/parte2/cp4_ejecucion_completa.png) |
| 5 — Calculadora MUL/DIV | [compilación](capturas/parte2/cp5_compilacion.png) | [7×8, 9/3 y 5/0](capturas/parte2/cp5_ejecucion_casos.png) |
| 6 — AAA/AAS | [compilación](capturas/parte2/cp6_compilacion.png) | [ejecución](capturas/parte2/cp6_ejecucion.png) |
| 7 — Decisiones técnicas | [compilación de `post2e`](capturas/parte2/cp7_compilacion_post2e.png) | [ejecución de `post2e` (bucle ADC)](capturas/parte2/cp7_ejecucion_post2e.png) |

Resultados observados:

- Checkpoint 1: `Suma OK: 0003:0000`, con CF=1 tras el `ADD` de las partes bajas.
- Checkpoint 2: `Resta OK: 0001:FFFF`, con CF=1 tras el `SUB`.
- Checkpoint 3: `BCD suma: 85` (sin DAA sería 7F) y la prueba `99 + 01` da `00` con CF=1.
- Checkpoint 4: `DAS OK: 45` (sin DAS, 4B) y `DAS OK: 19` (sin DAS, 1F).
- Checkpoint 5: `Resultado: 56` para 7×8, `Resultado: 3  Resto: 0` para 9/3 y `Division por cero.` para 5/0.
- Checkpoint 6: `AAA: 7 + 8 = 15` y `AAS: 13 - 8 = 5`, más tres contraejemplos al final que se usan en la decisión técnica 3.
- Checkpoint 7: `post2e` suma `0000:FFFF:FFFF:FFFF + 0000:0000:0000:0001 = 0001:0000:0000:0000`, con el acarreo atravesando las cuatro palabras.

---

# Decisiones técnicas

## Decisión 1 (Parte 1) — ¿REP MOVSB o un bucle manual con LODSB/STOSB?

`post1.asm` copia los 13 bytes con una sola instrucción `REP MOVSB`, mientras que `post1e.asm` hace el mismo recorrido con `LODSB`, dos comparaciones, `SUB`, `STOSB` y `LOOP`. `REP MOVSB` es más rápido porque el procesador la decodifica una sola vez y después la repite internamente como un ciclo de microcódigo: decrementa CX, avanza SI y DI y mueve el dato sin volver a leer ni decodificar instrucciones y sin evaluar un salto condicional en cada byte. El bucle manual paga en cada vuelta la decodificación de unas seis instrucciones, dos comparaciones, un salto condicional y el `LOOP`, o sea varias instrucciones por byte contra una operación repetida. (Esta diferencia es teórica; DOSBox no sirve para medirla con confianza, así que no se afirma ningún tiempo.) Aun así fue necesario abandonar `REP MOVSB` en `post1e.asm`, porque esa instrucción mueve el byte de `[DS:SI]` a `[ES:DI]` sin pasarlo por ningún registro que el programa pueda tocar: para restar 20h a las minúsculas hace falta tener el carácter en AL, y eso lo da `LODSB`, mientras que `STOSB` lo devuelve a memoria. Si hubiera que copiar una cadena larga sin ninguna transformación, `REP MOVSB` (o `REP MOVSW`) seguiría siendo claramente preferible, por velocidad y porque el código es más corto y simple; el bucle manual se reserva para cuando se necesita lógica por carácter, como convertir a mayúsculas, filtrar o contar.

## Decisión 2 (Parte 1) — ¿CX fijo en REPE CMPSB / REPNE SCASB o verificación manual del terminador?

`REPE CMPSB` y `REPNE SCASB` no conocen el nulo: se detienen solo cuando CX llega a 0 o cuando la condición de comparación se rompe. Si se comparan con CX=8 dos cadenas terminadas en nulo de 5 y 8 caracteres, la cadena corta ocupa 6 bytes (con el nulo), así que los bytes 6 y 7 que podría llegar a leer ya no son suyos: son lo que haya a continuación en memoria, otra variable u otro dato del programa. En ese par concreto la comparación se corta antes, en el índice 5, donde el nulo de la corta choca con la sexta letra de la larga; pero si las dos cadenas son iguales y más cortas que CX, `REPE` sí sigue leyendo más allá de los nulos y compara basura, y el resultado depende de qué esté al lado: puede decir "Diferentes" para cadenas iguales o "Iguales" por casualidad para cadenas distintas. Eso se comprobó en el caso 3 de `post1d.asm` (`NASM` contra `NASM` con CX=8 imprime `Diferentes.`). Para cadenas de longitud desconocida, el bucle de `post1e.asm` se adapta cambiando `STOSB` por una comparación: con `LODSB` se carga un carácter de la primera cadena en AL, se toma el de la segunda con `mov ah,[di]` y `inc di`, se comparan, si son distintos se termina con ZF=0, y si son iguales se prueba si AL es nulo con `test al,al`; si lo es, ambas terminaron juntas y son iguales, y si no, se sigue (es la rutina `comparaZ`, caso 4, que da `Iguales.`). En `post1d.asm` el CX fijo es apropiado únicamente porque `cad1`, `cad2` y `cad3` son literales de 8 caracteres cuya longitud se conoce al ensamblar; no serviría para cadenas de longitud arbitraria.

## Decisión 3 (Parte 2) — ¿DAA/DAS o AAA/AAS según el formato del dato?

`DAA` y `DAS` trabajan sobre BCD empaquetado: suponen que AL tiene dos dígitos decimales, uno en cada nibble, y ajustan los dos. `AAA` y `AAS` trabajan sobre BCD desempaquetado: solo miran el nibble bajo de AL, ajustan el acarreo hacia AH y siempre dejan el nibble alto de AL en cero. Si un byte `47h` representa los dígitos empaquetados "47" y se le aplica `AAA`, el resultado es incorrecto porque `AAA` pone en cero el nibble alto y el 4 de las decenas se pierde (en `post2d` la prueba da `AL=07`). En la calculadora del Paso 5 los dígitos se leen con `AH=01h` y se les resta 30h, así que quedan desempaquetados con el nibble alto en 0; si esa calculadora tuviera que sumarlos directamente, la instrucción correcta sería `AAA`, porque deja las unidades en AL y manda la decena a AH, justo el formato en que se están manejando los datos. Aplicar `DAA` en vez de `AAA` sobre `07h + 08h = 0Fh` no da una cifra imposible, pero sí en el formato equivocado: `DAA` suma 6 al nibble bajo y deja `15h` (empaquetado), con la decena en el nibble alto de AL y sin tocar AH, que sigue en 0. Si el programa trata ese AL como un dígito desempaquetado y le suma 30h para imprimirlo, aparece `45h`, la letra `E`, en lugar de "15"; así se vio en la captura de `post2d`.

## Decisión 4 (Parte 2) — ¿ADC de precisión fija o una cadena de ADC en bucle?

`post2.asm` suma 32 bits con exactamente dos instrucciones (`ADD` para la parte baja y `ADC` para la alta) porque el dato cabe en dos registros de 16 bits. Para N palabras (por ejemplo 4 para 64 bits, como en `post2e.asm`) se generaliza con un bucle que recorre las palabras de la de menor peso a la de mayor peso, con SI, DI y BX apuntando a los dos operandos y al resultado, y en cada vuelta hace `mov ax,[si]`, `adc ax,[di]` y `mov [bx],ax`, de modo que el CF de la palabra anterior entra en la siguiente. La primera palabra debe sumarse con `ADD` (o con `ADC` después de un `CLC`, que es lo que hace `post2e.asm`) porque no existe ningún acarreo previo que propagar: si el CF tuviera un valor viejo, un `ADC` en la primera palabra lo sumaría y daría un resultado errado; las demás palabras sí usan `ADC` precisamente para incorporar el acarreo de la anterior. Además hay que avanzar los punteros con `INC` y cerrar con `LOOP`, que no modifican CF, mientras que un `ADD si,2` o un `DEC cx` lo destruirían. La ventaja del bucle es la mantenibilidad: sirve para cualquier tamaño cambiando solo una constante (la idea de un "bignum"), en vez de escribir una instrucción `ADC` distinta por cada palabra. La desventaja es el rendimiento: cada vuelta agrega cargas, almacenamientos, incrementos y un salto, así que es más lento que las dos instrucciones fijas de `post2.asm`, en el mismo sentido en que el bucle `LODSB/STOSB` de la Parte 1 es más flexible pero más lento que `REP MOVSB`.

---

# Observaciones sobre el código de la guía

Al pasar los ejemplos de la guía a NASM y ejecutarlos en DOSBox hubo que corregir algunas cosas para que el resultado fuera el esperado:

- `13 dup(0)` es sintaxis de MASM; en NASM se escribe `times 13 db 0`.
- Los buffers `destino` se imprimen con `AH=09h`, que se detiene en `$`, así que se agregó `db "$"` justo después de cada buffer (en la guía quedaba pegado a otra variable y habría impreso texto de más).
- En `post1c` la letra `d` de `"Arquitectura de Computadores"` está en el índice 13 (hay 12 letras de "Arquitectura" y un espacio antes), no en el 4 que muestra la guía. Como el índice tiene dos dígitos, se usó una subrutina que imprime números en decimal en lugar de sumar 30h a un solo dígito.
- En `post1d`, los textos `NASM x86` y `NASM ARM` difieren en el índice 5 (base 0), que es el sexto carácter (la guía dice "quinto").
- `pOp` no se puede usar como etiqueta en NASM porque es la instrucción `POP`; en `post2c` se llama `pOper`.
- En `post2d`, AH se inicializa antes de `AAA`/`AAS` (ver la explicación en la Parte 2).
- Los ejemplos con `DAA`, `DAS`, `AAA` y `AAS` imprimen también el valor sin ajuste, para poder ver en pantalla lo que corrige cada instrucción.
