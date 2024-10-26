include "src/hardware.inc"

SECTION "BulletVariables", WRAM0

wBulletActive: ds 1         ; Indica si la bala está activa (1) o inactiva (0)
wBulletPosX: ds 1           ; Posición X de la bala
wBulletPosY: ds 1           ; Posición Y de la bala

SECTION "Bullet", ROM0

initializeBullet:
    ; Cargar el gráfico de la bala en VRAM en la dirección $8010
    ld de, bala_vertical          ; Dirección de origen del gráfico de la bala
    ld hl, $8010                  ; Dirección en VRAM donde se cargará el gráfico
    ld bc, bala_vertical_end - bala_vertical
    call mem_copy                 ; Copiar los datos del gráfico en VRAM

    ; Inicializamos la bala como inactiva y fuera de pantalla
    xor a
    ld [wBulletActive], a         ; Inactivo (0)
    ld a, 0                       ; Posición inicial X (fuera de pantalla)
    ld [wBulletPosX], a
    ld [wBulletPosY], a           ; Posición inicial Y (fuera de pantalla)
    ret

FireBullet::
    ; Activa la bala si no está activa y la coloca en la posición de la nave
    ld a, [wBulletActive]
    cp 1
    ret z                         ; Si ya está activa, no hacer nada

    ; Activa la bala y establece su posición en la posición de la nave
    ld a, 1
    ld [wBulletActive], a
    ld a, [posicionNaveX]
    ld [wBulletPosX], a
    ld a, [posicionNaveY]
    ld [wBulletPosY], a
    ret

UpdateBullet::
    ; Actualiza la posición de la bala solo si está activa
    ld a, [wBulletActive]
    cp 1
    ret nz                        ; Si no está activa, no hacer nada

    ; Mueve la bala hacia arriba
    ld a, [wBulletPosY]
    sub 1                          ; Reducir Y para mover la bala hacia arriba
    ld [wBulletPosY], a
    cp 0
    jp z, DeactivateBullet         ; Desactiva la bala si sale de la pantalla

    ; Dibujar la bala en una posición específica de la OAM
    ld hl, _OAMRAM + 4             ; Fija la posición en la OAM para la bala (4 bytes después de la nave)

    ; Escribir la posición Y sin incrementar `hl`
    ld a, [wBulletPosY]
    ld [hl], a

    ; Escribir la posición X
    inc hl
    ld a, [wBulletPosX]
    ld [hl], a

    ; Número de tile para la bala (01 en VRAM en $8010)
    inc hl
    ld a, $01
    ld [hl], a                     ; Tile de la bala

    ; Atributos de la bala (sin flip, paleta 0)
    inc hl
    xor a
    ld [hl], a
    ret



DeactivateBullet::
    ; Desactiva la bala y la mueve fuera de pantalla
    xor a
    ld [wBulletActive], a          ; Desactiva la bala
    ld [wBulletPosX], a            ; Posición fuera de pantalla
    ld [wBulletPosY], a            ; Posición fuera de pantalla
    ret
