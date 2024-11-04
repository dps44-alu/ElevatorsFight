INCLUDE "hardware.inc"    ; Include hardware constants

; Constants for HUD tiles

DEF HUD_TILE_START EQU $80 ; Starting tile number for our HUD tiles

SECTION "HUD Variables", WRAM0
DEF FIRST_FREE_OAM_SLOT EQU 12 * 4  ; Each sprite uses 4 bytes, empezamos en el slot 12

wScore: ds 1          ; 1 bytes for score (0-100)
wLives: db            ; 1 byte for lives
wScoreChanged: db     ; Flag to indicate if score needs updating
wLivesChanged: db     ; Flag to indicate if lives need updating
wScoreBuffer: ds 3    ; Buffer to hold the score digits for display
wLivesBuffer: ds 3    ; Buffer to hold the lives display data

SECTION "HUD Tiles", ROM0
hud_tiles:
    ; Numbers 0-9 tiles (16 bytes each)
    ; 0
    db $7E,$7E,$FF,$81,$FF,$81,$FF,$81
    db $FF,$81,$FF,$81,$FF,$81,$7E,$7E
    ; 1
    db $1C,$1C,$3C,$1C,$1C,$1C,$1C,$1C
    db $1C,$1C,$1C,$1C,$1C,$1C,$7F,$7F
    ; 2
    db $7E,$7E,$FF,$81,$03,$03,$0E,$0E
    db $38,$38,$E0,$E0,$FF,$FF,$FF,$FF
    ; 3
    db $7E,$7E,$FF,$81,$03,$03,$1E,$1E
    db $03,$03,$FF,$81,$7E,$7E,$00,$00
    ; 4
    db $C3,$C3,$C3,$C3,$C3,$C3,$FF,$FF
    db $03,$03,$03,$03,$03,$03,$00,$00
    ; 5
    db $FF,$FF,$FC,$FC,$FE,$FE,$03,$03
    db $FF,$81,$7E,$7E,$00,$00,$00,$00
    ; 6
    db $7E,$7E,$FF,$81,$FC,$FC,$FE,$FE
    db $FF,$81,$7E,$7E,$00,$00,$00,$00
    ; 7
    db $FF,$FF,$FF,$FF,$03,$03,$0E,$0E
    db $38,$38,$E0,$E0,$80,$80,$00,$00
    ; 8
    db $7E,$7E,$FF,$81,$FF,$81,$7E,$7E
    db $FF,$81,$FF,$81,$7E,$7E,$00,$00
    ; 9
    db $7E,$7E,$FF,$81,$FF,$81,$7F,$7F
    db $03,$03,$FF,$81,$7E,$7E,$00,$00
    ; Heart tile (for lives)
    db $66,$66,$FF,$FF,$FF,$7E,$7E,$3C
    db $3C,$18,$18,$00,$00,$00,$00,$00
   ; ; Letter tiles for "SCORE:" (16 bytes each)
    ; S 
    db $7E,$7C,$FF,$FE,$C0,$C0,$7E,$7C  ; Top curve and middle
    db $03,$02,$FF,$FE,$7E,$7C,$00,$00  ; Bottom curve

    ; C
    db $7E,$7C,$FF,$FE,$C0,$C0,$C0,$C0  ; Top curve and left side
    db $C0,$C0,$FF,$FE,$7E,$7C,$00,$00  ; Bottom curve

    ; O
    db $7E,$7C,$FF,$FE,$C3,$C2,$C3,$C2  ; Top curve and sides
    db $C3,$C2,$FF,$FE,$7E,$7C,$00,$00  ; Bottom curve

    db $FF,$FE,$C3,$C2,$C3,$C2,$FF,$FE  ; Top half - like P
    db $CC,$CC,$C6,$C6,$C3,$C2,$00,$00

    ; E
    db $FF,$FE,$C0,$C0,$C0,$C0,$FF,$FE  ; Top and middle
    db $C0,$C0,$FF,$FE,$FF,$FE,$00,$00  ; Bottom

    ; : (colon - centered with space right)
    db $00,$00,$38,$38,$38,$38,$00,$00  ; Top dot
    db $38,$38,$38,$38,$00,$00,$00,$00  ; Bottom dot
    ; Space
    db $00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00
hud_tiles_end:
 

; Constants for letter tiles
DEF EMPTY_TILE     EQU $00    ; Empty space tile
DEF NUMBER_START   EQU HUD_TILE_START      ; First number (0)
DEF HEART_TILE    EQU HUD_TILE_START + 10  ; After numbers
DEF LETTER_S      EQU HUD_TILE_START + 11  ; After heart
DEF LETTER_C      EQU HUD_TILE_START + 12
DEF LETTER_O      EQU HUD_TILE_START + 13
DEF LETTER_R      EQU HUD_TILE_START + 14
DEF LETTER_E      EQU HUD_TILE_START + 15
DEF LETTER_COLON  EQU HUD_TILE_START + 16
DEF LETTER_SPACE  EQU HUD_TILE_START + 17
SECTION "Math Functions", ROM0
; Divide function
; Input: BC = number to divide, L = divisor
; Output: BC = result, A = remainder
Divide::
    xor a           ; Clear a for remainder
    ld h, 8         ; 8 bits to process for each byte
.loop16:
    ; First process the high byte (B)
    sla c           ; Shift low byte left
    rla             ; Shift high byte left through carry
    cp l            ; Compare with divisor
    jr c, .skip     ; If remainder < divisor, skip subtraction
    sub l           ; Subtract divisor
    inc c           ; Set result bit
.skip:
    dec h
    jr nz, .loop16
    
    ; Now process the low byte (C)
    ld h, 8         ; 8 more bits to process
.loop8:
    sla c           ; Shift low byte left
    rla             ; Shift remainder left through carry
    cp l            ; Compare with divisor
    jr c, .skip2    ; If remainder < divisor, skip subtraction
    sub l           ; Subtract divisor
    inc c           ; Set result bit
.skip2:
    dec h
    jr nz, .loop8
    ret

SECTION "HUD Functions", ROM0
InitHUD::
    ; Load HUD tiles into VRAM
    ld de, hud_tiles
    ld hl, _VRAM8000 + (HUD_TILE_START * 16)  
    ld bc, hud_tiles_end - hud_tiles
.copyTiles:
    ld a, [de]             
    ld [hl+], a            
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .copyTiles

    ; Write "SCORE:" at $9A0A
    ld hl, $9A0A
    ld a, LETTER_S          
    ld [hl+], a             ; 9A0A
    ld a, LETTER_C          
    ld [hl+], a             ; 9A0B
    ld a, LETTER_O          
    ld [hl+], a             ; 9A0C
    ld a, LETTER_R          
    ld [hl+], a             ; 9A0D
    ld a, LETTER_E          
    ld [hl+], a             ; 9A0E
    ld a, LETTER_COLON      
    ld [hl+], a             ; 9A0F
    ld a, NUMBER_START
    ld [hl+], a             ; 9A10
    ld [hl+], a             ; 9A11
    ld [hl], a              ; 9A12
    
    ; Draw the initial hearts
    ld hl, $9A01          ; Position for first heart
    ld a, HEART_TILE      ; Heart tile
    ld [hl+], a           ; First heart
    ld [hl+], a           ; Second heart
    ld [hl], a            ; Third heart
    
    ; Initialize variables
    xor a
    ld [wScore], a
    ld a, 3
    ld [wLives], a
    ld a, 0 
    ld [wScoreChanged], a
    ld [wLivesChanged], a
    ret
UpdateHUDLogic::
    ld a, [wScoreChanged]
    and a
    jr z, .checkLives       ; Si no ha cambiado el valor del Score comprueba el de las vidas
    
    ; Convert score to digits
    ld hl, wScore               ; HL = wScore
    call convert_score          ; wScoreBuffer = Tiles de los digitos de Score  
    
.checkLives:
    ld a, [wLivesChanged]
    and a
    ret z
    
    ; Convert lives to display format
    ld a, [wLives]
    ld b, a
    ld hl, wLivesBuffer
.livesLoop:
    ld a, b
    and a
    jr z, .emptyHearts
    ld a, HEART_TILE      ; Use the defined heart tile constant instead of direct value
    ld [hl+], a
    dec b
    jr .livesLoop
.emptyHearts:
    ld a, EMPTY_TILE
    ld [hl+], a
    ret

UpdateHUDGraphics::
    ; Update score display if changed
    ld a, [wScoreChanged]
    and a
    jr z, .updateLives      ; Si wScoreChanged = 0, no ha cambiado la puntuación y se actualizan las vidas
    
    call print_score

    xor a
    ld hl, wScoreChanged
    ld [hl], a
    
.updateLives:
    ld a, [wLivesChanged]
    and a
    ret z                   ; Si wLivesChanged = 1, necesitan cambio
    
    ; Display lives at specific address $9A01
    ld hl, $9A01          
    ld de, wLivesBuffer
    ld b, 3                ; Maximum 3 lives
.livesDisplayLoop:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, .livesDisplayLoop
    
    xor a
    ld [wLivesChanged], a
    ret


; Entrada: HL = Dirección de la variable de 1 byte que contiene el puntaje (0-100)
; Salida: scoreBuffer = 6 bytes (3 para dígitos, 3 para tiles)
convert_score:
    ld a, [hl]          ; Cargar el puntaje en A
    ld hl, wScoreBuffer  ; Cargar la dirección de la variable scoreBuffer

    ; Dividir el puntaje entre 100 para obtener el dígito de las centenas
    ld b, a
    ld a, 100
    call div8      ; Dividir A/B y almacenar el resultado en A
    add a, 80      ; Sumar 80 para obtener el tile correspondiente
    ld [hl+], a     ; Almacenar el tile de las centenas en la cuarta posición

    ; Dividir el puntaje entre 10 para obtener el dígito de las decenas
    ld a, b
    ld b, 10
    call div8      ; Dividir A/B y almacenar el resultado en A
    add a, 80      ; Sumar 80 para obtener el tile correspondiente
    ld [hl+], a     ; Almacenar el tile de las decenas en la quinta posición

    ; El dígito de las unidades es el resto de la división entre 10
    ld a, b
    add a, 80      ; Sumar 80 para obtener el tile correspondiente
    ld [hl], a     ; Almacenar el tile de las unidades en la sexta posición

    ret            ; Regresar de la función


; Entrada: A = Dividendo, B = Divisor
; Salida: A = Resultado de la división, B = Resto de la división
div8:
    xor a          ; Limpiar el acumulador A
    ld c, 8        ; Inicializar el contador a 8 bits
div8_loop:
    rl a          ; Rotar A a la izquierda, el bit menos significativo se copia en el carry
    rl b          ; Rotar B a la izquierda, el bit menos significativo se copia en el carry
    jr nc, div8_skip ; Saltar si el carry es 0 (no hay divisor)
    sub b         ; Restar el divisor al dividendo
div8_skip:
    dec c         ; Decrementar el contador
    jr nz, div8_loop ; Repetir el bucle si el contador no es 0
    ld b, a       ; Almacenar el resto en B
    ret


; Entrada: wScoreBuffer = Variable de 6 bytes (3 dígitos, 3 tiles)
; Salida: El puntaje se imprime en la pantalla
print_score:
    ld hl, wScoreBuffer ; Cargar la dirección de wScoreBuffer
    
    ; Imprimir el dígito y tile de las centenas
    ld a, [hl+]     ; Cargar el dígito de las centenas
    ld de, $9A10   ; Establecer la posición de impresión para las centenas
    ld [de], a     ; Escribir el tile en la VRAM
    
    ; Imprimir el dígito y tile de las decenas    
    ld a, [hl+]     ; Cargar el dígito de las decenas
    inc de          ; DE = $9A11
    ld [de], a     ; Escribir el tile en la VRAM

    ; Imprimir el dígito y tile de las unidades
    ld a, [hl]     ; Cargar el dígito de las unidades
    inc de          ; DE = $9A12
    ld [de], a     ; Escribir el tile en la VRAM
    
    ret            ; Regresar de la función


lose_a_life:
    ; Decrementar el número de vidas
    ld a, [wLives]
    dec a
    ld [wLives], a    ; Guardar el nuevo valor
    
    ; Encontrar la posición correcta del último corazón
    ld a, [wLives]    ; Cargar el nuevo número de vidas
    ld b, a           ; Guardarlo en B para comparación
    
    ; Calcular la posición en VRAM para el corazón a borrar
    ld hl, $9A01      ; Posición base de los corazones en VRAM
    ld a, b           ; Recuperar el número de vidas
    add l             ; Añadir al offset base
    ld l, a           ; HL ahora apunta al corazón que queremos borrar
    
    ; Borrar el corazón reemplazándolo con un espacio
    ld a, EMPTY_TILE
    ld [hl], a
    
    ; Marcar que el HUD necesita actualizarse
    ld a, 1
    ld [wLivesChanged], a
    
    ret