# Shamus VIC-20 maze and progression notes

These notes describe behaviour verified directly from `main.asm`. Room numbers are decimal; encoded
bytes, addresses and masks retain their hexadecimal or binary representation.

## Room-number coordinate system

Each room begins with four compressed wall bitfields. `draw_room_layout` tests every byte against
`bit_selection_masks` (`$80,$40,...,$01`). A set bit selects the corresponding fixed screen-matrix
position from one of four placement tables:

- `vertical_wall_positions_a` and `vertical_wall_positions_b` select four-cell vertical segments;
- `horizontal_wall_positions_a` and `horizontal_wall_positions_b` select four- or five-cell
  horizontal segments, shortened where a segment meets a framebuffer row join;
- the four bytes are interleaved per room, so the record address is `ROOM_NUMBER * 4`;
- entering the lair forces room record 33, while record 32 is not selected by normal play.

Ordinary rooms use a six-column coordinate system. Crossing a horizontal edge changes the room by
one; crossing a vertical edge changes it by six.

```text
 0   1   2   3   4   5
 6   7   8   9  10  11
12  13  14  15  16  17
18  19  20  21  22  23
24  25  26  27  28  29
30  31
```

The four bytes for each room are not simple exit flags. They are four wall-segment bitfields. Each
set bit selects a fixed horizontal or vertical segment from `vertical_wall_positions_a`,
`vertical_wall_positions_b`, `horizontal_wall_positions_a`, or `horizontal_wall_positions_b`.
Together the 34 records occupy only 136 bytes.

Record 32 is present but ordinary room initialization advances the level as soon as the room
number reaches 32, so it is not drawn as a normal room. Record 33 is explicitly selected for
the lair.

## Keys and keyholes

There are three persistent key/keyhole pairs:

| Colour | Key room | Key flag | Keyhole room | Open flag |
|---|---:|---:|---:|---:|
| Red | 17 | `%10000000` (`$80`) | 9 | `%00001000` (`$08`) |
| White | 6 | `%01000000` (`$40`) | 20 | `%00000100` (`$04`) |
| Blue | 16 | `%00100000` (`$20`) | 31 | `%00000010` (`$02`) |

Touching a key records its high-bit flag. Touching the corresponding keyhole only succeeds when
that key flag is present, after which the low-bit open flag is recorded and the room is rebuilt.
Until that low-bit flag is set, room construction adds a four-cell electric-wall segment behind the
keyhole. Collected keys and opened keyholes are also redrawn in the lower-right inventory display.

## Persistent room objects

Extra-life bottles appear once in rooms 1, 2, 12 and 26.

Mystery question marks appear once in rooms 0, 8, 11 and 24. Their five accepted
outcomes are:

1. Force the Shadow to appear.
2. Add one life.
3. Select the slowest enemy update rate.
4. Select the fastest enemy update rate.
5. Award 500 points.

Random values 5-7 are rejected and rerolled; accepted values 0-4 map one-to-one to these results.

Room 27 contains a yellow central barrier made from the animated `$FE` electric-wall character.
Every eight main-loop iterations its two-character-high gap advances by two screen rows through one
of eight positions. The unlock test scans the three ION SHIV X coordinates only: any active SHIV in
the central band 80-109 changes the barrier state to `$FF` and rebuilds the room without it. It
does not compare the SHIV's Y coordinate with the currently displayed gap.

No ordinary enemies are spawned in room 27 while the barrier exists. Once it has been removed, all
seven slots of all three enemy species are placed at central X coordinate 88, with independent
random Y coordinates from 32-95. The Robo Droids also receive random directions.

## The room-rushing penalty

Room initialization sets a 40-iteration countdown. It is decremented once per main-loop iteration.
When the next room is entered, a nonzero countdown forces all seven slots of all three ordinary
enemy species to be populated. If the countdown has expired, the starting count is randomized.

This is a per-room traversal penalty, not a timer for completing the whole level. Dying clears the
timer before the room is rebuilt.

## Enemy speed

Maze depth selects an update-rate mask independently of the title-screen skill setting:

| Rooms | Mask | Enemy update opportunity |
|---|---:|---:|
| 0 | `%00001111` (`$0F`) | every 16 main-loop iterations |
| 1-7 | `%00000111` (`$07`) | every 8 main-loop iterations |
| 8-15 | `%00000011` (`$03`) | every 4 main-loop iterations |
| 16-23 | `%00000001` (`$01`) | every 2 main-loop iterations |
| 24-31 | `%00000000` (`$00`) | every iteration |

The mystery object's slow and fast outcomes force indices zero and five respectively. The four
skill settings - Beginner, Novice, Advanced, and Expert - change a separate busy-wait delay, with
Expert removing the inner delay completely.

## Shadow timing

The Shadow timer advances approximately once per 256 main-loop iterations. State two produces the
warning sound near the end of that cycle; state three releases the Shadow. A mystery result can set
the timer directly to five, causing immediate release on the next update.

ION SHIVs stun the Shadow temporarily but cannot destroy it.

## Scoring and progression

- An ordinary enemy is worth 50 displayed points.
- The mystery score award is 500 points.
- Level completion calls the 50-point routine 256 times: 12,800 points.
- The lair target requires 20 ION SHIV hits.

Internally, score and high score use three packed binary-coded decimal (BCD) bytes. The renderer
suppresses leading zeroes and appends one fixed zero, so adding stored BCD `$000005` produces the
displayed award `50`.

The compact VIC-20 level sequence is Level One, Level Two, then the Lair. This is independent of the
title-screen skill sequence Beginner, Novice, Advanced, and Expert. Advancing from Level One to
Level Two and then to the Lair preserves the selected skill. Defeating the Lair target returns to
Level One and only then forces the skill setting to Expert.

## Enemy spawn positions

Each ordinary room has one byte in `room_spawn_position_masks`. Its eight bits correspond to eight
candidate cells in a coarse three-by-three grid; the bottom-right cell is omitted. A set bit permits
that candidate for the room. Enemy initialization repeatedly chooses a random candidate until its
bit is enabled, then adds independent random offsets of 0-15 pixels to the candidate's X and Y
origins. All three enemy species use the same permitted-position mask.
