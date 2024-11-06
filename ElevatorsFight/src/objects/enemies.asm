INCLUDE "objects/constants.asm"

SECTION "Enemy Variables", WRAM0
wEnemyArray:        DS MAX_ENEMIES * ENEMY_STRUCT_SIZE  ; Array to store enemy data
wCurrentEnemies:    DS 1                                ; Current number of active enemies
wEnemyTimer:        DS 1                                ; Shared movement timer
wEnemyDelayShoot:   DS MAX_ENEMIES                      ; Array of delay between shots for each enemy
wShootTimer:        DS 1                                ; Timer between enemy shots
wLastShootingEnemy: DS 1                                ; Index of last enemy that shot
wFailedAttempts:    DS 1                                ; Counter for failed shooting attempts

DEF ENEMY_DELAY_SHOOT   EQU 60     ; 1 shot every 3 seconds
DEF MAX_FAILED_ATTEMPTS EQU 5       ; Maximum number of failed attempts before forcing a shot
DEF RANDOM_SEED_ADDR    EQU $FFE1   ; Using unused hardware address for random seed


SECTION "Enemy Code", ROM0

; Initialize all enemies
initialize_enemies::
    ; Reset enemy counter based on current level
    ld a, [wCurrentLevel]    ; wCurrentLevel is defined in levels.asm
    cp 1
    jr nz, .check_level2
    ld a, TOTAL_ENEMIES_LVL1
    jr .set_enemies
.check_level2:
    cp 2
    jr nz, .level3
    ld a, TOTAL_ENEMIES_LVL2
    jr .set_enemies
.level3:
    ld a, TOTAL_ENEMIES_LVL3

.set_enemies:
    ld [wCurrentEnemies], a
    
    ; Reset timer
    xor a
    ld [wEnemyTimer], a
    ld [wShootTimer], a
    ld [wLastShootingEnemy], a
    
    ; Initialize random seed
    ld a, [rDIV]      ; Get a semi-random value from divider register
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
    jr z, .setup_level1
    cp 2
    jr z, .setup_level2
    jp .setup_level3

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

.init_done:
    call copy_enemy_tiles_to_vram
    ret

; Copy enemy sprite data to VRAM
copy_enemy_tiles_to_vram:
    ld de, nave2
    ld hl, $8020
    ld bc, nave2end - nave2
    call mem_copy
    ret

; Update OAM for all enemies
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
    cp MOVE_DELAY
    ret nz

    ; Reset timer
    xor a
    ld [wEnemyTimer], a

    ; Move each enemy
    ld hl, wEnemyArray
    ld b, MAX_ENEMIES      ; Use MAX_ENEMIES here instead of wCurrentEnemies

.move_loop:
    push bc
    push hl

    ; Check if enemy is active
    ld bc, ENEMY_ACTIVE_OFFSET
    add hl, bc         ; Point to active status
    ld a, [hl]
    and a
    jr z, .next_enemy  ; Skip if inactive

    ; Get back to start of enemy struct
    pop hl
    push hl
    
    ; Get X position and direction
    ld a, [hl]         ; Get X position
    ld b, a            ; Store X in B
    inc hl
    inc hl             ; Point to direction
    ld a, [hl]         ; Get direction
    and a              ; Check if 0 (right) or 1 (left)
    jr nz, .move_left  ; If direction is 1, move left

.move_right:
    ld a, b            ; Get X position back
    cp ENEMY_MAX_X     ; Compare with right boundary
    jr nc, .change_to_left
    add ENEMY_SPEED    ; Move right
    pop hl             ; Get array pointer
    push hl
    ld [hl], a         ; Update X position
    jr .next_enemy

.move_left:
    ld a, b            ; Get X position back
    cp ENEMY_MIN_X     ; Compare with left boundary
    jr c, .change_to_right
    sub ENEMY_SPEED    ; Move left
    pop hl             ; Get array pointer
    push hl
    ld [hl], a         ; Update X position
    jr .next_enemy

.change_to_left:
    ; First update direction to left (1)
    pop hl             ; Get array pointer
    push hl
    inc hl
    inc hl             ; Point to direction
    ld a, 1
    ld [hl], a         ; Set direction to left
    ; Then move one step left
    dec hl
    dec hl             ; Back to X position
    ld a, [hl]         ; Get current X
    sub ENEMY_SPEED    ; Move left
    ld [hl], a         ; Update X position
    jr .next_enemy

.change_to_right:
    ; First update direction to right (0)
    pop hl             ; Get array pointer
    push hl
    inc hl
    inc hl             ; Point to direction
    xor a
    ld [hl], a         ; Set direction to right
    ; Then move one step right
    dec hl
    dec hl             ; Back to X position
    ld a, [hl]         ; Get current X
    add ENEMY_SPEED    ; Move right
    ld [hl], a         ; Update X position

.next_enemy:
    pop hl             ; Restore array pointer
    ld de, ENEMY_STRUCT_SIZE
    add hl, de         ; Point to next enemy
    pop bc
    dec b
    jr nz, .move_loop
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
    
    ; Check if selected enemy is active
    ld hl, wEnemyArray
    ld b, 0
    ld c, a
    add hl, bc         ; Point to enemy struct
    
    push hl            ; Save enemy pointer
    ld bc, 3          ; Offset to active status
    add hl, bc
    ld a, [hl]        ; Get active status
    pop hl            ; Restore enemy pointer
    and a
    jr nz, .shoot_with_enemy   ; If active, shoot with this enemy

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

.shoot_with_enemy:
    ; Save this as last shooting enemy
    ld [wLastShootingEnemy], a

    ; DE = enemy position for shooting
    push hl
    pop de
    push de
    push bc

    ; Find inactive bullet
    ld bc, 0          ; Use C as counter
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

    ; Set bullet X position
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

.no_free_bullets:
    pop bc
    pop de

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