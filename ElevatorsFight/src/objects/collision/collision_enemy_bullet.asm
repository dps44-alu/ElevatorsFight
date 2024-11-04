INCLUDE "objects/constants.asm"

SECTION "Collision Enemies Variables", WRAM0
wCollisionFlag: DS 1

SECTION "Collision Enemies Code", ROM0

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
    ld a, [hl+]       ; Get X
    ld d, a           ; Store X in d
    ld a, [hl]        ; Get Y
    ld e, a           ; Store Y in e

    ; Check against each bullet
    ld c, 0           ; Bullet counter
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

    ; Comprueba si la bala la dispara el jugador o el enemigo
    ld hl, wBulletDirection
    ld b, 0
    add hl, bc
    ld a, [hl]
    and a
    jr nz, .next_bullet ; Si es 1 = up_to_down, la dispara el enemigo y pasamos a la siguiente

    ; Get bullet position
    ld hl, wBulletPosX
    ld b, 0
    add hl, bc
    ld a, [hl]        ; A = Bullet X

    ; Compare X positions
    sub d             ; Bullet X - Enemy X
    add 5
    cp 16             ; Check if within range
    jr nc, .next_bullet

    ld hl, wBulletPosY
    ld b, 0
    add hl, bc
    ld a, [hl]        ; A = Bullet Y

    ; Compare Y positions
    sub e             ; Bullet Y - Enemy Y
    add 10
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

    ; Add 10 points to score
    ld hl, wScore
    ld a, [hl]        ; Get low byte of score
    add 10            ; Add 10 points
    ld [hl], a        ; Store new score
    ld a, 1
    ld [wScoreChanged], a  ; Mark score for update

    ; Decrease enemy counter - ADD THIS
    ld a, [wCurrentEnemies]
    dec a
    ld [wCurrentEnemies], a

    ; Check if all enemies are destroyed - ADD THIS
    and a               ; Check if zero
    jr nz, .next_enemy
    ld a, 1
    ld [wLevelComplete], a  ; Set level complete flag if all enemies destroyed

    jr .next_enemy

.next_bullet:
    pop de
    pop bc
    inc c
    ld a, c
    cp 10              ; Max bullets check
    jr nz, .bullet_loop

.next_enemy:
    pop hl             ; Restore enemy array pointer
    ld bc, ENEMY_STRUCT_SIZE
    add hl, bc         ; Point to next enemy
    pop bc             ; Restore enemy counter
    dec b
    jp nz, .enemy_loop
    ret