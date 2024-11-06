; Enemy Constants
DEF MAX_ENEMIES           EQU 10    ; Maximum number of enemies on screen
DEF ENEMY_STRUCT_SIZE     EQU 4     ; Size of each enemy structure (X, Y, direction, active)
DEF ENEMY_MIN_X          EQU 8     ; Left screen boundary
DEF ENEMY_MAX_X          EQU 152   ; Right screen boundary
DEF ENEMY_MIN_Y          EQU 16    ; Top screen boundary
DEF ENEMY_MAX_Y          EQU 88    ; Bottom screen boundary
DEF ENEMY_ACTIVE_OFFSET    EQU 3     

DEF MOVE_DELAY EQU 8

; Movement Directions/Patterns (using the direction byte)
DEF DIR_RIGHT            EQU 0     ; Original right movement
DEF DIR_LEFT             EQU 1     ; Original left movement
DEF DIR_UP               EQU 2     ; Moving up
DEF DIR_DOWN             EQU 3     ; Moving down
DEF DIR_DIAGONAL_RIGHT   EQU 4     ; Moving diagonal right
DEF DIR_DIAGONAL_LEFT    EQU 5     ; Moving diagonal left

; Enemy Speed per Level
DEF ENEMY_SPEED    EQU 1     

DEF ENEMY_SPEED_LVL4     EQU 2     ; Faster speed for level 4
DEF ENEMY_SPEED_LVL5     EQU 3     ; Even faster for level 5
DEF ENEMY_SPEED_LVL6     EQU 4     ; Fastest for level 6

; Level Constants
DEF TOTAL_ENEMIES_LVL1   EQU 3     ; Level 4: Diagonal pattern
DEF TOTAL_ENEMIES_LVL2    EQU 5     ; Level 5: Mixed up/down
DEF TOTAL_ENEMIES_LVL3    EQU 7    ; Level 6: All directions
DEF TOTAL_ENEMIES_LVL4    EQU 8     ; Level 4: Diagonal pattern
DEF TOTAL_ENEMIES_LVL5    EQU 9     ; Level 5: Mixed up/down
DEF TOTAL_ENEMIES_LVL6    EQU 10    ; Level 6: All directions