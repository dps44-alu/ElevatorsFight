INCLUDE "hardware.inc"

SECTION "Main", ROM0[$0150]


wait_vblank_start:
	.loop
		ld a, [rLY]		; rLY = $FF44 -> Indica la línea actual que está siendo dibujada
		cp 144			; Principio de VBLANK
		jr nz, .loop
    ret


switch_screen_off:
    call wait_vblank_start
	ld hl, rLCDC
	res 7, [hl]					; rLCDC = $FF40 -> Controla la pantalla, el bit 7 indica si está encendia (1) o apagada (0)			
    ret


switch_screen_on:
	ldh a, [rLCDC] ;; A = Read LCD Control Register (rLCDC)
	set 7, a       ;; Set Bit 7 to 1 (switch LCD on)
	ldh [rLCDC], a ;; Write new value of rLCDC


setup_screen:
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON	; OR de encender_pantalla, habilitar_fondo y habilitar_sprites
	ld [rLCDC], a
	ret


; Copia bytes de un área a otra
; DE: Origen
; HL: Destino
; BC: Tamaño
mem_copy:
	.loop
		ld a, [de]
		ld [hl+], a
		inc de
		dec bc
		ld a, b
		or a, c
		jr nz, .loop
	ret


; Pone la OAM a 0's
; A: 0
; B: Contador
; HL: Puntero a la dirección de la OAM
clear_oam:
	xor a
	ld b, 160			; Número e bytes en la OAM que controla los sprites
	ld hl, _OAMRAM		; _OAMRAM = $FE00 -> Puntero al inicio de la OAM (Almacena las propiedades de los sprites)
	.loop
		ld [hl+], a
		dec b
		jr nz, .loop
	ret







my_ret:
	ret


; Lee el estado de los botones y los guarda en A
; 1 nibble = 4 bits = 1/2 byte
; rP1 (P1/JOYP) -> Guarda el estado de los botones de la consola
; 	-> Bits 0-3: indica el estado de los botones (A, B, Select, Start, Derecha, Izquierda, Arriba, Abajo)
; 	-> Bits 4,5: indica en grupo de botones que se quiere leer, direcciones (Derecha, Izquierda, Arriba, Abajo) o botones (A, B, Select, Start)
one_nibble:
	ldh [rP1], a 	; rP1 = $FF00 -> Actualiza la matriz de teclas
	call my_ret 	; Quema 10 ciclos llamando a un ret (Pausa)
	ldh a, [rP1] 	; Ignorar para que la matriz de teclas se estabilice
	ldh a, [rP1]
	ldh a, [rP1] 	; Lee
	or a, $F0 		; 11110000 -> 7-4 = 1, 3-0 = teclas no presionadas
	ret


update_keys:
	; Escribe la mitad del controllador (Botones A y B)
	ld a, P1F_GET_BTN	; P1F_GET_BTN = P1F_4 = %00010000 -> Carga los botones
	call one_nibble
	ld b, a 			; 11110000 -> 7-4 = 1, 3-0 = botones no presionados

	; Escribe la otra mitad (Direcciones)
	ld a, P1F_GET_DPAD	; P1F_GET_DPAD = P1F_5 = %00100000 -> Carga las direcciones
	call one_nibble
	swap a 				; A3-0 = direcciones no presionadas; A7-4 = 1
	xor b 				; A = botones presionados + direcciones
	ld b, a 			; B = botones presionados + direcciones

	; Carga los controladores
	ld a, P1F_GET_NONE	; P1F_GET_NONE = OR(P1F_4, P1F_5) = OR(%00010000, %00100000) -> No carga ninguno
	ldh [rP1], a

	; Combina con las wCurKeys previas para crear las wNewKeys
	ld a, [wCurKeys]	; wCurKeys -> Teclas que estaban presionadas anteriormente (Estado actual de los botones)
	xor b 				; A = teclas que han cambiado de estado
	and b 				; A = teclas que han cambiado a presionadas
	ld [wNewKeys], a	; wNewKeys -> Teclas recién presionadas (Estado nuevo de los botones)
	ld a, b
	ld [wCurKeys], a	; wCurKeys = estado actualizado de las teclas

	ret


move:
    ; First store current position in case we need to restore it
    ld a, [_OAMRAM + 1]    ; Get current X position
    ld b, a                ; Store it in b for safekeeping
    
    ; Check left button
    .check_left
        ld a, [wCurKeys]
        and PADF_LEFT          ; Check if left button is pressed
        jr z, .check_right     ; If not pressed, check right
        
        ; Move left
        ld a, b               ; Get stored X position
        dec a                 ; Move left one pixel
        cp 15                ; Check left boundary
        jr z, .done          ; If at boundary, don't move
        ld [_OAMRAM + 1], a  ; Update position
        jr .done
        
    ; Check right button
    .check_right
        ld a, [wCurKeys]
        and PADF_RIGHT         ; Check if right button is pressed
        jr z, .done           ; If not pressed, we're done
        
        ; Move right
        ld a, b               ; Get stored X position
        inc a                 ; Move right one pixel
        cp 105               ; Check right boundary
        jr z, .done          ; If at boundary, don't move
        ld [_OAMRAM + 1], a  ; Update position
        
    .done:
        ret                   ; Return instead of jumping to game_loop

main:
    call switch_screen_off

	; Copia los tiles PARA EL FONDO
	ld de, tilesfondo
	ld hl, $9000
	ld bc, tilesfondoend - tilesfondo
	call mem_copy

	; Copia el tilemap
	ld de, mapafondo
	ld hl, $9800
	ld bc, mapafondoend - mapafondo
	call mem_copy

	
	
	call inicializarNave

	call initializeBullet

	call initialize_level_system ;bien
	call initialize_enemies	;bien


	call InitHUD

	
	call clear_oam





	

	call setup_screen

	; Durante el primer frame de VBLANk, inicializa los registros display
	ld a, %11100100
	ld [rBGP], a
	ld a, %11100100
	ld [rOBP0], a

	; Inicializa las variables globales
	xor a
	ld [wFrameCounter], a
	ld [wCurKeys], a
	ld [wNewKeys], a


; main.asm (game loop section)
game_loop:
    ; Update game logic (no need to wait for VBlank)
    call update_keys
    call updateNave
    call UpdateBulletLogic
    call move_enemies	;bien
	call enemies_shoots
    call check_bullet_enemy_collisions
	call check_bullet_player_collisions
	call check_level_complete

	 ; Check level completion
    call check_level_complete
    ld a, [wLevelComplete]
    and a
    call nz, advance_level       ; If level complete, advance to next level
    
    call UpdateHUDLogic
    ; Wait for VBlank only before updating sprites
    call wait_vblank_start


	call copy_enemies_to_oam	;no cambiar orden a estas funciones
    call UpdateBulletSprites
    call UpdatePlayer_UpdateSprite
    
	
	call UpdateHUDGraphics

 
    
    jp game_loop



SECTION "Couter", WRAM0
wFrameCounter: db



SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db



SECTION "Ball Data", WRAM0
wBallMomentumX: db
wBallMomentumY: db