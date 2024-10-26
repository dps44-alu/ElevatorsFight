include "src/hardware.inc"

SECTION "VariablesNave", WRAM0

; Definir variables para almacenar las posiciones X e Y de la nave

posicionNaveX: ds 1  ; Variable de 1 byte para la posición X
posicionNaveY: ds 1  ; Variable de 1 byte para la posición Y

SECTION "Player", ROM0

inicializarNave::
    xor a ;LIMPIAMOS REGISTRO A
    ; Inicializar la posición de la nave en coordenadas específicas (por ejemplo, X = 10, Y = 20)
    ld a, 24
    ld [posicionNaveX], a  ; Guardar en la variable posicionNaveX

    ld a, 144
    ld [posicionNaveY], a  ; Guardar en la variable posicionNaveY

copiarTilesnaveVram:
    ; Copy the player's tile data into VRAM
    ld de, nave
    ld hl, $8000
    ld bc, naveend - nave
    call mem_copy

updateNave::

updateNave_HandleInput:
    ld a, [wCurKeys]
    and PADF_UP
    call nz, MoveUp

    ld a, [wCurKeys]
    and PADF_DOWN
    call nz, MoveDown

    ld a, [wCurKeys]
    and PADF_LEFT
    call nz, MoveLeft

    ld a, [wCurKeys]
    and PADF_RIGHT
    call nz, MoveRight

    ld a, [wCurKeys]
	and PADF_A
	call nz, TryShoot

    
    call UpdatePlayer_UpdateSprite
    ret


UpdatePlayer_UpdateSprite:
    ; x position in b
    ld a, [posicionNaveX]
    ld b, a

    ; y position in c
    ld a, [posicionNaveY]
    ld c, a

    ; Establece la dirección base en la OAM para la nave
    ld hl, _OAMRAM

    ; Escribir la posición Y sin incrementar `hl`
    ld a, c
    ld [hl], a

    ; Escribir la posición X sin incrementar `hl`
    inc hl
    ld a, b
    ld [hl], a

    ; Primer tile en la memoria de tiles sin incrementar `hl`
    inc hl
    xor a
    ld [hl], a

    ; Sprite sin propiedades especiales sin incrementar `hl`
    inc hl
    ld [hl], a

    ret


TryShoot:
    ld a, [wCurKeys]   ; Cargar el estado actual de los botones
    and PADF_A         ; Comprobar si el botón A está presionado
    ret z              ; Salir si A no está presionado
    jp FireBullet

;;DAMAgeplayer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MoveUp:
    ; Decrease the player's y position
    ld a, [posicionNaveY]
    sub 1                  ; Velocidad fija de 1 píxel
    ld [posicionNaveY], a
    ret

MoveDown:
    ; Increase the player's y position
    ld a, [posicionNaveY]
    add 1                  ; Velocidad fija de 1 píxel
    ld [posicionNaveY], a
    ret

MoveLeft:
    ; Decrease the player's x position
    ld a, [posicionNaveX]
    sub 1                  ; Velocidad fija de 1 píxel
    ld [posicionNaveX], a
    ret

MoveRight:
    ; Increase the player's x position
    ld a, [posicionNaveX]
    add 1                  ; Velocidad fija de 1 píxel
    ld [posicionNaveX], a
    ret
; ANCHOR_END: player-update-sprite
