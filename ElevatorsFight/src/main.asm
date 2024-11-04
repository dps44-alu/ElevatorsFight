include "hardware.inc"
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

SECTION "Intro Screen Code", ROM0
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
    
    ; Write "START" - Now with proper A tile
    ld [hl], 4        ; S
    inc hl
    ld [hl], 6        ; T
    inc hl
    ld [hl], 8        ; A (proper A tile)
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

SECTION "Main", ROM0[$0150]
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

; Copia bytes de un área a otra
; DE: Origen
; HL: Destino
; BC: Tamaño
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

one_nibble:
    ldh [rP1], a
    call my_ret
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    or a, $F0
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

move:
    ld a, [_OAMRAM + 1]
    ld b, a
    
    .check_left
        ld a, [wCurKeys]
        and PADF_LEFT
        jr z, .check_right
        
        ld a, b
        dec a
        cp 15
        jr z, .done
        ld [_OAMRAM + 1], a
        jr .done
        
    .check_right
        ld a, [wCurKeys]
        and PADF_RIGHT
        jr z, .done
        
        ld a, b
        inc a
        cp 105
        jr z, .done
        ld [_OAMRAM + 1], a
        
    .done:
        ret

main:
    ;; Show intro screen first
    call show_intro_screen
    
    ; After A is pressed, first clear the text
    call switch_screen_off
    
    ; Clear the text line
    ld hl, $9800 + (32 * 8) + 2  ; Same position where we wrote the text
    ld b, 16                      ; Length of "PRESS A TO START"
.clear_text
    ld [hl], 0                    ; Write empty tile
    inc hl
    dec b
    jr nz, .clear_text

	

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

    ; Durante el primer frame de VBLANk, inicializa los registros display
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

    ; Inicializa las variables globales
    xor a
    ld [wFrameCounter], a
    ld [wCurKeys], a
    ld [wNewKeys], a

game_loop:
    ; Update game logic (no need to wait for VBlank)
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
    
    ; Wait for VBlank only before updating sprites
    call wait_vblank_start

    call copy_enemies_to_oam
    call UpdateBulletSprites
    call UpdatePlayer_UpdateSprite
    call UpdateHUDGraphics
    
    jp game_loop

SECTION "Counter", WRAM0
wFrameCounter: db

SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db

SECTION "Ball Data", WRAM0
wBallMomentumX: db
wBallMomentumY: db