include "src/hardware.inc"

SECTION "VariablesNave", WRAM0
; Definir variables para almacenar las posiciones X e Y de la nave
posicionNaveX: DS 1 ; Variable de 1 byte para la posición X
posicionNaveY: DS 1 ; Variable de 1 byte para la posición Y

SECTION "Player", ROM0

inicializarNave::
    xor a
    ; Inicializar la posición de la nave en coordenadas específicas
    ld a, 80
    ld [posicionNaveX], a
    ld a, 120
    ld [posicionNaveY], a

    ; Copiar tiles a VRAM (esto debe hacerse durante VBLANK o con la pantalla apagada)
    ld de, nave
    ld hl, $8000
    ld bc, naveend - nave
    call mem_copy
    ret

; Actualiza la lógica de la nave (posiciones, disparos, etc.)
; Esta función puede llamarse en cualquier momento
updateNave::
    call updateNave_HandleInput
    ret

; Maneja la entrada del jugador y actualiza las posiciones
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
    ret

; Actualiza el sprite en OAM (DEBE llamarse durante VBLANK)
UpdatePlayer_UpdateSprite::
    ; x position in b
    ld a, [posicionNaveX]
    add 8          ; Add 8 for hardware X offset
    ld b, a
    ; y position in c
    ld a, [posicionNaveY]
    add 16         ; Add 16 for hardware Y offset
    ld c, a

    ; Actualiza OAM
    ld hl, _OAMRAM
    ; Y position
    ld a, c
    ld [hl+], a
    ; X position
    ld a, b
    ld [hl+], a
    ; Tile number
    xor a
    ld [hl+], a
    ; Attributes
    ld [hl], a
    ret

TryShoot:
    ld a, [wCurKeys]
    and PADF_A
    ret z
    jp FireBullet

; Movement functions; Movement functions with corrected screen boundaries
MoveUp:
    ld a, [posicionNaveY]
    cp 0              ; Upper limit (top of screen)
    ret z
    sub 1
    ld [posicionNaveY], a
    ret

MoveDown:
    ld a, [posicionNaveY]
    cp 128            ; Lower limit (144 - 16 for sprite height)
    ret z
    add 1
    ld [posicionNaveY], a
    ret

MoveLeft:
    ld a, [posicionNaveX]
    cp 0              ; Left limit (left edge of screen)
    ret z
    sub 1
    ld [posicionNaveX], a
    ret

MoveRight:
    ld a, [posicionNaveX]
    cp 152            ; Right limit (160 - 8 for sprite width)
    ret z
    add 1
    ld [posicionNaveX], a
    ret