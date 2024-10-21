include "include/hardware.inc"

SECTION "Entry point", ROM0[$200]

DEF VRAM_TILE_DATA = $8300
DEF BYTES_PER_TILE = $10
DEF NUM_TILES = 11
DEF TILES_TOTAL_BYTES = NUM_TILES * BYTES_PER_TILE

wait_vblank_start:
   ldh a, [$44]   ; ldh a, [$44] = ld a, [$FF44]  -> rLY = $FF44
   cp a, $90      ; 144 (2⁷ + 2⁴)
   jr c, wait_vblank_start
   ret

switch_off_screen:
   call wait_vblank_start
   ld hl, $FF40   ; rLCDC
   res 7, [hl]
   ret

switch_on_screen:
   ldh a, [$40]   ; ldh a, [$40] = ld a, [$FF40]  -> rLCDC = $FF40
   set 7, a
   ldh [$40], a 
   ret

copy_data:
   .loop
      ld a, [hl] 
      ld [de], a 
      inc hl     
      inc de    
      dec bc     
      ld a, b    
      or c      
      jr nz, .loop  
   ret 

load_tiles_to_vram:
   call switch_off_screen
   ld hl, tiles_roca4t
   ld de, VRAM_TILE_DATA
   ld bc, TILES_TOTAL_BYTES
   call copy_data
   call switch_on_screen
   ret

draw_background:
   call switch_off_screen
   ld hl, $9800      ; Apuntar al inicio del BG Map ($9800)
   ld de, $87F0      ; Apuntar a la casilla del fondo
   ld bc, 32 * 32    ; Cargar el número de bytes a escribir (2048 bytes = 1024 * 2)

   .fill_loop
      ld a, [de]           ; Cargar el tile 7F
      ld [hl+], a          ; Escribir el valor $7F en la celda actual del BG Map
      dec bc               ; Decrementar el contador de bytes (BC)
      ld a, b              ; Verificar si hemos terminado (BC = 0)
      or c
      jr nz, .fill_loop    ; Si no hemos terminado, continuar con el bucle

   call switch_on_screen   
   ret


;-----------------------------
   
;;-----------------------------------------------------------
;;-----------------------------------------------------------
SECTION "Tiles_map", ROM0

;; Constantes
DEF TLM_ROW_SIZE = 20
DEF TLM_COL_SIZE = 18
DEF VRAM_ROW_SIZE = 32
DEF OAM_NUM_OBJS = 40
DEF OAM_OBJ_SIZE = 4
DEF OAM_BYTES = OAM_NUM_OBJS * OAM_OBJ_SIZE
DEF OAM_START = $FE00


;; Simple tilemap made of 4x4 tile Rocks
;; Total size of the tilemap: 20x18 (all the screen)
tilemap:
   DB 30,31,30,31,30,31,30,31,30,31,30,31,30,31,30,31,30,31,30,31
   DB 32,33,32,33,32,33,32,33,32,33,32,33,32,33,32,33,32,33,32,33
   DB 30,31, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,30,31
   DB 32,33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,32,33
   DB 30,31, 0, 0,30,31,30,31,30,31, 0, 0,30,31,30,31, 0, 0,30,31
   DB 32,33, 0, 0,32,33,32,33,32,33, 0, 0,32,33,32,33, 0, 0,32,33
   DB 30,31, 0, 0, 0, 0, 0, 0,30,31, 0, 0, 0, 0, 0, 0, 0, 0,30,31
   DB 32,33, 0, 0, 0, 0, 0, 0,32,33, 0, 0, 0, 0, 0, 0, 0, 0,32,33
   DB 30,31,30,31,30,31, 0, 0,30,31, 0, 0,30,31,30,31, 0, 0,30,31
   DB 32,33,32,33,32,33, 0, 0,32,33, 0, 0,32,33,32,33, 0, 0,32,33
   DB 30,31, 0, 0, 0, 0, 0, 0,30,31, 0, 0, 0, 0, 0, 0, 0, 0,30,31
   DB 32,33, 0, 0, 0, 0, 0, 0,32,33, 0, 0, 0, 0, 0, 0, 0, 0,32,33
   DB 30,31, 0, 0,30,31, 0, 0,30,31,30,31,30,31,30,31, 0, 0,30,31
   DB 32,33, 0, 0,32,33, 0, 0,32,33,32,33,32,33,32,33, 0, 0,32,33
   DB 30,31, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,30,31
   DB 32,33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,32,33
   DB 30,31,30,31,30,31,30,31,30,31,30,31,30,31,30,31,30,31,30,31
   DB 32,33,32,33,32,33,32,33,32,33,32,33,32,33,32,33,32,33,32,33

;;---------------------------------------------------------
;;---------------------------------------------------------
SECTION "Helpers", ROM0

;;----------------------------------------------
;; Sets all the bytes of an array of bytes in
;; memory to a given value-
;; WARNING: Maximum of 510 bytes per array
;; INPUT:
;; - HL: Start address of the array in memory
;; - B:  Number of pairs of bytes to set
;; - A:  Value to be set for each byte
;; MODIFIES: F, B, HL
;;
memset_mini_2x:
   inc b
   .loop
      dec b
      ret z
      ld [hl+], a    ;; Write next two bytes and 
      ld [hl+], a    ;; HL += 2
      jr .loop       ;; Repeat loop

;;----------------------------------------------
;; Clear the OAM (sets all bytes to 0’s)
;; Uses memset_mini_2x.
;; WARNING: If doesn't test for VBLANK/HBLANK
;; MODIFIES: AF, B, HL
;;
clear_OAM:
   ld a, 0
   ld b, OAM_BYTES / 2     ;; Size of the OAM in Pairs of bytes
   ld hl, OAM_START        ;; HL -> OAM Start Address
   call memset_mini_2x     ;; Set all to 0's
   ret                     ;; Return to caller

;;----------------------------------------------
;; Sets all three palettes (rBGP, rOBP0, rOBP1)
;; to the ones given by parameters
;; INPUT:
;;    B: Background Palette
;;    C: rOBP0 Palette
;;    A: rOBP1 Palette
;; MODIFIES: A
;;
set_default_palettes:
   ld [rOBP1], a     ;; Set rOBP1 Palette  
   ld a, c
   ld [rOBP0], a     ;; Set rOBP0 Palette  
   ld a, b
   ld [rBGP], a      ;; Set rBGP Palette
   ret               ;; Return to caller

;;----------------------------------------------
;; Makes objects (sprites) visible, sets
;; object size to 8x8 and enable the 2nd tilemap
;; Tilemap select: bit6 = 1 -> $9C00 selected
;; Object size:    bit2 = 0 -> 8x8 selected
;; Object visible: bit1 = 1 -> Visible
;; MODIFIES: A
;;
setup_LCD:
   ld hl, rLCDC
   set 6, [hl]    ;; Set bit 6 (Selects tilemap $9C00)
   res 2, [hl]    ;; Reset bit 2 (Object size 8x8)
   set 1, [hl]    ;; Set bit 1 (Objects visible)
   ret            ;; Return to caller

;;----------------------------------------------
;; Copies one tilemap column from ROM to VRAM. 
;; Remember: As tilemaps are stored by rows,
;; the next in the same column is after a compete
;; row of elements.
;; INPUT:
;; - HL: Start address of the column in ROW
;; - DE: Start address of the destination in VRAM
;; - C: Size of the column in bytes
;; MODIFIES: AF, B, DE, HL
;;
draw_one_tilemap_column:
   .loop
      ld a, [hl]              ;; A = Read a tilemap byte from ROM
      ld [de], a              ;; Copy the byte to the VRAM (draw it)
      
      push bc                 ;; Save BC in the stack
   
      ld bc, VRAM_ROW_SIZE    ;; HL += 1-VRAM-ROW
      add hl, bc              ;; HL Points to the next column element
      
      pop bc                  ;; Restore BC from the stack
      push hl                 ;; Save HL in the stack
      
      ld hl, TLM_ROW_SIZE     ;; HL = 1-TLM-ROW + DE
      add hl, de
      ld d, h                 ;; DE = HL = 1-TLM-ROW + DE
      ld e, l                 ;; DE Points to next column element
      
      pop hl                  ;; Restore HL from the stack
      
      dec c                   ;; Counter -= 1
      jr nz, .loop            ;; If (Counter != 0) next element
   ret                 

;;---------------------------------------------------------
;; Dibuja el mapa de tiles completo en la pantalla
;; Copia las columnas desde el tilemap en ROM a la VRAM
;; Utiliza la función draw_one_tilemap_column para dibujar cada columna
;; MODIFICA: AF, BC, DE, HL
;;
draw_tilemap:
   ld hl, tilemap        ;; HL apunta al inicio del tilemap en ROM
   ld de, $9800          ;; DE apunta al inicio de la VRAM (dirección del tilemap en VRAM)
   ld b, TLM_COL_SIZE    ;; B = número de columnas del tilemap

   .loop_column
      ld c, TLM_ROW_SIZE            ;; C = número de filas por columna (alto del tilemap)
      call draw_one_tilemap_column  ;; Dibuja una columna
      inc de                        ;; Pasa a la siguiente columna en la VRAM
      inc de                        ;; Avanza al siguiente espacio de VRAM para la siguiente columna
      inc hl                        ;; Pasa a la siguiente columna en el tilemap en ROM
      inc hl                        ;; Siguiente par de tiles en el tilemap en ROM
      dec b                         ;; Reduce el contador de columnas
      jr nz, .loop_column           ;; Si no ha terminado, dibuja la siguiente columna

   ret                              ;; Regresa cuando el tilemap está dibujado



;;---------------------------------------------------------
;;---------------------------------------------------------
SECTION "Render System", ROM0

;;----------------------------------------------
;; Initializes the render system
;; INPUT:
;; - DE: Start address of the source tilemap in ROM
;; - HL: Start address of the destination in VRAM
;; - BC: Size of a ROW in bytes
;; - A: Number of ROWs
;; MODIFIES: AF, BC, DE, HL
;;
;;---------------------------------------------------------
;; Inicializa la memoria, la pantalla y dibuja el mapa
;;
init_map:
   call switch_off_screen

   call clear_OAM

   ld b, $E4                    ;; Paleta de fondo (rBGP)
   ld c, $D2                    ;; Paleta de sprites 1 (rOBP0)
   ld a, $D2                    ;; Paleta de sprites 2 (rOBP1)
   call set_default_palettes     ;; Aplicar las paletas

   call setup_LCD             
   call draw_tilemap           
   call switch_on_screen

   ret                          

;-----------------------------------


main::

   call load_tiles_to_vram

   call draw_background

   call init_map

   di     ;; Disable Interrupts
   halt   ;; Halt the CPU (stop procesing here)
