INCLUDE "hardware.inc"

SECTION "Intro Screen Tiles", ROM0
intro_text_tiles:
    ; Tile 0: Empty/background tile (16 bytes)
    db $00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00

    ; Tile 1: P (16 bytes)
    db $FC,$FC,$C6,$C6,$C6,$C6,$FC,$FC
    db $C0,$C0,$C0,$C0,$C0,$C0,$00,$00

    ; Tile 2: R (16 bytes)
    db $FC,$FC,$C6,$C6,$C6,$C6,$FC,$FC
    db $CC,$CC,$C6,$C6,$C6,$C6,$00,$00

    ; Tile 3: E (16 bytes)
    db $FE,$FE,$C0,$C0,$C0,$C0,$FC,$FC
    db $C0,$C0,$C0,$C0,$FE,$FE,$00,$00

    ; Tile 4: S (16 bytes)
    db $FE,$FE,$C0,$C0,$C0,$C0,$FE,$FE
    db $06,$06,$06,$06,$FC,$FC,$00,$00

    ; Tile 5: B (16 bytes)
    db $FC,$FC,$C6,$C6,$C6,$C6,$FC,$FC
    db $C6,$C6,$C6,$C6,$FC,$FC,$00,$00

    ; Tile 6: T (16 bytes)
    db $FE,$FE,$18,$18,$18,$18,$18,$18
    db $18,$18,$18,$18,$18,$18,$00,$00

    ; Tile 7: O (16 bytes)
    db $7C,$7C,$C6,$C6,$C6,$C6,$C6,$C6
    db $C6,$C6,$C6,$C6,$7C,$7C,$00,$00

    ; Tile 8: A (16 bytes)
    db $7C,$7C,$C6,$C6,$C6,$C6,$FE,$FE
    db $C6,$C6,$C6,$C6,$C6,$C6,$00,$00
intro_text_tiles_end:

SECTION "Game Over Screen Tiles", ROM0
game_over_tiles:
    ; Tile 0: Empty (blank) tile
    db $00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00

    ; Tile 1: G
    db $7E,$7E,$C0,$C0,$C0,$C0,$CE,$CE
    db $C6,$C6,$C6,$C6,$7E,$7E,$00,$00

    ; Tile 2: A
    db $7E,$7E,$C6,$C6,$C6,$C6,$FE,$FE
    db $C6,$C6,$C6,$C6,$C6,$C6,$00,$00

    ; Tile 3: M
    db $C6,$C6,$EE,$EE,$FE,$FE,$D6,$D6
    db $C6,$C6,$C6,$C6,$C6,$C6,$00,$00

    ; Tile 4: E
    db $FE,$FE,$C0,$C0,$C0,$C0,$FC,$FC
    db $C0,$C0,$C0,$C0,$FE,$FE,$00,$00

    ; Tile 5: O
    db $7C,$7C,$C6,$C6,$C6,$C6,$C6,$C6
    db $C6,$C6,$C6,$C6,$7C,$7C,$00,$00

    ; Tile 6: V
    db $C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6
    db $6C,$6C,$38,$38,$10,$10,$00,$00

    ; Tile 7: R
    db $FC,$FC,$C6,$C6,$C6,$C6,$FC,$FC
    db $DC,$DC,$CE,$CE,$C6,$C6,$00,$00
game_over_tiles_end:

SECTION "Counter", WRAM0
wFrameCounter: db

SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db

SECTION "Game State", WRAM0
wGameState: db        ; 0 = Title, 1 = Playing, 2 = Game Over

SECTION "Ball Data", WRAM0
wBallMomentumX: db
wBallMomentumY: db

SECTION "Main", ROM0[$0150]
main:
    ;; Show intro screen first
    call show_intro_screen
    
    ; After B is pressed, first clear the text
    call switch_screen_off
    
    ; Clear the text line
    ld hl, $9800 + (32 * 8) + 2
    ld b, 16
.clear_text
    ld [hl], 0
    inc hl
    dec b
    jr nz, .clear_text

    ; Initialize game state
    ld a, 1            ; Set to playing state
    ld [wGameState], a

    ; Copia los tiles PARA EL FONDO
    ld de, tilesfondo
    ld hl, $9000
    ld bc, tilesfondoend - tilesfondo
    call mem_copy

    ; Copia el tilemap
    ld de, mapafondo
    ld hl, $9800
    ld bc, mapafondoend - mapafondo
    call mem_copy

    call inicializarNave
    call initializeBullet
    call initialize_level_system
    call initialize_enemies
    
    call InitHUD
    call clear_oam
    call setup_screen

    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

    xor a
    ld [wFrameCounter], a
    ld [wCurKeys], a
    ld [wNewKeys], a

game_loop:
    ; Check game state
    ld a, [wGameState]
    cp 2                  ; Check if game over
    jp z, show_game_over_screen

    call update_keys
    call updateNave
    call UpdateBulletLogic
    call move_enemies
    call enemies_shoots
    call check_bullet_enemy_collisions
    call check_bullet_player_collisions
    call check_level_complete

    ; Check level completion
    call check_level_complete
    ld a, [wLevelComplete]
    and a
    call nz, advance_level

    call UpdateHUDLogic
    
    call wait_vblank_start


    call UpdatePlayer_UpdateSprite  ; Update player sprite first SI PONEMOS ESTO PRIMERA EL JUGADOR NO SE CONGELA
    call copy_enemies_to_oam       ; Finally update enemies

    call UpdateBulletSprites       ; Then update bullets

    ; call copy_enemies_to_oam
    ; call UpdateBulletSprites
    ; call UpdatePlayer_UpdateSprite
    call UpdateHUDGraphics
    
    jp game_loop

show_intro_screen:
    ; Turn off the screen
    call switch_screen_off

    ; Load intro text tiles into VRAM at $9000
    ld de, intro_text_tiles
    ld hl, $9000          
    ld bc, intro_text_tiles_end - intro_text_tiles
    call mem_copy

    ; Write "PRESS B TO START" centered
    ld hl, $9800 + (32 * 8) + 2  ; Center both vertically and horizontally

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

    ; Set up palette
    ld a, %11100100
    ld [rBGP], a

    ; Turn screen back on with ONLY background enabled
    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a

.wait_for_start:
    call wait_vblank_start
    call update_keys
    
    ld a, [wNewKeys]
    and PADF_B
    jr z, .wait_for_start
    
    ret

show_game_over_screen::
    ; Turn off the screen
    call switch_screen_off
    
    ; Load game over tiles into VRAM starting at $9000
    ld de, game_over_tiles
    ld hl, $9000
    ld bc, game_over_tiles_end - game_over_tiles
    call mem_copy

    ; Load intro text tiles right after game over tiles
    ; Game over tiles are 8 tiles (0-7), so intro tiles start at tile 8
    ld de, intro_text_tiles
    ld hl, $9080        ; $9000 + (8 tiles * 16 bytes per tile)
    ld bc, intro_text_tiles_end - intro_text_tiles
    call mem_copy

    ; Clear ALL tilemap to empty tiles (tile 0)
    ld hl, $9800
    ld bc, 32*32        ; Full background size
.clear_loop:
    xor a               ; Empty tile (now points to our blank tile)
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, .clear_loop

    ; Write "GAME OVER" centered using game over tiles (0-7)
    ld hl, $9800 + (32 * 8) + 5  ; Center horizontally on line 8
    
    ; Write "GAME"
    ld [hl], 1        ; G
    inc hl
    ld [hl], 2        ; A
    inc hl
    ld [hl], 3        ; M
    inc hl
    ld [hl], 4        ; E
    inc hl
    
    ; Space
    inc hl
    
    ; Write "OVER"
    ld [hl], 5        ; O
    inc hl
    ld [hl], 6        ; V
    inc hl
    ld [hl], 4        ; E
    inc hl
    ld [hl], 7        ; R

    ; Write "PRESS B TO START" two lines below using intro tiles (starting at tile 8)
    ld hl, $9800 + (32 * 10) + 2  ; Two lines below GAME OVER
    
    ; Write "PRESS" (using intro tiles, adding 8 to each tile number)
    ld [hl], 8+1      ; P (intro tile 1)
    inc hl
    ld [hl], 8+2      ; R (intro tile 2)
    inc hl
    ld [hl], 8+3      ; E (intro tile 3)
    inc hl
    ld [hl], 8+4      ; S (intro tile 4)
    inc hl
    ld [hl], 8+4      ; S (intro tile 4)
    inc hl
    
    ; Space
    ld [hl], 8+0      ; Empty tile
    inc hl
    
    ; Write "B"
    ld [hl], 8+5      ; B (intro tile 5)
    inc hl
    
    ; Space
    ld [hl], 8+0      ; Empty tile
    inc hl
    
    ; Write "TO"
    ld [hl], 8+6      ; T (intro tile 6)
    inc hl
    ld [hl], 8+7      ; O (intro tile 7)
    inc hl
    
    ; Space
    ld [hl], 8+0      ; Empty tile
    inc hl
    
    ; Write "START"
    ld [hl], 8+4      ; S (intro tile 4)
    inc hl
    ld [hl], 8+6      ; T (intro tile 6)
    inc hl
    ld [hl], 8+8      ; A (intro tile 8)
    inc hl
    ld [hl], 8+2      ; R (intro tile 2)
    inc hl
    ld [hl], 8+6      ; T (intro tile 6)
    
    ; Turn screen back on
    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a
    
    ; Set game state to game over
    ld a, 2
    ld [wGameState], a
    
.wait_for_restart:
    call wait_vblank_start
    call update_keys
    
    ld a, [wNewKeys]
    and PADF_B
    jr z, .wait_for_restart

    ; When B is pressed, first clear both text lines before restarting
    call switch_screen_off    ; Turn off screen while we clear
    
    ; Clear the "GAME OVER" line
    ld hl, $9800 + (32 * 8) + 5  ; Position of "GAME OVER"
    ld b, 9                      ; Length of "GAME OVER" including space
.clear_game_over
    xor a                        ; Load 0 (empty tile)
    ld [hl+], a
    dec b
    jr nz, .clear_game_over
    
    ; Clear the "PRESS B TO START" line
    ld hl, $9800 + (32 * 10) + 2  ; Position of "PRESS B TO START"
    ld b, 16                      ; Length of "PRESS B TO START" including spaces
.clear_press_b
    xor a                         ; Load 0 (empty tile)
    ld [hl+], a
    dec b
    jr nz, .clear_press_b
    
    ; Reset game state
    xor a
    ld [wGameState], a
    
    ; Reset score
    xor a
    ld [wScore], a
    ld a, 1
    ld [wScoreChanged], a
    
    ; Reset lives
    ld a, 3
    ld [wLives], a
    ld a, 1
    ld [wLivesChanged], a
    
    ; Initialize game components
    call inicializarNave
    call initializeBullet
    call initialize_level_system
    call initialize_enemies
    call InitHUD
    call clear_oam

    ; Set game state to playing
    ld a, 1
    ld [wGameState], a

    ; Set up screen (including turning it on with proper flags)
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    ld [rLCDC], a

    ; Set up palettes
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

    ; Reset other variables
    xor a
    ld [wFrameCounter], a
    ld [wCurKeys], a
    ld [wNewKeys], a

    jp game_loop        ; Jump directly to game loop

restart_game:
    ; Reset game state
    xor a
    ld [wGameState], a
    
    ; Reset score
    xor a
    ld [wScore], a
    ld a, 1
    ld [wScoreChanged], a
    
    ; Reset lives
    ld a, 3
    ld [wLives], a
    ld a, 1
    ld [wLivesChanged], a
    
    ; Reinitialize game components
    call inicializarNave
    call initializeBullet
    call initialize_level_system
    call initialize_enemies
    call InitHUD
    call clear_oam
    
    ; Restart main game loop
    jp main

wait_vblank_start:
    .loop
        ld a, [rLY]
        cp 144
        jr nz, .loop
    ret

switch_screen_off:
    call wait_vblank_start
    ld hl, rLCDC
    res 7, [hl]
    ret

switch_screen_on:
    ldh a, [rLCDC]
    set 7, a
    ldh [rLCDC], a
    ret

setup_screen:
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    ld [rLCDC], a
    ret

mem_copy:
    .loop
        ld a, [de]
        ld [hl+], a
        inc de
        dec bc
        ld a, b
        or a, c
        jr nz, .loop
    ret

clear_oam:
    xor a
    ld b, 160
    ld hl, _OAMRAM
    .loop
        ld [hl+], a
        dec b
        jr nz, .loop
    ret

my_ret:
    ret

update_keys:
    ld a, P1F_GET_BTN
    call one_nibble
    ld b, a

    ld a, P1F_GET_DPAD
    call one_nibble
    swap a
    xor b
    ld b, a

    ld a, P1F_GET_NONE
    ldh [rP1], a

    ld a, [wCurKeys]
    xor b
    and b
    ld [wNewKeys], a
    ld a, b
    ld [wCurKeys], a

    ret

one_nibble:
    ldh [rP1], a
    call my_ret
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    or a, $F0
    ret