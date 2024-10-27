include "hardware.inc"
SECTION "BulletVariables", WRAM0
wBulletActive: ds 10        ; Array of 10 active bullets (1 = active, 0 = inactive)
wBulletPosX: ds 10          ; Array of X positions for each bullet
wBulletPosY: ds 10          ; Array of Y positions for each bullet
wShootDelay: ds 1          ; Counter for shooting delay

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
    ld [wShootDelay], a         ; Start with no delay
    ret

FireBullet::
    ; First check if we're still in delay
    ld a, [wShootDelay]
    and a                       ; Check if delay is zero
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

UpdateBullet::
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

    ; Get X position for OAM
    push hl                  ; Save Y position pointer
    ld hl, wBulletPosX
    ld b, 0
    add hl, bc
    ld d, [hl]              ; Save X position in D
    pop hl                  ; Get Y position pointer back
    ld e, [hl]              ; Save Y position in E

    ; Update OAM
    push bc
    ld hl, _OAMRAM + 4      ; Start after player sprite
    ld a, c
    add a, a                ; × 4 for OAM entry size
    add a, a
    ld c, a
    ld b, 0
    add hl, bc              

    ; Write to OAM
    ld a, e                 ; Y position
    ld [hl+], a
    ld a, d                 ; X position
    ld [hl+], a
    ld a, $01               ; Tile number
    ld [hl+], a
    xor a                   ; Attributes
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
    push bc
    ld hl, _OAMRAM + 4     
    ld a, c
    add a, a               
    add a, a
    ld c, a
    ld b, 0
    add hl, bc             

    xor a                  
    ld [hl+], a            ; Clear Y
    ld [hl+], a            ; Clear X
    ld [hl+], a            ; Clear tile
    ld [hl], a             ; Clear attributes
    pop bc

.nextBullet:
    pop bc                 
    inc c
    ld a, c
    cp 10                  
    jr nz, .updateLoop
    ret