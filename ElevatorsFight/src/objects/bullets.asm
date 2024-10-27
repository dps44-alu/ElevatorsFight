include "hardware.inc"
SECTION "BulletVariables", WRAM0
wBulletActive: ds 10        ; Array of 10 active bullets (1 = active, 0 = inactive)
wBulletPosX: ds 10          ; Array of X positions for each bullet
wBulletPosY: ds 10          ; Array of Y positions for each bullet
wShootDelay: ds 1           ; Simple delay counter for shooting

SECTION "Bullet", ROM0

initializeBullet:
    ; Load bullet sprite into VRAM
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
    ld [wShootDelay], a
    ret

FireBullet::
    ; Check and update delay
    ld a, [wShootDelay]
    and a                       ; Check if delay is zero
    jr z, .canShoot
    dec a                       ; Decrease delay
    ld [wShootDelay], a
    ret                         ; Can't shoot yet

.canShoot:
    ; Reset delay counter
    ld a, 10                    ; Set delay to 10 frames (adjust this for different fire rates)
    ld [wShootDelay], a

    ; Find inactive bullet
    ld b, 0                     ; Initialize bullet index
    ld de, wBulletActive        
.findFreeBullet:
    ld a, [de]                  
    and a                       ; Check if bullet is inactive (0)
    jr z, .foundFree           
    inc de                      
    inc b                       
    ld a, b
    cp 10
    ret z                       ; No free bullets
    jr .findFreeBullet

.foundFree:
    ; Activate found bullet
    ld a, 1
    ld [de], a                  ; Set as active

    ; Set bullet position
    push bc                    
    ld hl, wBulletPosX
    ld c, b
    ld b, 0
    add hl, bc                
    ld a, [posicionNaveX]
    ld [hl], a                

    ld hl, wBulletPosY
    ld c, b
    ld b, 0
    add hl, bc                
    ld a, [posicionNaveY]
    ld [hl], a                
    pop bc                    
    ret

UpdateBullet::
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

    ; Update Y position
    ld hl, wBulletPosY
    ld b, 0
    add hl, bc
    ld a, [hl]
    sub 2                    ; Move up
    ld [hl], a

    ; Check if off screen
    cp 16                    
    jr c, .deactivateBullet

    ; Update OAM
    push bc
    ld hl, _OAMRAM + 4      ; Start after player sprite
    ld b, 0
    ld a, c
    add a, a                ; × 4 for OAM entry size
    add a, a
    ld c, a
    add hl, bc              

    ; Update Y
    ld a, [wBulletPosY]
    ld [hl+], a

    ; Update X
    ld a, [wBulletPosX]
    ld [hl+], a

    ; Tile number
    ld a, $01              
    ld [hl+], a

    ; Attributes
    xor a                   
    ld [hl], a
    
    pop bc
    jr .nextBullet

.deactivateBullet:
    ; Deactivate bullet
    ld hl, wBulletActive
    ld b, 0
    add hl, bc
    xor a
    ld [hl], a

    ; Clear from OAM
    ld hl, _OAMRAM + 4     
    ld b, 0
    ld a, c
    add a, a               
    add a, a
    ld c, a
    add hl, bc             

    xor a                  
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a

.nextBullet:
    pop bc                 
    inc c
    ld a, c
    cp 10                  
    jr nz, .updateLoop
    ret

DeactivateAllBullets::
    ; Deactivate all bullets
    ld b, 10
    ld hl, wBulletActive
.clearAllLoop:
    xor a
    ld [hl+], a
    dec b
    jr nz, .clearAllLoop

    ; Clear all sprites of bullets in the OAM
    call ClearAllBulletSprites
    ret

ClearAllBulletSprites:
    ; Clear all sprites of bullets in the OAM
    ld b, 10
    ld a, 4                ; Start index in OAM for bullets
    ld c, a
.clearAllSpritesLoop:
    push bc
    call ClearBulletSprite
    pop bc
    inc c
    dec b
    jr nz, .clearAllSpritesLoop
    ret

ClearBulletSprite:
    ; Clear a bullet sprite in the OAM
    ld hl, _OAMRAM
    ld b, 0
    add hl, bc
    add hl, bc             ; Each bullet takes 4 bytes in the OAM
    add hl, bc
    add hl, bc

    xor a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    ret