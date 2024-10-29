INCLUDE "hardware.inc"

SECTION "EnemyBulletCollisionVariables", WRAM0
wCollisionFlag: ds 1            ; Set to 1 when collision occurs, 0 otherwise
wEnemyCollisionActive: ds 1     ; Enemy state after collision
wCollisionCheckX: ds 1          ; Temporal storage for enemy X
wCollisionCheckY: ds 1          ; Temporal storage for enemy Y

SECTION "EnemyBulletCollision", ROM0

; Actualización de lógica (puede llamarse fuera de VBLANK)
UpdateCollisionLogic::
    ; Store enemy position for later use
    ld a, b
    ld [wCollisionCheckX], a
    ld a, c
    ld [wCollisionCheckY], a

    ; Initialize collision flag to 0
    xor a
    ld [wCollisionFlag], a

    ; Check if enemy is active
    ld a, [wEnemyCollisionActive]
    and a
    ret z                       ; Return if enemy is inactive

    ; Loop through all bullets
    ld c, 0                     ; Bullet counter
.bulletLoop:
    ; Check if bullet is active
    ld hl, wBulletActive
    ld b, 0
    add hl, bc
    ld a, [hl]
    and a
    jr z, .nextBullet          ; Skip inactive bullets

    ; Get bullet and enemy positions
    ld hl, wBulletPosX
    ld b, 0
    add hl, bc
    ld a, [hl]                 ; A = Bullet X
    ld d, a                    ; Save bullet X in D
    
    ld hl, wBulletPosY
    ld b, 0
    add hl, bc
    ld a, [hl]                 ; A = Bullet Y
    ld e, a                    ; Save bullet Y in E

    ; Check X collision
    ld a, d                    ; Bullet X
    ld hl, wCollisionCheckX
    sub [hl]                   ; Bullet X - Enemy X
    add a, 8                   ; Add sprite width
    cp 16                      ; Check if within range
    jr nc, .nextBullet         ; If not in range, next bullet

    ; Check Y collision
    ld a, e                    ; Bullet Y
    ld hl, wCollisionCheckY
    sub [hl]                   ; Bullet Y - Enemy Y
    add a, 8                   ; Add sprite height
    cp 16                      ; Check if within range
    jr nc, .nextBullet         ; If not in range, next bullet

    ; Collision detected! Mark bullet for removal
    ld hl, wBulletActive
    ld b, 0
    add hl, bc
    xor a
    ld [hl], a

    ; Set collision flags
    ld a, 1
    ld [wCollisionFlag], a
    xor a
    ld [wEnemyCollisionActive], a
    ret                         ; Exit after collision

.nextBullet:
    inc c
    ld a, c
    cp 10
    jr nz, .bulletLoop
    ret

; Actualización visual (DEBE llamarse durante VBLANK)
UpdateCollisionSprites::
    ; Solo hacemos algo si hubo una colisión
    ld a, [wCollisionFlag]
    and a
    ret z

    ; Clear collided bullet from OAM
    ld c, 0                     ; Start with first bullet
.clearLoop:
    ld hl, wBulletActive
    ld b, 0
    add hl, bc
    ld a, [hl]
    and a
    jr nz, .nextBullet

    ; Found inactive bullet, clear its sprite
    push bc
    ld hl, _OAMRAM + 4
    ld a, c
    add a, a
    add a, a
    ld c, a
    ld b, 0
    add hl, bc
    
    xor a
    ld [hl+], a                ; Clear Y
    ld [hl+], a                ; Clear X
    ld [hl+], a                ; Clear tile
    ld [hl], a                 ; Clear attributes
    pop bc

.nextBullet:
    inc c
    ld a, c
    cp 10
    jr nz, .clearLoop

    ; Si hubo colisión, limpiamos el sprite del enemigo en posición 11
    ld hl, _OAMRAM + 44        ; Posición 11 en OAM (11 * 4 bytes)
    xor a
    ld [hl+], a                ; Clear Y
    ld [hl+], a                ; Clear X
    ld [hl+], a                ; Clear tile
    ld [hl], a                 ; Clear attributes
    ret

; Helper functions
GetCollisionResult::
    ld a, [wCollisionFlag]
    ret

SetEnemyCollisionState::
    ld [wEnemyCollisionActive], a
    ret