INCLUDE "hardware.inc"

SECTION "Explosion Variables", WRAM0
wExplosionActive:    DB      ; 1 si hay explosión activa, 0 si no
wExplosionFrame:     DB      ; Frame actual de la animación
wExplosionX:         DB      ; Posición X de la explosión
wExplosionY:         DB      ; Posición Y de la explosión
wExplosionTimer:     DB      ; Temporizador para cambio de frame

SECTION "Explosion Animation", ROM0

; Tiles de explosión (definidos anteriormente)
ExplosionTiles:
    ; Tile 1 - Inicio
    DB $00,$00,$10,$10,$28,$28,$44,$44,$44,$44,$28,$28,$10,$10,$00,$00
    ; Tile 2 - Medio
    DB $00,$00,$3C,$3C,$7E,$7E,$DB,$DB,$DB,$DB,$7E,$7E,$3C,$3C,$00,$00
    ; Tile 3 - Máximo
    DB $7E,$7E,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$7E,$7E,$00,$00
    ; Tile 4 - Final
    DB $00,$00,$3C,$3C,$7E,$7E,$DB,$DB,$DB,$DB,$7E,$7E,$3C,$3C,$00,$00

; Inicia una explosión en la posición del enemigo
; Input: B = posX, C = posY
start_explosion::
    ; Guardar posición
    ld a, b
    ld [wExplosionX], a
    ld a, c
    ld [wExplosionY], a
    
    ; Inicializar variables de explosión
    ld a, 1
    ld [wExplosionActive], a    ; Activar explosión
    xor a
    ld [wExplosionFrame], a     ; Empezar en frame 0
    ld a, 8                     ; Delay entre frames
    ld [wExplosionTimer], a
    ret

; Actualiza la animación de explosión
; Debe llamarse cada frame
update_explosion::
    ; Comprobar si hay explosión activa
    ld a, [wExplosionActive]
    and a
    ret z                       ; Retornar si no hay explosión

    ; Decrementar timer
    ld a, [wExplosionTimer]
    dec a
    ld [wExplosionTimer], a
    ret nz                      ; Retornar si el timer no es 0

    ; Reset timer
    ld a, 8
    ld [wExplosionTimer], a

    ; Actualizar frame
    ld a, [wExplosionFrame]
    inc a
    cp 4                        ; Comprobar si llegamos al último frame
    jr z, .end_explosion
    ld [wExplosionFrame], a

    ; Actualizar sprite de explosión
    call draw_explosion
    ret

.end_explosion:
    xor a
    ld [wExplosionActive], a    ; Desactivar explosión
    ret

; Dibuja el frame actual de la explosión
draw_explosion::
    ; Calcular qué tile usar basado en wExplosionFrame
    ld a, [wExplosionFrame]
    ld b, a                     ; B = número de frame
    sla b                       ; B *= 16 (cada tile es 16 bytes)
    sla b
    sla b
    sla b
    
    ; Copiar tile al VRAM
    ld hl, ExplosionTiles
    ld de, _VRAM + $800        ; Dirección en VRAM para el tile
    ld a, b
    ld b, 0
    add hl, bc                 ; HL = dirección del tile correcto
    
    ; Copiar 16 bytes del tile
    ld bc, 16
    call mem_copy              ; Necesitarás implementar esta función

    ; Actualizar OAM para mostrar el sprite
    ld a, [wExplosionY]
    ld [_OAMRAM + 0], a        ; Y position
    ld a, [wExplosionX]
    ld [_OAMRAM + 1], a        ; X position
    ld a, $80                  ; Tile número (ajustar según tu configuración)
    ld [_OAMRAM + 2], a
    xor a                      ; Atributos
    ld [_OAMRAM + 3], a
    ret