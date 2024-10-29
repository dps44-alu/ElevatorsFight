INCLUDE "objects/constants.asm"

SECTION "Enemy Variables", WRAM0
wEnemyArray: DS MAX_ENEMIES * ENEMY_STRUCT_SIZE  ; Array to store enemy data
wCurrentEnemies: DS 1                            ; Current number of active enemies
wEnemyTimer: DS 1                                ; Shared movement timer

SECTION "Enemy Code", ROM0

; Initialize all enemies
initialize_enemies::
    ; Reset enemy counter
    ld a, TOTAL_ENEMIES_LVL1;mirar la variable de max enemies
    ld [wCurrentEnemies], a
    
    xor a
    ld [wEnemyTimer], a

    ; Initialize enemy array
    ld hl, wEnemyArray
    ld b, TOTAL_ENEMIES_LVL1
    ld c, 0           ; Enemy spacing counter

.init_loop:
    ; Set X position (spaced horizontally)
    ld a, 40
    add a, c          ; Add spacing
    ld [hl+], a       ; Store X
    
    ; Set Y position
    ld a, 40
    ld [hl+], a       ; Store Y
    
    ; Set direction (0 = right)
    xor a
    ld [hl+], a       ; Store direction
    
    ; Set active status (1 = active)
    ld a, 1
    ld [hl+], a       ; Store active status
    
    ; Increase spacing for next enemy
    ld a, 30
    add a, c
    ld c, a
    
    dec b
    jr nz, .init_loop

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
copy_enemies_to_oam::
    ld hl, wEnemyArray
    ld de, _OAMRAM + 44    ; Starting OAM address for enemies
    ld b, MAX_ENEMIES

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
; Move all active enemies; Move all active enemies
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
    ld b, MAX_ENEMIES

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

; Deactivate enemy at specified index
; Input: A = enemy index
; Deactivate enemy at specified index
; Input: A = enemy index
deactivate_enemy::
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
    
    pop de
    pop bc
    pop hl
    ret

; Multiply BC by A
; Returns: HL = BC * A
multiply:
    ld hl, 0
    and a
    ret z
.loop:
    add hl, bc
    dec a
    jr nz, .loop
    ret