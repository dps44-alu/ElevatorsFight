INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

	jp EntryPoint

	ds $150 - @, 0 ; Crea ROM para el Header

EntryPoint:
	; No apagar la pantalla fuera de VBLANK

WaitVBlank:
	ld a, [rLY]
	cp 144				; Principio de VBLANK
	jp c, WaitVBlank

	; Apaga la pantalla
	xor a
	ld [rLCDC], a	

	; Copia los tiles
	ld de, Tiles
	ld hl, $9000
	ld bc, TilesEnd - Tiles
	call Memcopy

	; Copia el tilemap
	ld de, Tilemap
	ld hl, $9800
	ld bc, TilemapEnd - Tilemap
	call Memcopy

	; Copia el tile de la nave
	ld de, nave
	ld hl, $8000
	ld bc, naveend - nave
	call Memcopy

	xor a
	ld b, 160			; Número de bytes en la OAM que controla los sprites
	ld hl, _OAMRAM

ClearOam:
	ld [hl+], a
	dec b
	jr nz, ClearOam

	ld hl, _OAMRAM
	ld a, 128 + 16
	ld [hl+], a
	ld a, 16 + 8
	ld [hl+], a
	ld a, 0
	ld [hl+], a
	ld [hl], a

	; Enciende la pantalla
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
	ld [rLCDC], a

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

Main:
	ld a, [rLY]
	cp 144
	jp nc, Main
	
WaitVBlank2:
	ld a, [rLY]
	cp 144
	jp c, WaitVBlank2

	; Conprueba las teclas actuales cada frame y mueve a la izquierda o la derecha 
	call UpdateKeys

	; Primero comprueba si el botón de la izquierda ha sido presionado
CheckLeft:
	ld a, [wCurKeys]
	and a, PADF_LEFT
	jp z, CheckRight

Left:
	; Mueve la nave un pixel a la izquierda
	ld a, [_OAMRAM + 1]  	; OAM -> 0:Y, 1:X, 2:INDICETILE, 3:ATRIBUTOS
	dec a
	; Si está en el borde, no se mueve
	cp a, 15
	jp z, Main
	ld [_OAMRAM + 1], a
	jp Main

; Comprueba la tecla de la derecha
CheckRight:
	ld a, [wCurKeys]
	and a, PADF_RIGHT
	jp z, Main

Right:
	; Mueve la nave un pixel a la derecha
	ld a, [_OAMRAM + 1]
	inc a
	; Si está en el borde, no se mueve
	cp a, 105
	jp z, Main
	ld [_OAMRAM + 1], a
	jp Main

UpdateKeys:
	; Escribe la mitad del controllador
	ld a, P1F_GET_BTN
	call .onenibble		; 1 nibble = 4 bits = 1/2 bytes
	ld b, a 			; B7-4 = 1; B3-0 = botones no presionados

	; Escribe la otra mitad
	ld a, P1F_GET_DPAD
	call .onenibble
	swap a 				; A3-0 = direcciones no presionadas; A7-4 = 1
	xor a, b 			; A = botones presionados + direcciones
	ld b, a 			; B = botones presionados + direcciones

	; Carga los controladores
	ld a, P1F_GET_NONE
	ldh [rP1], a

	; Combina con las wCurKeys previas para crear las wNewKeys
	ld a, [wCurKeys]
	xor a, b 			; A = teclas que han cambiado de estado
	and a, b 			; A = teclas que han cambiado a presionadas
	ld [wNewKeys], a
	ld a, b
	ld [wCurKeys], a
	ret

	.onenibble
		ldh [rP1], a 		; Cambia la matriz de teclas
		call .knownret 		; Quema 10 ciclos llamando a un ret
		ldh a, [rP1] 		; Ignorar para que la matriz de teclas se estabilice
		ldh a, [rP1]
		ldh a, [rP1] 		; Lee
		or a, $F0 			; A7-4 = 1; A3-0 = teclas no presionadas
	
	.knownret
		ret

; Copia bytes de un área a otra
; DE: Origen
; HL: Destino
; BC: Tamaño
Memcopy:
	ld a, [de]
	ld [hl+], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, Memcopy
	ret

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



SECTION "Counter", WRAM0
wFrameCounter: db

; ANCHOR: vars
SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db
; ANCHOR_END: vars