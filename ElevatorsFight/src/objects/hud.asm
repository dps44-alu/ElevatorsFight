INCLUDE "hardware.inc"    ; Include hardware constants

; Constants for HUD tiles
DEF HUD_TILE_START EQU $80 ; Starting tile number for our HUD tiles

SECTION "HUD Variables", WRAM0
DEF FIRST_FREE_OAM_SLOT EQU 12 * 4  ; Each sprite uses 4 bytes

wScore: ds 1          ; 1 bytes for score (0-100)
wLives: db            ; 1 byte for lives
wScoreChanged: db     ; Flag to indicate if score needs updating
wLivesChanged: db     ; Flag to indicate if lives need updating
wScoreBuffer: ds 3    ; Buffer to hold the score digits for display
wLivesBuffer: ds 3    ; Buffer to hold the lives display data

SECTION "HUD Tiles", ROM0
hud_tiles:
    ; Numbers 0-9 tiles (16 bytes each)
    ; [Your existing number tiles 0-9...]
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
    ; Letter tiles for "SCORE:" (16 bytes each)
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
    xor a
    ld [wScoreChanged], a
    ld [wLivesChanged], a
    ret

UpdateHUDLogic::
    ld a, [wScoreChanged]
    and a
    jr z, .checkLives       ; If score hasn't changed, check lives

    call convert_score      ; Convert score to digits
    
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
    ld a, HEART_TILE
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
    jr z, .updateLives
    
    call print_score
    
    xor a
    ld hl, wScoreChanged
    ld [hl], a
    
.updateLives:
    ld a, [wLivesChanged]
    and a
    ret z
    
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
    ld a, [wScore]          ; A = Dividendo

    ; Calcula las centenas
    ld b, 100                   ; Coloca 100 en B para dividir.
    call div_a_by_b                        
    add $80
    ld [wScoreBuffer], a        ; Almacena el dígito de las centenas en wScoreBuffer.
    ld a, b
    
    ; Calcula las decenas
    ld b, 10                    ; Coloca 10 en B para dividir.
    call div_a_by_b                    
    add $80
    ld [wScoreBuffer + 1], a    ; Almacena el dígito de las decenas en wScoreBuffer + 1.
    ld a, b
    
    ; Calcula las unidades
    ld b, 1
    call div_a_by_b
    xor a
    add $80
    ld [wScoreBuffer + 2], a    ; Almacena el dígito de las unidades en wScoreBuffer + 2.
    
    ret                         ; Regresa de la función.


; A -> Dividendo (wScore)
; B -> Divisor (1, 10 ,100)
; C -> Resultado
div_a_by_b:
    ld c, 0                 ; C = Resultado

    .div_loop
        cp b                ; A - B            
        jr c, .div_end      ; Si A > B está acabada
        inc c               ; Sino C++
        sub b               ; A -= B
        jr .div_loop

    .div_end
        ld b, a             ; B = A
        ld a, c             ; A = C = Resultado

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


; Your life loss function
lose_a_life:
    ; Decrease lives
    ld a, [wLives]
    dec a
    ld [wLives], a    
    
    ; Check if game over (lives = 0)
    and a
    jp z, show_game_over_screen    ; Jump to game over if no lives left
    
    ; If not game over, continue with normal life loss routine
    ld b, a           
    ld hl, $9A01      
    ld a, b           
    add l             
    ld l, a           
    
    ld a, EMPTY_TILE
    ld [hl], a
    
    ld a, 1
    ld [wLivesChanged], a
    ret