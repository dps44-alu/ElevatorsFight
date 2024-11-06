include "hardware.inc"
include "objects/constants.asm"

DEF MAX_LEVEL EQU 1    ; Total number of levels

SECTION "Level Variables", WRAM0
wCurrentLevel:    DS 1    ; Current level (1-3)
wLevelComplete:   DS 1    ; Flag for level completion

SECTION "Win Screen Tiles", ROM0
win_screen_tiles:
    ; Tile 0: Empty (blank) tile
    db $00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00
    
    ; Tile 1: Y
    db $C6,$C6,$C6,$C6,$6C,$6C,$38,$38
    db $18,$18,$18,$18,$18,$18,$00,$00
    
    ; Tile 2: O
    db $7C,$7C,$C6,$C6,$C6,$C6,$C6,$C6
    db $C6,$C6,$C6,$C6,$7C,$7C,$00,$00
    
    ; Tile 3: U
    db $C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6
    db $C6,$C6,$C6,$C6,$7C,$7C,$00,$00
    
    ; Tile 4: W
    db $C6,$C6,$C6,$C6,$C6,$C6,$D6,$D6
    db $FE,$FE,$EE,$EE,$C6,$C6,$00,$00
    
    ; Tile 5: I
    db $7E,$7E,$18,$18,$18,$18,$18,$18
    db $18,$18,$18,$18,$7E,$7E,$00,$00
    
    ; Tile 6: N
    db $C6,$C6,$E6,$E6,$F6,$F6,$DE,$DE
    db $CE,$CE,$C6,$C6,$C6,$C6,$00,$00
    
    ; Tile 7: ! (Exclamation mark)
    db $18,$18,$18,$18,$18,$18,$18,$18
    db $18,$18,$00,$00,$18,$18,$00,$00
    
    ; Tile 8: P
    db $FC,$FC,$C6,$C6,$C6,$C6,$FC,$FC
    db $C0,$C0,$C0,$C0,$C0,$C0,$00,$00
    
    ; Tile 9: R
    db $FC,$FC,$C6,$C6,$C6,$C6,$FC,$FC
    db $CC,$CC,$C6,$C6,$C6,$C6,$00,$00
    
    ; Tile 10: E
    db $FE,$FE,$C0,$C0,$C0,$C0,$FC,$FC
    db $C0,$C0,$C0,$C0,$FE,$FE,$00,$00
    
    ; Tile 11: S
    db $7C,$7C,$C6,$C6,$C0,$C0,$7C,$7C
    db $06,$06,$C6,$C6,$7C,$7C,$00,$00
    
    ; Tile 12: B
    db $FC,$FC,$C6,$C6,$C6,$C6,$FC,$FC
    db $C6,$C6,$C6,$C6,$FC,$FC,$00,$00
    
    ; Tile 13: T
    db $FE,$FE,$18,$18,$18,$18,$18,$18
    db $18,$18,$18,$18,$18,$18,$00,$00
    
    ; Tile 14: C
    db $7C,$7C,$C6,$C6,$C0,$C0,$C0,$C0
    db $C0,$C0,$C6,$C6,$7C,$7C,$00,$00
    
win_screen_tiles_end:
SECTION "Level Code", ROM0


initialize_level_system::
    ld a, 1              ; Start with level 1
    ld [wCurrentLevel], a
    xor a
    ld [wLevelComplete], a
    ret

check_level_complete::
    ld a, [wCurrentEnemies]
    and a               ; Check if enemies = 0
    ret nz              ; Return if not complete
    
    ; Level is complete
    ld a, 1
    ld [wLevelComplete], a
    ret

advance_level::
    ld a, [wCurrentLevel]
    inc a
    cp MAX_LEVEL + 1
    jr z, .game_complete
    ; Start next level
    ld [wCurrentLevel], a
    xor a
    ld [wLevelComplete], a
    call initialize_enemies
    ret
.game_complete:
    jp show_win_screen 

show_win_screen::
    ; Turn off the screen
    call switch_screen_off
    
    ; Load win screen tiles into VRAM starting at $9000
    ld de, win_screen_tiles
    ld hl, $9000
    ld bc, win_screen_tiles_end - win_screen_tiles
    call mem_copy

    ; Clear ALL tilemap
    ld hl, $9800
    ld bc, 32*32
.clear_loop:
    ld a, 0            
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, .clear_loop

    ; Write "YOU WIN!" centered
    ld hl, $9800 + (32 * 8) + 5  
    
    ; Write "YOU WIN!" using win screen tiles
    ld [hl], 1        ; Y
    inc hl
    ld [hl], 2        ; O
    inc hl
    ld [hl], 3        ; U
    inc hl
    ld [hl], 0        ; Space
    inc hl
    ld [hl], 4        ; W
    inc hl
    ld [hl], 5        ; I
    inc hl
    ld [hl], 6        ; N
    inc hl
    ld [hl], 7        ; !

    ; Write "PRESS B TO CONTINUE"
    ld hl, $9800 + (32 * 10) + 1
    
    ; Write "PRESS"
    ld [hl], 8       ; P
    inc hl
    ld [hl], 9       ; R
    inc hl
    ld [hl], 10      ; E
    inc hl
    ld [hl], 11      ; S
    inc hl
    ld [hl], 11      ; S
    inc hl
    
    ; Space
    ld [hl], 0        
    inc hl
    
    ; Write "B"
    ld [hl], 12      ; B
    inc hl
    
    ; Space
    ld [hl], 0        
    inc hl
    
    ; Write "TO"
    ld [hl], 13      ; T
    inc hl
    ld [hl], 2       ; O
    inc hl
    
    ; Space
    ld [hl], 0        
    inc hl
    
    ; Write "CONTINUE"
    ld [hl], 14      ; C
    inc hl
    ld [hl], 2       ; O
    inc hl
    ld [hl], 6       ; N
    inc hl
    ld [hl], 13      ; T
    inc hl
    ld [hl], 5       ; I
    inc hl
    ld [hl], 6       ; N
    inc hl
    ld [hl], 3       ; U
    inc hl
    ld [hl], 10      ; E

    ; Turn screen back on
    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a
    
.wait_for_continue:
    call wait_vblank_start
    call update_keys
    
    ld a, [wNewKeys]
    and PADF_B
    jr z, .wait_for_continue

    ; When B is pressed, reload intro screen
    call switch_screen_off
    
    ; Load intro text tiles into VRAM at $9000
    ld de, intro_text_tiles
    ld hl, $9000          
    ld bc, intro_text_tiles_end - intro_text_tiles
    call mem_copy

    ; Clear ALL tilemap
    ld hl, $9800
    ld bc, 32*32
.clear_before_main:
    xor a
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, .clear_before_main

    ; Write "PRESS B TO START" centered
    ld hl, $9800 + (32 * 8) + 2  ; Center position for intro text

    ; Write "PRESS"
    ld [hl], 1        ; P
    inc hl
    ld [hl], 2        ; R
    inc hl
    ld [hl], 3        ; E
    inc hl
    ld [hl], 4        ; S
    inc hl
    ld [hl], 4        ; S
    inc hl
    
    ; Space
    ld [hl], 0
    inc hl
    
    ; Write "B"
    ld [hl], 5        ; B
    inc hl
    
    ; Space
    ld [hl], 0
    inc hl
    
    ; Write "TO"
    ld [hl], 6        ; T
    inc hl
    ld [hl], 7        ; O
    inc hl
    
    ; Space
    ld [hl], 0
    inc hl
    
    ; Write "START"
    ld [hl], 4        ; S
    inc hl
    ld [hl], 6        ; T
    inc hl
    ld [hl], 8        ; A
    inc hl
    ld [hl], 2        ; R
    inc hl
    ld [hl], 6        ; T

    ; Turn screen back on
    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a

    ; Now jump to main loop
    jp main