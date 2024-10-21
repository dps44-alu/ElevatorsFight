INCLUDE "src/main/utils/hardware.inc"

SECTION "GameVariables", WRAM0

wLastKeys:: db ; Joypat input
wCurKeys:: db  ; Joypat input
wNewKeys:: db
wGameState::db ; Track the game state

SECTION "Header", ROM0[$100]

   jp EntryPoint

   ds $150 - @, 0 ; Make room for the header

EntryPoint:
; ANCHOR_END: entry-point
	
; ANCHOR: entry-point-end
	; Shut down audio circuitry
	xor a
	ld [rNR52], a
	; We don't actually need another xor a here, because the value of A doesn't change between these two instructions
	ld [wGameState], a

	; Wait for the vertical blank phase before initiating the library
    call WaitForOneVBlank

	; from: https://github.com/eievui5/gb-sprobj-lib
	; The library is relatively simple to get set up. First, put the following in your initialization code:
	; Initilize Sprite Object Library.
	call InitSprObjLibWrapper

	; Turn the LCD off
	xor a
	ld [rLCDC], a

	; Load our common text font into VRAM
	call LoadTextFontIntoVRAM

	; Turn the LCD on
	ld a, LCDCF_ON  | LCDCF_BGON|LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_WINON | LCDCF_WIN9C00
	ld [rLCDC], a

	; During the first (blank) frame, initialize display registers
	ld a, %11100100
	ld [rBGP], a
	ld [rOBP0], a

; ANCHOR_END: entry-point-end
; ANCHOR: next-game-state