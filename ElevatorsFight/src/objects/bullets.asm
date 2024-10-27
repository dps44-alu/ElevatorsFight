include "hardware.inc"
SECTION "BulletVariables", WRAM0
wBulletActive: ds 1        ; Indica si la bala está activa (1) o inactiva (0)
wBulletPosX: ds 1          ; Posición X de la bala
wBulletPosY: ds 1          ; Posición Y de la bala
wBulletOAMIndex: ds 1      ; Índice fijo en OAM para la bala
wLastShotTime: ds 1        ; Contador para el debounce del disparo

SECTION "Bullet", ROM0

initializeBullet:
    ; Cargar el gráfico de la bala en VRAM
    ld de, bala_vertical          
    ld hl, $8010                  
    ld bc, bala_vertical_end - bala_vertical
    call mem_copy                 

    ; Inicializar variables
    xor a
    ld [wBulletActive], a        
    ld [wBulletPosX], a
    ld [wBulletPosY], a   
    ld [wLastShotTime], a       
    
    ; Establecer índice fijo en OAM
    ld a, 4                      ; 4 bytes después de la nave
    ld [wBulletOAMIndex], a
    
    ; Limpiar el sprite inicial
    call ClearBulletSprite
    ret

ClearBulletSprite:
    ; Mover el sprite de la bala fuera de la pantalla
    ld a, [wBulletOAMIndex]
    ld c, a
    ld b, 0
    ld hl, _OAMRAM
    add hl, bc
    
    ; Y = 0 (fuera de pantalla)
    xor a
    ld [hl+], a
    ; X = 0
    ld [hl+], a
    ; Tile = 0
    ld [hl+], a
    ; Atributos = 0
    ld [hl], a
    ret

FireBullet::
    ; Verificar si la bala ya está activa
    ld a, [wBulletActive]
    cp 1
    ret z               

    ; Verificar el debounce timer
    ld a, [wLastShotTime]
    cp 0
    ret nz

    ; Activar la bala
    ld a, 1
    ld [wBulletActive], a
    
    ; Establecer el tiempo de debounce
    ld a, 30           ; 15 frames de espera entre disparos
    ld [wLastShotTime], a
    
    ; Posicionar la bala centrada sobre la nave
    ld a, [posicionNaveX]
    ld [wBulletPosX], a
    
    ld a, [posicionNaveY]
    sub 8               ; Colocar encima de la nave
    ld [wBulletPosY], a
    ret

UpdateBullet::
    ; Actualizar el timer de debounce
    ld a, [wLastShotTime]
    cp 0
    jr z, .skipTimerUpdate
    dec a
    ld [wLastShotTime], a
.skipTimerUpdate:

    ; Verificar si la bala está activa
    ld a, [wBulletActive]
    cp 1
    ret nz              

    ; Mover la bala hacia arriba
    ld a, [wBulletPosY]
    sub 2               ; Velocidad de la bala
    ld [wBulletPosY], a
    
    ; Verificar si salió de la pantalla
    cp 16              ; 16 es el límite superior visible
    jp c, DeactivateBullet
    
    ; Actualizar el sprite en OAM durante VBLANK
    call wait_vblank_start
    
    ld a, [wBulletOAMIndex]
    ld c, a
    ld b, 0
    ld hl, _OAMRAM
    add hl, bc
    
    ; Actualizar Y
    ld a, [wBulletPosY]
    ld [hl+], a
    
    ; Actualizar X
    ld a, [wBulletPosX]
    ld [hl+], a
    
    ; Tile de la bala
    ld a, $01
    ld [hl+], a
    
    ; Atributos
    xor a
    ld [hl], a
    ret

DeactivateBullet::
    xor a
    ld [wBulletActive], a
    
    ; Limpiar el sprite durante VBLANK
    call wait_vblank_start
    call ClearBulletSprite
    ret