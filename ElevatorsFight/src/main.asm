INCLUDE "hardware.inc"

SECTION "Main", ROM0[$0150]


wait_vblank_start:
	.loop
		ld a, [rLY]		; rLY = $FF44 -> Indica la línea actual que está siendo dibujada
		cp 144			; Principio de VBLANK
		jr c, .loop
    ret


wait_vblank_end:
	.loop
		ld a, [rLY]
		cp 144
		jr nc, .loop
	ret


switch_screen_off:
    call wait_vblank_start
    xor a
	ld [rLCDC], a				; rLCDC = $FF40 -> Controla la pantalla, el bit 7 indica si está encendia (1) o apagada (0)
    ret


switch_screen_on:
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


; Añade el momentum de la bola a su posicion en la OAM
; ball_new_position:
;     ld a, [wBallMomentumX]
;     ld b, a
;     ld a, [_OAMRAM + 5]			; +5 -> Ubicación de la posición X en la OAM
;     add a, b					; Momentum en X + Posición actual en X
;     ld [_OAMRAM + 5], a			; Nueva posición en X

;     ld a, [wBallMomentumY]
;     ld b, a
;     ld a, [_OAMRAM + 4]			; +4 -> Ubicación de la posición Y en la OAM
;     add a, b					; Momentum en Y + Posición actual en Y
;     ld [_OAMRAM + 4], a			; Nueva posición en Y

; 	ret


; Convierte una posición de un pixel en la dirección de un tilemap
; HL = $9800 + X + Y * 32
; B: X
; C: Y
; HL: Dirección del tile
get_tile_by_pixel:
	; Primero hay que dividir entre 8 para convertir la posición de un pixel en la posición de un tile
	; (Porque cada tile ocupa 8 pixeles en el eje vertical)
	; Después hay que multiplicar la posición Y por 32 (Ancho de la pantalla en tiles)
	; Como estas dos operaciones se cancelan, sólo hay que enmascarar el valor de Y
    ld a, c
    and %11111000		; Enmascara los 3 bits menos significativos, pone a 0 estos bits
    ld l, a				; Carga A en la parte baja de HL
    ld h, 0				; Pone a 0 la parte alta de HL

	; Ahora tenemos la posición multiplicada por 8 en HL
    add hl, hl 			; Posición * 16
    add hl, hl 			; Posición * 32

	; Convierte la posición X en offset
    ld a, b
    srl a 				; a / 2
    srl a 				; a / 4
    srl a 				; a / 8

    ; Añade los dos offsets juntos
    add a, l
    ld l, a
    adc a, h
    sub a, l
    ld h, a

	; Añade el offset a la dirección base del tilemap
    ld bc, $9800
    add hl, bc
    ret


; A: ID del tile
; Tiles considerados paredes, si la bola está en estos rebota
; is_wall_tile:
;     cp a, $00
;     ret z
;     cp a, $01
;     ret z
;     cp a, $02
;     ret z
;     cp a, $04
;     ret z
;     cp a, $05
;     ret z
;     cp a, $06
;     ret z
;     cp a, $07
;     ret


; ball_bounce:
; 	.bounce_on_top
; 		; Los sprites en OAM no coinciden directamente con la posición en pantalla
; 		; Hay un offset de 16 unidades en Y, y de 8 unidades en X -> (8, 16) en OAM es (0, 0) en la pantalla
; 		ld a, [_OAMRAM + 4]			; _OAMRAM + 4 -> Posición Y de la bola
; 		sub a, 16 + 1				; +1 -> Para prever un posible choque en la parte superior del tile
; 		ld c, a
; 		ld a, [_OAMRAM + 5]			; _OAMRAM + 5 -> Posición X de la bola
; 		sub a, 8
; 		ld b, a
; 		call get_tile_by_pixel 		; Devuelve la dirección del tile en HL
; 		ld a, [hl]
; 		call is_wall_tile			; Se verifica si el tile es una pared
; 		jp nz, .bounce_on_right		; Si no se encuentra un tile de pared, se salta a la siguiente subrutina
; 		ld a, 1
; 		ld [wBallMomentumY], a		; Si se encuentra un tile de pared, invierte la dirección vertical

; 	.bounce_on_right
; 		ld a, [_OAMRAM + 4]
; 		sub a, 16
; 		ld c, a
; 		ld a, [_OAMRAM + 5]
; 		sub a, 8 - 1				; -1 -> Para prever un posible choque en la parte superior del tile
; 		ld b, a
; 		call get_tile_by_pixel
; 		ld a, [hl]
; 		call is_wall_tile
; 		jp nz, .bounce_on_left
; 		ld a, -1
; 		ld [wBallMomentumX], a		; Si se encuentra un tile de pared, invierte la dirección horizontal

; 	.bounce_on_left:
; 		ld a, [_OAMRAM + 4]
; 		sub a, 16
; 		ld c, a
; 		ld a, [_OAMRAM + 5]
; 		sub a, 8 + 1				; +1 -> Para prever un posible choque en la parte superior del tile
; 		ld b, a
; 		call get_tile_by_pixel
; 		ld a, [hl]
; 		call is_wall_tile
; 		jp nz, .bounce_on_bottom
; 		ld a, 1
; 		ld [wBallMomentumX], a		; Si se encuentra un tile de pared, invierte la dirección vertical

; 	.bounce_on_bottom:
; 		ld a, [_OAMRAM + 4]
; 		sub a, 16 - 1				; -1 -> Para prever un posible choque en la parte superior del tile
; 		ld c, a
; 		ld a, [_OAMRAM + 5]
; 		sub a, 8
; 		ld b, a
; 		call get_tile_by_pixel
; 		ld a, [hl]
; 		call is_wall_tile
; 		jp nz, .bounce_done
; 		ld a, -1
; 		ld [wBallMomentumY], a		; Si se encuentra un tile de pared, invierte la dirección vertical

; 	.bounce_done
; 	ret


; spaceship_bounce:
; 	; Primero comprueba si la bola está lo suficientemente abajo como para rebotar con la nave
;     ld a, [_OAMRAM]					; Posición Y de la nave
;     ld b, a
;     ld a, [_OAMRAM + 4]				; Posición Y de la bola
; 	;add 6							; Para que rebote en cuanto toque y no con los sprites superpuestos
;     cp b
;     jp nz, .spaceship_bounce_done	; Si la nave no está en la misma posición Y que la nave, no puede rebotar

; 	; Ahora se compara la posición X de los objetos para comprobar si se están tocando
;     ld a, [_OAMRAM + 5] 			; Posición X de la bola
;     ld b, a
;     ld a, [_OAMRAM + 1] 			; Posición X de la nave
;     sub 8							; Ajuste por el borde de la nave
;     cp b
;     jp nc, .spaceship_bounce_done	; Si la posición ajustada es mayor o igual, no hay colisión
;     add a, 8 + 16 					; Deshacer el ajuste de 8 y sumar el ancho de la nave (16)
;     cp b
;     jp c, .spaceship_bounce_done	; Si la bola está más allá del borde de la nave, no hay colisión

;     ld a, -1
;     ld [wBallMomentumY], a			; Invierte la dirección vertical de la bola

; 	.spaceship_bounce_done
; 	ret


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
	; Comprueba del botón izquierdo
	.check_left
		ld a, [wCurKeys]
		and PADF_LEFT			; PADF_LEFT = $20 = %00100000 -> Bit correspondiente al botón izquierdo
		jp z, .check_right		; Si el botón no está presionado, salta a check_right

	; .left
	; 	; Mueve la nave un pixel a la izquierda
	; 	ld a, [_OAMRAM + 1]  	; Se accede a la posición X de la nave, OAM -> 0:Y, 1:X, 2:INDICETILE, 3:ATRIBUTOS
	; 	dec a					; Se mueve 1 pixel a la izquierda
	; 	cp 15					; 15 = $0F = %00001111 -> Borde izquierda
	; 	jp z, main				; Si es 0, está en el borde y no se mueve
	; 	ld [_OAMRAM + 1], a		; Si no lo está, actualiza el valor de X de la nave
	; 	jp game_loop

	; Comprueba del botón derecho
	.check_right
		ld a, [wCurKeys]
		and a, PADF_RIGHT		; PADF_RIGHT = $10 = %00010000 -> Bit corresponidente al botón derecho
		jp z, game_loop				; Si el botón no está presionado, salta a main

	; .right
	; 	; Mueve la nave un pixel a la derecha
	; 	ld a, [_OAMRAM + 1]		; Se accede a la posición X de la nave
	; 	inc a					; Se mueve 1 pixel a la derecha
	; 	cp 105					; 105 = $69 = %01101001 -> Borde derecha
	; 	jp z, main				; Si es 0, está en el borde y no se mueve
	; 	ld [_OAMRAM + 1], a		; Si no lo está, actualiza el valor de X de la nave
	; 	jp game_loop


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

	; ; Copia los tiles de la nave
	; ld de, nave
	; ld hl, $8000
	; ld bc, naveend - nave
	; call mem_copy
	
	call inicializarNave

	call initializeBullet

	call initialize_enemy

	; ; Copia los tiles de la bola
    ; ld de, ball
    ; ld hl, $8010
    ; ld bc, ballend - ball
    ; call mem_copy

	;COPIAMOS LA NAVE1
	; ld de,nave1
	; ld hl,$8010
	; ld bc, nave1end - nave1
	; call mem_copy

	call clear_oam

	call copy_enemy_to_oam

	; ; Inicializa el sprite de la nave en la OAM
	; ;ESTE ES NUESTRO JUGADOR
	; ld hl, _OAMRAM
	; ld a, 128 + 16
	; ld [hl+], a			; Posición en el eje Y -> 144
	; ld a, 16 + 8
	; ld [hl+], a			; Posición en el eje X -> 24
	; xor a
	; ld [hl+], a			; Primer tile en la memoria de tiles
	; ld [hl+], a			; Sprite sin propiedades especiales
	
	;call updateNave NOOO

	; ; Inicializa el sprite de la bola en la OAM
	; ld a, 100 + 16
    ; ld [hl+], a			; Posición en el eje Y -> 116
    ; ld a, 32 + 8
    ; ld [hl+], a			; Posición en el eje X -> 40
    ; ld a, 1
    ; ld [hl+], a			; Primer tile de la bola
    ; ld a, 0
    ; ld [hl+], a			; Sprite sin propiedades especiales

    ; ld a, 1
    ; ld [wBallMomentumX], a	; La bola comienza moviéndose a la derecha
    ; ld a, -1
    ; ld [wBallMomentumY], a	; Y hacia arriba

	;NAVE1
	; ld a, 50 + 16
    ; ld [hl+], a			; Posición en el eje Y -> 116
    ; ld a, 32 + 8
    ; ld [hl+], a			; Posición en el eje X -> 40
    ; ld a, 1			;AQUI VA EL NUMERO DE CELDA DE LA VRAM
    ; ld [hl+], a			; Primer tile de la bola
    ; ld a, 0
    ; ld [hl+], a			; Sprite sin propiedades especiales

	call switch_screen_on

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


game_loop:
	call wait_vblank_end
	call wait_vblank_start

	call update_keys

	call move_enemy
	call copy_enemy_to_oam

    ; Actualiza las entradas y mueve la nave
	call updateNave

	call UpdateBullet

    jp game_loop



SECTION "Couter", WRAM0
wFrameCounter: db



SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db



SECTION "Ball Data", WRAM0
wBallMomentumX: db
wBallMomentumY: db