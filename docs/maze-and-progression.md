# Shamus VIC-20 maze and progression notes

These notes describe behaviour verified directly from `main.asm`. Room numbers are hexadecimal.

## Room-number coordinate system

Each room begins with four compressed wall bitfields. `draw_room_layout` tests every byte against
`bit_selection_masks` (`$80,$40,...,$01`). A set bit selects the corresponding fixed screen-matrix
position from one of four placement tables:

- `vertical_wall_positions_a` and `vertical_wall_positions_b` select four-cell vertical segments;
- `horizontal_wall_positions_a` and `horizontal_wall_positions_b` select four- or five-cell
  horizontal segments, shortened where a segment meets a framebuffer row join;
- the four bytes are interleaved per room, so the record address is `ROOM_NUMBER * 4`;
- entering the lair forces room record `$21`, while record `$20` is not selected by normal play.

Ordinary rooms use a six-column coordinate system. Crossing a horizontal edge changes the room by
one; crossing a vertical edge changes it by six.

```text
00  01  02  03  04  05
06  07  08  09  0A  0B
0C  0D  0E  0F  10  11
12  13  14  15  16  17
18  19  1A  1B  1C  1D
1E  1F
```

The four bytes for each room are not simple exit flags. They are four wall-segment bitfields. Each
set bit selects a fixed horizontal or vertical segment from `vertical_wall_positions_a`,
`vertical_wall_positions_b`, `horizontal_wall_positions_a`, or `horizontal_wall_positions_b`.
Together the 34 records occupy only 136 bytes.

Record `$20` is present but ordinary room initialization advances the level as soon as the room
number reaches `$20`, so it is not drawn as a normal room. Record `$21` is explicitly selected for
the lair.

## Keys and keyholes

There are three persistent key/keyhole pairs:

| Colour | Key room | Key flag | Keyhole room | Open flag |
|---|---:|---:|---:|---:|
| Red | `$11` | `$80` | `$09` | `$08` |
| White | `$06` | `$40` | `$14` | `$04` |
| Blue | `$10` | `$20` | `$1F` | `$02` |

Touching a key records its high-bit flag. Touching the corresponding keyhole only succeeds when
that key flag is present, after which the low-bit open flag is recorded and the room is rebuilt.
Until that low-bit flag is set, room construction adds a four-cell electric-wall segment behind the
keyhole. Collected keys and opened keyholes are also redrawn in the lower-right inventory display.

## Persistent room objects

Extra-life bottles appear once in rooms `$01`, `$02`, `$0C`, and `$1A`.

Mystery question marks appear once in rooms `$00`, `$08`, `$0B`, and `$18`. Their five accepted
outcomes are:

1. Force the Shadow to appear.
2. Add one life.
3. Select the slowest enemy update rate.
4. Select the fastest enemy update rate.
5. Award 500 points.

Random values 5-7 are rejected and rerolled; accepted values 0-4 map one-to-one to these results.

Room `$1B` contains a yellow central barrier made from the animated `$FE` electric-wall character.
Every eight main-loop iterations its two-character-high gap advances by two screen rows through one
of eight positions. The unlock test scans the three ION SHIV X coordinates only: any active SHIV in
the central band `$50-$6D` changes the barrier state to `$FF` and rebuilds the room without it. It
does not compare the SHIV's Y coordinate with the currently displayed gap.

No ordinary enemies are spawned in room `$1B` while the barrier exists. Once it has been removed,
all seven slots of all three enemy species are placed at central X coordinate `$58`, with independent
random Y coordinates from `$20-$5F`. The Robo Droids also receive random directions.

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
| `$00` | `$0F` | every 16 main-loop iterations |
| `$01-$07` | `$07` | every 8 main-loop iterations |
| `$08-$0F` | `$03` | every 4 main-loop iterations |
| `$10-$17` | `$01` | every 2 main-loop iterations |
| `$18-$1F` | `$00` | every iteration |

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

Internally, score and high score use three packed-BCD bytes. The renderer suppresses leading zeroes
and appends one fixed zero, so adding stored BCD `$000005` produces the displayed award `50`.

The compact VIC-20 sequence is Level One, Level Two, then the Lair. Defeating the lair target
returns to Level One with the skill setting forced to Expert.

## Enemy spawn positions

Each ordinary room has one byte in `room_spawn_position_masks`. Its eight bits correspond to eight
candidate cells in a coarse three-by-three grid; the bottom-right cell is omitted. A set bit permits
that candidate for the room. Enemy initialization repeatedly chooses a random candidate until its
bit is enabled, then adds independent random offsets of 0-15 pixels to the candidate's X and Y
origins. All three enemy species use the same permitted-position mask.
