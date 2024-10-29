include "src/hardware.inc"

SECTION "VariablesNave", WRAM0
; Definir variables para almacenar las posiciones X e Y de la nave
posicionNaveX: ds 1 ; Variable de 1 byte para la posición X
posicionNaveY: ds 1 ; Variable de 1 byte para la posición Y

SECTION "Player", ROM0

inicializarNave::
    xor a
    ; Inicializar la posición de la nave en coordenadas específicas
    ld a, 24
    ld [posicionNaveX], a
    ld a, 144
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
    ld b, a
    ; y position in c
    ld a, [posicionNaveY]
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

; Movement functions
MoveUp:
    ld a, [posicionNaveY]
    cp 16              ; Límite superior (ajusta según necesites)
    ret z
    sub 1
    ld [posicionNaveY], a
    ret

MoveDown:
    ld a, [posicionNaveY]
    cp 144            ; Límite inferior (ajusta según necesites)
    ret z
    add 1
    ld [posicionNaveY], a
    ret

MoveLeft:
    ld a, [posicionNaveX]
    cp 8              ; Límite izquierdo (ajusta según necesites)
    ret z
    sub 1
    ld [posicionNaveX], a
    ret

MoveRight:
    ld a, [posicionNaveX]
    cp 160            ; Límite derecho (ajusta según necesites)
    ret z
    add 1
    ld [posicionNaveX], a
    ret