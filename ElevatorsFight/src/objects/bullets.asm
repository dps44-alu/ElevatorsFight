include "hardware.inc"

SECTION "BulletVariables", WRAM0
wBulletActive: ds 10        ; Array of 10 active bullets (1 = active, 0 = inactive)
wBulletPosX: ds 10          ; Array of X positions for each bullet
wBulletPosY: ds 10          ; Array of Y positions for each bullet
wShootDelay: ds 1           ; Counter for shooting delay
wBulletDirection: DS 10     ; 0 = down_to_up, 1 = up_to_down

SECTION "Bullet", ROM0

initializeBullet::
    ; Load bullet sprite into VRAM (debe hacerse durante VBLANK o con pantalla apagada)
    ld de, bala_vertical          
    ld hl, $8010                  
    ld bc, bala_vertical_end - bala_vertical
    call mem_copy                 

    ; Initialize all bullets as inactive and off-screen
    ld b, 10                      ; Bullet counter
    ld hl, wBulletActive
.clearLoop:
    xor a
    ld [hl+], a                  ; Initialize as inactive
    ld [hl+], a                  ; Initialize PosX
    ld [hl+], a                  ; Initialize PosY
    dec b
    jr nz, .clearLoop

    ; Initialize shoot delay
    xor a
    ld [wShootDelay], a         ; Start with no delay
    ret

; Puede llamarse en cualquier momento - maneja la lógica de disparo
FireBullet::
    ; First check if we're still in delay
    ld a, [wShootDelay]
    and a                      ; Check if delay is zero
    jr z, .canShoot            ; If zero, we can shoot
    ret                        ; If not zero, return without shooting

.canShoot:
    ; Check for new button press
    ld a, [wNewKeys]
    and PADF_A                  ; Check if A button is newly pressed
    ret z                       ; Return if A is not newly pressed
    
    ; Set shooting delay (adjust this value to change delay length)
    ld a, 30                    ; About 0.5 seconds at 60 FPS
    ld [wShootDelay], a
    
    ; Find inactive bullet
    ld c, 0                     ; Use C as counter
    ld hl, wBulletActive        
.findFreeBullet:
    ld a, [hl]                  
    and a                       
    jr z, .foundFree           
    inc hl                      
    inc c                       
    ld a, c
    cp 10
    ret z                      ; No free bullets found
    jr .findFreeBullet

.foundFree:
    ; Activate bullet
    ld a, 1
    ld [hl], a                  ; Set as active

    ; Set 0 = down_to_up -> Dispara el jugador 
    ld hl, wBulletDirection
    ld b, 0
    add hl, bc
    xor a
    ld [hl], a

    ; Set bullet position
    ld hl, wBulletPosX
    ld b, 0
    add hl, bc                  ; Point to correct X position
    ld a, [posicionNaveX]
    ld [hl], a                 

    ld hl, wBulletPosY
    ld b, 0
    add hl, bc                  ; Point to correct Y position
    ld a, [posicionNaveY]
    ld [hl], a                 
    ret

; Actualiza la lógica de las balas (puede llamarse en cualquier momento)
UpdateBulletLogic::
    ; First update the shoot delay
    ld a, [wShootDelay]
    and a                       ; Check if delay is active
    jr z, .updateBullets       ; If zero, skip decreasing
    dec a                       ; Decrease delay counter
    ld [wShootDelay], a        ; Save new delay value

.updateBullets:
    ld c, 0                   ; Bullet index
.updateLoop:
    push bc                   

    ; Check if bullet is active
    ld hl, wBulletActive
    ld b, 0
    add hl, bc
    ld a, [hl]
    and a
    jr z, .nextBullet        ; Skip if inactive

    ; Comprueba si la bala la dispara el jugador (0) o el enemigo (1)
    ld hl, wBulletDirection
    ld b, 0
    add hl, bc
    ld a, [hl]
    and a
    jr nz, .move_down      ; Skip si la dispara el enemigo

.move_up
    ; Update Y position
    ld hl, wBulletPosY
    ld b, 0
    add hl, bc
    ld a, [hl]
    sub 2                    ; Move up
    ld [hl], a               ; Save new Y position
    
    ; Check if off screen
    cp 16                    
    jr c, .deactivateBullet
    jr .nextBullet

.move_down
    ; Update Y position
    ld hl, wBulletPosY
    ld b, 0
    add hl, bc
    ld a, [hl]
    add 2                    ; Move down
    ld [hl], a               ; Save new Y position

    ; Check if off screen
    cp 144                
    jr nc, .deactivateBullet
    jr .nextBullet

.deactivateBullet:
    ; Deactivate bullet
    ld hl, wBulletActive
    ld b, 0
    add hl, bc
    xor a
    ld [hl], a

.nextBullet:
    pop bc                 
    inc c
    ld a, c
    cp 10                  
    jr nz, .updateLoop
    ret

; Actualiza los sprites de las balas en OAM (DEBE llamarse durante VBLANK)
UpdateBulletSprites::
    
    ; OAM Layout:
    ; _OAMRAM + 0  (4 bytes):  Player sprite
    ; _OAMRAM + 4  (40 bytes): All bullets (10 bullets × 4 bytes)
    ; _OAMRAM + 44: Start of enemy sprites

    ; Clear all bullet slots first
    ld hl, _OAMRAM + 4          ; Start after player sprite
    ld b, 40                    ; Clear 40 bytes (10 bullets × 4 bytes)
    xor a
.clear_all_bullets:
    ld [hl+], a                 ; Clear each byte of bullet OAM area
    dec b
    jr nz, .clear_all_bullets

    ; Now update active bullets
    ld c, 0                     ; Bullet index
.updateLoop:
    push bc

    ; Check if bullet is active
    ld hl, wBulletActive
    ld b, 0
    add hl, bc
    ld a, [hl]
    and a
    jr z, .nextBullet           ; Skip if inactive

    ; Get positions
    ld hl, wBulletPosX
    ld b, 0
    add hl, bc
    ld d, [hl]                  ; X position in D
    
    ld hl, wBulletPosY
    ld b, 0
    add hl, bc
    ld e, [hl]                  ; Y position in E

    ; Calculate OAM position
    push bc
    ld a, c
    add a, a                    ; × 4 for OAM entry size
    add a, a
    ld c, a
    ld b, 0
    ld hl, _OAMRAM + 4         ; Bullets start after player
    add hl, bc                  ; Add offset for this bullet

    ; Write sprite data
    ld a, e                     ; Y position
    ld [hl+], a
    ld a, d                     ; X position
    ld [hl+], a
    ld a, $01                   ; Tile number
    ld [hl+], a
    xor a                       ; Attributes
    ld [hl], a
    
    pop bc

.nextBullet:
    pop bc
    inc c
    ld a, c
    cp 10                       ; Check if we've done all bullets
    jr nz, .updateLoop
    ret