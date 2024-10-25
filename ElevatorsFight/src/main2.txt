INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

	jp EntryPoint

	ds $150 - @, 0  ; Crea ROM para el Header


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

	.left
		; Mueve la nave un pixel a la izquierda
		ld a, [_OAMRAM + 1]  	; Se accede a la posición X de la nave, OAM -> 0:Y, 1:X, 2:INDICETILE, 3:ATRIBUTOS
		dec a					; Se mueve 1 pixel a la izquierda
		cp 15					; 15 = $0F = %00001111 -> Borde izquierda
		jp z, main				; Si es 0, está en el borde y no se mueve
		ld [_OAMRAM + 1], a		; Si no lo está, actualiza el valor de X de la nave
		jp main

	; Comprueba del botón derecho
	.check_right
		ld a, [wCurKeys]
		and a, PADF_RIGHT		; PADF_RIGHT = $10 = %00010000 -> Bit corresponidente al botón derecho
		jp z, main				; Si el botón no está presionado, salta a main

	.right
		; Mueve la nave un pixel a la derecha
		ld a, [_OAMRAM + 1]		; Se accede a la posición X de la nave
		inc a					; Se mueve 1 pixel a la derecha
		cp 105					; 105 = $69 = %01101001 -> Borde derecha
		jp z, main				; Si es 0, está en el borde y no se mueve
		ld [_OAMRAM + 1], a		; Si no lo está, actualiza el valor de X de la nave
		jp main


main:
	call wait_vblank_end
	call wait_vblank_start
	call update_keys
	jp move 
	ret


EntryPoint:
    call switch_screen_off

	; Copia los tiles
	ld de, Tiles
	ld hl, $9000
	ld bc, TilesEnd - Tiles
	call mem_copy

	; Copia el tilemap
	ld de, Tilemap
	ld hl, $9800
	ld bc, TilemapEnd - Tilemap
	call mem_copy

	; Copia los tiles de la nave
	ld de, nave
	ld hl, $8000
	ld bc, naveend - nave
	call mem_copy

	call clear_oam

	ld hl, _OAMRAM
	ld a, 128 + 16		
	ld [hl+], a			; Posición en el eje Y -> 144
	ld a, 16 + 8		
	ld [hl+], a			; Posición en el eje X -> 24
	xor a
	ld [hl+], a			; Primer tile en la memoria de tiles
	ld [hl], a			; Sprite sin propiedades especiales

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

	jp main


Tiles:
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33322222
	dw `33322222
	dw `33322222
	dw `33322211
	dw `33322211
	dw `33333333
	dw `33333333
	dw `33333333
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11111111
	dw `11111111
	dw `33333333
	dw `33333333
	dw `33333333
	dw `22222333
	dw `22222333
	dw `22222333
	dw `11222333
	dw `11222333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `22222222
	dw `20000000
	dw `20111111
	dw `20111111
	dw `20111111
	dw `20111111
	dw `22222222
	dw `33333333
	dw `22222223
	dw `00000023
	dw `11111123
	dw `11111123
	dw `11111123
	dw `11111123
	dw `22222223
	dw `33333333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `11001100
	dw `11111111
	dw `11111111
	dw `21212121
	dw `22222222
	dw `22322232
	dw `23232323
	dw `33333333
	; My custom logo (tail)
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33302333
	dw `33333133
	dw `33300313
	dw `33300303
	dw `33013330
	dw `30333333
	dw `03333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `03333333
	dw `30333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333330
	dw `33333320
	dw `33333013
	dw `33330333
	dw `33100333
	dw `31001333
	dw `20001333
	dw `00000333
	dw `00000033
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33330333
	dw `33300333
	dw `33333333
	dw `33033333
	dw `33133333
	dw `33303333
	dw `33303333
	dw `33303333
	dw `33332333
	dw `33332333
	dw `33333330
	dw `33333300
	dw `33333300
	dw `33333100
	dw `33333000
	dw `33333000
	dw `33333100
	dw `33333300
	dw `00000001
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `10000333
	dw `00000033
	dw `00000003
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `33332333
	dw `33302333
	dw `32003333
	dw `00003333
	dw `00003333
	dw `00013333
	dw `00033333
	dw `00033333
	dw `33333300
	dw `33333310
	dw `33333330
	dw `33333332
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `30000000
	dw `33000000
	dw `33333000
	dw `33333333
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000003
	dw `00000033
	dw `00003333
	dw `02333333
	dw `33333333
	dw `00333333
	dw `03333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
TilesEnd:

Tilemap:
	db $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $02, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $0A, $0B, $0C, $0D, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $0E, $0F, $10, $11, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $12, $13, $14, $15, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $16, $17, $18, $19, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
TilemapEnd:



SECTION "Contador", WRAM0
wFrameCounter: db



SECTION "Variables de entrada", WRAM0
wCurKeys: db
wNewKeys: db