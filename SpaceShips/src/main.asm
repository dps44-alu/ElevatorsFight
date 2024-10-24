include "include/hardware.inc"

SECTION "Entry point", ROM0[$200]

DEF VRAM_TILE_DATA = $8300
DEF BYTES_PER_TILE = $10
DEF NUM_TILES = 11
DEF TILES_TOTAL_BYTES = NUM_TILES * BYTES_PER_TILE

wait_vblank_start:
   ldh a, [rLY]            ; ldh a, [$44] = ld a, [$FF44]  -> rLY = $FF44
   cp 144                  ; $90
   jr c, wait_vblank_start
   ret

switch_off_screen:
   call wait_vblank_start
   ld hl, rLCDC   ; $FF40
   res 7, [hl]
   ret

switch_on_screen:
   ldh a, [rLCDC]    ; ldh a, [$40] = ld a, [$FF40]  -> rLCDC = $FF40
   set 7, a
   ldh [rLCDC], a 

   ld a, %11100100   ; Durante el primer frame de vblank 
   ld [rBGP], a      ; inicializa los registros de visualización

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


draw_rock:
   call switch_off_screen

   ld hl, $9800
   ld a, 30
   ld [hl], a

   ld bc, 16
   .loop
      inc hl
      inc a
      ld [hl], a
      dec bc
      ld a, b
      or c
      jr nz, .lopp


   call switch_on_screen
   ret


main::

   call load_tiles_to_vram

   call draw_background

   call draw_rock

   di     ;; Disable Interrupts
   halt   ;; Halt the CPU (stop procesing here)
