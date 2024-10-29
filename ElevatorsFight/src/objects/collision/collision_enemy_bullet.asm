INCLUDE "objects/constants.asm"
SECTION "Collision Variables", WRAM0
wCollisionFlag: DS 1

SECTION "Collision Code", ROM0

; Check for collisions between bullets and enemies
; Modifies all registers

check_bullet_enemy_collisions::
    ; For each enemy
    ld hl, wEnemyArray
    ld b, MAX_ENEMIES

.enemy_loop:
    push bc
    push hl
    
    ; Check if enemy is active
    ld bc, ENEMY_ACTIVE_OFFSET
    add hl, bc         ; Point to active status
    ld a, [hl]
    and a
    jr z, .next_enemy  ; Skip if inactive
    
    ; Get enemy position
    pop hl
    push hl
    
    ld a, [hl+]        ; Get X
    ld d, a            ; Store X in d
    ld a, [hl]         ; Get Y
    ld e, a            ; Store Y in e
    
    ; Check against each bullet
    ld c, 0            ; Bullet counter

.bullet_loop:
    push bc
    push de
    
    ; Check if bullet is active
    ld hl, wBulletActive
    ld b, 0
    add hl, bc
    ld a, [hl]
    and a
    jr z, .next_bullet
    
    ; Get bullet position
    ld hl, wBulletPosX
    ld b, 0
    add hl, bc
    ld a, [hl]        ; A = Bullet X
    
    ; Compare X positions
    sub d             ; Bullet X - Enemy X
    add a, 8          ; Add sprite width
    cp 16             ; Check if within range
    jr nc, .next_bullet
    
    ld hl, wBulletPosY
    ld b, 0
    add hl, bc
    ld a, [hl]        ; A = Bullet Y
    
    ; Compare Y positions
    sub e             ; Bullet Y - Enemy Y
    add a, 8          ; Add sprite height
    cp 16             ; Check if within range
    jr nc, .next_bullet
    
    ; Collision detected!
    pop de
    pop bc
    
    ; Deactivate bullet
    ld hl, wBulletActive
    ld b, 0
    add hl, bc
    xor a
    ld [hl], a
    
    ; Deactivate enemy (just set active flag to 0)
    pop hl
    push hl
    ld bc, ENEMY_ACTIVE_OFFSET
    add hl, bc
    xor a
    ld [hl], a
    
    jr .next_enemy

.next_bullet:
    pop de
    pop bc
    inc c
    ld a, c
    cp 10             ; Max bullets check
    jr nz, .bullet_loop
    
.next_enemy:
    pop hl            ; Restore enemy array pointer
    ld bc, ENEMY_STRUCT_SIZE
    add hl, bc        ; Point to next enemy
    pop bc            ; Restore enemy counter
    dec b
    jp nz, .enemy_loop
    ret