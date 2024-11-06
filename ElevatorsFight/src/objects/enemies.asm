include "objects/constants.asm"
include "hardware.inc"
SECTION "Enemy Variables", WRAM0
wEnemyArray:        DS MAX_ENEMIES * ENEMY_STRUCT_SIZE  ; Array to store enemy data
wCurrentEnemies:    DS 1                                ; Current number of active enemies
wEnemyTimer:        DS 1                                ; Shared movement timer
wEnemyDelayShoot:   DS MAX_ENEMIES                      ; Array of delay between shots for each enemy
wShootTimer:        DS 1                                ; Timer between enemy shots
wLastShootingEnemy: DS 1                                ; Index of last enemy that shot
wFailedAttempts:    DS 1                                ; Counter for failed shooting attempts


DEF ENEMY_DELAY_SHOOT   EQU 60    ; 60 = 1 disparo por segundo
DEF MAX_FAILED_ATTEMPTS EQU 5       ; Maximum number of failed attempts before forcing a shot
DEF RANDOM_SEED_ADDR    EQU $FFE1   ; Using unused hardware address for random seed


SECTION "Enemy Code", ROM0

; Initialize all enemies
initialize_enemies::
    ; Reset enemy counter based on current level
    ld a, [wCurrentLevel]    
    cp 1
    jr nz, .check_level2
    ld a, TOTAL_ENEMIES_LVL1
    jr .set_enemies
.check_level2:
    ld a, [wCurrentLevel]
    cp 2
    jr nz, .check_level3
    ld a, TOTAL_ENEMIES_LVL2
    jr .set_enemies
.check_level3:
    ld a, [wCurrentLevel]
    cp 3
    jr nz, .check_level4
    ld a, TOTAL_ENEMIES_LVL3
    jr .set_enemies
.check_level4:
    ld a, [wCurrentLevel]
    cp 4
    jr nz, .check_level5
    ld a, TOTAL_ENEMIES_LVL4
    jr .set_enemies
.check_level5:
    ld a, [wCurrentLevel]
    cp 5
    jr nz, .check_level6
    ld a, TOTAL_ENEMIES_LVL5
    jr .set_enemies
.check_level6:
    ld a, TOTAL_ENEMIES_LVL6

.set_enemies:
    ld [wCurrentEnemies], a
    
    ; Reset timer
    xor a
    ld [wEnemyTimer], a
    ld [wShootTimer], a
    ld [wLastShootingEnemy], a
    
    ; Initialize random seed
    ld a, [rDIV]
    ld [RANDOM_SEED_ADDR], a

    ; Initialize the delayShoot array
    ld hl, wEnemyDelayShoot
    ld a, ENEMY_DELAY_SHOOT
    ld c, MAX_ENEMIES

    .delay_shoot_loop
        ld [hl+], a
        dec c
        jr nz, .delay_shoot_loop

    ; Clear all enemies first
    call clear_enemies

    ; Initialize enemy formation based on level
    ld a, [wCurrentLevel]
    cp 1
    jp z, .setup_level1
    cp 2
    jp z, .setup_level2
    cp 3
    jp z, .setup_level3
    cp 4
    jp z, .setup_level4
    cp 5
    jp z, .setup_level5
    cp 6
    jp z, .setup_level6
    jp .setup_level1    ; Default to level 1 if unknown level

; Los setups de los niveles originales (1-3)
.setup_level1:
    ; Row formation (3 enemies)
    ld hl, wEnemyArray
    ld b, TOTAL_ENEMIES_LVL1
    ld c, 0           ; Spacing counter
.l1_loop:
    ; X position
    ld a, 40
    add a, c
    ld [hl+], a       
    ; Y position
    ld a, 40
    ld [hl+], a
    ; Direction
    xor a
    ld [hl+], a
    ; Active status
    ld a, 1
    ld [hl+], a
    ; Spacing
    ld a, 30
    add a, c
    ld c, a
    dec b
    jp nz, .l1_loop
    jp .init_done

.setup_level2:
    ; V formation (5 enemies)
    ld hl, wEnemyArray
    ; First row (3 enemies)
    ; Enemy 1
    ld a, 40          ; X
    ld [hl+], a
    ld a, 30          ; Y
    ld [hl+], a
    xor a             ; Direction
    ld [hl+], a
    ld a, 1           ; Active
    ld [hl+], a
    ; Enemy 2
    ld a, 70          ; X
    ld [hl+], a
    ld a, 30          ; Y
    ld [hl+], a
    xor a             ; Direction
    ld [hl+], a
    ld a, 1           ; Active
    ld [hl+], a
    ; Enemy 3
    ld a, 100         ; X
    ld [hl+], a
    ld a, 30          ; Y
    ld [hl+], a
    xor a             ; Direction
    ld [hl+], a
    ld a, 1           ; Active
    ld [hl+], a
    ; Second row (2 enemies)
    ld a, 55          ; X
    ld [hl+], a
    ld a, 50          ; Y
    ld [hl+], a
    xor a             ; Direction
    ld [hl+], a
    ld a, 1           ; Active
    ld [hl+], a
    ld a, 85          ; X
    ld [hl+], a
    ld a, 50          ; Y
    ld [hl+], a
    xor a             ; Direction
    ld [hl+], a
    ld a, 1           ; Active
    ld [hl+], a
    jp .init_done

.setup_level3:
    ; Diamond formation (7 enemies)
    ld hl, wEnemyArray
    ; Top enemy
    ld a, 70          ; X
    ld [hl+], a
    ld a, 20          ; Y
    ld [hl+], a
    xor a             ; Direction
    ld [hl+], a
    ld a, 1           ; Active
    ld [hl+], a
    ; Middle row (3 enemies)
    ld a, 40          ; X
    ld [hl+], a
    ld a, 40          ; Y
    ld [hl+], a
    xor a             ; Direction
    ld [hl+], a
    ld a, 1           ; Active
    ld [hl+], a
    ld a, 70          ; X
    ld [hl+], a
    ld a, 40          ; Y
    ld [hl+], a
    xor a             ; Direction
    ld [hl+], a
    ld a, 1           ; Active
    ld [hl+], a
    ld a, 100         ; X
    ld [hl+], a
    ld a, 40          ; Y
    ld [hl+], a
    xor a             ; Direction
    ld [hl+], a
    ld a, 1           ; Active
    ld [hl+], a
    ; Bottom row (3 enemies)
    ld a, 40          ; X
    ld [hl+], a
    ld a, 60          ; Y
    ld [hl+], a
    xor a             ; Direction
    ld [hl+], a
    ld a, 1           ; Active
    ld [hl+], a
    ld a, 70          ; X
    ld [hl+], a
    ld a, 60          ; Y
    ld [hl+], a
    xor a             ; Direction
    ld [hl+], a
    ld a, 1           ; Active
    ld [hl+], a
    ld a, 100         ; X
    ld [hl+], a
    ld a, 60          ; Y
    ld [hl+], a
    xor a             ; Direction
    ld [hl+], a
    ld a, 1           ; Active
    ld [hl+], a
    jp .init_done
.setup_level4:
    ; Diagonal formation (8 enemies)
    ld hl, wEnemyArray
    ld b, TOTAL_ENEMIES_LVL4
    ld c, 0           ; Spacing counter
    
.l4_loop:
    ; X position (diagonal spacing)
    ld a, 20
    add a, c
    ld [hl+], a       
    ; Y position
    ld a, 30
    add a, c
    ld [hl+], a
    ; Direction (alternating diagonal right/left)
    ld a, c
    and %00000001     ; Check if even/odd
    add a, DIR_DIAGONAL_RIGHT  ; 4 or 5 for diagonal movement
    ld [hl+], a
    ; Active status
    ld a, 1
    ld [hl+], a
    ; Spacing
    ld a, 16
    add a, c
    ld c, a
    dec b
    jp nz, .l4_loop
    jp .init_done

.setup_level5:
    ; Up/Down formation (9 enemies in rows)
    ld hl, wEnemyArray
    
    ; First row (3 enemies moving down)
    ld b, 3
    ld c, 0
.l5_row1:
    ; X position
    ld a, 40
    add a, c
    ld [hl+], a
    ; Y position
    ld a, 20
    ld [hl+], a
    ; Direction (down)
    ld a, DIR_DOWN
    ld [hl+], a
    ; Active
    ld a, 1
    ld [hl+], a
    ; Spacing
    ld a, 30
    add a, c
    ld c, a
    dec b
    jr nz, .l5_row1
    
    ; Second row (3 enemies moving up)
    ld b, 3
    ld c, 0
.l5_row2:
    ; X position
    ld a, 40
    add a, c
    ld [hl+], a
    ; Y position
    ld a, 60
    ld [hl+], a
    ; Direction (up)
    ld a, DIR_UP
    ld [hl+], a
    ; Active
    ld a, 1
    ld [hl+], a
    ; Spacing
    ld a, 30
    add a, c
    ld c, a
    dec b
    jr nz, .l5_row2
    
    ; Middle row (3 enemies moving left/right)
    ld b, 3
    ld c, 0
.l5_row3:
    ; X position
    ld a, 40
    add a, c
    ld [hl+], a
    ; Y position
    ld a, 40
    ld [hl+], a
    ; Direction (right)
    xor a
    ld [hl+], a
    ; Active
    ld a, 1
    ld [hl+], a
    ; Spacing
    ld a, 30
    add a, c
    ld c, a
    dec b
    jr nz, .l5_row3
    jp .init_done

.setup_level6:
    ; Mixed formation (10 enemies with all patterns)
    ld hl, wEnemyArray
    ld b, TOTAL_ENEMIES_LVL6
    ld c, 0          ; Counter for position
    
.l6_loop:
    ; X position in zigzag
    ld a, 30
    add a, c
    ld [hl+], a
    
    ; Y position alternating
    ld a, c
    and %00000011    ; 0-3 pattern
    add a, 2         ; Avoid being too high
    sla a            ; Multiply by 16
    sla a
    sla a
    sla a
    ld [hl+], a
    
    ; Direction (cycling through all patterns)
    ld a, c
    and %00000111    ; 0-7 range for different directions
    ld [hl+], a
    
    ; Active
    ld a, 1
    ld [hl+], a
    
    ; Update spacing
    ld a, 12
    add a, c
    ld c, a
    
    dec b
    jp nz, .l6_loop
    jp .init_done
.init_done:
    call copy_enemy_tiles_to_vram
    ret

; Copy enemy sprite data to VRAM
; Copy enemy sprite data to VRAM based on current level
copy_enemy_tiles_to_vram:
    ; Get current level
    ld a, [wCurrentLevel]
    
    ; Compare with each level and jump to appropriate ship loading
    cp 1
    jr z, .load_ship1
    cp 2
    jr z, .load_ship2
    cp 3
    jr z, .load_ship3
    cp 4
    jr z, .load_ship4
    cp 5
    jr z, .load_ship5
    cp 6
    jr z, .load_ship6
    ; Default to ship1 if unknown level
    jr .load_ship1

.load_ship1:
    ld de, nave1
    ld bc, nave1end - nave1
    jr .do_copy

.load_ship2:
    ld de, nave2
    ld bc, nave2end - nave2
    jr .do_copy

.load_ship3:
    ld de, nave3
    ld bc, nave3end - nave3
    jr .do_copy

.load_ship4:
    ld de, nave4
    ld bc, nave4end - nave4
    jr .do_copy

.load_ship5:
    ld de, nave5
    ld bc, nave5end - nave5
    jr .do_copy

.load_ship6:
    ld de, nave6
    ld bc, nave6end - nave6
    ; Fall through to .do_copy

.do_copy:
    ld hl, $8020     ; Destination in VRAM (tile 2)
    call mem_copy
    ret
; Update OAM for all enemies
copy_enemies_to_oam::
    ld hl, wEnemyArray
    ld de, _OAMRAM + 44    ; Starting OAM address for enemies
    ld b, MAX_ENEMIES      ; Use MAX_ENEMIES instead of wCurrentEnemies here

.copy_loop:
    ; Check if enemy is active
    push bc
    ld a, [hl+]        ; Get X
    ld b, a
    ld a, [hl+]        ; Get Y
    ld c, a
    inc hl             ; Skip direction
    ld a, [hl+]        ; Get active status
    and a
    jr z, .skip_enemy  ; Skip if inactive

    ; Copy to OAM
    ld a, c
    ld [de], a         ; Y position
    inc de
    ld a, b
    ld [de], a         ; X position
    inc de
    ld a, 2            ; Tile number
    ld [de], a
    inc de
    xor a              ; Attributes
    ld [de], a
    inc de
    
    jr .continue

.skip_enemy:
    ; Clear OAM entry
    xor a
    ld [de], a
    inc de
    ld [de], a
    inc de
    ld [de], a
    inc de
    ld [de], a
    inc de

.continue:
    pop bc
    dec b
    jr nz, .copy_loop
    ret

; Move all active enemies
move_enemies::
    ; Update timer
    ld a, [wEnemyTimer]
    inc a
    ld [wEnemyTimer], a
    
    ; Get delay based on level
    ld a, [wCurrentLevel]
    cp 4
    jr c, .check_normal_delay   ; Levels 1-3 use normal delay
    
    ld a, [wEnemyTimer]
    cp 4                        ; Faster update for higher levels
    ret nz
    jr .continue_move

.check_normal_delay:
    ld a, [wEnemyTimer]
    cp MOVE_DELAY
    ret nz

.continue_move:
    ; Reset timer
    xor a
    ld [wEnemyTimer], a

    ; Move each enemy
    ld hl, wEnemyArray
    ld b, MAX_ENEMIES

.move_loop:
    push bc
    push hl

    ; Check if enemy is active
    ld bc, ENEMY_ACTIVE_OFFSET
    add hl, bc
    ld a, [hl]
    and a
    jp z, .next_enemy

    ; Get back to start of enemy struct
    pop hl
    push hl
    
    ; Get speed based on level
    push hl
    ld a, [wCurrentLevel]
    cp 4
    jr c, .normal_speed
    cp 5
    jr c, .speed_4
    cp 6
    jr c, .speed_5
    ld b, ENEMY_SPEED_LVL6
    jr .got_speed
.speed_4:
    ld b, ENEMY_SPEED_LVL4
    jr .got_speed
.speed_5:
    ld b, ENEMY_SPEED_LVL5
    jr .got_speed
.normal_speed:
    ld b, ENEMY_SPEED
.got_speed:
    pop hl

    ; Get direction and check pattern type
    inc hl
    inc hl
    ld a, [hl]        ; Get direction
    dec hl
    dec hl
    
    cp DIR_RIGHT
    jr z, .move_right
    cp DIR_LEFT
    jr z, .move_left
    cp DIR_UP
    jr z, .move_up
    cp DIR_DOWN
    jr z, .move_down
    cp DIR_DIAGONAL_RIGHT
    jr z, .move_diagonal_right
    cp DIR_DIAGONAL_LEFT
    jr z, .move_diagonal_left
    jr .next_enemy    ; Unknown direction, skip

.move_right:
    ; Original right movement code
    ld a, [hl]
    cp ENEMY_MAX_X
    jr nc, .change_dir_left
    add b              ; Add speed
    ld [hl], a
    jr .next_enemy

.move_left:
    ; Original left movement code
    ld a, [hl]
    cp ENEMY_MIN_X
    jr c, .change_dir_right
    sub b              ; Subtract speed
    ld [hl], a
    jr .next_enemy

.move_up:
    ; Move Y position up
    inc hl            ; Point to Y
    ld a, [hl]
    cp ENEMY_MIN_Y
    jr c, .change_dir_down
    sub b
    ld [hl], a
    jr .next_enemy

.move_down:
    ; Move Y position down
    inc hl            ; Point to Y
    ld a, [hl]
    cp ENEMY_MAX_Y
    jr nc, .change_dir_up
    add b
    ld [hl], a
    jr .next_enemy

.move_diagonal_right:
    ; Move both X and Y
    ld a, [hl]        ; X position
    cp ENEMY_MAX_X
    jr nc, .change_diagonal_left
    add b
    ld [hl+], a       ; Update X
    ld a, [hl]        ; Y position
    add b
    cp ENEMY_MAX_Y
    jr nc, .change_diagonal_left
    ld [hl], a        ; Update Y
    jr .next_enemy

.move_diagonal_left:
    ld a, [hl]        ; X position
    cp ENEMY_MIN_X
    jr c, .change_diagonal_right
    sub b
    ld [hl+], a       ; Update X
    ld a, [hl]        ; Y position
    sub b
    cp ENEMY_MIN_Y
    jr c, .change_diagonal_right
    ld [hl], a        ; Update Y
    jr .next_enemy

.change_dir_left:
    inc hl
    inc hl
    ld a, DIR_LEFT
    ld [hl], a
    jr .next_enemy

.change_dir_right:
    inc hl
    inc hl
    ld a, DIR_RIGHT
    ld [hl], a
    jr .next_enemy

.change_dir_up:
    inc hl
    inc hl
    ld a, DIR_UP
    ld [hl], a
    jr .next_enemy

.change_dir_down:
    inc hl
    inc hl
    ld a, DIR_DOWN
    ld [hl], a
    jr .next_enemy

.change_diagonal_left:
    inc hl
    inc hl
    ld a, DIR_DIAGONAL_LEFT
    ld [hl], a
    jr .next_enemy

.change_diagonal_right:
    inc hl
    inc hl
    ld a, DIR_DIAGONAL_RIGHT
    ld [hl], a

.next_enemy:
    pop hl
    ld de, ENEMY_STRUCT_SIZE
    add hl, de
    pop bc
    dec b
    jp nz, .move_loop
    ret
; Clear all enemies
clear_enemies:
    ld hl, wEnemyArray
    ld b, MAX_ENEMIES
.clear_loop:
    xor a
    ld [hl+], a        ; Clear X
    ld [hl+], a        ; Clear Y
    ld [hl+], a        ; Clear direction
    ld [hl+], a        ; Clear active status
    dec b
    jr nz, .clear_loop
    ret

; Check for collisions between bullets and enemies


; Enemy shooting logic
; Enemy shooting logic
enemies_shoots::
    ; Check if there are any active enemies
    ld a, [wCurrentEnemies]
    and a
    ret z               ; Return if no enemies

    ; Check if enough time has passed since last shot
    ld a, [wShootTimer]
    and a
    jr z, .try_shoot
    dec a
    ld [wShootTimer], a
    ret

.try_shoot:
    ; Reset timer for next shot
    ld a, ENEMY_DELAY_SHOOT
    ld [wShootTimer], a

    ; Get current number of enemies for random selection
    ld a, [wCurrentEnemies]
    ld b, a            ; Save number of enemies in B

    ; Initialize attempts counter
    xor a
    ld [wFailedAttempts], a

.find_shooter:
    ; Generate random enemy index
    call generate_random
    and %00000111      ; Limit to 0-7 range
    cp b              ; Compare with number of enemies
    jr nc, .find_shooter  ; If too high, try again

    ; Convert to enemy array index (multiply by 4 for struct size)
    sla a              ; × 2
    sla a              ; × 4
    
    ; Save the original index for later
    push af

    ; Check if selected enemy is active
    ld hl, wEnemyArray
    ld b, 0
    ld c, a
    add hl, bc         ; Point to enemy struct
    
    ; Double check enemy is still active before proceeding
    push hl            ; Save enemy struct pointer
    ld bc, 3          ; Offset to active status
    add hl, bc
    ld a, [hl]        ; Get active status
    pop hl            ; Restore enemy struct pointer
    
    ; If enemy is not active, pop saved index and try again
    and a
    jr z, .retry_find

    ; Enemy is active, get saved index back but keep it on stack
    pop af
    push af
    
    jr .shoot_with_enemy   ; If active, shoot with this enemy

.retry_find:
    pop af            ; Clean up stack
    ; Enemy wasn't active, increment failed attempts
    ld a, [wFailedAttempts]
    inc a
    ld [wFailedAttempts], a
    cp MAX_FAILED_ATTEMPTS
    jr z, .force_find_active   ; If too many failures, force find an active enemy
    jr .find_shooter

.force_find_active:
    ; Systematically check each enemy until we find an active one
    ld hl, wEnemyArray
    ld b, MAX_ENEMIES
    ld c, 0           ; Current enemy index * 4

.check_next:
    push hl
    push bc
    ld b, 0
    add hl, bc        ; Point to current enemy
    
    ; Check active status
    push hl
    ld bc, 3
    add hl, bc
    ld a, [hl]        ; Get active status
    pop hl
    
    pop bc
    pop hl
    
    and a
    jr nz, .found_active
    
    ; Move to next enemy
    ld a, c
    add 4
    ld c, a
    dec b
    jr nz, .check_next
    ret               ; If no active enemies found, return

.found_active:
    ld a, c           ; Get enemy index * 4 in A
    push af           ; Save index for consistency with other path

.shoot_with_enemy:
    ; At this point, we have a confirmed active enemy and its index is on the stack
    
    ; Save this as last shooting enemy
    pop af            ; Get index
    ld [wLastShootingEnemy], a

    ; Get enemy position
    ld hl, wEnemyArray
    ld b, 0
    ld c, a
    add hl, bc        ; Point to enemy struct

    ; Final active check before shooting
    push hl
    ld bc, 3
    add hl, bc
    ld a, [hl]
    pop hl
    and a
    ret z            ; Return if enemy became inactive

    ; Find inactive bullet
    ld bc, 0          ; Use C as counter
    push hl           ; Save enemy pointer
    ld hl, wBulletActive

.find_free_bullet:
    ld a, [hl]        ; Check bullet active status
    and a
    jr z, .bullet_found
    inc hl
    inc c
    ld a, c
    cp 10
    jr z, .no_free_bullets
    jr .find_free_bullet

.bullet_found:
    ; Activate bullet
    ld a, 1
    ld [hl], a        ; Set as active

    ; Set direction (1 = enemy bullet)
    ld hl, wBulletDirection
    add hl, bc
    ld a, 1
    ld [hl], a        ; Set as enemy bullet

    ; Get enemy pointer back
    pop hl            ; Restore enemy pointer

    ; Set bullet X position
    push hl           ; Save enemy pointer
    ld d, h
    ld e, l          ; DE = enemy struct pointer
    ld hl, wBulletPosX
    add hl, bc
    ld a, [de]        ; Get enemy X
    ld [hl], a        ; Set bullet X

    ; Set bullet Y position
    inc de            ; Point to enemy Y
    ld hl, wBulletPosY
    add hl, bc
    ld a, [de]        ; Get enemy Y
    add 7             ; Offset bullet position
    ld [hl], a        ; Set bullet Y
    
    pop hl            ; Clean up stack
    jr .end

.no_free_bullets:
    pop hl            ; Clean up stack

.end:
    ; Make random seed more random by adding timer value
    ld a, [wEnemyTimer]
    ld b, a
    ld a, [RANDOM_SEED_ADDR]
    add b
    ld [RANDOM_SEED_ADDR], a
    ret
; Generate random number using improved LFSR
generate_random:
    ; Get current seed
    ld a, [RANDOM_SEED_ADDR]
    ld b, a

    ; Rotate left through carry
    rlca
    
    ; XOR with original and timer for more randomness
    xor b
    ld b, a
    ld a, [wEnemyTimer]
    xor b
    
    ; Store back as new seed
    ld [RANDOM_SEED_ADDR], a
    
    ret
; Deactivate enemy at specified index
; Input: A = enemy index
desactivate_enemy::
    push hl
    push bc
    push de
    
    ; Save enemy index
    ld c, a            ; Save index in C
    
    ; Calculate enemy address
    ld hl, wEnemyArray
    ld d, 0
    ld e, ENEMY_STRUCT_SIZE
    
.multiply_loop:        ; Multiply index by ENEMY_STRUCT_SIZE
    ld a, c
    and a             ; Check if index is zero
    jr z, .done_multiply
    add hl, de        ; Add ENEMY_STRUCT_SIZE to HL
    dec c
    jr .multiply_loop
    
.done_multiply:
    ; Point to active status
    ld bc, ENEMY_ACTIVE_OFFSET
    add hl, bc
    
    ; Deactivate enemy
    xor a
    ld [hl], a
    
    ; Decrease enemy counter
    ld a, [wCurrentEnemies]
    dec a
    ld [wCurrentEnemies], a
    
    ; Check if level is complete
    and a               ; Check if zero enemies remain
    jr nz, .not_complete
    ld a, 1
    ld [wLevelComplete], a

.not_complete:
    pop de
    pop bc
    pop hl
    ret

; Multiply BC by A
; Returns: HL = BC * A
multiply::
    ld hl, 0
    and a
    ret z
.loop:
    add hl, bc
    dec a
    jr nz, .loop
    ret