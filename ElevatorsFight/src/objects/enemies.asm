INCLUDE "hardware.inc"

SECTION "Enemy Constants", ROM0
DEF ENEMY_MIN_X     EQU 8 ; Límite izquierdo de la pantalla
DEF ENEMY_MAX_X     EQU 152 ; Límite derecho de la pantalla
DEF ENEMY_SPEED     EQU 1 ; Velocidad de movimiento
DEF MOVE_DELAY      EQU 4 ; Se moverá cada 4 frames
DEF ENEMY_COUNT     EQU 3 ; Número de enemigos


SECTION "Enemies Atributes", WRAM0
enemyX:             DS ENEMY_COUNT ; Array de 3 bytes para la posición X
enemyY:             DS ENEMY_COUNT ; Array de 3 bytes para la posición Y
enemy_direction:    DS ENEMY_COUNT ; Array de 3 bytes para la dirección
enemy_timer:        DS ENEMY_COUNT ; Array de 3 bytes para los contadores


SECTION "Enemy", ROM0

initialize_enemies:
    ld d, ENEMY_COUNT   ; Contador de enemigos
    ld e, 0             ; Suma posición para que no estén todos en la misma
    ld b, 0             ; Siempre 0 para que las operaciones funcionen
    ld c, 0             ; Índice del enemigo

    .loop
        xor a

        ld hl, enemy_direction      ; 0 = derecha
        add hl, bc
        ld [hl], a

        ld hl, enemy_timer
        add hl, bc
        ld [hl], a

        ld a, e
        add 30
        ld hl, enemyX
        add hl, bc
        ld [hl], a

        ld a, e
        ld hl, enemyY
        add hl, bc
        ld [hl], a

        inc c                       ; enemigo1, enemigo2 y enemigo3
        dec d                       ; 3 enemigos, 2 enemigos, 1 enemigo
        xor a 
        ld a, e
        add 10
        ld e, a
        jr nz, .loop

    call copy_enemy_tiles_to_vram
    ret


copy_enemy_tiles_to_vram:
    ; Copia los datos del tile del enemigo en la VRAM
    ld de, nave2
    ld hl, $8020
    ld bc, nave2end - nave2
    call mem_copy
    ret


copy_enemies_to_oam:
    ld b, ENEMY_COUNT
    ld c, 0 ; Índice del enemigo
    ld de, _OAMRAM + 44 ; Establece la dirección base en la OAM para el primer enemigo

    .loop
        push bc

        ld b, 0

        ld hl, enemyY
        add hl, bc
        ld a, [hl]
        ld [de], a
        inc de

        ld hl, enemyX
        add hl, bc
        ld a, [hl]
        ld [de], a
        inc de

        ld a, 2         ; Tercer tile
        ld [de], a
        inc de

        xor a           ; Sin propiedades especiales
        ld [de], a
        inc de

        pop bc

        inc c
        dec b   ;;;;;
        jr nz, .loop

    ret


move_enemies:
    ld e, ENEMY_COUNT   ; Contador de enemigos
    ld b, 0             ; Siempre 0 para que las operaciones funcionen
    ld c, 0             ; Índice del enemigo

    .loop   
        ld hl, enemy_timer
        add hl, bc
        ld a, [hl]          ; A = enemy_timer
        inc a
        ld [hl], a          ; enemy_timer += 1

        ; Si timer == MOVE_DELAY, mueve, sino sigue con el siguiente
        cp MOVE_DELAY  
        jr nz, .next

        ; Actualiza timer
        xor a
        ld [hl], a          ; enemy_timer = 0

        ; Comprueba la dirección actual
        ld hl, enemy_direction
        add hl, bc
        ld a, [hl]
        and a
        jr nz, .move_left

        .move_right:
            ld hl, enemyX
            add hl, bc
            ld a, [hl]      

            cp ENEMY_MAX_X              ; Compara con el limite derecho

            jr nc, .change_to_left      ; Si llegamos al límite, cambia dirección

            add ENEMY_SPEED             ; Suma la velocidad

            ld [hl], a              ; enemyX += enemy_speed
            jr .next

        .move_left:
            ld hl, enemyX
            add hl, bc
            ld a, [hl]

            cp ENEMY_MIN_X              ; Compara con el limite derecho

            jr c, .change_to_right     ; Si llegamos al límite, cambia dirección

            sub ENEMY_SPEED             ; Suma la velocidad

            ld [hl], a              ; enemyX += enemy_speed
            jr .next

        .change_to_left:
            ld hl, enemy_direction
            add hl, bc
            ld a, 1                     ; 1 = izquierda
            ld [hl], a
            jr .next 

        .change_to_right:
            ld hl, enemy_direction
            add hl, bc
            xor a                       ; 0 = derecha
            ld [hl], a
            jr .next 

        .next:
            inc c
            dec e
            jr nz, .loop
        
    ret