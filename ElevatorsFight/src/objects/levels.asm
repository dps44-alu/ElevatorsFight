; levels.asm
INCLUDE "objects/constants.asm"

DEF MAX_LEVEL EQU 3     ; Total number of levels

SECTION "Level Variables", WRAM0
wCurrentLevel:    DS 1    ; Current level (1-3)
wLevelComplete:   DS 1    ; Flag for level completion

SECTION "Level Code", ROM0


initialize_level_system::
    ld a, 1              ; Start with level 1
    ld [wCurrentLevel], a
    xor a
    ld [wLevelComplete], a
    ret

check_level_complete::
    ld a, [wCurrentEnemies]
    and a               ; Check if enemies = 0
    ret nz              ; Return if not complete
    
    ; Level is complete
    ld a, 1
    ld [wLevelComplete], a
    ret

advance_level::
    ld a, [wCurrentLevel]
    inc a
    cp MAX_LEVEL + 1
    jr z, .game_complete
    
    ; Start next level
    ld [wCurrentLevel], a
    xor a
    ld [wLevelComplete], a
    call initialize_enemies
    ret

.game_complete:
    ; Handle game completion (you can add your own code here)
    ret