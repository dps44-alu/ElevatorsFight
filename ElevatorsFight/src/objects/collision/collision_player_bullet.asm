INCLUDE "objects/constants.asm"
SECTION "Collision Player Variables", WRAM0


SECTION "Collision Player Code", ROM0

; Check for collisions between bullets and enemies
; Modifies all registers

check_bullet_player_collisions::
    ld hl, posicionNaveX
    ld d, [hl]              ; D = naveX
    ld hl, posicionNaveY
    ld e, [hl]              ; E = naveY
    ld bc, 0                ; Bullet counter

    .bullet_loop:       
        ; Check if bullet is active
        ld hl, wBulletActive
        add hl, bc
        ld a, [hl]
        and a
        jr z, .next_bullet

        ; Comprueba si la bala la dispara el jugador o el enemigo
        ld hl, wBulletDirection
        add hl, bc
        ld a, [hl]
        and a
        jr z, .next_bullet      ; Si es 0 = down_to_up, la dispara el jugador y pasamos a la siguiente
        
        ; Get bullet position
        ld hl, wBulletPosX
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
        
        ; Deactivate bullet
        ld hl, wBulletActive
        ld b, 0
        add hl, bc
        xor a
        ld [hl], a

        call lose_a_life

    .next_bullet:
        inc c
        ld a, c
        cp 10             ; Max bullets check
        jr nz, .bullet_loop

    ret
    