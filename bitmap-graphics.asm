;--------------------------------------------------------------------------------------------------
; Bitmap graphics. Each comment gives the original address, gameplay identity and frame where
; applicable. Rows are binary so the eight-pixel shape remains visible in the source.

; $B6D3  initial 16-row vertical electric-wall character
electric_vertical_wall_seed_bitmap
	!byte %10000001
	!byte %10000001
	!byte %10000001
	!byte %10011001
	!byte %10100101
	!byte %11011011
	!byte %10100101
	!byte %11000011

	!byte %10000001
	!byte %10000001
	!byte %10000001
	!byte %10011001
	!byte %10100101
	!byte %11011011
	!byte %10100101
	!byte %11000011

; $B6E3  initial 16-row horizontal electric-wall character
electric_horizontal_wall_seed_bitmap
	!byte %11111111
	!byte %10100000
	!byte %10100000
	!byte %01010000
	!byte %01010000
	!byte %00101000
	!byte %00101000
	!byte %00010100
	!byte %00010100
	!byte %00101000
	!byte %00101000
	!byte %01010000
	!byte %01010000
	!byte %10100000
	!byte %10100000
	!byte %11111111

; $B6F3  KEYHOLE_GRAPHIC (16 rows)
KEYHOLE_GRAPHIC
	!byte %00111100
	!byte %01111110
	!byte %01111110
	!byte %11111111
	!byte %11111111
	!byte %11000011
	!byte %10000001
	!byte %10000001
	!byte %11000011
	!byte %11100111
	!byte %11100111
	!byte %11100111
	!byte %11111111
	!byte %01111110
	!byte %01111110
	!byte %00111100

; $B703  KEY_GRAPHIC (12 rows)
KEY_GRAPHIC
	!byte %11100000
	!byte %11100000
	!byte %10100000
	!byte %10100000
	!byte %10100000
	!byte %10111111
	!byte %10111111
	!byte %10101110
	!byte %10101110
	!byte %10101010
	!byte %11101010
	!byte %11100000

; $B70F  QUESTION_GRAPHIC_1 (10 rows)
QUESTION_GRAPHIC_1
	!byte %00111100
	!byte %01100110
	!byte %11000011
	!byte %01100110
	!byte %00000110
	!byte %00001100
	!byte %00011000
	!byte %00000000
	!byte %00011000
	!byte %00011000

; $B719  QUESTION_GRAPHIC_2 (10 rows)
QUESTION_GRAPHIC_2
	!byte %00000000
	!byte %00111100
	!byte %01100110
	!byte %00001100
	!byte %00001100
	!byte %00011000
	!byte %00000000
	!byte %00011000
	!byte %00011000
	!byte %00000000

; $B723  EXTRA_LIFE_BOTTLE_1 (11 rows)
EXTRA_LIFE_BOTTLE_1
	!byte %00111000
	!byte %00010000
	!byte %00010000
	!byte %00010000
	!byte %00111000
	!byte %01000100
	!byte %10100010
	!byte %10001010
	!byte %10010010
	!byte %01000100
	!byte %01111100

; $B72E  EXTRA_LIFE_BOTTLE_2 (11 rows)
EXTRA_LIFE_BOTTLE_2
	!byte %00111000
	!byte %00010000
	!byte %00010000
	!byte %00010000
	!byte %00111000
	!byte %01000100
	!byte %10010010
	!byte %10100010
	!byte %10001010
	!byte %01000100
	!byte %01111100

; $B739  ROBO_DROID frame 1
ROBO_DROID_FRAME_1
	!byte %00111100
	!byte %00011100
	!byte %11111111
	!byte %10111101
	!byte %10011001
	!byte %00100010
	!byte %00000000
	!byte %01001001

; $B741  ROBO_DROID frame 2
ROBO_DROID_FRAME_2
	!byte %00111100
	!byte %00101100
	!byte %11111111
	!byte %10111101
	!byte %10011001
	!byte %00010001
	!byte %01000000
	!byte %00010010

; $B749  ROBO_DROID frame 3
ROBO_DROID_FRAME_3
	!byte %00111100
	!byte %00110100
	!byte %11111111
	!byte %10111101
	!byte %10011001
	!byte %01001000
	!byte %00000001
	!byte %00100100

; $B751  ROBO_DROID frame 4
ROBO_DROID_FRAME_4
	!byte %00111100
	!byte %00111000
	!byte %11111111
	!byte %10111101
	!byte %10011001
	!byte %00100100
	!byte %00000000
	!byte %01001001

; $B759  SHADOW frame 1
SHADOW_FRAME_1
	!byte %01111100
	!byte %01010100
	!byte %01010100
	!byte %01111100
	!byte %00010000
	!byte %00000000
	!byte %00111000
	!byte %00101000
	!byte %00101000
	!byte %00101000
	!byte %00101000
	!byte %01101100

; $B765  SHADOW frame 2
SHADOW_FRAME_2
	!byte %01111100
	!byte %01010100
	!byte %01010100
	!byte %01111100
	!byte %00010000
	!byte %00000000
	!byte %00111000
	!byte %01000100
	!byte %10000010
	!byte %01101100
	!byte %00101000
	!byte %00000000

; $B771  SPIRAL_DRONE frame 1
SPIRAL_DRONE_FRAME_1
	!byte %01000110
	!byte %11000011
	!byte %10111100
	!byte %00111100
	!byte %00111100
	!byte %00111101
	!byte %11000011
	!byte %01100010

; $B779  SPIRAL_DRONE frame 2
SPIRAL_DRONE_FRAME_2
	!byte %00011100
	!byte %00001000
	!byte %10111100
	!byte %11111101
	!byte %10111111
	!byte %00111101
	!byte %00010000
	!byte %00111000

; $B781  SPIRAL_DRONE frame 3
SPIRAL_DRONE_FRAME_3
	!byte %00111000
	!byte %00010000
	!byte %00111101
	!byte %10111111
	!byte %11111101
	!byte %10111100
	!byte %00001000
	!byte %00011100

; $B789  SPIRAL_DRONE frame 4
SPIRAL_DRONE_FRAME_4
	!byte %01110000
	!byte %00100001
	!byte %00111111
	!byte %00111101
	!byte %10111100
	!byte %11111100
	!byte %10000100
	!byte %00001110

; $B791  SNAP_JUMPER_GRAPHIC
SNAP_JUMPER_GRAPHIC
	!byte %11111111
	!byte %10000001
	!byte %10100101
	!byte %10000001
	!byte %11111111
	!byte %01000010
	!byte %01000010
	!byte %11100111

; $B799  SHAMUS vertical, frame 1 (shared by up and down)
SHAMUS_FRAME_1
	!byte %00111000
	!byte %01111100
	!byte %00000000
	!byte %01111100
	!byte %01010100
	!byte %01111100
	!byte %00010000
	!byte %11111110
	!byte %00111000
	!byte %00101000
	!byte %01101100

; $B7A4  SHAMUS vertical, frame 2 (shared by up and down)
SHAMUS_VERTICAL_FRAME_2
	!byte %00111000
	!byte %01111100
	!byte %00000000
	!byte %01111100
	!byte %01010100
	!byte %01111100
	!byte %10010010
	!byte %01111100
	!byte %00111000
	!byte %01101100
	!byte %00000000

; $B7AF  SHAMUS right, frame 1
SHAMUS_RIGHT_FRAME_1
	!byte %00111000
	!byte %01111100
	!byte %00000000
	!byte %00111100
	!byte %00110110
	!byte %00111100
	!byte %00010000
	!byte %00011100
	!byte %00010000
	!byte %00101010
	!byte %01100100

; $B7BA  SHAMUS right, frame 2
SHAMUS_RIGHT_FRAME_2
	!byte %00111000
	!byte %01111100
	!byte %00000000
	!byte %00111100
	!byte %00110110
	!byte %00111100
	!byte %00010000
	!byte %00011110
	!byte %00110000
	!byte %01010000
	!byte %00111000

; $B7C5  SHAMUS left, frame 1
SHAMUS_LEFT_FRAME_1
	!byte %00011100
	!byte %00111110
	!byte %00000000
	!byte %00111100
	!byte %01101100
	!byte %00111100
	!byte %00001000
	!byte %00111000
	!byte %00001000
	!byte %01010100
	!byte %00100110

; $B7D0  SHAMUS left, frame 2
SHAMUS_LEFT_FRAME_2
	!byte %00011100
	!byte %00111110
	!byte %00000000
	!byte %00111100
	!byte %01101100
	!byte %00111100
	!byte %00001000
	!byte %01111000
	!byte %00001100
	!byte %00001010
	!byte %00011100

; $B7DB  ION_SHIV direction 0
ION_SHIV_FRAME_1
	!byte %00010000
	!byte %00111000
	!byte %00111000
	!byte %00010000
	!byte %00111000
	!byte %00010000
	!byte %00010000
	!byte %00010000

; $B7E3  ION_SHIV direction 1
ION_SHIV_DIRECTION_1
	!byte %00000110
	!byte %00001110
	!byte %00001100
	!byte %00110000
	!byte %00110000
	!byte %01000000
	!byte %10000000
	!byte %00000000

; $B7EB  ION_SHIV direction 2
ION_SHIV_DIRECTION_2
	!byte %00000000
	!byte %00000000
	!byte %00010110
	!byte %11111111
	!byte %00010110
	!byte %00000000
	!byte %00000000
	!byte %00000000

; $B7F3  ION_SHIV direction 3
ION_SHIV_DIRECTION_3
	!byte %00000000
	!byte %10000000
	!byte %01000000
	!byte %00110000
	!byte %00110000
	!byte %00001100
	!byte %00001110
	!byte %00000110

; $B7FB  ION_SHIV direction 4
ION_SHIV_DIRECTION_4
	!byte %00010000
	!byte %00010000
	!byte %00010000
	!byte %00111000
	!byte %00010000
	!byte %00111000
	!byte %00111000
	!byte %00010000

; $B803  ION_SHIV direction 5
ION_SHIV_DIRECTION_5
	!byte %00000000
	!byte %00000010
	!byte %00000100
	!byte %00011000
	!byte %00011000
	!byte %01100000
	!byte %11100000
	!byte %11000000

; $B80B  ION_SHIV direction 6
ION_SHIV_DIRECTION_6
	!byte %00000000
	!byte %00000000
	!byte %01101000
	!byte %11111111
	!byte %01101000
	!byte %00000000
	!byte %00000000
	!byte %00000000

; $B813  ION_SHIV direction 7
ION_SHIV_DIRECTION_7
	!byte %11000000
	!byte %11100000
	!byte %01100000
	!byte %00011000
	!byte %00011000
	!byte %00000100
	!byte %00000010
	!byte %00000000

; $B81B  explosion frame 1
EXPLOSION_FRAME_1
	!byte %00011000
	!byte %01100110
	!byte %10101001
	!byte %01001010
	!byte %01010110
	!byte %10110001
	!byte %01101010
	!byte %00110100

; $B823  explosion frame 2
EXPLOSION_FRAME_2
	!byte %00010100
	!byte %01000100
	!byte %00100101
	!byte %10001011
	!byte %01010110
	!byte %01100101
	!byte %00111010
	!byte %00011000

; $B82B  explosion frame 3
EXPLOSION_FRAME_3
	!byte %00000000
	!byte %00011000
	!byte %00101000
	!byte %00100100
	!byte %01011000
	!byte %00110100
	!byte %00001000
	!byte %00000000

; $B833  explosion frame 4
EXPLOSION_FRAME_4
	!byte %00000000
	!byte %00000000
	!byte %00101000
	!byte %00010000
	!byte %00011000
	!byte %00000000
	!byte %00000000
	!byte %00000000

; $B83B  enemy shot, horizontal graphic
ENEMY_SHOT_GRAPHIC_1
	!byte %00000000
	!byte %11100000
	!byte %00000000

; $B83E  enemy shot, vertical/diagonal graphic
ENEMY_SHOT_VERTICAL_GRAPHIC
	!byte %01000000
	!byte %01000000
	!byte %01000000

; $B841  left third of Shamus's "OUCH!" death graphic
SHAMUS_DEATH_OUCH_LEFT
	!byte %00111111
	!byte %01000000
	!byte %10001001
	!byte %10010101
	!byte %10010101
	!byte %10010101
	!byte %10001001
	!byte %01000000
	!byte %00110001
	!byte %00010010
	!byte %00101100
	!byte %01110000

; $B84D  middle third of Shamus's "OUCH!" death graphic
SHAMUS_DEATH_OUCH_MIDDLE
	!byte %11111111
	!byte %00000000
	!byte %01001001
	!byte %01010101
	!byte %01010001
	!byte %01010101
	!byte %11001001
	!byte %00000000
	!byte %11111111
	!byte %00000000
	!byte %00000000
	!byte %00000000

; $B859  right third of Shamus's "OUCH!" death graphic
SHAMUS_DEATH_OUCH_RIGHT
	!byte %11111100
	!byte %00000010
	!byte %01001001
	!byte %01001001
	!byte %11001001
	!byte %01000001
	!byte %01001001
	!byte %00000010
	!byte %11111100
	!byte %00000000
	!byte %00000000
	!byte %00000000

; $B865  lair target, left half
LAIR_TARGET_LEFT_GRAPHIC
	!byte %11111111
	!byte %11111111
	!byte %11000011
	!byte %11000011
	!byte %11000011
	!byte %11000011
	!byte %11111111
	!byte %11111111
	!byte %00000011
	!byte %00000011
	!byte %00000000
	!byte %00000000
	!byte %00111111
	!byte %00111111
	!byte %00110000
	!byte %00110000
	!byte %00110000
	!byte %00110000
	!byte %00110000
	!byte %00110000
	!byte %00110000
	!byte %00110000
	!byte %11110000
	!byte %11110000

; $B87D  lair target, right half
LAIR_TARGET_RIGHT_GRAPHIC
	!byte %11111100
	!byte %11111100
	!byte %00001100
	!byte %00001100
	!byte %00001100
	!byte %00001100
	!byte %11111100
	!byte %11111100
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %00000000
	!byte %11110000
	!byte %11110000
	!byte %00110000
	!byte %00110000
	!byte %00110000
	!byte %00110000
	!byte %00110000
	!byte %00110000
	!byte %00110000
	!byte %00110000
	!byte %00111100
	!byte %00111100
