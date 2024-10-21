SECTION "Tiles", ROM0[$150]

;; https://pastebin.com/P93KuT5U
tile_definitions::
    tiles_roca4t:
        DB $03, $FF, $19, $F8, $7E, $E0, $A9, $A4, $5A, $40, $ED, $80, $D7, $88, $EF, $80 ;; 1
        DB $E0, $FF, $54, $1F, $BF, $0E, $6F, $15, $FF, $0A, $FD, $07, $AF, $5B, $5D, $A7 ;; 2
        DB $BF, $80, $FB, $E4, $F1, $D4, $DA, $8D, $E4, $9A, $FA, $B5, $78, $EF, $3F, $D7 ;; 3
        DB $AF, $5B, $F5, $0F, $BB, $2F, $5D, $B7, $2B, $5F, $5D, $AF, $1E, $F7, $FC, $EB ;; 4
    tiles_character:
        ;; Caminando: Cabeza-Pies Izquierda, Cabeza-Pies Derecha
        DB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;; 5 (Relleno)
        DB $00, $00, $07, $07, $08, $0F, $10, $1F, $10, $1F, $3B, $3C, $3F, $3F, $7F, $50 ;; 6
        DB $7F, $42, $7F, $72, $7E, $59, $3F, $3F, $1B, $1F, $0E, $0F, $09, $0F, $07, $07 ;; 7
        DB $00, $00, $E0, $E0, $10, $F0, $08, $F8, $08, $F8, $DC, $3C, $FC, $FC, $FE, $0A ;; 8
        DB $FE, $42, $FC, $4C, $7C, $9C, $F4, $F4, $FC, $CC, $78, $C8, $B0, $B0, $00, $00 ;; 9
        ;; Quieto: Cabeza-Pies Izquierda
        DB $07, $07, $08, $0F, $10, $1F, $10, $1F, $3B, $3C, $3F, $37, $7F, $50, $7F, $42 ;; A
        DB $3F, $32, $3E, $39, $7F, $4F, $7F, $4F, $39, $3F, $16, $1F, $11, $1F, $0E, $0E ;; B