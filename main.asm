; Shamus for the Commodore Vic20
; Written by Tom Griner and released by Human Enginered Software in 1983.
;
; This disassembly explains how this well-crafted game works in detail.
;
;--------------------------------------------------------------------------------------------------
; System addresses

_VIC_SCREEN_LEFT_EDGE  = $9000  ;36864 left edge of TV picture
_VIC_SCREEN_TOP_EDGE   = $9001  ;36865 vertical TV picture origin
_VIC_CR2               = $9002  ;36866 bit 7 to switch screen buffer
                                ;      bit 6-0: for characters per column
_VIC_CR3               = $9003  ;36867, used for setting number of rows displayed
                                ;  bit 7: raster beam location bit 0 (n/a here)
                                ;  bit 6-1: number of character lines / rows
                                ;  bit 0: 1 for tall characters (16-pixels tall by 8 pixels wide)
_VIC_CR4               = $9004  ;36868, raster beam location bits
_VIC_CR5               = $9005  ;36869 provides the screen and pixel bitmap memory addresses
_VIC_SOUND_BASS        = $900a  ;36874 audio frequency generator 1
_VIC_SOUND_ALTO        = $900b  ;36875 audio frequency generator 2
_VIC_SOUND_SOPRANO     = $900c  ;36876 audio frequency generator 3
_VIC_SOUND_NOISE       = $900d  ;36877 audio frequency generator 4
_VIC_VOLUME_AUX_COLOUR = $900e  ;36878 bit 7-4 for aux colour, bit 3-0 for no volume
_VIC_BG_BORDER_COL     = $900f  ;36879 bit 7-4 for background, bit 3-0 for border

_VIA_JOYSTICK_MIRROR   = $911f  ;37151 mirror of $9111 (37137) port A I/O register
_VIA_KEYB_ROWS         = $9120  ;37152 port B I/O register
_VIA_KEYB_COLS         = $9121  ;37153 port A I/O register
_VIA_DATADIR_B         = $9122  ;37154 data direction register for port B

_COLOUR_SCREEN_ADDR    = $9600  ;38400 colour memory
_SCREEN_MATRIX_ADDR    = $0200  ;22 by 11 character-code display matrix
_CHARACTER_BITMAP_ADDR = $1000  ;writable tall-character graphics / software framebuffer
_CHARACTER_BITMAP_END  = $2000  ;first address after writable character graphics
_CHARACTER_ROM_ADDR    = $8800  ;uppercase/graphics character ROM visible to the VIC

ELECTRIC_VERTICAL_WALL_BITMAP   = _CHARACTER_BITMAP_ADDR+$0fe0 ;character code $fe
ELECTRIC_HORIZONTAL_WALL_BITMAP = _CHARACTER_BITMAP_ADDR+$0ff0 ;character code $ff

_KERNAL_NMI_VECTOR     = $0318  ;792-793 RAM vector used by the KERNAL NMI handler
_KERNAL_INITVIA        = $fdf9  ;65017 initialize VIA timers and interrupt state
_KERNAL_EXIT_INTERRUPT = $ff56  ;restore registers and return from an interrupt
_KERNAL_RS232_TIMING_DATA = $ff5b ;start of data, deliberately used here as an NMI destination

;--------------------------------------------------------------------------------------------------
; Working RAM map
;
; The game makes very heavy use of zero page.  Some locations are also scratch values inside
; drawing routines, but the names below describe their persistent meaning in the game loop.

FRAMEBUFFER_PTR        = $00    ;2-byte address of the destination byte in character bitmap RAM
GRAPHIC_PTR            = $02    ;2-byte address of the source graphic
SCORE_PTR              = $04    ;2-byte pointer used while printing a three-byte BCD score
JOYSTICK_STATE         = $06    ;active-low: up=$04, down=$08, left=$10, fire=$20, right=$80
RANDOM_STATE           = $07
DRAW_X                 = $08
DRAW_Y                 = $09
PLAYER_X               = $0a
PLAYER_Y               = $0b
FRAME_COUNTER          = $0c
GRAPHIC_LAST_BYTE      = $0d
SHIFTED_BYTE_LOW       = $0e
SHIFTED_BYTE_HIGH      = $0f
PIXEL_SHIFT            = $10
INPUT_DIRECTION_LATCH  = $1a

PLAYER_SHOT_X          = $11    ;three entries: $11-$13
PLAYER_SHOT_Y          = $14    ;three entries: $14-$16
PLAYER_SHOT_DIRECTION  = $17    ;three entries: $17-$19, directions 0-7 clockwise

ENEMY1_X               = $1b    ;seven entries; wandering, player-seeking enemy family
ENEMY1_Y               = $22
ENEMY2_X               = $2b    ;seven entries; eight-direction moving enemy family
ENEMY2_Y               = $32
ENEMY2_DIRECTION       = $39
COLLISION_X            = $40
COLLISION_Y            = $41
EXPLOSION_X            = $42    ;seven entries
EXPLOSION_Y            = $49
EXPLOSION_FRAME        = $50    ;seven entries; zero means unused

EXTRA_LIFE_OBJECT_X    = $57
EXTRA_LIFE_OBJECT_Y    = $58
ENEMY3_X               = $5a    ;seven entries; directly homes in on the player
ENEMY3_Y               = $61
ENEMY_STEP_COUNT       = $68
SHADOW_X               = $69
SHADOW_Y               = $6a
ENEMY_ACTIVITY         = $6b
SHADOW_APPEARANCE_TIMER = $6b  ;warning at 2, Shadow released at 3; mystery may force 5
SHADOW_HIT_TIMER       = $6c
ENEMY_SHOT_X           = $6d    ;seven entries
ENEMY_SHOT_Y           = $74
ENEMY_SHOT_DIRECTION   = $7b

; Gameplay identities for the three generic array groups above.
SPIRAL_DRONE_X         = ENEMY1_X
SPIRAL_DRONE_Y         = ENEMY1_Y
ROBO_DROID_X           = ENEMY2_X
ROBO_DROID_Y           = ENEMY2_Y
ROBO_DROID_DIRECTION   = ENEMY2_DIRECTION
SNAP_JUMPER_X          = ENEMY3_X
SNAP_JUMPER_Y          = ENEMY3_Y
ROOM_NUMBER            = $59    ;0-$1f normal rooms; $21 is the lair layout
ROOM_SPEED_INDEX       = $2a    ;increases every eight rooms, indexes update-rate masks
TITLE_MUSIC_DELAY      = $82
SKILL_KEY_LATCH        = $85
SKILL_LEVEL            = $86    ;0=beginner, 1=novice, 2=advanced, 3=expert
LIVES_REMAINING        = $87
KEY_FLAGS              = $88    ;bits $80/$40/$20: keys; $08/$04/$02: matching opened keyholes
EXTRA_LIFE_COLLECTED_FLAGS = $89 ;four entries for rooms $01,$02,$0c,$1a
MYSTERY_COLLECTED_FLAGS = $8d    ;four entries for rooms $00,$08,$18,$0b
MYSTERY_OBJECT_X       = $91
MYSTERY_OBJECT_Y       = $92
HIT_TEST_MODE          = $93    ;zero permits explosion chains; nonzero tests ION SHIVs only
SCORE_BCD              = $94    ;three bytes, most significant first
HIGH_SCORE_BCD         = $97    ;three bytes, most significant first
SCORE_DIGIT_BYTE       = $83    ;packed-BCD byte being split into two displayed digits
SCORE_SAVED_Y          = $84    ;preserves score-byte index while drawing one digit
LEVEL_NUMBER           = $9c    ;0=level one, 1=level two, 2=lair
ROOM_27_BARRIER_PHASE  = $9a    ;0-7 moving gap, $ff after an ION SHIV passes through
ROOM_EXIT_RUSH_TIMER   = $9d    ;leaving within 40 main-loop iterations forces maximum enemies
ION_SHIV_SOUND_TIMER   = $9e
TITLE_MUSIC_STEP       = $9f
LAIR_HIT_COUNT         = $a0
REWARD_SOUND_TIMER     = $a1
EXPLOSION_SOUND_TIMER  = $9b
LAIR_TARGET_X          = $a2
LAIR_TARGET_Y          = $a3

; Graphic data used by the entity draw routines. These symbolic addresses also identify the
; otherwise anonymous bitmap-data stream beginning at the electric-wall seed graphics.
KEYHOLE_GRAPHIC        = $b6f3
KEY_GRAPHIC            = $b703
QUESTION_GRAPHIC_1     = $b70f
QUESTION_GRAPHIC_2     = $b719
EXTRA_LIFE_BOTTLE_1    = $b723
EXTRA_LIFE_BOTTLE_2    = $b72e
ROBO_DROID_FRAME_1     = $b739
SPIRAL_DRONE_FRAME_1   = $b771
SNAP_JUMPER_GRAPHIC    = $b791
SHAMUS_FRAME_1         = $b799
ION_SHIV_FRAME_1       = $b7db
EXPLOSION_FRAME_1      = $b81b
ENEMY_SHOT_GRAPHIC_1   = $b83b
SHADOW_FRAME_1         = $b759

;--------------------------------------------------------------------------------------------------
; Start program, game was originally a cartridge so no basic loader.

* = $a000
    ; auto start the program
	!byte <start_of_program  ;cold start vector (low)
	!byte >start_of_program  ;cold start vector (high)
	!byte <_KERNAL_EXIT_INTERRUPT  ;cartridge NMI return vector (low)
	!byte >_KERNAL_EXIT_INTERRUPT  ;cartridge NMI return vector (high)
	!pet "a0CBM"  ;start of signature a0CBM

;--------------------------------------------------------------------------------------------------
start_of_program
	sei
	; Poison the normal RAM NMI vector with the address of KERNAL data rather than executable code.
	; The cartridge header separately supplies _KERNAL_EXIT_INTERRUPT as its safe NMI return entry.
	lda #>_KERNAL_RS232_TIMING_DATA
	sta _KERNAL_NMI_VECTOR+1
	lda #<_KERNAL_RS232_TIMING_DATA
	sta _KERNAL_NMI_VECTOR
	jsr _KERNAL_INITVIA
	ldx #$50
	txs
	jsr configure_display
	lda #$00
	sta+2 SKILL_LEVEL                ;force the original three-byte absolute store
	sta SKILL_LEVEL
	sta HIGH_SCORE_BCD
	sta HIGH_SCORE_BCD+1
	sta HIGH_SCORE_BCD+2
	jmp start_new_game

;--------------------------------------------------------------------------------------------------
; Animate every lethal electric-wall cell at once by modifying character definitions $FE and $FF.
	; Rotate the horizontal-wall rows right by one pixel and the vertical-wall rows upward by one line.
animate_electric_walls
	ldx #$0f
.rotate_horizontal_wall_row
	lda ELECTRIC_HORIZONTAL_WALL_BITMAP,x
	lsr
	bcc .store_horizontal_wall_row
	ora #$80
.store_horizontal_wall_row
	sta ELECTRIC_HORIZONTAL_WALL_BITMAP,x
	dex
	bpl .rotate_horizontal_wall_row
	ldy ELECTRIC_VERTICAL_WALL_BITMAP
	ldx #$00
.shift_vertical_wall_rows
	lda ELECTRIC_VERTICAL_WALL_BITMAP+1,x
	sta ELECTRIC_VERTICAL_WALL_BITMAP,x
	inx
	cpx #$0f
	bne .shift_vertical_wall_rows
	sty ELECTRIC_VERTICAL_WALL_BITMAP+$0f
	rts

;--------------------------------------------------------------------------------------------------
; Fixed screen-matrix offsets selected by the four wall bytes in each room record. Vertical entries
; draw four cells spaced 22 bytes apart; horizontal entries draw adjacent cells. The masks retain
; the same top-to-bottom bit order for all four groups.
vertical_wall_positions_a
	!byte $03,$08,$0d,$12,$42,$45,$4a,$4f
vertical_wall_positions_b
	!byte $54,$57,$87,$8c,$91,$96
horizontal_wall_positions_a
	!byte $84,$42,$ca,$88,$46,$04,$cf,$8d
horizontal_wall_positions_b
	!byte $4b,$09,$d4,$92,$50,$0e,$96,$54
bit_selection_masks
	!byte $80,$40,$20,$10,$08,$04,$02,$01

; Level two in the state machine is the lair. It always uses the otherwise separate record $21.
select_lair_room_layout
	lda #$21
	sta ROOM_NUMBER
	jmp decode_room_wall_bitfields

;--------------------------------------------------------------------------------------------------
; Draw the current room from its four compressed wall-bitfield bytes, then place its persistent
; bottle/question object, keys, keyholes, level text, and special-room features. X retains the
; ROOM_NUMBER*4 record offset while Y scans the eight possible segments in each wall group.
draw_room_layout
	ldy #$00
	lda LEVEL_NUMBER
	cmp #$02
	beq select_lair_room_layout
decode_room_wall_bitfields
	lda ROOM_NUMBER
	asl
	asl
	tax
.scan_vertical_group_a
	lda room_vertical_bits_a,x
	and bit_selection_masks,y
	beq .next_vertical_a
	lda vertical_wall_positions_a,y
	jsr .draw_vertical_wall_segment
.next_vertical_a
	iny
	cpy #$08
	bne .scan_vertical_group_a
	ldy #$00
.scan_vertical_group_b
	lda room_vertical_bits_b,x
	and bit_selection_masks,y
	beq .next_vertical_b
	lda vertical_wall_positions_b,y
	jsr .draw_vertical_wall_segment
.next_vertical_b
	iny
	cpy #$08
	bne .scan_vertical_group_b
	ldy #$00
.scan_horizontal_group_a
	lda room_horizontal_bits_a,x
	and bit_selection_masks,y
	beq .next_horizontal_a
	lda horizontal_wall_positions_a,y
	jsr .draw_horizontal_wall_segment
.next_horizontal_a
	iny
	cpy #$08
	bne .scan_horizontal_group_a
	ldy #$00
.scan_horizontal_group_b
	lda room_horizontal_bits_b,x
	and bit_selection_masks,y
	beq .next_horizontal_b
	lda horizontal_wall_positions_b,y
	jsr .draw_horizontal_wall_segment
.next_horizontal_b
	iny
	cpy #$08
	bne .scan_horizontal_group_b
	jsr .draw_room_number
	jsr .draw_closed_keyhole_wall
	jmp .place_extra_life_object

.draw_vertical_wall_segment
	stx $83
	tax
	jsr .draw_vertical_wall_cell
	jsr .draw_vertical_wall_cell
	jsr .draw_vertical_wall_cell
	jsr .draw_vertical_wall_cell
	ldx $83
	rts

.draw_vertical_wall_cell
	lda #$fe
	sta _SCREEN_MATRIX_ADDR,x
	jsr .select_vertical_wall_colour
	sta _COLOUR_SCREEN_ADDR,x
	txa
	clc
	adc #$16
	tax
	rts

.draw_horizontal_wall_segment
	stx $83
	tax
	lda #$ff
	sta _SCREEN_MATRIX_ADDR,x
	inx
	sta _SCREEN_MATRIX_ADDR,x
	inx
	sta _SCREEN_MATRIX_ADDR,x
	inx
	sta _SCREEN_MATRIX_ADDR,x
	txa
	cmp #$45
	beq .colour_horizontal_wall_segment
	cmp #$87
	beq .colour_horizontal_wall_segment
	cmp #$57
	beq .colour_horizontal_wall_segment
	cmp #$99
	beq .colour_horizontal_wall_segment
	lda #$ff
	inx
	sta _SCREEN_MATRIX_ADDR,x
	jsr .select_horizontal_wall_colour
	sta _COLOUR_SCREEN_ADDR,x
	dex
.colour_horizontal_wall_segment
	jsr .select_horizontal_wall_colour
	sta _COLOUR_SCREEN_ADDR,x
	dex
	sta _COLOUR_SCREEN_ADDR,x
	dex
	sta _COLOUR_SCREEN_ADDR,x
	dex
	sta _COLOUR_SCREEN_ADDR,x
	ldx $83
	rts

.room_word_text
	!byte $52,$0f,$0f,$0d

.draw_room_number
	ldx #$00
	stx $08
	lda #$a0
	sta $09
.draw_room_word
	lda .room_word_text,x
	jsr draw_text_character_and_advance
	cpx #$04
	bne .draw_room_word
	lda #$08
	sta $08
	lda #$a8
	sta $09
	lda ROOM_NUMBER
	cmp #$1e
	bcs .draw_thirties_digit
	cmp #$14
	bcs .draw_twenties_digit
	cmp #$0a
	bcs .draw_tens_digit
.draw_room_digit
	clc
	adc #$30
	jsr draw_character
	jmp advance_draw_x_by_8

.draw_thirties_digit
	lda #$03
	jsr .draw_room_digit
	lda ROOM_NUMBER
	sec
	sbc #$1e
	jmp .draw_room_digit

.draw_twenties_digit
	lda #$02
	jsr .draw_room_digit
	lda ROOM_NUMBER
	sec
	sbc #$14
	jmp .draw_room_digit

.draw_tens_digit
	lda #$01
	jsr .draw_room_digit
	lda ROOM_NUMBER
	sec
	sbc #$0a
	jmp .draw_room_digit

.place_extra_life_object
	lda #$00
	sta EXTRA_LIFE_OBJECT_X
	lda ROOM_NUMBER
	cmp #$01
	beq .test_room_01_extra_life
	cmp #$0c
	beq .test_room_0c_extra_life
	cmp #$02
	beq .test_room_02_extra_life
	cmp #$1a
	beq .test_room_1a_extra_life
.skip_extra_life
	jmp .place_mystery_object

.test_room_01_extra_life
	lda EXTRA_LIFE_COLLECTED_FLAGS
	bne .skip_extra_life
	jmp .draw_extra_life

.test_room_0c_extra_life
	lda EXTRA_LIFE_COLLECTED_FLAGS+2
	bne .skip_extra_life
	jmp .draw_extra_life

.test_room_02_extra_life
	lda EXTRA_LIFE_COLLECTED_FLAGS+1
	bne .skip_extra_life
	jmp .draw_extra_life

.test_room_1a_extra_life
	lda EXTRA_LIFE_COLLECTED_FLAGS+3
	bne .skip_extra_life
	jmp .draw_extra_life

.draw_extra_life
	lda #$78
	sta EXTRA_LIFE_OBJECT_X
	lda #$46
	sta EXTRA_LIFE_OBJECT_Y
	jsr draw_extra_life_object
.place_mystery_object
	lda #$00
	sta MYSTERY_OBJECT_X
	lda ROOM_NUMBER
	cmp #$00
	beq .test_room_00_mystery
	cmp #$08
	beq .test_room_08_mystery
	cmp #$18
	beq .test_room_18_mystery
	cmp #$0b
	beq .test_room_0b_mystery
.skip_mystery_object
	jmp .prepare_key_colours

.test_room_00_mystery
	lda MYSTERY_COLLECTED_FLAGS
	bne .skip_mystery_object
	jmp .draw_mystery_object

.test_room_08_mystery
	lda MYSTERY_COLLECTED_FLAGS+1
	bne .skip_mystery_object
	jmp .draw_mystery_object

.test_room_18_mystery
	lda MYSTERY_COLLECTED_FLAGS+2
	bne .skip_mystery_object
	jmp .draw_mystery_object

.test_room_0b_mystery
	lda MYSTERY_COLLECTED_FLAGS+3
	bne .skip_mystery_object
.draw_mystery_object
	lda #$54
	sta MYSTERY_OBJECT_X
	lda #$46
	sta MYSTERY_OBJECT_Y
	jsr draw_bonus_object
.prepare_key_colours
	lda #$02
	sta _COLOUR_SCREEN_ADDR+$ad
	sta _COLOUR_SCREEN_ADDR+$af
	lda #$01
	sta _COLOUR_SCREEN_ADDR+$c3
	sta _COLOUR_SCREEN_ADDR+$c5
	lda #$06
	sta _COLOUR_SCREEN_ADDR+$d9
	sta _COLOUR_SCREEN_ADDR+$db
	lda ROOM_NUMBER
	cmp #$11
	beq .test_room_11_key
	cmp #$06
	beq .test_room_06_key
	cmp #$10
	beq .test_room_10_key
	jmp .draw_collected_keys

.test_room_11_key
	ldy #$02
	lda KEY_FLAGS
	and #$80
	beq .draw_room_key
	jmp .draw_collected_keys

.test_room_06_key
	ldy #$01
	lda KEY_FLAGS
	and #$40
	beq .draw_room_key
	jmp .draw_collected_keys

.test_room_10_key
	ldy #$06
	lda KEY_FLAGS
	and #$20
	beq .draw_room_key
	jmp .draw_collected_keys

.draw_room_key
	sty _COLOUR_SCREEN_ADDR+$62
	lda #$42
	sta $09
	lda #$50
	sta $08
	jsr draw_key
.draw_collected_keys
	lda #$98
	sta $08
	lda KEY_FLAGS
	and #$80
	bne .draw_red_key_icon
.test_white_key_icon
	lda KEY_FLAGS
	and #$40
	bne .draw_white_key_icon
.test_blue_key_icon
	lda KEY_FLAGS
	and #$20
	bne .draw_blue_key_icon
	jmp .draw_opened_keyholes

.draw_red_key_icon
	lda #$72
	sta $09
	jsr draw_key
	jmp .test_white_key_icon

.draw_white_key_icon
	lda #$82
	sta $09
	jsr draw_key
	jmp .test_blue_key_icon

.draw_blue_key_icon
	lda #$92
	sta $09
	jsr draw_key
.draw_opened_keyholes
	lda #$a8
	sta $08
	lda KEY_FLAGS
	and #$08
	bne .draw_red_keyhole_icon
.test_white_keyhole_icon
	lda KEY_FLAGS
	and #$04
	bne .draw_white_keyhole_icon
.test_blue_keyhole_icon
	lda KEY_FLAGS
	and #$02
	bne .draw_blue_keyhole_icon
	jmp .place_room_keyhole

.draw_red_keyhole_icon
	lda #$70
	sta $09
	jsr draw_keyhole
	jmp .test_white_keyhole_icon

.draw_white_keyhole_icon
	lda #$80
	sta $09
	jsr draw_keyhole
	jmp .test_blue_keyhole_icon

.draw_blue_keyhole_icon
	lda #$90
	sta $09
	jsr draw_keyhole
.place_room_keyhole
	lda ROOM_NUMBER
	cmp #$09
	beq .test_room_09_keyhole
	cmp #$14
	beq .test_room_14_keyhole
	cmp #$1f
	beq .test_room_1f_keyhole
	jmp .draw_level_text

.test_room_09_keyhole
	ldy #$02
	lda KEY_FLAGS
	and #$08
	beq .draw_room_keyhole
	jmp .draw_level_text

.test_room_14_keyhole
	ldy #$01
	lda KEY_FLAGS
	and #$04
	beq .draw_room_keyhole
	jmp .draw_level_text

.test_room_1f_keyhole
	ldy #$06
	lda KEY_FLAGS
	and #$02
	beq .draw_room_keyhole
	jmp .draw_level_text

.draw_room_keyhole
	sty _COLOUR_SCREEN_ADDR+$69
	lda #$40
	sta $09
	lda #$88
	sta $08
	jsr draw_keyhole
.draw_level_text
	jmp .draw_level_heading

.draw_closed_keyhole_wall
	lda ROOM_NUMBER
	cmp #$09
	beq .test_room_09_wall
	cmp #$14
	beq .test_room_14_wall
	cmp #$1f
	beq .test_room_1f_wall
.closed_wall_done
	rts

.test_room_09_wall
	lda KEY_FLAGS
	and #$08
	bne .closed_wall_done
.draw_keyhole_wall
	lda #$57
	jmp .draw_vertical_wall_segment

.test_room_14_wall
	lda KEY_FLAGS
	and #$04
	bne .closed_wall_done
	jmp .draw_keyhole_wall

.test_room_1f_wall
	lda KEY_FLAGS
	and #$02
	bne .closed_wall_done
	jmp .draw_keyhole_wall

.select_horizontal_wall_colour
	stx $84
	lda ROOM_NUMBER
	and #$03
	tax
	lda .wall_colour_values,x
	ldx $84
	rts

;--------------------------------------------------------------------------------------------------
; VIC colour values selected by the wall-colour routines: yellow, green, cyan and purple.
.wall_colour_values
	!byte $07,$05,$03,$04

.select_vertical_wall_colour
	; Index bytes of .select_horizontal_wall_colour as a compact room-dependent pattern table.
	stx $84
	lda ROOM_NUMBER
	tax
	lda .select_horizontal_wall_colour,x
	and #$03
	tax
	lda .wall_colour_values,x
	ldx $84
	rts

;--------------------------------------------------------------------------------------------------
; Screen text used for the level/lair heading.
.level_word
	!pet "level"
.level_one_word
	!pet "one"
.level_two_word
	!pet "two"
.lair_word
	!pet "lair"

.draw_level_heading
	lda #$32
	sta $08
	lda #$a0
	sta $09
	lda LEVEL_NUMBER
	cmp #$02
	beq .draw_level_name
	ldx #$00
.draw_level_word
	lda .level_word,x
	jsr draw_text_character_and_advance
	cpx #$05
	bne .draw_level_word
.draw_level_name
	ldx #$00
	lda #$3a
	sta $08
	lda #$a8
	sta $09
	lda LEVEL_NUMBER
	beq .draw_level_one
	cmp #$01
	beq .draw_level_two
.draw_lair_name
	lda .lair_word,x
	jsr draw_text_character_and_advance
	cpx #$04
	bne .draw_lair_name
	rts

.draw_level_one
	lda .level_one_word,x
	jsr draw_text_character_and_advance
	cpx #$03
	bne .draw_level_one
	rts

.draw_level_two
	lda .level_two_word,x
	jsr draw_text_character_and_advance
	cpx #$03
	bne .draw_level_two
	rts

;--------------------------------------------------------------------------------------------------
; Test Shamus against the maze and every lethal entity. If he survives, handle special objects and
; convert crossings of the four screen edges into room-number changes of +1, -1, -6, or +6.
handle_player_collision_and_room_exit
	lda PLAYER_X
	sta COLLISION_X
	dec COLLISION_X
	lda PLAYER_Y
	clc
	adc #$02
	sta COLLISION_Y
	jsr test_2x2_background_collision
	beq handle_player_death
	jsr test_player_enemy_collisions
	beq handle_player_death
	lda PLAYER_X
	cmp #$a6
	bcs .exit_right
	cmp #$03
	bcc .exit_left
	lda PLAYER_Y
	cmp #$98
	bcs .exit_bottom
	lda PLAYER_Y
	cmp #$02
	bcc .exit_top
	jmp handle_keys_and_keyholes

	; The ordinary maze is a six-column grid: horizontal exits alter the room by one and
	; vertical exits alter it by six. Missing connections are enforced by the drawn walls.
.exit_right
	inc ROOM_NUMBER                 ;right edge: next room
	lda #$06
	sta PLAYER_X
	jmp initialize_current_room

.exit_left
	dec ROOM_NUMBER                 ;left edge: previous room
	lda #$a2
	sta PLAYER_X
	jmp initialize_current_room

.exit_top
	lda ROOM_NUMBER                 ;top edge: one map row up
	sec
	sbc #$06
	sta ROOM_NUMBER
	lda #$92
	sta PLAYER_Y
	jmp initialize_current_room

.exit_bottom
	lda ROOM_NUMBER                 ;bottom edge: one map row down
	clc
	adc #$06
	sta ROOM_NUMBER
	lda #$06
	sta PLAYER_Y
	jmp initialize_current_room

.return_to_title_after_game_over
	jmp start_new_game

;--------------------------------------------------------------------------------------------------
; Pixel coordinates for the nine life icons displayed in a three-by-three grid.
life_icon_x_positions
	!byte $98,$a0,$a8,$98,$a0,$a8,$98,$a0,$a8
life_icon_y_positions
	!byte $00,$00,$00,$10,$10,$10,$20,$20,$20

;--------------------------------------------------------------------------------------------------
; Draw at most nine remaining-life icons in the status area's three-by-three grid.
draw_lives_remaining
	lda LIVES_REMAINING
	beq .life_display_done
	cmp #$09
	bcc .cap_life_count
	lda #$09
.cap_life_count
	tax
	dex
.draw_next_life
	lda life_icon_x_positions,x
	sta $08
	lda life_icon_y_positions,x
	sta $09
	jsr select_life_icon_graphic
	dex
	bpl .draw_next_life
.life_display_done
	rts

;--------------------------------------------------------------------------------------------------
; Animate Shamus's destruction, remove a life, then choose a safe room-specific respawn edge.
handle_player_death
	jsr .play_death_animation
	dec LIVES_REMAINING
	lda LIVES_REMAINING
	cmp #$ff
	beq .return_to_title_after_game_over
	lda ROOM_NUMBER
	cmp #$06
	beq .respawn_at_right_edge
	cmp #$0b
	beq .respawn_at_top_edge
	cmp #$0c
	beq .respawn_at_right_edge
	cmp #$10
	beq .respawn_at_top_edge
	cmp #$11
	beq .respawn_at_top_edge
	cmp #$12
	beq .respawn_at_right_edge
	cmp #$14
	beq .respawn_at_top_edge
	cmp #$18
	beq .respawn_at_top_edge
	cmp #$19
	beq .respawn_at_right_edge
	cmp #$1e
	beq .respawn_at_right_edge
	cmp #$1b
	beq .respawn_at_right_edge
	lda #$0a
	sta PLAYER_X
.respawn_at_middle_height
	lda #$42
	sta PLAYER_Y
	jmp initialize_current_room

.respawn_at_right_edge
	lda #$a2
	sta $0a
	jmp .respawn_at_middle_height

.respawn_at_top_edge
	lda #$06
	sta PLAYER_Y
	lda #$54
	sta PLAYER_X
	jmp initialize_current_room

.play_death_animation
	lda #$b8
	sta GRAPHIC_PTR+1
	lda #$41
	sta GRAPHIC_PTR
	lda #$00
	sta ROOM_EXIT_RUSH_TIMER
	lda PLAYER_X
	cmp #$90
	bcs .animate_player_fragments
	clc
	adc #$08
	sta DRAW_X
	lda PLAYER_Y
	sec
	sbc #$05
	sta DRAW_Y
	lda #$0b
	jsr xor_draw_shifted_bitmap
	lda DRAW_X
	clc
	adc #$08
	sta DRAW_X
	lda #$b8
	sta GRAPHIC_PTR+1
	lda #$4d
	sta GRAPHIC_PTR
	lda #$0b
	jsr xor_draw_shifted_bitmap
	lda DRAW_X
	clc
	adc #$08
	sta DRAW_X
	lda #$b8
	sta GRAPHIC_PTR+1
	lda #$59
	sta GRAPHIC_PTR
	lda #$0b
	jsr xor_draw_shifted_bitmap
.animate_player_fragments
	ldx #$00
.death_animation_loop
	jsr draw_player
	jsr update_random_number
	sta _VIC_SOUND_NOISE
	stx _VIC_SOUND_SOPRANO
	stx _VIC_SOUND_ALTO
	inc FRAME_COUNTER
	jsr draw_player
	inc FRAME_COUNTER
	jsr draw_player
	inx
	bne .death_animation_loop
	jmp silence_sound_generators

;--------------------------------------------------------------------------------------------------
; Collect the three coloured keys or open their matching keyholes when Shamus touches them.
; Three key/keyhole pairs are encoded in KEY_FLAGS:
;   red key in room $11 -> bit $80, opens the red bit-$08 keyhole in room $09
;   white key in room $06 -> bit $40, opens the white bit-$04 keyhole in room $14
;   blue key in room $10 -> bit $20, opens the blue bit-$02 keyhole in room $1f
; Touching a key or an unlocked matching keyhole rebuilds the room so the changed object vanishes.
handle_keys_and_keyholes
	lda PLAYER_Y
	cmp #$38
	bcc .check_room_27_barrier
	cmp #$50
	bcs .check_room_27_barrier
	lda PLAYER_X
	cmp #$48
	bcc .test_keyhole_position
	cmp #$58
	bcs .test_keyhole_position
	lda ROOM_NUMBER
	cmp #$11
	beq .collect_red_key
	cmp #$06
	beq .collect_white_key
	cmp #$10
	beq .collect_blue_key
.test_keyhole_position
	lda PLAYER_X
	cmp #$80
	bcc .check_room_27_barrier
	cmp #$90
	bcs .check_room_27_barrier
	lda ROOM_NUMBER
	cmp #$09
	beq .open_red_keyhole
	cmp #$14
	beq .open_white_keyhole
	cmp #$1f
	beq .open_blue_keyhole
.check_room_27_barrier
	jmp update_room_27_moving_barrier

.collect_red_key
	lda KEY_FLAGS
	and #$80
	bne .check_room_27_barrier
	lda KEY_FLAGS
	ora #$80
	sta KEY_FLAGS
	jmp rebuild_current_room_after_object_change

.collect_white_key
	lda KEY_FLAGS
	and #$40
	bne .check_room_27_barrier
	lda KEY_FLAGS
	ora #$40
	sta KEY_FLAGS
	jmp rebuild_current_room_after_object_change

.collect_blue_key
	lda KEY_FLAGS
	and #$20
	bne .check_room_27_barrier
	lda KEY_FLAGS
	ora #$20
	sta KEY_FLAGS
	jmp rebuild_current_room_after_object_change

.open_red_keyhole
	lda KEY_FLAGS
	and #$88
	cmp #$80
	bne .check_room_27_barrier
	lda KEY_FLAGS
	ora #$08
	sta KEY_FLAGS
	jmp rebuild_current_room_after_object_change

.open_white_keyhole
	lda KEY_FLAGS
	and #$44
	cmp #$40
	bne .check_room_27_barrier
	lda KEY_FLAGS
	ora #$04
	sta KEY_FLAGS
	jmp rebuild_current_room_after_object_change

.open_blue_keyhole
	lda KEY_FLAGS
	and #$22
	cmp #$20
	bne .check_room_27_barrier
	lda KEY_FLAGS
	ora #$02
	sta KEY_FLAGS
	jmp rebuild_current_room_after_object_change

.continue_main_game_loop
	jmp main_game_loop

;--------------------------------------------------------------------------------------------------
; Animate room $1B's central electric barrier and test whether an ION SHIV has reached its X band.
; Reaching it permanently removes the barrier by changing its phase to $FF and rebuilding the room.
update_room_27_moving_barrier
	lda ROOM_NUMBER
	cmp #$1b
	bne .continue_main_game_loop
	lda ROOM_27_BARRIER_PHASE
	cmp #$ff
	beq .continue_main_game_loop
	lda FRAME_COUNTER
	and #$07
	bne .draw_barrier
	inc ROOM_27_BARRIER_PHASE
	lda ROOM_27_BARRIER_PHASE
	and #$07
	sta ROOM_27_BARRIER_PHASE
.draw_barrier
	ldy #$1b
.draw_barrier_cell
	lda #$fe
	sta _SCREEN_MATRIX_ADDR,y
	lda #$07
	sta _COLOUR_SCREEN_ADDR,y
	tya
	clc
	adc #$0b
	tay
	cpy #$c2
	bcc .draw_barrier_cell
	lda #$26
	ldx ROOM_27_BARRIER_PHASE
	beq .clear_gap
.advance_gap_position
	clc
	adc #$16
	dex
	bne .advance_gap_position
.clear_gap
	tay
	lda #$00
	sta _SCREEN_MATRIX_ADDR,y
	sta $01f5,y
	ldx #$02
.test_next_ion_shiv
	lda PLAYER_SHOT_X,x
	beq .next_ion_shiv
	cmp #$6e
	bcs .next_ion_shiv
	cmp #$50
	bcc .next_ion_shiv
	jmp .remove_barrier

.next_ion_shiv
	dex
	bpl .test_next_ion_shiv
	jmp main_game_loop

.remove_barrier
	lda #$ff
	sta ROOM_27_BARRIER_PHASE
	jmp initialize_current_room

.player_collision_detected
	lda #$00
	rts

;--------------------------------------------------------------------------------------------------
; Return zero if Shamus overlaps an enemy shot, any ordinary enemy, the Shadow, or the lair target.
test_player_enemy_collisions
	ldx #$06
.test_enemy_shot
	lda ENEMY_SHOT_X,x
	beq .next_enemy_shot
	sec
	sbc PLAYER_X
	cmp #$06
	bcs .next_enemy_shot
	lda ENEMY_SHOT_Y,x
	sec
	sbc #$02
	sec
	sbc PLAYER_Y
	cmp #$07
	bcc .player_collision_detected
.next_enemy_shot
	dex
	bpl .test_enemy_shot
	ldx #$06
.test_spiral_drone
	lda SPIRAL_DRONE_X,x
	beq .next_spiral_drone
	sta DRAW_X
	lda SPIRAL_DRONE_Y,x
	sta DRAW_Y
	jsr test_player_object_overlap
	beq .player_collision_detected
.next_spiral_drone
	dex
	bpl .test_spiral_drone
	ldx #$06
.test_robo_droid
	lda ROBO_DROID_X,x
	beq .next_robo_droid
	sta DRAW_X
	lda ROBO_DROID_Y,x
	sta DRAW_Y
	jsr test_player_object_overlap
	beq .player_collision_detected
.next_robo_droid
	dex
	bpl .test_robo_droid
	ldx #$06
.test_snap_jumper
	lda SNAP_JUMPER_X,x
	beq .next_snap_jumper
	sta DRAW_X
	lda SNAP_JUMPER_Y,x
	sta DRAW_Y
	jsr test_player_object_overlap
	beq .player_collision_detected
.next_snap_jumper
	dex
	bpl .test_snap_jumper
	lda SHADOW_X
	beq .test_lair_target
	sta DRAW_X
	lda SHADOW_Y
	sta DRAW_Y
	jsr test_player_object_overlap
	beq .player_collision_detected
.test_lair_target
	lda LEVEL_NUMBER
	cmp #$02
	bne .no_player_collision
	lda LAIR_TARGET_X
	sta DRAW_X
	lda LAIR_TARGET_Y
	sta DRAW_Y
	jsr test_player_object_overlap
	beq .player_collision_detected
.no_player_collision
	lda #$01
	rts

;--------------------------------------------------------------------------------------------------
; Silence all four VIC sound generators. The entry below preserves the bass and alto voices and is
; used when only an explosion's soprano/noise pair has finished.
silence_sound_generators
	lda #$00
	sta _VIC_SOUND_BASS
	sta _VIC_SOUND_ALTO
silence_soprano_and_noise
	sta _VIC_SOUND_SOPRANO
	sta _VIC_SOUND_NOISE
	rts

;--------------------------------------------------------------------------------------------------
update_game_sound_effects
; Multiplex the short ION SHIV firing tone, explosion noise/tone sweep, Shadow warning and
; bottle/question-mark reward tones through the VIC's four generators.
	jsr .update_ion_shiv_tone
	lda EXPLOSION_SOUND_TIMER
	beq silence_soprano_and_noise
	inc EXPLOSION_SOUND_TIMER
	lda EXPLOSION_SOUND_TIMER
	cmp #$09
	beq .finish_explosion
	asl
	asl
	ora #$80
	sta _VIC_SOUND_NOISE
	eor #$ff
	ora #$80
	sbc #$14
	sta _VIC_SOUND_SOPRANO
	rts

.finish_explosion
	lda #$00
	sta EXPLOSION_SOUND_TIMER
	jmp silence_soprano_and_noise

.update_ion_shiv_tone
	lda ION_SHIV_SOUND_TIMER
	beq .update_secondary_effects
	asl
	asl
	asl
	clc
	adc #$96
	sta _VIC_SOUND_BASS
	lda ION_SHIV_SOUND_TIMER
	asl
	asl
	clc
	adc #$96
	sta _VIC_SOUND_ALTO
	dec ION_SHIV_SOUND_TIMER
	bne .update_secondary_effects
	lda #$00
	sta _VIC_SOUND_BASS
	sta _VIC_SOUND_ALTO
.update_secondary_effects
	jmp update_secondary_sound_effects

;--------------------------------------------------------------------------------------------------
; Register pairs for Gounod's "Funeral March of a Marionette", familiar as the Alfred Hitchcock
; Presents theme. Each pair supplies soprano/alto followed by bass; $ff,$ff terminates the tune.
title_theme_music
title_note_voice
	!byte $00
title_note_bass
	!byte $c9
        ; Remaining music bytes are interleaved soprano/alto and bass register values.
	!byte $e4,$00,$e4,$d1,$e3,$00,$df,$00,$e3,$d7,$00,$00,$e4,$00,$e7,$d7
	!byte $00,$00,$00,$db,$00,$c9,$00,$00,$e4,$00,$e4,$d1,$e3,$00,$df,$00
	!byte $e3,$d7,$00,$00,$e4,$00,$e7,$d7,$00,$00,$00,$db,$00,$e4,$00,$00
	!byte $e8,$00,$ed,$cf,$eb,$00,$e8,$d1,$00,$00,$ed,$00,$f0,$d7,$ef,$00
	!byte $ed,$e3,$00,$00,$f0,$00,$f3,$d7,$f1,$00,$ed,$e8,$f1,$00,$ef,$00
	!byte $ed,$00,$eb,$00,$e8,$00,$ff,$ff

;--------------------------------------------------------------------------------------------------
; Add 50 points 256 times (12,800 points total) while sweeping three sound voices.
award_level_completion_bonus
	lda #$00
	sta FRAME_COUNTER
	jsr silence_sound_generators
.award_next_bonus_increment
	jsr award_50_points
	dec _VIC_SOUND_SOPRANO
	inc _VIC_SOUND_ALTO
	dec _VIC_SOUND_BASS
	inc FRAME_COUNTER
	bne .award_next_bonus_increment
	rts

;--------------------------------------------------------------------------------------------------
; Continue the per-iteration sound update with the Shadow warning pulse and the short rising bass
; tone used when a bottle or mystery symbol is collected.
update_secondary_sound_effects
	lda SHADOW_APPEARANCE_TIMER
	cmp #$02
	bne .update_reward_sound
	lda FRAME_COUNTER
	cmp #$e6
	bcc .update_reward_sound
	cmp #$fe
	bcs .end_shadow_warning
	lda FRAME_COUNTER
	sta _VIC_SOUND_BASS
	sta _VIC_SOUND_ALTO
	sta _VIC_SOUND_SOPRANO
	jmp .update_reward_sound

.end_shadow_warning
	jsr silence_sound_generators
.update_reward_sound
	lda REWARD_SOUND_TIMER
	beq .secondary_sound_update_done
	clc
	adc #$b6
	sta _VIC_SOUND_BASS
	dec REWARD_SOUND_TIMER
	bne .secondary_sound_update_done
	lda #$00
	sta _VIC_SOUND_BASS
.secondary_sound_update_done
	rts

;--------------------------------------------------------------------------------------------------
; Toggle the keyboard-controlled pause: silence the VIC, wait for release, then for another press
; and release before returning to the main game loop.
handle_pause_key
	lda #$80
	sta _VIA_KEYB_ROWS
	lda _VIA_KEYB_COLS
	cmp #$df
	beq .pause_pressed
	rts

.pause_pressed
	jsr silence_sound_generators
	lda _VIA_KEYB_COLS
	cmp #$df
	beq .pause_pressed
.wait_for_second_press
	lda _VIA_KEYB_COLS
	cmp #$df
	bne .wait_for_second_press
.wait_for_second_release
	lda _VIA_KEYB_COLS
	cmp #$df
	beq .wait_for_second_release
	rts

;--------------------------------------------------------------------------------------------------
; Screen-code text used by the title, credits, object legend and enemy legend.
title_and_credit_text
	!scr " Shamus by Tom Griner     (c)1983 H.E.S.      under license from   Synapse Software Inc."
keyhole_name
	!scr "Keyhole"
key_name
	!scr "Key"
extra_life_name
	!scr "Extra Life"
mystery_name
	!scr "Mystery"
shadow_name
	!scr "Shadow"
robo_droids_name
	!scr "Robo-Droids"
spiral_drones_name
	!scr "Spiral Drones"
snap_jumpers_name
	!scr "Snap Jumpers"

;--------------------------------------------------------------------------------------------------
; Draw one text character, advance X, and wrap at the 176-pixel right edge.
draw_text_character_and_advance
	jsr draw_character
	jsr advance_draw_x_by_8
	lda DRAW_X
	cmp #$b0
	bcc .text_position_ready
	lda #$00
	sta DRAW_X
	jsr advance_draw_y_by_8
.text_position_ready
	inx
	rts

;--------------------------------------------------------------------------------------------------
; Select a text row, reset the text index, and set the left text margin to 15 pixels.
set_text_row
	sta DRAW_Y
	lda show_title_and_calibration_screen  ;discarded absolute load retained from the original
	ldx #$00
	lda #$0f
	sta DRAW_X
	rts

;--------------------------------------------------------------------------------------------------
; Advance the drawing position by one eight-pixel character column.
advance_draw_x_by_8
	lda DRAW_X
	clc
	adc #$08
	sta DRAW_X
	rts

;--------------------------------------------------------------------------------------------------
; Advance the drawing position by one eight-pixel half-character row.
advance_draw_y_by_8
	lda DRAW_Y
	clc
	adc #$08
	sta DRAW_Y
	rts

;--------------------------------------------------------------------------------------------------
; Draw the title, credits, object/enemy legend and current skill. The continuing loop plays the
; theme, raster-paces the animation, polls the skill key and lets the joystick directly adjust the
; VIC horizontal/vertical origins. Fire accepts the calibrated screen position.
show_title_and_calibration_screen
	jsr clear_and_build_framebuffer
	lda .colour_title_rows             ;dead read of the following STA opcode, immediately replaced
	lda #$01
	sta $1a
	ldx #$2b
	lda #$05
.colour_title_rows
	sta _COLOUR_SCREEN_ADDR,x
	dex
	bpl .colour_title_rows
	lda #$00
	sta $08
	sta $09
	ldx #$00
.draw_title_and_credits
	lda title_and_credit_text,x
	jsr draw_text_character_and_advance
	cpx #$58
	bne .draw_title_and_credits
	lda #$28
	sta $09
	lda #$00
	sta $08
	jsr draw_keyhole
	lda #$3c
	sta $09
	jsr draw_key
	lda #$62
	sta $09
	jsr select_and_draw_shadow_frame
	lda #$84
	sta $09
	jsr select_snap_jumper_graphic
	lda #$30
	jsr set_text_row
.draw_keyhole_name
	lda keyhole_name,x
	jsr draw_text_character_and_advance
	cpx #$07
	bne .draw_keyhole_name
	lda #$3e
	jsr set_text_row
.draw_key_name
	lda key_name,x
	jsr draw_text_character_and_advance
	cpx #$03
	bne .draw_key_name
	lda #$4a
	jsr set_text_row
.draw_extra_life_name
	lda extra_life_name,x
	jsr draw_text_character_and_advance
	cpx #$0a
	bne .draw_extra_life_name
	lda #$56
	jsr set_text_row
.draw_mystery_name
	lda mystery_name,x
	jsr draw_text_character_and_advance
	cpx #$07
	bne .draw_mystery_name
	lda #$64
	jsr set_text_row
.draw_shadow_name
	lda shadow_name,x
	jsr draw_text_character_and_advance
	cpx #$06
	bne .draw_shadow_name
	lda #$70
	jsr set_text_row
.draw_robo_droids_name
	lda robo_droids_name,x
	jsr draw_text_character_and_advance
	cpx #$0b
	bne .draw_robo_droids_name
	lda #$7a
	jsr set_text_row
.draw_spiral_drones_name
	lda spiral_drones_name,x
	jsr draw_text_character_and_advance
	cpx #$0d
	bne .draw_spiral_drones_name
	lda #$84
	jsr set_text_row
.draw_snap_jumpers_name
	lda snap_jumpers_name,x
	jsr draw_text_character_and_advance
	cpx #$0c
	bne .draw_snap_jumpers_name
	jsr .animate_legend_objects
	lda #$00
	sta $0a
	jsr .draw_title_shamus
	jsr draw_selected_skill_level
	lda #$00
	sta TITLE_MUSIC_STEP
.title_loop
	jsr update_title_theme
.wait_for_frame_start
	lda _VIC_CR4
	bne .wait_for_frame_start
	jsr .animate_legend_objects
	inc $0c
	jsr .animate_legend_objects
	dec $0c
	jsr .draw_title_shamus
	inc $0c
	inc TITLE_MUSIC_DELAY
	inc $0a
	lda $0a
	cmp #$9f
	bcc .draw_next_title_frame
	lda #$00
	sta $0a
.draw_next_title_frame
	jsr .draw_title_shamus
	jsr poll_skill_level_key
	jsr read_joystick
	lda $1a
	beq .adjust_screen_position
	lda $06
	and #$9c
	cmp #$9c
	beq .directions_released
	lda $1a
	bne .title_loop
.adjust_screen_position
	lda $06
	and #$04
	beq .move_screen_up
.test_screen_down
	lda $06
	and #$08
	beq .move_screen_down
.test_screen_left
	lda $06
	and #$10
	beq .move_screen_left
.test_screen_right
	lda $06
	and #$80
	beq .move_screen_right
.test_fire_button
	lda $06
	and #$20
	bne .title_loop
	jmp silence_sound_generators

.directions_released
	lda #$00
	sta $1a
	jmp .title_loop

.move_screen_up
	dec _VIC_SCREEN_TOP_EDGE
	jmp .test_screen_down

.move_screen_down
	inc _VIC_SCREEN_TOP_EDGE
	jmp .test_screen_left

.move_screen_left
	dec _VIC_SCREEN_LEFT_EDGE
	jmp .test_screen_right

.move_screen_right
	inc _VIC_SCREEN_LEFT_EDGE
	jmp .test_fire_button

.animate_legend_objects
	lda #$56
	sta $09
	lda #$00
	sta $08
	jsr draw_mystery_question
	lda #$4a
	sta $09
	jsr draw_extra_life_bottle
	lda #$70
	sta $09
	jsr select_robo_droid_frame
	lda #$7a
	sta $09
	jmp select_spiral_drone_frame

.draw_title_shamus
	lda $0a
	sta $08
	lda #$a2
	sta $09
	jsr select_and_draw_shadow_frame
	lda $0a
	clc
	adc #$09
	sta $08
	lda #$a3
	sta $09
	lda #$b7
	sta $03
	lda #$af
	sta $02
	lda $0c
	lsr
	and #$01
	beq draw_small_shamus_graphic
select_life_icon_graphic
	lda #$b7
	sta $03
	lda #$ba
	sta $02
draw_small_shamus_graphic
	lda #$0a
	jmp xor_draw_shifted_bitmap

;--------------------------------------------------------------------------------------------------
; Four fixed-width, eight-character skill names indexed by SKILL_LEVEL*8.
skill_level_names
	!scr "Beginner"
	!scr "Novice  "
	!scr "Advanced"
	!scr "Expert  "

draw_selected_skill_level
	lda SKILL_LEVEL
	asl
	asl
	asl
	tax
	ldy #$07
	lda #$64
	sta $08
	lda #$90
	sta $09
.draw_skill_character
	tya
	pha
	lda skill_level_names,x
	jsr draw_text_character_and_advance
	pla
	tay
	dey
	bpl .draw_skill_character
skill_input_done
	rts

;--------------------------------------------------------------------------------------------------
; Edge-detect the title-screen skill key and cycle Beginner, Novice, Advanced and Expert.
poll_skill_level_key
	lda #$80
	sta _VIA_KEYB_ROWS
	lda _VIA_KEYB_COLS
	cmp #$7f
	beq .skill_key_pressed
	lda #$00
	sta SKILL_KEY_LATCH
	rts

.skill_key_pressed
	lda SKILL_KEY_LATCH
	bne skill_input_done
	lda #$01
	sta SKILL_KEY_LATCH
	jsr draw_selected_skill_level
	inc SKILL_LEVEL
	lda SKILL_LEVEL
	and #$03
	sta SKILL_LEVEL
	jmp draw_selected_skill_level

;--------------------------------------------------------------------------------------------------
; Advance Gounod's title theme from interleaved voice/bass register pairs. Most steps use a
; four-frame divider; steps $1b, $20 and $25 use eight frames. Between notes the VIC volume decays.
update_title_theme
	lda TITLE_MUSIC_STEP
	cmp #$1b
	beq .use_long_note_delay
	cmp #$20
	beq .use_long_note_delay
	cmp #$25
	beq .use_long_note_delay
	lda TITLE_MUSIC_DELAY
	and #$03
	bne .decay_volume
	jmp .advance_note

.use_long_note_delay
	lda TITLE_MUSIC_DELAY
	and #$07
	bne .decay_long_note
.advance_note
	jsr .wait_before_next_note
	lda TITLE_MUSIC_STEP
	asl
	tax
	lda title_note_voice,x
	sta _VIC_SOUND_SOPRANO
	sta _VIC_SOUND_ALTO
	lda #$01
	sta TITLE_MUSIC_DELAY
	lda title_note_bass,x
	sta _VIC_SOUND_BASS
	lda #$0f
	sta _VIC_VOLUME_AUX_COLOUR
	inc TITLE_MUSIC_STEP
	lda TITLE_MUSIC_STEP
	asl
	tax
	lda title_note_voice,x
	cmp #$ff
	bne .note_update_done
	lda #$00
	sta TITLE_MUSIC_STEP
.note_update_done
	rts

.decay_long_note
	dec _VIC_VOLUME_AUX_COLOUR
.decay_volume
	dec _VIC_VOLUME_AUX_COLOUR
	lda _VIC_VOLUME_AUX_COLOUR
	cmp #$80
	bcc .apply_title_delay
	lda #$00
	sta _VIC_VOLUME_AUX_COLOUR
.apply_title_delay
	jmp apply_skill_level_delay

.wait_before_next_note
	ldx #$c8
.delay_outer_loop
	lda SKILL_LEVEL
	eor #$03
	asl
	asl
	asl
	tay
.delay_inner_loop
	dey
	bpl .delay_inner_loop
	txa
	and #$0f
	bne .next_delay_iteration
	lda _VIC_VOLUME_AUX_COLOUR
	beq .next_delay_iteration
	dec _VIC_VOLUME_AUX_COLOUR
.next_delay_iteration
	dex
	bne .delay_outer_loop
	rts

;--------------------------------------------------------------------------------------------------
; High bytes and low-byte offsets for the four Robo Droid animation frames.
robo_droid_frame_high_bytes
	!byte $b7,$b7,$b7,$b7
robo_droid_frame_low_bytes
	!byte $39,$41,$49,$51
;--------------------------------------------------------------------------------------------------
; Select and draw one of the Robo Droid's four animation frames.
draw_robo_droid
	lda ROBO_DROID_X,x
	beq .enemy_update_done
	sta DRAW_X
	lda ROBO_DROID_Y,x
	sta DRAW_Y
select_robo_droid_frame
	lda FRAME_COUNTER
	eor #$ff
	lsr
	and #$03
	tay
	lda robo_droid_frame_high_bytes,y
	sta GRAPHIC_PTR+1
	lda robo_droid_frame_low_bytes,y
	sta GRAPHIC_PTR
	lda #$07
	jmp xor_draw_shifted_bitmap

.delay_for_empty_robo_droid_slot
	jsr .delay_for_empty_enemy_slot
	jmp .advance_robo_droid_slot

;--------------------------------------------------------------------------------------------------
; Update all seven Robo Droid slots.
update_robo_droids
	ldx #$06                ;up to seven independently moving enemies
.update_next_robo_droid
	lda ROBO_DROID_X,x
	beq .delay_for_empty_robo_droid_slot
	jsr update_one_robo_droid
.advance_robo_droid_slot
	dex
	bpl .update_next_robo_droid
.enemy_update_done
	rts

;--------------------------------------------------------------------------------------------------
; Move one Robo Droid, reject walls, fire if possible, and resolve incoming hits.
; Move along the current eight-way direction, occasionally turn clockwise, and reject
; moves that hit the maze. Robo Droids can fire and can be destroyed by either a SHIV or explosion.
update_one_robo_droid
	dec FRAME_COUNTER
	jsr draw_robo_droid
	inc FRAME_COUNTER
	ldy ROOM_SPEED_INDEX
	lda FRAME_COUNTER
	and enemy_update_masks,y
	bne .resolve_robo_droid_actions
	lda ROBO_DROID_DIRECTION,x
	tay
	lda ROBO_DROID_X,x
	clc
	adc direction_delta_x,y
	jsr .clamp_robo_droid_coordinate
	sta COLLISION_X
	lda ROBO_DROID_Y,x
	clc
	adc direction_delta_y,y
	jsr .clamp_robo_droid_coordinate
	cmp #$98
	bcc .store_robo_droid_y
	lda #$98
.store_robo_droid_y
	sta COLLISION_Y
	jsr update_random_number
	and #$07
	bne .normalize_robo_droid_direction
	and #$01
	beq .turn_robo_droid_clockwise  ;always branch
.unreachable_counter_clockwise_turn
	dec ROBO_DROID_DIRECTION,x
	jmp .normalize_robo_droid_direction

.turn_robo_droid_clockwise
	inc ROBO_DROID_DIRECTION,x
.normalize_robo_droid_direction
	lda ROBO_DROID_DIRECTION,x
	and #$07
	sta ROBO_DROID_DIRECTION,x
	jsr test_2x2_background_collision
	beq .resolve_robo_droid_actions
	lda COLLISION_X
	sta ROBO_DROID_X,x
	lda COLLISION_Y
	sta ROBO_DROID_Y,x
.resolve_robo_droid_actions
	lda ROBO_DROID_X,x
	sta COLLISION_X
	lda ROBO_DROID_Y,x
	sta COLLISION_Y
	jsr try_enemy_fire
	jsr test_ion_shiv_or_explosion_hit
	beq .destroy_robo_droid
	jmp draw_robo_droid

.destroy_robo_droid
	lda #$00
	sta ROBO_DROID_X,x
	jmp award_50_points

.clamp_robo_droid_coordinate
	cmp #$a2
	bcs .clamp_robo_droid_high
	cmp #$08
	bcc .clamp_robo_droid_low
	rts

.clamp_robo_droid_high
	lda #$a2
	rts

.clamp_robo_droid_low
	lda #$08
	rts

;--------------------------------------------------------------------------------------------------
; Test an ordinary enemy against all ION SHIVs, then against active explosion frames.
; COLLISION_X/Y identifies the entity being tested. First test all three active ION SHIV slots.
; A direct hit erases the SHIV and creates an explosion. Ordinary enemies then also test against
; active explosion frames, allowing one destroyed enemy to trigger a chain reaction.
test_ion_shiv_or_explosion_hit
	lda #$00
test_ion_shiv_hit
	sta HIT_TEST_MODE
	txa
	pha
	ldx #$02
.test_next_ion_shiv_for_entity
	lda PLAYER_SHOT_X,x
	beq .next_ion_shiv_for_entity
	sec
	sbc COLLISION_X
	adc #$06
	cmp #$0c
	bcs .next_ion_shiv_for_entity
	lda PLAYER_SHOT_Y,x
	sec
	sbc COLLISION_Y
	adc #$06
	cmp #$0c
	bcs .next_ion_shiv_for_entity
	jsr draw_player_shot
	lda #$00
	sta PLAYER_SHOT_X,x
	jsr create_explosion
	pla
	tax
	lda #$00
	rts

.next_ion_shiv_for_entity
	dex
	bpl .test_next_ion_shiv_for_entity
	pla
	tax
	lda HIT_TEST_MODE
	bne .no_combat_hit
	jmp test_explosion_hit

;--------------------------------------------------------------------------------------------------
; Allocate a free explosion slot at COLLISION_X/Y and draw its first animation frame.
create_explosion
; Allocate one of seven explosion slots at COLLISION_X/Y. If all slots are occupied the visual
; effect is dropped, but the caller still removes the entity and awards its score.
	ldx #$06
.find_free_explosion_slot
	lda EXPLOSION_FRAME,x
	beq .initialize_explosion
	dex
	bpl .find_free_explosion_slot
.no_combat_hit
	rts

.initialize_explosion
	lda COLLISION_X
	sta EXPLOSION_X,x
	lda COLLISION_Y
	sta EXPLOSION_Y,x
	lda #$01
	sta EXPLOSION_FRAME,x
	jmp draw_explosion

;--------------------------------------------------------------------------------------------------
; Advance each active four-frame explosion every fourth main-loop iteration.
update_explosions
	ldx #$06
.update_next_explosion
	jsr .update_one_explosion
	dex
	bpl .update_next_explosion
.explosion_update_done
	rts

.update_one_explosion
	lda EXPLOSION_FRAME,x
	beq .explosion_update_done
	cmp #$01
	bne .test_animation_delay
	lda EXPLOSION_SOUND_TIMER
	bne .test_animation_delay
	lda #$03
	sta EXPLOSION_SOUND_TIMER
.test_animation_delay
	lda FRAME_COUNTER
	and #$03
	bne .explosion_update_done
	jsr draw_explosion
	inc EXPLOSION_FRAME,x
	lda EXPLOSION_FRAME,x
	cmp #$05
	beq .retire_explosion
	jmp draw_explosion

.retire_explosion
	lda #$00
	sta EXPLOSION_FRAME,x
explosion_frame_high_bytes_minus_1
	rts

;--------------------------------------------------------------------------------------------------
; Explosion bitmap pointer components indexed by EXPLOSION_FRAME. The three bytes immediately
; before explosion_frame_low_bytes_minus_1 deliberately provide the high-byte entries for the
; active frames. Index zero is unused; the preceding RTS doubles as the minus-one table base.
	!byte $b8,$b8,$b8
explosion_frame_low_bytes_minus_1
	!byte $b8,$1b,$23,$2b,$33

;--------------------------------------------------------------------------------------------------
; Select and draw one active explosion animation frame.
draw_explosion
	lda EXPLOSION_X,x
	sta DRAW_X
	lda EXPLOSION_Y,x
	sta DRAW_Y
	lda EXPLOSION_FRAME,x
	tay
	lda explosion_frame_high_bytes_minus_1,y
	sta GRAPHIC_PTR+1
	lda explosion_frame_low_bytes_minus_1,y
	sta GRAPHIC_PTR
	lda #$07
	jmp xor_draw_shifted_bitmap

;--------------------------------------------------------------------------------------------------
; Draw the box-shaped Snap Jumper graphic.
draw_snap_jumper
	lda SNAP_JUMPER_X,x
	beq explosion_frame_high_bytes_minus_1
	sta DRAW_X
	lda SNAP_JUMPER_Y,x
	sta DRAW_Y
select_snap_jumper_graphic
	lda #>SNAP_JUMPER_GRAPHIC
	sta GRAPHIC_PTR+1
	lda #<SNAP_JUMPER_GRAPHIC
	sta GRAPHIC_PTR
	lda #$07
	jmp xor_draw_shifted_bitmap

.delay_for_empty_snap_jumper_slot
	jsr .delay_for_empty_enemy_slot
	jmp .advance_snap_jumper_slot

;--------------------------------------------------------------------------------------------------
; Update all seven Snap Jumper slots.
update_snap_jumpers
	ldx #$06                ;up to seven direct player-seeking enemies
.update_next_snap_jumper
	lda SNAP_JUMPER_X,x
	beq .delay_for_empty_snap_jumper_slot
	jsr update_one_snap_jumper
.advance_snap_jumper_slot
	dex
	bpl .update_next_snap_jumper
	rts

;--------------------------------------------------------------------------------------------------
; Pursue Shamus with one Snap Jumper, occasionally attempting an eight-step leap.
; Move toward Shamus on both axes during each permitted update. Usually one one-pixel pursuit step
; is attempted; occasionally eight are attempted, producing the characteristic sudden "jump".
update_one_snap_jumper
	dec FRAME_COUNTER
	jsr draw_snap_jumper
	lda SNAP_JUMPER_X,x
	sta COLLISION_X
	lda SNAP_JUMPER_Y,x
	sta COLLISION_Y
	lda #$01
	sta ENEMY_STEP_COUNT
	inc FRAME_COUNTER
	jsr update_random_number
	and #$07
	beq .start_snap_jumper_leap
.perform_snap_jumper_step
	ldy ROOM_SPEED_INDEX
	lda FRAME_COUNTER
	and enemy_update_masks,y
	bne .finish_snap_jumper_step
	lda COLLISION_X
	cmp PLAYER_X
	bcc .move_snap_jumper_right
	dec COLLISION_X
	jmp .move_snap_jumper_vertically

.move_snap_jumper_right
	inc COLLISION_X
.move_snap_jumper_vertically
	lda COLLISION_Y
	cmp PLAYER_Y
	bcc .move_snap_jumper_down
	dec COLLISION_Y
	jmp .finish_snap_jumper_step

.move_snap_jumper_down
	inc COLLISION_Y
.finish_snap_jumper_step
	dec ENEMY_STEP_COUNT
	bne .perform_snap_jumper_step
	jsr test_2x2_background_collision
	beq .restore_snap_jumper_position
	lda COLLISION_X
	sta SNAP_JUMPER_X,x
	lda COLLISION_Y
	sta SNAP_JUMPER_Y,x
.restore_snap_jumper_position
	lda SNAP_JUMPER_Y,x
	sta COLLISION_Y
	lda SNAP_JUMPER_X,x
	sta COLLISION_X
	jsr test_ion_shiv_or_explosion_hit
	beq .destroy_snap_jumper
	jmp draw_snap_jumper

.destroy_snap_jumper
	lda #$00
	sta SNAP_JUMPER_X,x
	jmp award_50_points

.snap_or_shadow_update_done
	rts

.start_snap_jumper_leap
	lda #$08
	sta ENEMY_STEP_COUNT
	jmp .perform_snap_jumper_step

;--------------------------------------------------------------------------------------------------
; Release, draw and pursue Shamus with the indestructible Shadow; an ION SHIV temporarily stuns it.
; The Shadow is released after enough enemy activity ($6b >= 3). It homes toward Shamus two
; pixels per update. ION SHIV contact starts a temporary hit/stun timer rather than destroying it.
update_shadow
	lda SHADOW_X
	bne .update_active_shadow
	lda SHADOW_APPEARANCE_TIMER
	cmp #$03
	bcc .snap_or_shadow_update_done
	lda #$05
	sta SHADOW_X
	sta SHADOW_Y
;--------------------------------------------------------------------------------------------------
; Draw the Shadow at its stored position; title-screen callers may enter at the frame selector with
; DRAW_X/Y already prepared.
draw_shadow
	lda SHADOW_X
	sta DRAW_X
	lda SHADOW_Y
	sta DRAW_Y
select_and_draw_shadow_frame
	lda #>SHADOW_FRAME_1
	sta GRAPHIC_PTR+1
	lda #<SHADOW_FRAME_1
	sta GRAPHIC_PTR
	lda DRAW_X
	clc
	adc DRAW_Y
	and #$07
	cmp #$04
	bcc .use_second_shadow_frame
.draw_selected_shadow_frame
	lda #$0b
	jmp xor_draw_shifted_bitmap

.use_second_shadow_frame
	lda #$b7
	sta GRAPHIC_PTR+1
	lda #$65
	sta GRAPHIC_PTR
	jmp .draw_selected_shadow_frame

.update_active_shadow
	jsr draw_shadow
	lda SHADOW_HIT_TIMER
	bne .test_ion_shiv_hit
	lda SHADOW_X
	cmp PLAYER_X
	bcc .move_shadow_right
	dec SHADOW_X
	dec SHADOW_X
	jmp .move_shadow_vertically

.move_shadow_right
	inc SHADOW_X
	inc SHADOW_X
.move_shadow_vertically
	lda SHADOW_Y
	cmp PLAYER_Y
	bcc .move_shadow_down
	dec SHADOW_Y
	dec SHADOW_Y
	jmp .test_ion_shiv_hit

.move_shadow_down
	inc SHADOW_Y
	inc SHADOW_Y
.test_ion_shiv_hit
	lda SHADOW_X
	sta COLLISION_X
	lda SHADOW_Y
	adc #$02
	sta COLLISION_Y
	lda #$01
	jsr test_ion_shiv_hit
	php
	lda SHADOW_HIT_TIMER
	bne .advance_stun_timer
	plp
	beq .begin_shadow_stun
	jmp draw_shadow

.begin_shadow_stun
	lda #$2d
	sta SHADOW_HIT_TIMER
	jmp draw_shadow

.advance_stun_timer
	plp
	dec SHADOW_HIT_TIMER
	jmp draw_shadow

.delay_for_empty_enemy_slot
	ldy #$be
.delay_loop
	dey
	bne .delay_loop
.enemy_fire_done
	rts

;--------------------------------------------------------------------------------------------------
; Enemies only attempt to fire every eighth frame. Close alignment selects a cardinal direction;
; otherwise a random attempt uses the diagonal quadrant facing Shamus. Seven enemy-shot slots are
; shared by the Spiral Drones and Robo Droids; Snap Jumpers only pursue by contact.
try_enemy_fire
	lda FRAME_COUNTER
	and #$07
	bne .enemy_fire_done
	lda COLLISION_X
	sbc PLAYER_X
	cmp #$04
	bcc .choose_vertical_shot
	lda COLLISION_Y
	sbc PLAYER_Y
	cmp #$04
	bcc .choose_horizontal_shot
	jsr update_random_number
	and #$07
	bne .enemy_fire_done
	jsr choose_direction_toward_player
	jmp .allocate_enemy_shot

.choose_vertical_shot
	lda COLLISION_Y
	cmp PLAYER_Y
	bcc .shoot_down
	jmp .shoot_up

.choose_horizontal_shot
	lda COLLISION_X
	cmp PLAYER_X
	bcc .shoot_right
	lda #$06
	jmp .allocate_enemy_shot

.shoot_right
	lda #$02
	jmp .allocate_enemy_shot

.shoot_up
	lda #$00
	jmp .allocate_enemy_shot

.shoot_down
	lda #$04
	jmp .allocate_enemy_shot

.allocate_enemy_shot
	sta GRAPHIC_PTR+1             ;temporary direction while searching for a free slot
	txa
	pha
	ldx #$06
.find_free_enemy_shot_slot
	lda ENEMY_SHOT_X,x
	beq .initialize_enemy_shot
	dex
	bpl .find_free_enemy_shot_slot
	pla
	tax
	rts

.initialize_enemy_shot
	lda GRAPHIC_PTR+1
	sta ENEMY_SHOT_DIRECTION,x
	lda COLLISION_X
	adc #$03
	sta ENEMY_SHOT_X,x
	lda COLLISION_Y
	adc #$03
	sta ENEMY_SHOT_Y,x
	jsr draw_enemy_shot
	pla
	tax
	rts

;--------------------------------------------------------------------------------------------------
; Draw the short vertical enemy-shot bitmap for directions 0/4 or the longer horizontal/diagonal
; bitmap for all other directions.
draw_enemy_shot
	lda #>(ENEMY_SHOT_GRAPHIC_1+3)
	sta GRAPHIC_PTR+1
	lda #<(ENEMY_SHOT_GRAPHIC_1+3)
	sta GRAPHIC_PTR
	lda ENEMY_SHOT_DIRECTION,x
	beq .draw_selected_enemy_shot
	cmp #$04
	beq .draw_selected_enemy_shot
	lda #>ENEMY_SHOT_GRAPHIC_1
	sta GRAPHIC_PTR+1
	lda #<ENEMY_SHOT_GRAPHIC_1
	sta GRAPHIC_PTR
.draw_selected_enemy_shot
	lda ENEMY_SHOT_X,x
	sta DRAW_X
	lda ENEMY_SHOT_Y,x
	sta DRAW_Y
	lda #$02
	jmp xor_draw_shifted_bitmap

;--------------------------------------------------------------------------------------------------
; Move all seven enemy shots one pixel and remove shots outside the screen or over a solid cell.
update_enemy_shots
	ldx #$06
.update_next_enemy_shot
	lda ENEMY_SHOT_X,x
	beq .advance_enemy_shot_slot
	jsr .update_one_enemy_shot
.advance_enemy_shot_slot
	dex
	bpl .update_next_enemy_shot
	rts

.update_one_enemy_shot
	jsr draw_enemy_shot
	lda ENEMY_SHOT_DIRECTION,x
	tay
	lda ENEMY_SHOT_X,x
	clc
	adc direction_delta_x,y
	sta ENEMY_SHOT_X,x
	lda ENEMY_SHOT_Y,x
	clc
	adc direction_delta_y,y
	sta ENEMY_SHOT_Y,x
	cmp #$05
	bcc .remove_enemy_shot
	cmp #$aa
	bcs .remove_enemy_shot
	lda ENEMY_SHOT_X,x
	cmp #$05
	bcc .remove_enemy_shot
	cmp #$aa
	bcs .remove_enemy_shot
	lda ENEMY_SHOT_X,x
	adc #$01
	sta COLLISION_X             ;calculated but the background test uses pre-move DRAW_X/Y
	lda ENEMY_SHOT_Y,x
	adc #$01
	sta COLLISION_Y
	jsr test_background_at_position
	beq .remove_enemy_shot
	jmp draw_enemy_shot

.remove_enemy_shot
	lda #$00
	sta ENEMY_SHOT_X,x
	rts

;--------------------------------------------------------------------------------------------------
; Draw the fixed keyhole bitmap.
draw_keyhole
	lda #>KEYHOLE_GRAPHIC
	sta GRAPHIC_PTR+1
	lda #<KEYHOLE_GRAPHIC
	sta GRAPHIC_PTR
	lda #$0f
	jmp xor_draw_shifted_bitmap

;--------------------------------------------------------------------------------------------------
; Draw the fixed key bitmap.
draw_key
	lda #>KEY_GRAPHIC
	sta GRAPHIC_PTR+1
	lda #<KEY_GRAPHIC
	sta GRAPHIC_PTR
	lda #$0b
	jmp xor_draw_shifted_bitmap

;--------------------------------------------------------------------------------------------------
; Draw one of the extra-life bottle's two animation frames.
draw_extra_life_bottle
	lda #>EXTRA_LIFE_BOTTLE_1
	sta GRAPHIC_PTR+1
	lda #<EXTRA_LIFE_BOTTLE_1
	sta GRAPHIC_PTR
	lda FRAME_COUNTER
	lsr
	and #$01
	beq .draw_selected_extra_life_bottle
	lda #>EXTRA_LIFE_BOTTLE_2
	sta GRAPHIC_PTR+1
	lda #<EXTRA_LIFE_BOTTLE_2
	sta GRAPHIC_PTR
.draw_selected_extra_life_bottle
	lda #$0a
	jmp xor_draw_shifted_bitmap

;--------------------------------------------------------------------------------------------------
; Draw one of the mystery question mark's two animation frames.
draw_mystery_question
	lda #>QUESTION_GRAPHIC_1
	sta GRAPHIC_PTR+1
	lda #<QUESTION_GRAPHIC_1
	sta GRAPHIC_PTR
	lda FRAME_COUNTER
	lsr
	and #$01
	beq .draw_selected_mystery_question
	lda #>QUESTION_GRAPHIC_2
	sta GRAPHIC_PTR+1
	lda #<QUESTION_GRAPHIC_2
	sta GRAPHIC_PTR
.draw_selected_mystery_question
	lda #$09
	jmp xor_draw_shifted_bitmap

;--------------------------------------------------------------------------------------------------
; Test an entity at COLLISION_X/Y against active explosions, consuming a colliding old explosion
; and replacing it with a fresh explosion at the entity position to produce the chain reaction.
test_explosion_hit
	txa
	pha
	ldx #$06
.test_next_explosion
	lda EXPLOSION_FRAME,x
	beq .next_explosion
	lda EXPLOSION_X,x
	sec
	sbc COLLISION_X
	adc #$04
	cmp #$08
	bcs .next_explosion
	lda EXPLOSION_Y,x
	sec
	sbc COLLISION_Y
	adc #$04
	cmp #$08
	bcs .next_explosion
	jsr draw_explosion
	lda #$00
	sta EXPLOSION_FRAME,x
	jsr create_explosion
	pla
	tax
	lda #$00
	rts

.next_explosion
	dex
	bpl .test_next_explosion
	pla
	tax
	lda #$01
	rts

;--------------------------------------------------------------------------------------------------
; Draw the lair target's two adjacent 24-row bitmap halves.
draw_lair_target
	lda LAIR_TARGET_X
	sta DRAW_X
	lda LAIR_TARGET_Y
	sta DRAW_Y
	lda #$b8
	sta GRAPHIC_PTR+1
	lda #$65
	sta GRAPHIC_PTR
	lda #$17
	jsr xor_draw_shifted_bitmap
	jsr advance_draw_x_by_8
	lda #$b8
	sta GRAPHIC_PTR+1
	lda #$7d
	sta GRAPHIC_PTR
	lda #$17
	jmp xor_draw_shifted_bitmap

;--------------------------------------------------------------------------------------------------
; Pursue Shamus with the lair target and complete the lair after its twentieth ION SHIV hit.
; The two-part lair target follows Shamus and tests SHIV contact. It takes 20 hits; each successful
; hit creates the ordinary hit effects before the game cycles back to level one at Expert speed.
update_lair_target
	jsr draw_lair_target
	lda LAIR_TARGET_X
	adc #$08
	cmp PLAYER_X
	bcc .move_lair_target_right
	dec LAIR_TARGET_X
	jmp .move_lair_target_vertically

.move_lair_target_right
	inc LAIR_TARGET_X
.move_lair_target_vertically
	lda LAIR_TARGET_Y
	cmp PLAYER_Y
	bcc .move_lair_target_down
	dec LAIR_TARGET_Y
	jmp .test_lair_target_hit

.move_lair_target_down
	inc LAIR_TARGET_Y
.test_lair_target_hit
	lda LAIR_TARGET_X
	adc #$04
	sta COLLISION_X
	lda LAIR_TARGET_Y
	adc #$02
	sta COLLISION_Y
	lda LAIR_HIT_COUNT
	cmp #$14
	beq .complete_lair
	lda #$01
	jsr test_ion_shiv_hit
	beq .record_lair_hit
	jmp draw_lair_target

.record_lair_hit
	inc LAIR_HIT_COUNT
	jmp draw_lair_target

.complete_lair
	lda #$00
	sta LEVEL_NUMBER
	lda #$03
	sta SKILL_LEVEL
	jmp reset_level_state

;--------------------------------------------------------------------------------------------------
; Convert the relative quadrant of COLLISION_X/Y and Shamus into direction codes 1,3,5 or 7.
choose_direction_toward_player
	lda PLAYER_X
	cmp COLLISION_X
	bcc .player_is_left
	lda PLAYER_Y
	cmp COLLISION_Y
	bcc .player_is_above_and_right
	lda #$03
	rts

.player_is_left
	lda PLAYER_Y
	cmp COLLISION_Y
	bcc .player_is_above_and_left
	lda #$05
	rts

.player_is_above_and_left
	lda #$07
	rts

.player_is_above_and_right
	lda #$01
	rts

;--------------------------------------------------------------------------------------------------
; Clear and repopulate the three ordinary-enemy species for the current room.
; Clear all three seven-entry enemy arrays, then choose permitted spawn positions from the current
; room's mask at room_spawn_position_masks. Normally each species gets a random effective count
; from one to seven.
; A random X=7 performs a harmless dummy eighth write outside the processed slots; all update loops
; deliberately process only slots 6..0.
; If Shamus left the previous room before ROOM_EXIT_RUSH_TIMER expired, all seven slots are forced
; active for every species - a strong penalty for rushing straight through a room.
initialize_room_enemies
	lda #$00
	ldx #$06
.clear_spiral_drone_slots
	sta SPIRAL_DRONE_X,x
	dex
	bpl .clear_spiral_drone_slots
	ldx #$06
.clear_snap_jumper_slots
	sta SNAP_JUMPER_X,x
	dex
	bpl .clear_snap_jumper_slots
	ldx #$06
.clear_robo_droid_slots
	sta ROBO_DROID_X,x
	dex
	bpl .clear_robo_droid_slots
	lda LEVEL_NUMBER
	cmp #$02
	beq .enemy_initialization_done
	lda ROOM_NUMBER
	cmp #$1b
	beq .initialize_room_27_enemies
	jsr choose_enemy_population_count
.spawn_next_spiral_drone
	jsr .choose_enemy_spawn_position
	lda COLLISION_X
	sta SPIRAL_DRONE_X,x
	lda COLLISION_Y
	sta SPIRAL_DRONE_Y,x
	dex
	bpl .spawn_next_spiral_drone
	jsr choose_enemy_population_count
.spawn_next_robo_droid
	jsr .choose_enemy_spawn_position
	lda COLLISION_X
	sta ROBO_DROID_X,x
	lda COLLISION_Y
	sta ROBO_DROID_Y,x
	jsr update_random_number
	and #$07
	sta ROBO_DROID_DIRECTION,x
	dex
	bpl .spawn_next_robo_droid
	jsr choose_enemy_population_count
.spawn_next_snap_jumper
	jsr .choose_enemy_spawn_position
	lda COLLISION_X
	sta SNAP_JUMPER_X,x
	lda COLLISION_Y
	sta SNAP_JUMPER_Y,x
	dex
	bpl .spawn_next_snap_jumper
.enemy_initialization_done
	rts

.initialize_room_27_enemies
	jmp initialize_open_room_27_enemies

.choose_enemy_spawn_position
	txa
	pha
.choose_permitted_spawn_cell
	jsr update_random_number
	and #$07
	tay
	ldx ROOM_NUMBER
	lda room_spawn_position_masks,x
	and bit_selection_masks,y
	beq .choose_permitted_spawn_cell
	jsr update_random_number
	and #$0f
	adc .enemy_spawn_y_bases,y
	sta COLLISION_Y
	jsr update_random_number
	and #$0f
	adc .enemy_spawn_x_bases,y
	sta COLLISION_X
	pla
	tax
	rts

;--------------------------------------------------------------------------------------------------
; Coarse 3-by-3 spawn-grid origins. A random 0-15 pixel displacement is added on each axis.
.enemy_spawn_x_bases
	!byte $20,$48,$70,$20,$48,$70,$20,$48
.enemy_spawn_y_bases
	!byte $10,$10,$10,$40,$40,$40,$70,$70

;--------------------------------------------------------------------------------------------------
; Clear player shots, explosions and enemy shots, then draw every populated ordinary-enemy slot.
clear_transient_entities
	ldx #$02
	lda #$00
.clear_player_shots
	sta PLAYER_SHOT_X,x
	dex
	bpl .clear_player_shots
	ldx #$06
.clear_explosions
	sta EXPLOSION_FRAME,x
	dex
	bpl .clear_explosions
	ldx #$06
.clear_enemy_shots
	sta ENEMY_SHOT_X,x
	dex
	bpl .clear_enemy_shots
	ldx #$06
.draw_next_robo_droid
	lda ROBO_DROID_X,x
	beq .skip_robo_droid
	jsr draw_robo_droid
.skip_robo_droid
	dex
	bpl .draw_next_robo_droid
	ldx #$06
.draw_next_spiral_drone
	lda SPIRAL_DRONE_X,x
	beq .skip_spiral_drone
	jsr draw_spiral_drone
.skip_spiral_drone
	dex
	bpl .draw_next_spiral_drone
	ldx #$06
.draw_next_snap_jumper
	lda SNAP_JUMPER_X,x
	beq .skip_snap_jumper
	jsr draw_snap_jumper
.skip_snap_jumper
	dex
	bpl .draw_next_snap_jumper
	rts

;--------------------------------------------------------------------------------------------------
; Once room $1B's barrier has been removed, place all enemy slots on its central X coordinate with
; randomized Y positions. Before removal the room deliberately contains no ordinary enemies.
initialize_open_room_27_enemies
	lda ROOM_27_BARRIER_PHASE
	cmp #$ff
	beq .populate_open_room_27
	rts

.populate_open_room_27
	ldx #$06
.spawn_room_27_spiral_drone
	lda #$58
	sta SPIRAL_DRONE_X,x
	jsr .choose_room_27_enemy_y
	sta SPIRAL_DRONE_Y,x
	dex
	bpl .spawn_room_27_spiral_drone
	ldx #$06
.spawn_room_27_robo_droid
	lda #$58
	sta ROBO_DROID_X,x
	jsr .choose_room_27_enemy_y
	sta ROBO_DROID_Y,x
	dex
	bpl .spawn_room_27_robo_droid
	ldx #$06
.spawn_room_27_snap_jumper
	lda #$58
	sta SNAP_JUMPER_X,x
	jsr .choose_room_27_enemy_y
	sta SNAP_JUMPER_Y,x
	dex
	bpl .spawn_room_27_snap_jumper
	ldx #$06
.choose_room_27_robo_droid_direction
	jsr update_random_number
	and #$07
	sta ROBO_DROID_DIRECTION,x
	dex
	bpl .choose_room_27_robo_droid_direction
	rts

.choose_room_27_enemy_y
	jsr update_random_number
	and #$3f
	adc #$20
	rts

;--------------------------------------------------------------------------------------------------
; Draw a three-byte packed-BCD value through SCORE_PTR, suppressing leading zeroes and appending
; the fixed units zero used by the displayed score. A zero score is rendered as one zero.
draw_packed_bcd_score
	ldy #$00
.find_first_nonzero_score_byte
	lda (SCORE_PTR),y
	beq .skip_leading_zero_byte
	cmp #$10
	bcs .draw_remaining_score_bytes
	jsr .draw_low_digit
	jmp .advance_score_byte

.draw_remaining_score_bytes
	lda (SCORE_PTR),y
	jsr .draw_two_digits
.advance_score_byte
	iny
	cpy #$03
	bne .draw_remaining_score_bytes
.draw_fixed_units_zero
	lda #$00
	jmp .draw_low_digit

.skip_leading_zero_byte
	iny
	cpy #$03
	bne .find_first_nonzero_score_byte
	jmp .draw_fixed_units_zero

.advance_score_draw_position
	pha
	lda DRAW_X
	clc
	adc #$08
	sta DRAW_X
	pla
	rts

.draw_two_digits
	sta SCORE_DIGIT_BYTE
	lsr
	lsr
	lsr
	lsr
	jsr .draw_low_digit
	lda SCORE_DIGIT_BYTE
.draw_low_digit
	and #$0f
	jsr .draw_score_digit
	jmp .advance_score_draw_position

.draw_score_digit
	sty SCORE_SAVED_Y
	clc
	adc #$30
	jsr draw_character
	ldy SCORE_SAVED_Y
	rts

;--------------------------------------------------------------------------------------------------
; Draw the current score and high score as BCD values followed by their fixed units zero.
draw_score_and_high_score
	lda #$a0
	sta DRAW_Y
	lda #$70
	sta DRAW_X
	lda #$00
	sta SCORE_PTR+1
	lda #<SCORE_BCD
	sta SCORE_PTR
	jsr draw_packed_bcd_score
	lda #$a8
	sta DRAW_Y
	lda #$70
	sta DRAW_X
	lda #$00
	sta SCORE_PTR+1
	lda #<HIGH_SCORE_BCD
	sta SCORE_PTR
	jmp draw_packed_bcd_score

;--------------------------------------------------------------------------------------------------
; Add 50 displayed points (stored BCD +5 with a fixed trailing zero) and update the high score.
award_50_points
	txa
	pha
	jsr draw_score_and_high_score
	lda SCORE_BCD+2
	clc
	sed
	adc #$05
	sta SCORE_BCD+2
	lda SCORE_BCD+1
	adc #$00
	sta SCORE_BCD+1
	lda SCORE_BCD
	adc #$00
	sta SCORE_BCD
	cld
	lda SCORE_BCD
	cmp HIGH_SCORE_BCD
	bcc .score_update_done
	bne .copy_new_high_score
	lda SCORE_BCD+1
	cmp HIGH_SCORE_BCD+1
	bcc .score_update_done
	bne .copy_new_high_score
	lda SCORE_BCD+2
	cmp HIGH_SCORE_BCD+2
	bcc .score_update_done
.copy_new_high_score
	ldx #$02
.copy_high_score_byte
	lda SCORE_BCD,x
	sta HIGH_SCORE_BCD,x
	dex
	bpl .copy_high_score_byte
.score_update_done
	jsr draw_score_and_high_score
	pla
	tax
.return_from_score_or_population_count
	rts

force_maximum_population_if_room_rushed
	lda ROOM_EXIT_RUSH_TIMER
	beq .return_from_score_or_population_count
	ldx #$06
	rts

choose_enemy_population_count
	jsr update_random_number
	and #$07
	tax
	jmp force_maximum_population_if_room_rushed

;--------------------------------------------------------------------------------------------------
; The skill setting changes the busy-wait duration rather than the movement rules themselves:
; Beginner waits longest; Expert has no inner delay. Room progression separately controls the
; enemy update masks in enemy_update_masks, making enemies update more frequently deeper into the
; maze.
apply_skill_level_delay
	lda ROOM_NUMBER
	ldx #$dc
.repeat_skill_delay
	lda SKILL_LEVEL
	eor #$03
	asl
	asl
	asl
	tay
.skill_delay_loop
	dey
	bpl .skill_delay_loop
	dex
	bne .repeat_skill_delay
	rts

;--------------------------------------------------------------------------------------------------
; Draw Shamus using the vertical, right-facing, or left-facing two-frame animation selected by the
; active-low joystick state. Up and down share the same vertical graphic pair.
draw_player
	lda PLAYER_X
	sta DRAW_X
	lda PLAYER_Y
	sta DRAW_Y
	jsr .select_player_graphic
	lda #$0a
	jmp xor_draw_shifted_bitmap

.select_player_graphic
	lda JOYSTICK_STATE
	and #$80
	beq .select_right_facing_player
	lda JOYSTICK_STATE
	and #$10
	beq .select_left_facing_player
	lda JOYSTICK_STATE
	and #$04
	beq .select_vertical_player
	lda JOYSTICK_STATE
	and #$08
	beq .select_vertical_player
	lda #$b7
	sta GRAPHIC_PTR+1
	lda #$99
	sta GRAPHIC_PTR
.player_graphic_selected
	rts

.select_right_facing_player
	lda #$b7
	sta GRAPHIC_PTR+1
	lda #$af
	sta GRAPHIC_PTR
	jmp .select_player_animation_frame

.select_left_facing_player
	lda #$b7
	sta GRAPHIC_PTR+1
	lda #$c5
	sta GRAPHIC_PTR
	jmp .select_player_animation_frame

.select_vertical_player
	lda #$b7
	sta GRAPHIC_PTR+1
	lda #$99
	sta GRAPHIC_PTR
.select_player_animation_frame
	lda FRAME_COUNTER
	lsr
	and #$01
	beq .player_graphic_selected
	lda GRAPHIC_PTR
	clc
	adc #$0b
	sta GRAPHIC_PTR
	lda GRAPHIC_PTR+1
	adc #$00
	sta GRAPHIC_PTR+1
	rts

;--------------------------------------------------------------------------------------------------
; Fire once when the button is first pressed, or again when the joystick direction changes while
; it remains held. Releasing fire resets INPUT_DIRECTION_LATCH. Unlike manuals for some other
; versions, this VIC-20 implementation actually allocates three simultaneous ION SHIV slots.
handle_fire_button
	jsr decode_joystick_direction
	cmp INPUT_DIRECTION_LATCH
	beq .redraw_player_after_update
	sta INPUT_DIRECTION_LATCH
	jsr draw_player
	jmp try_fire_player_shot

;--------------------------------------------------------------------------------------------------
; XOR-erase Shamus, sample the joystick, move two pixels on each active axis, process firing, and
; redraw the appropriate directional animation frame. Maze/death collision is handled later.
update_player
	dec FRAME_COUNTER
	jsr draw_player
	inc FRAME_COUNTER
	jsr read_joystick
	and #$20
	beq handle_fire_button
	lda JOYSTICK_STATE
	and #$04
	beq .move_player_up
.test_move_down
	lda JOYSTICK_STATE
	and #$08
	beq .move_player_down
.test_move_right
	lda JOYSTICK_STATE
	and #$80
	beq .move_player_right
.test_move_left
	lda JOYSTICK_STATE
	and #$10
	beq .move_player_left
.redraw_player_after_update
	jsr draw_player
	jmp .release_fire_latch_if_needed

.move_player_up
	dec PLAYER_Y
	dec PLAYER_Y
	jmp .test_move_down

.move_player_down
	inc PLAYER_Y
	inc PLAYER_Y
	jmp .test_move_right

.move_player_right
	inc PLAYER_X
	inc PLAYER_X
	jmp .test_move_left

.move_player_left
	dec PLAYER_X
	dec PLAYER_X
	jmp .redraw_player_after_update

.release_fire_latch_if_needed
	lda JOYSTICK_STATE
	and #$20
	bne .release_fire_latch
	rts

.release_fire_latch
	lda #$ff
	sta INPUT_DIRECTION_LATCH
.player_weapon_update_done
	rts

;--------------------------------------------------------------------------------------------------
; Search slots 2..0, store the current eight-way joystick direction and start the firing tone.
; If all three slots are active the request is silently ignored.
try_fire_player_shot
	ldx #$02
.find_free_player_shot_slot
	lda PLAYER_SHOT_X,x
	beq .initialize_player_shot
	dex
	bpl .find_free_player_shot_slot
	rts

.initialize_player_shot
	jsr decode_joystick_direction
	cmp #$80
	beq .player_weapon_update_done
	sta PLAYER_SHOT_DIRECTION,x
	lda PLAYER_Y
	clc
	adc #$03
	sta PLAYER_SHOT_Y,x
	lda PLAYER_X
	sta PLAYER_SHOT_X,x
	lda #$05
	sta ION_SHIV_SOUND_TIMER
;--------------------------------------------------------------------------------------------------
; Select and draw the ION SHIV bitmap for one of the eight direction values.
draw_player_shot
	lda PLAYER_SHOT_X,x
	beq .player_weapon_update_done
	sta DRAW_X
	lda PLAYER_SHOT_Y,x
	sta DRAW_Y
	lda PLAYER_SHOT_DIRECTION,x
	tay
	lda player_shot_frame_high_bytes,y
	sta GRAPHIC_PTR+1
	lda player_shot_frame_low_bytes,y
	sta GRAPHIC_PTR
	lda #$07
	jmp xor_draw_shifted_bitmap

;--------------------------------------------------------------------------------------------------
; Bitmap pointers for the eight directional ION SHIV graphics.
player_shot_frame_high_bytes
	!fill 5,$b7
	!byte $b8,$b8,$b8
player_shot_frame_low_bytes
	!byte $db,$e3,$eb,$f3,$fb,$03,$0b,$13

;--------------------------------------------------------------------------------------------------
; Convert active-low joystick direction bits to values 0-7 clockwise; return $80 for neutral or an
; unsupported opposing-direction combination.
decode_joystick_direction
	lda JOYSTICK_STATE
	eor #$ff
	and #$9c
	beq .no_valid_direction
	cmp #$04
	beq .direction_up
	cmp #$84
	beq .direction_up_right
	cmp #$80
	beq .direction_right
	cmp #$88
	beq .direction_down_right
	cmp #$08
	beq .direction_down
	cmp #$18
	beq .direction_down_left
	cmp #$10
	beq .direction_left
	cmp #$14
	beq .direction_up_left
.no_valid_direction
	lda #$80
	rts

.direction_up
	lda #$00
	rts

.direction_up_right
	lda #$01
	rts

.direction_right
	lda #$02
	rts

.direction_down_right
	lda #$03
	rts

.direction_down
	lda #$04
	rts

.direction_down_left
	lda #$05
	rts

.direction_left
	lda #$06
	rts

.direction_up_left
	lda #$07
.direction_or_shot_update_done
	rts

;--------------------------------------------------------------------------------------------------
; Signed X/Y deltas indexed by the eight-way direction value. The two-byte Y table deliberately
; runs into direction_delta_x, providing all eight Y entries without storing duplicates.
direction_delta_y
	!byte $fe,$ff
direction_delta_x
	!byte $00,$01,$02,$01,$00,$ff,$fe,$ff

;--------------------------------------------------------------------------------------------------
; Update all three ION SHIV slots. Each active shot moves four pixels along its eight-way direction
; and is removed if it reaches a screen limit or its leading point enters a solid maze character.
update_player_shots
	ldx #$02
.update_next_player_shot
	jsr .update_one_player_shot
	dex
	bpl .update_next_player_shot
	rts

.update_one_player_shot
	lda PLAYER_SHOT_X,x
	beq .direction_or_shot_update_done
	jsr draw_player_shot
	lda PLAYER_SHOT_DIRECTION,x
	tay
	lda PLAYER_SHOT_X,x
	clc
	adc direction_delta_x,y
	clc
	adc direction_delta_x,y
	clc
	adc direction_delta_x,y
	clc
	adc direction_delta_x,y
	jsr .remove_player_shot_if_outside_screen
	sta PLAYER_SHOT_X,x
	adc #$04
	sta DRAW_X
	lda PLAYER_SHOT_Y,x
	clc
	adc direction_delta_y,y
	clc
	adc direction_delta_y,y
	clc
	adc direction_delta_y,y
	clc
	adc direction_delta_y,y
	jsr .remove_player_shot_if_outside_screen
	sta PLAYER_SHOT_Y,x
	clc
	adc #$03
	sta DRAW_Y
	jsr test_background_at_position
	beq .remove_player_shot
	jmp draw_player_shot

.remove_player_shot_if_outside_screen
	cmp #$a6
	bcs .remove_player_shot
	cmp #$06
	bcc .remove_player_shot
	rts

.remove_player_shot
	lda #$00
	sta PLAYER_SHOT_X,x
.entity_draw_or_shot_update_done
	rts

;--------------------------------------------------------------------------------------------------
; High bytes and low-byte offsets for the four Spiral Drone animation frames.
spiral_drone_frame_high_bytes
	!byte $b7,$b7,$b7,$b7
spiral_drone_frame_low_bytes
	!byte $71,$79,$81,$89

;--------------------------------------------------------------------------------------------------
; Select and draw one of the Spiral Drone's four animation frames.
draw_spiral_drone
	lda SPIRAL_DRONE_X,x
	beq .entity_draw_or_shot_update_done
	sta DRAW_X
	lda SPIRAL_DRONE_Y,x
	sta DRAW_Y
select_spiral_drone_frame
	lda FRAME_COUNTER
	lsr
	and #$03
	tay
	lda spiral_drone_frame_high_bytes,y
	sta GRAPHIC_PTR+1
	lda spiral_drone_frame_low_bytes,y
	sta GRAPHIC_PTR
	lda #$07
	jmp xor_draw_shifted_bitmap

.delay_for_empty_spiral_drone_slot
	jsr .delay_for_empty_enemy_slot
	jmp .advance_spiral_drone_slot

;--------------------------------------------------------------------------------------------------
; Update all seven Spiral Drone slots and advance the Shadow appearance timer on counter rollover.
update_spiral_drones
	ldx #$06                ;up to seven wandering/player-seeking enemies
.update_next_spiral_drone
	lda SPIRAL_DRONE_X,x
	beq .delay_for_empty_spiral_drone_slot
	jsr update_one_spiral_drone
.advance_spiral_drone_slot
	dex
	bpl .update_next_spiral_drone
	lda FRAME_COUNTER
	beq .advance_shadow_appearance_timer
	rts

.advance_shadow_appearance_timer
	inc SHADOW_APPEARANCE_TIMER
	rts

;--------------------------------------------------------------------------------------------------
; Main-loop masks controlling enemy update frequency as ROOM_SPEED_INDEX increases.
enemy_update_masks
	!byte $0f,$07,$03,$01,$00,$00

;--------------------------------------------------------------------------------------------------
; Move one Spiral Drone toward Shamus, reject walls, fire if possible, and resolve incoming hits.
; Independently decide whether to move one pixel toward Shamus on each axis, then reject movement
; into the maze. Spiral Drones can fire and participate in explosion chain reactions.
update_one_spiral_drone
	dec FRAME_COUNTER
	jsr draw_spiral_drone
	lda SPIRAL_DRONE_X,x
	sta COLLISION_X
	lda SPIRAL_DRONE_Y,x
	sta COLLISION_Y
	inc FRAME_COUNTER
	ldy ROOM_SPEED_INDEX
	lda FRAME_COUNTER
	and enemy_update_masks,y
	bne .test_spiral_drone_position
	jsr update_random_number
	and #$03
	beq .choose_spiral_drone_y_step
	lda COLLISION_X
	cmp PLAYER_X
	bcc .move_spiral_drone_right
	dec COLLISION_X
	jmp .choose_spiral_drone_y_step

.move_spiral_drone_right
	inc COLLISION_X
.choose_spiral_drone_y_step
	jsr update_random_number
	and #$03
	beq .test_spiral_drone_position
	lda COLLISION_Y
	cmp PLAYER_Y
	bcc .move_spiral_drone_down
	dec COLLISION_Y
	jmp .test_spiral_drone_position

.move_spiral_drone_down
	inc COLLISION_Y
.test_spiral_drone_position
	lda COLLISION_Y
	jsr test_2x2_background_collision
	beq .restore_spiral_drone_position
	lda COLLISION_X
	sta SPIRAL_DRONE_X,x
	lda COLLISION_Y
	sta SPIRAL_DRONE_Y,x
.restore_spiral_drone_position
	lda SPIRAL_DRONE_X,x
	sta COLLISION_X
	lda SPIRAL_DRONE_Y,x
	sta COLLISION_Y
	jsr try_enemy_fire
	jsr test_ion_shiv_or_explosion_hit
	beq .destroy_spiral_drone
	jmp draw_spiral_drone

.destroy_spiral_drone
	lda #$00
	sta SPIRAL_DRONE_X,x
	jmp award_50_points

;--------------------------------------------------------------------------------------------------
; Convert DRAW_X/DRAW_Y to a screen-matrix cell. Return A=0 for solid character codes $fd-$ff,
; including electric walls $fe/$ff, or A=1 for traversable character codes below $fd.
test_background_at_position
	lda DRAW_X
	lsr
	lsr
	lsr
	sta $03
	lda DRAW_Y
	lsr
	lsr
	lsr
	lsr
	tay
	lda #$00
.advance_to_screen_row
	cpy #$00
	beq .screen_row_selected
	clc
	adc #$16
	dey
	jmp .advance_to_screen_row

.screen_row_selected
	clc
	adc $03
	tay
	lda _SCREEN_MATRIX_ADDR,y
	cmp #$fd
	bcs .solid_background
	lda #$01
	rts

.solid_background
	lda #$00
	rts

;--------------------------------------------------------------------------------------------------
; Test the four framebuffer cells around COLLISION_X/Y; return zero if any is a solid maze cell.
test_2x2_background_collision
	lda COLLISION_X
	sta DRAW_X
	lda COLLISION_Y
	sta DRAW_Y
	jsr test_background_at_position
	beq .collision_or_object_update_done
	jsr advance_draw_x_by_8
	jsr test_background_at_position
	beq .collision_or_object_update_done
	lda DRAW_X
	sec
	sbc #$08
	sta DRAW_X
	jsr advance_draw_y_by_8
	jsr test_background_at_position
	beq .collision_or_object_update_done
	jsr advance_draw_x_by_8
	jsr test_background_at_position
.collision_or_object_update_done
	rts

;--------------------------------------------------------------------------------------------------
; Draw the current room's extra-life bottle at its stored coordinates.
draw_extra_life_object
	lda EXTRA_LIFE_OBJECT_X
	sta DRAW_X
	lda EXTRA_LIFE_OBJECT_Y
	sta DRAW_Y
	jmp draw_extra_life_bottle

;--------------------------------------------------------------------------------------------------
; Animate, collect and persist the current room's extra-life bottle.
; Bottles occur once in rooms $01, $02, $0c and $1a. Collection increments the life count and
; records a persistent per-room flag in $89-$8c so the bottle cannot be collected again.
update_extra_life_object
	lda EXTRA_LIFE_OBJECT_X
	beq .collision_or_object_update_done
	dec FRAME_COUNTER
	jsr draw_extra_life_object
	inc FRAME_COUNTER
	lda EXTRA_LIFE_OBJECT_X
	sta DRAW_X
	lda EXTRA_LIFE_OBJECT_Y
	sta DRAW_Y
	jsr test_player_object_overlap
	bne .redraw_extra_life_object
	jsr draw_lives_remaining
	inc LIVES_REMAINING
	jsr draw_lives_remaining
	lda #$05
	sta REWARD_SOUND_TIMER
	lda #$00
	sta EXTRA_LIFE_OBJECT_X
	ldy #$01
	lda ROOM_NUMBER
	cmp #$01
	beq .mark_room_01_extra_life_collected
	cmp #$02
	beq .mark_room_02_extra_life_collected
	cmp #$0c
	beq .mark_room_0c_extra_life_collected
	cmp #$1a
	beq .mark_room_1a_extra_life_collected
.redraw_extra_life_object
	jmp draw_extra_life_object

.mark_room_01_extra_life_collected
	sty EXTRA_LIFE_COLLECTED_FLAGS
	rts

.mark_room_02_extra_life_collected
	sty EXTRA_LIFE_COLLECTED_FLAGS+1
	rts

.mark_room_0c_extra_life_collected
	sty EXTRA_LIFE_COLLECTED_FLAGS+2
	rts

.mark_room_1a_extra_life_collected
	sty EXTRA_LIFE_COLLECTED_FLAGS+3
	rts

;--------------------------------------------------------------------------------------------------
; Draw the current room's animated mystery question mark at its stored coordinates.
draw_bonus_object
	lda MYSTERY_OBJECT_X
	sta DRAW_X
	lda MYSTERY_OBJECT_Y
	sta DRAW_Y
	jmp draw_mystery_question

;--------------------------------------------------------------------------------------------------
; Animate, collect and resolve the current room's mystery question mark.
; Question marks occur once in rooms $00, $08, $0b and $18. Their random result is one of:
; force the Shadow to appear, add a life, set the slowest enemy speed, set the fastest enemy speed,
; or award 500 points. Values 5-7 are rejected and rerolled; accepted values 0-4 map one-to-one.
update_bonus_object
	lda MYSTERY_OBJECT_X
	beq .collision_or_object_update_done
	dec FRAME_COUNTER
	jsr draw_bonus_object
	inc FRAME_COUNTER
	lda MYSTERY_OBJECT_X
	sta DRAW_X
	lda MYSTERY_OBJECT_Y
	sta DRAW_Y
	jsr test_player_object_overlap
	bne .redraw_bonus_object
	jsr .choose_mystery_reward
	lda #$00
	sta MYSTERY_OBJECT_X
	ldy #$01
	lda ROOM_NUMBER
	cmp #$00
	beq .mark_room_00_mystery_collected
	cmp #$08
	beq .mark_room_08_mystery_collected
	cmp #$0b
	beq .mark_room_0b_mystery_collected
	cmp #$18
	beq .mark_room_18_mystery_collected
.redraw_bonus_object
	jmp draw_bonus_object

.mark_room_00_mystery_collected
	sty MYSTERY_COLLECTED_FLAGS
	rts

.mark_room_08_mystery_collected
	sty MYSTERY_COLLECTED_FLAGS+1
	rts

.mark_room_18_mystery_collected
	sty MYSTERY_COLLECTED_FLAGS+2
	rts

.mark_room_0b_mystery_collected
	sty MYSTERY_COLLECTED_FLAGS+3
	rts

.choose_mystery_reward
	lda #$05
	sta REWARD_SOUND_TIMER
	jsr update_random_number
	and #$07
	beq .force_shadow_reward
	cmp #$01
	beq .extra_life_reward
	cmp #$02
	beq .slow_enemies_reward
	cmp #$03
	beq .fast_enemies_reward
	cmp #$04
	beq .score_reward
	jmp .choose_mystery_reward

.force_shadow_reward
	lda #$05
	sta SHADOW_APPEARANCE_TIMER                     ;force Shadow appearance
	rts

.extra_life_reward
	jsr draw_lives_remaining
	inc LIVES_REMAINING
	jmp draw_lives_remaining                   ;extra life

.slow_enemies_reward
	lda #$00
	sta ROOM_SPEED_INDEX                     ;slowest enemy update rate
	rts

.fast_enemies_reward
	lda #$05
	sta ROOM_SPEED_INDEX                     ;fastest enemy update rate
	rts

.score_reward
	ldx #$09
.award_next_50_points
	jsr award_50_points                    ;10 * 50 = 500 points
	dex
	bpl .award_next_50_points
	rts

;--------------------------------------------------------------------------------------------------
; Return zero when Shamus and the object at DRAW_X/Y overlap within an approximately 16-pixel box.
test_player_object_overlap
	lda PLAYER_X
	clc
	adc #$08
	sbc DRAW_X
	cmp #$10
	bcs .no_player_object_overlap
	lda PLAYER_Y
	clc
	adc #$08
	sbc DRAW_Y
	cmp #$10
	bcs .no_player_object_overlap
	lda #$00
	rts

.no_player_object_overlap
	lda #$01
	rts

;--------------------------------------------------------------------------------------------------
; Configure the VIC for a 22-column by 11-row double-height character display. The screen matrix is
; at _SCREEN_MATRIX_ADDR, colour RAM at _COLOUR_SCREEN_ADDR, and writable character graphics at
; _CHARACTER_BITMAP_ADDR through _CHARACTER_BITMAP_END-1.
configure_display
    ; Set the screen and pixel bitmap memory addresses
    ;   bit 7-4: 1000. Bit 7 needs to viewed as 0 (see COMPUTE! Mapping the VIC page 129) so these bits
    ;   are now 0000. To complete the 14-bit screen map address location, _VIC_CR2 bit 7 is added (is 1)
    ;   and completes with bits 0 0000 0000. The result is 0000 10 0000 0000 which means the
    ;   screen matrix is located at _SCREEN_MATRIX_ADDR (512), and colour map at
    ;   _COLOUR_SCREEN_ADDR (38400)
    ;   bit 3-0: 1100 means the pixel bitmaps are located at _CHARACTER_BITMAP_ADDR (4096)
	lda #%10001100  ;$8c
	sta _VIC_CR5

    ; Set the number of columns displayed
    ;   bit 7: see _VIC_CR5 above
    ;   bit 6-0: 22 means 22 characters per column
	lda #%10010110  ;$96
	sta _VIC_CR2

    ; Set number of rows displayed
    ;   bit 7: raster beam location bit 0 (n/a here)
    ;   bit 6-1: 22 means 11 character lines / rows
    ;   bit 0: 1 tall characters (16-pixels tall by 8 pixels wide)
	lda #%00010111  ;$17
	sta _VIC_CR3

	lda #5
	sta _VIC_SCREEN_LEFT_EDGE
	lda #25
	sta _VIC_SCREEN_TOP_EDGE

	lda #%00001111  ;volume max 15
	sta _VIC_VOLUME_AUX_COLOUR
	lda #8  ;black background and border
	sta _VIC_BG_BORDER_COL

;--------------------------------------------------------------------------------------------------
; Populate the screen matrix with character codes that make writable character memory behave as a
; 176-by-176 software framebuffer, initialize colour RAM, and clear all character bitmap bytes.
clear_and_build_framebuffer
	lda #>_SCREEN_MATRIX_ADDR
	sta FRAMEBUFFER_PTR+1
	lda #<_SCREEN_MATRIX_ADDR
	sta FRAMEBUFFER_PTR
	ldx #$0b
.build_next_screen_column
	ldy #$00
.write_next_screen_code
	sta (FRAMEBUFFER_PTR),y
	clc
	adc #$0b
	iny
	cpy #$16
	bne .write_next_screen_code
	pha
	lda FRAMEBUFFER_PTR
	clc
	adc #$16
	sta FRAMEBUFFER_PTR
	pla
	sec
	sbc #$f1
	dex
	bne .build_next_screen_column
	ldx #$00
	lda #$01
.initialize_colour_memory
	sta _COLOUR_SCREEN_ADDR,x
	sta _COLOUR_SCREEN_ADDR+$100,x
	dex
	bne .initialize_colour_memory
	lda #<_CHARACTER_BITMAP_ADDR
	sta FRAMEBUFFER_PTR
	lda #>_CHARACTER_BITMAP_ADDR
	sta FRAMEBUFFER_PTR+1
.clear_next_bitmap_page
	lda #$00
	tay
.clear_next_bitmap_byte
	sta (FRAMEBUFFER_PTR),y
	inc FRAMEBUFFER_PTR
	bne .clear_next_bitmap_byte
	inc FRAMEBUFFER_PTR+1
	lda FRAMEBUFFER_PTR+1
	cmp #>_CHARACTER_BITMAP_END
	bne .clear_next_bitmap_page
	rts

;--------------------------------------------------------------------------------------------------
; XOR a variable-height, one-byte-wide source graphic at arbitrary pixel coordinates. Split shifted
; bytes across adjacent framebuffer columns; drawing the same image twice erases it.
xor_draw_shifted_bitmap
	sta GRAPHIC_LAST_BYTE
	txa
	pha
	jsr calculate_framebuffer_address
	cmp #$04
	bcs .draw_left_shifted_graphic
	ldy GRAPHIC_LAST_BYTE
.draw_next_right_shifted_row
	lda (GRAPHIC_PTR),y
	sta SHIFTED_BYTE_LOW
	lda #$00
	ldx PIXEL_SHIFT
	beq .store_right_shifted_row
.shift_graphic_right
	lsr SHIFTED_BYTE_LOW
	ror
	dex
	bne .shift_graphic_right
.store_right_shifted_row
	sta SHIFTED_BYTE_HIGH
	lda (FRAMEBUFFER_PTR),y
	eor SHIFTED_BYTE_LOW
	sta (FRAMEBUFFER_PTR),y
	tya
	tax
	clc
	adc #$b0
	tay
	lda (FRAMEBUFFER_PTR),y
	eor SHIFTED_BYTE_HIGH
	sta (FRAMEBUFFER_PTR),y
	txa
	tay
	dey
	bpl .draw_next_right_shifted_row
	pla
	tax
	rts

.draw_left_shifted_graphic
	ldy GRAPHIC_LAST_BYTE
.draw_next_left_shifted_row
	lda (GRAPHIC_PTR),y
	sta SHIFTED_BYTE_HIGH
	lda PIXEL_SHIFT
	eor #$07
	clc
	adc #$01
	tax
	lda #$00
.shift_graphic_left
	asl SHIFTED_BYTE_HIGH
	rol
	dex
	bne .shift_graphic_left
	sta SHIFTED_BYTE_LOW
	lda (FRAMEBUFFER_PTR),y
	eor SHIFTED_BYTE_LOW
	sta (FRAMEBUFFER_PTR),y
	tya
	tax
	clc
	adc #$b0
	tay
	lda (FRAMEBUFFER_PTR),y
	eor SHIFTED_BYTE_HIGH
	sta (FRAMEBUFFER_PTR),y
	txa
	tay
	dey
	bpl .draw_next_left_shifted_row
	pla
	tax
	rts

;--------------------------------------------------------------------------------------------------
; High and low bytes for the 22 possible pixel-X columns in the 176-pixel framebuffer.
framebuffer_column_high_bytes
	!byte $10,$10,$11,$12,$12,$13,$14,$14,$15,$16,$16
	!byte $17,$18,$18,$19,$1a,$1b,$1b,$1c,$1d,$1d,$1e
framebuffer_column_low_bytes
	!byte $00,$b0,$60,$10,$c0,$70,$20,$d0,$80,$30,$e0
	!byte $90,$40,$f0,$a0,$50,$00,$b0,$60,$10,$c0,$70

;--------------------------------------------------------------------------------------------------
; Combine the joystick lines from both VIAs into JOYSTICK_STATE. Bits are active-low:
; up=$04, down=$08, left=$10, fire=$20, right=$80.
read_joystick
	lda #$7f
	sta _VIA_DATADIR_B
	lda _VIA_KEYB_ROWS
	and #$80
	sta JOYSTICK_STATE
	lda _VIA_JOYSTICK_MIRROR
	and #$3c
	ora JOYSTICK_STATE
	sta JOYSTICK_STATE
	rts

;--------------------------------------------------------------------------------------------------
; Mix raster position, joystick input, counters, drawing state, and the previous value into the
; lightweight RANDOM_STATE byte. Carry is intentionally part of the mixer.
update_random_number
	adc DRAW_X
	adc DRAW_Y
	adc _VIC_CR4
	adc (FRAMEBUFFER_PTR,x)
	adc RANDOM_STATE
	adc _VIA_JOYSTICK_MIRROR
	adc FRAMEBUFFER_PTR
	adc SCORE_BCD+2
	adc JOYSTICK_STATE
	adc FRAME_COUNTER
	sta RANDOM_STATE
	rts

;--------------------------------------------------------------------------------------------------
; Convert a screen character code into its eight-byte uppercase/graphics ROM bitmap address.
get_character_bitmap_address
	sta GRAPHIC_PTR
	lda #$00
	sta GRAPHIC_PTR+1
	asl GRAPHIC_PTR
	rol GRAPHIC_PTR+1
	asl GRAPHIC_PTR
	rol GRAPHIC_PTR+1
	asl GRAPHIC_PTR
	rol GRAPHIC_PTR+1
	clc
	lda GRAPHIC_PTR+1
	adc #>_CHARACTER_ROM_ADDR
	sta GRAPHIC_PTR+1
	rts

;--------------------------------------------------------------------------------------------------
; Draw one eight-row character-ROM glyph through the XOR bitmap renderer.
draw_character
	jsr get_character_bitmap_address
	lda #$07
	jmp xor_draw_shifted_bitmap

;--------------------------------------------------------------------------------------------------
; Convert DRAW_X/DRAW_Y into FRAMEBUFFER_PTR and PIXEL_SHIFT for the linearized 176-pixel-wide
; bitmap. The high/low lookup tables avoid a general multiplication.
calculate_framebuffer_address
	lda DRAW_X
	lsr
	lsr
	lsr
	tax
	lda framebuffer_column_high_bytes,x
	sta FRAMEBUFFER_PTR+1
	lda framebuffer_column_low_bytes,x
	clc
	adc DRAW_Y
	sta FRAMEBUFFER_PTR
	lda FRAMEBUFFER_PTR+1
	adc #$00
	sta FRAMEBUFFER_PTR+1
	lda DRAW_X
	and #$07
	sta PIXEL_SHIFT
	rts


;--------------------------------------------------------------------------------------------------
; Bitmap graphics are kept separately because the binary row data is substantially larger than
; the surrounding game logic.
	!source "bitmap-graphics.asm"

;--------------------------------------------------------------------------------------------------
; There are 34 four-byte records: rooms $00-$1f, an otherwise unreachable $20 record, and the
; lair at $21. draw_room_layout indexes this table with ROOM_NUMBER*4. Each bit selects one fixed
; wall segment from the four named placement tables above. Thus the entire
; room maze occupies only 136 bytes.
room_layout_bytes
room_vertical_bits_b
	!byte $24
room_vertical_bits_a
	!byte $9b
room_horizontal_bits_b
	!byte $e7
room_horizontal_bits_a
	!byte $f6
	!byte $18,$00,$9b,$d8  ;room $01
	!byte $34,$b3,$67,$e6  ;room $02
	!byte $00,$93,$d7,$d4  ;room $03
	!byte $24,$90,$7f,$fe  ;room $04
	!byte $18,$01,$80,$d8  ;room $05
	!byte $24,$95,$e7,$27  ;room $06
	!byte $0c,$93,$a7,$d4  ;room $07
	!byte $24,$b3,$67,$f6  ;room $08
	!byte $28,$93,$57,$e5  ;room $09
	!byte $98,$60,$58,$d8  ;room $0a
	!byte $98,$64,$18,$18  ;room $0b
	!byte $0c,$c4,$ab,$15  ;room $0c
	!byte $24,$92,$e7,$e7  ;room $0d
	!byte $18,$00,$9b,$d8  ;room $0e
	!byte $00,$a2,$80,$d4  ;room $0f
	!byte $24,$93,$3c,$3e  ;room $10
	!byte $a4,$96,$b4,$36  ;room $11
	!byte $18,$02,$9b,$00  ;room $12
	!byte $18,$01,$80,$d8  ;room $13
	!byte $24,$97,$a7,$26  ;room $14
	!byte $00,$00,$9b,$d9  ;room $15
	!byte $3c,$f0,$67,$e6  ;room $16
	!byte $6c,$90,$67,$e5  ;room $17
	!byte $98,$94,$94,$14  ;room $18
	!byte $00,$62,$1b,$01  ;room $19
	!byte $28,$50,$57,$ea  ;room $1a
	!byte $24,$90,$67,$e6  ;room $1b
	!byte $00,$93,$d7,$d4  ;room $1c
	!byte $98,$a0,$18,$d6  ;room $1d
	!byte $28,$a4,$9b,$27  ;room $1e
	!byte $34,$91,$67,$e7  ;room $1f
	!byte $34,$91,$67,$e7  ;room $20
	!byte $64,$98,$67,$e6  ;room $21
;--------------------------------------------------------------------------------------------------
; One spawn-position mask per ordinary room. Set bits select candidates through bit_selection_masks.
room_spawn_position_masks
	!byte $eb,$08,$eb,$e0,$eb,$08,$eb,$a0
	!byte $eb,$ea,$4c,$1c,$18,$eb,$08,$80
	!byte $ab,$bf,$08,$08,$bb,$08,$eb,$ee
	!byte $bc,$08,$6b,$eb,$e0,$8d,$9b,$eb

;--------------------------------------------------------------------------------------------------
; The compact VIC-20 progression is LEVEL ONE -> LEVEL TWO -> LAIR. Defeating the lair target
; restarts at level one with SKILL_LEVEL forced to EXPERT, so subsequent cycles run at top speed.
advance_to_next_level
	inc LEVEL_NUMBER
	jsr award_level_completion_bonus
	jmp reset_level_state

;--------------------------------------------------------------------------------------------------
; Redraw the current room after collecting a key or opening a keyhole without respawning enemies.
rebuild_current_room_after_object_change
	jsr clear_and_build_framebuffer
	jsr draw_room_layout
	jsr clear_transient_entities
	jmp initialize_room_runtime_state

;--------------------------------------------------------------------------------------------------
; Show the title/calibration sequence and initialize a new score, life count, and Level One game.
start_new_game
	jsr silence_sound_generators
	jsr show_title_and_calibration_screen
	lda #$03
	sta LIVES_REMAINING
	lda reset_level_state             ;discarded absolute load retained from the original
	lda #$00
	sta SCORE_BCD
	sta SCORE_BCD+1
	sta SCORE_BCD+2
	sta LEVEL_NUMBER
	sta ROOM_EXIT_RUSH_TIMER
;--------------------------------------------------------------------------------------------------
; Reset keys, persistent room objects, room number, barrier state, and Shamus's starting position.
reset_level_state
	lda #$00
	sta KEY_FLAGS
	sta ROOM_NUMBER
	ldx #$03
.clear_next_persistent_object_flag
	sta EXTRA_LIFE_COLLECTED_FLAGS,x
	sta MYSTERY_COLLECTED_FLAGS,x
	dex
	bpl .clear_next_persistent_object_flag
	lda #$03
	sta ROOM_27_BARRIER_PHASE
	lda #$0a
	sta PLAYER_X
	lda #$42
	sta PLAYER_Y
;--------------------------------------------------------------------------------------------------
; Rebuild the current room: clear the framebuffer, draw its walls and persistent objects, choose
; enemy populations, reset transient state and timers, then enter the main loop.
initialize_current_room
	lda ROOM_NUMBER
	cmp #$20
	beq advance_to_next_level
	jsr clear_and_build_framebuffer
	jsr draw_room_layout
	jsr initialize_room_enemies
	jsr clear_transient_entities
	lda initialize_room_runtime_state  ;discarded absolute load retained from the original
;--------------------------------------------------------------------------------------------------
; Restore the animated wall seeds, draw Shamus/HUD, clear runtime timers, prepare the Lair when
; applicable, and derive ordinary-enemy speed from the current room number.
initialize_room_runtime_state
	ldx #$0f
.restore_next_electric_wall_byte
	lda electric_horizontal_wall_seed_bitmap,x
	sta ELECTRIC_HORIZONTAL_WALL_BITMAP,x
	lda electric_vertical_wall_seed_bitmap,x
	sta ELECTRIC_VERTICAL_WALL_BITMAP,x
	dex
	bpl .restore_next_electric_wall_byte
	jsr read_joystick
	jsr draw_player
	jsr draw_lives_remaining
	jsr draw_score_and_high_score
	inc FRAME_COUNTER
	jsr silence_sound_generators
	lda #$00
	sta LAIR_HIT_COUNT
	sta EXPLOSION_SOUND_TIMER
	sta SHADOW_APPEARANCE_TIMER
	sta SHADOW_HIT_TIMER
	sta SHADOW_X
	sta TITLE_MUSIC_DELAY
	sta REWARD_SOUND_TIMER
	sta ROOM_SPEED_INDEX
	sta ION_SHIV_SOUND_TIMER
	lda LEVEL_NUMBER
	cmp #$02
	bne .initialize_room_timing
	lda #$58
	sta LAIR_TARGET_X
	sta LAIR_TARGET_Y
	lda #$03
	sta SHADOW_APPEARANCE_TIMER
	sta+2 SHADOW_APPEARANCE_TIMER    ;force the original three-byte absolute store
	jsr draw_lair_target
.initialize_room_timing
	lda #$28
	sta ROOM_EXIT_RUSH_TIMER
	lda ROOM_NUMBER
	beq main_game_loop
	lsr
	lsr
	lsr
	sta ROOM_SPEED_INDEX
	inc ROOM_SPEED_INDEX
;--------------------------------------------------------------------------------------------------
; Central game dispatcher. Update shots, Shamus, all three enemy species, explosions, the Shadow,
; objects, lair state, sound, delay and counters before testing death or a room transition.
main_game_loop
	jsr update_enemy_shots
	jsr update_player
	jsr update_player_shots
	jsr update_spiral_drones
	jsr update_robo_droids
	jsr animate_electric_walls
	jsr update_explosions
	jsr update_snap_jumpers
	jsr update_random_number
	lda ROOM_NUMBER                    ;redundant zero-page load retained from the original
	lda+2 ROOM_NUMBER                  ;force the original three-byte absolute load
	cmp #$1b
	beq .preserve_room_27_barrier_state
	lda #$03
	sta ROOM_27_BARRIER_PHASE
.preserve_room_27_barrier_state
	jsr handle_pause_key
	lda LEVEL_NUMBER
	cmp #$02
	beq .skip_shadow_update_in_lair
	jsr update_shadow
.skip_shadow_update_in_lair
	lda ROOM_NUMBER
	beq .skip_extra_enemy_shot_update
	lda LEVEL_NUMBER
	bne .perform_extra_enemy_shot_update
	lda FRAME_COUNTER
	and #$01
	bne .skip_extra_enemy_shot_update
.perform_extra_enemy_shot_update
	jsr update_enemy_shots
.skip_extra_enemy_shot_update
	jsr update_extra_life_object
	jsr update_bonus_object
	lda LEVEL_NUMBER
	cmp #$02
	bne .skip_lair_target_update
	jsr update_lair_target
.skip_lair_target_update
	jsr update_game_sound_effects
	jsr apply_skill_level_delay
	jsr update_random_number
	inc FRAME_COUNTER
	lda ROOM_EXIT_RUSH_TIMER
	beq .room_rush_timer_done
	dec ROOM_EXIT_RUSH_TIMER
.room_rush_timer_done
	jmp handle_player_collision_and_room_exit

;--------------------------------------------------------------------------------------------------
; Tom Griner's embedded anti-piracy message, followed by unused cartridge ROM padding.
anti_piracy_message
	!pet "what a horrible mess!this program has great amounts of wasted "
	!pet "rom space... note to prospective software pirates: this progra"
	!pet "m was written by tom griner 777-36 san antonio rd. palo alto c"
	!pet "alifornia...i would loose money if you distribute stolen copie"
	!pet "s of this program...so, rather than steal this, write me a let"
	!pet "ter and i will send you some free software... this may sound s"
	!pet "illy, but i would really hate to have people stealing my progr"
	!pet "ams...by the way: it is illegal to copy this program  ........"
	!pet "............this space for rent......help, i am trapped in a v"
	!pet "ic-20 cartridge..."
.unused_rom_padding
	!fill 867,$aa
