INCLUDE "hardware.inc"

; Enemy Constants
DEF MAX_ENEMIES          EQU 10   ; Maximum number of enemies on screen
DEF ENEMY_STRUCT_SIZE    EQU 4     ; Size of each enemy structure (X, Y, direction, active)
DEF ENEMY_MIN_X         EQU 8      ; Left screen boundary
DEF ENEMY_MAX_X         EQU 152    ; Right screen boundary
DEF ENEMY_SPEED         EQU 1      ; Movement speed
DEF MOVE_DELAY          EQU 8      ; Movement update frequency

; Enemy Structure Offsets
DEF ENEMY_X_OFFSET      EQU 0
DEF ENEMY_Y_OFFSET      EQU 1
DEF ENEMY_DIR_OFFSET    EQU 2
DEF ENEMY_ACTIVE_OFFSET EQU 3
DEF ENEMY_DELAY_SHOOT_1   EQU 180    ; 1 disparo cada 3 segundos
DEF ENEMY_DELAY_SHOOT_2   EQU 180    ; 1 disparo cada 2 segundos
DEF ENEMY_DELAY_SHOOT_3   EQU 180     ; 1 disparo cada 1 segundos

; Gameplay Constants
DEF TOTAL_ENEMIES_LVL1  EQU 3     ; Number of enemies in level 1
DEF TOTAL_ENEMIES_LVL2  EQU 5     ; Number of enemies in level 2
DEF TOTAL_ENEMIES_LVL3  EQU 7     ; Number of enemies in level 3
