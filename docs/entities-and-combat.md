# Shamus VIC-20 entities and combat

This document describes behaviour verified in `main.asm`. An "iteration" means one pass through
the main game loop; it is not necessarily one television frame.

## Drawing model

Shamus uses XOR drawing into its character-based software framebuffer. Updating a moving object
usually follows this sequence:

1. Draw the old graphic again to erase it.
2. Calculate a proposed new position.
3. Reject the move if it intersects a solid maze character.
4. Store the accepted position.
5. Draw the graphic at its current position.

This avoids saving and restoring background pixels. It also explains why animation routines often
adjust `FRAME_COUNTER` before drawing the old image: they must select the same frame that is already
visible in order to erase it correctly.

## Shamus

Shamus moves two pixels per main-loop iteration in each pressed joystick direction. Vertical and
horizontal inputs are processed independently, so diagonal movement changes both coordinates.

The player has six graphics arranged as three two-frame pairs: vertical, right-facing, and
left-facing. Up and down share the vertical pair; left and right have separate graphics rather than
mirroring one sideways image.

Maze collision samples four points around Shamus, effectively testing the corners of the occupied
area. Screen-character values below `$FD` are traversable; `$FD-$FF` are solid cells, including the
electric-wall characters `$FE` and `$FF`.

Touching an electrified wall, an ordinary enemy, the Shadow, an enemy shot, or the lair target
enters the same death sequence.

The enemy-shot collision is an inline asymmetric test matching the way shot coordinates are
anchored: the shot must be within six pixels to the right of Shamus's X coordinate and, after a
two-pixel Y adjustment, within seven pixels below his Y coordinate. Ordinary enemies, the Shadow,
and the lair target use the shared approximately 16 by 16-pixel overlap routine.

## Fire control and ION SHIVs

The VIC-20 implementation allocates three simultaneous ION SHIV slots:

- X positions: `$11-$13`
- Y positions: `$14-$16`
- Directions: `$17-$19`

The manuals for some versions state a limit of two, but this port's update and allocation loops
process all three slots.

The fire button is edge/direction latched. Pressing fire launches once in the current eight-way
joystick direction. While fire remains held, changing direction permits another launch. Releasing
fire resets the latch. If all three slots are occupied, the launch request is ignored.

Directions are numbered clockwise:

```text
        0
     7     1
   6         2
     5     3
        4
```

Each ION SHIV advances four pixels per update by applying its one-pixel direction delta four times.
It disappears when it reaches the screen limits or when its leading sample enters a solid maze
cell.

The direction-delta data saves six bytes by placing the two explicit Y-delta bytes immediately
before the eight-byte X table. Indexing the Y label with directions 2-7 deliberately reads the first
six X-table bytes, whose values are also the required remaining Y deltas.

## Ordinary enemies

Each species has seven active slots. Room initialization chooses spawn points permitted by the
room's `room_spawn_position_masks` entry. All three species are recreated when a room is entered.

### Spiral Drones

Spiral Drones use four animation frames. Their pointer tables select the eight-byte frames at
`$B771,$B779,$B781,$B789`; all four high-byte entries are therefore `$B7`. On each permitted update
they independently make a three-in-four decision to move one pixel toward Shamus on each axis. This
produces loose, irregular pursuit rather than a straight-line approach.

They can fire enemy shots.

### Robo Droids

Robo Droids use four animation frames selected through `robo_droid_frame_high_bytes` and
`robo_droid_frame_low_bytes`: `$B739,$B741,$B749,$B751`. They retain an eight-way direction per
slot. Cardinal movement changes one coordinate by two pixels; diagonal movement changes both by one.
They remain clamped to the playable coordinate range and reject movement through maze walls.

Their turn logic contains a small quirk. A turn is requested when `random & $07` is zero, but the
result is then ANDed with one and tested again. Because it is already zero, the clockwise increment
is always selected and the counter-clockwise decrement path is unreachable. Thus a permitted turn
always advances the direction clockwise by one step.

They can fire enemy shots.

### Snap Jumpers

Snap Jumpers use the box-shaped robot graphic. They directly compare both coordinates with Shamus
and move toward him on both axes. Most permitted updates attempt one one-pixel pursuit step. A
one-in-eight random branch changes the step count to eight, producing the characteristic jump.

Snap Jumpers do not use the enemy-fire routine; they attack through contact.

## Enemy shots

Spiral Drones and Robo Droids share seven enemy-shot slots. Firing is considered only every eighth
main-loop iteration. A sufficiently aligned enemy fires cardinally whenever a slot is available;
an unaligned enemy makes a further one-in-eight random test before firing diagonally toward Shamus.

When an enemy is closely aligned with Shamus, a cardinal shot direction is selected. Otherwise a
random firing attempt may select the diagonal direction for the relative quadrant. A shot is lost
if no slot is free.

Enemy shots advance one pixel per update. They disappear at the screen limits or on contact with a
solid maze cell. The wall sample uses the pre-move drawing coordinates rather than the newly
calculated leading point, so a shot can be displayed in a wall for one update before being removed.

Enemy-shot update frequency also rises with progression. Room `$00` performs one update per main
loop. In later Level One rooms a second update occurs on alternate frame-counter values. Nonzero
rooms on Level Two and the Lair perform two enemy-shot updates every loop. This scheduling is
separate from the ordinary-enemy update masks.

## Hits, explosions, and scoring

An ordinary entity first tests all three ION SHIV slots. The direct-hit test uses an approximately
12 by 12-pixel region around the entity. A hit erases the SHIV, allocates an explosion, removes the
enemy, and awards 50 displayed points.

If no SHIV hit is found, ordinary enemies are also tested against active explosions using a tighter
approximately 8 by 8-pixel overlap. Therefore explosions can destroy nearby enemies and create new
explosions, allowing chain reactions.

The chain is implemented by consuming the explosion which touched the enemy, then allocating a new
first-frame explosion at that enemy's coordinates. Thus the visible blast effectively propagates
from one destroyed enemy to the next rather than leaving the original explosion active as well.

There are seven explosion slots. Each animation has four frames and advances once every four loop
iterations. If every explosion slot is occupied, the enemy is still removed and scored but the new
visual effect is omitted.

Score and high score are stored as three-byte packed BCD values and displayed as six digits.

## The Shadow

The Shadow is controlled by a slow appearance timer. Timer state two produces its warning sound;
state three releases it. A mystery result can force the timer beyond the release threshold.

Once active, the Shadow moves two pixels toward Shamus on each axis. It passes through the ordinary
maze-collision logic and cannot be destroyed. An ION SHIV hit starts a temporary stun timer instead
of removing it. Explosions do not kill it.

The Shadow calls the same direct SHIV test in SHIV-only mode, so a hit consumes the SHIV and creates
an explosion normally. Instead of removing or scoring the Shadow, the caller loads `$2D` into
`SHADOW_HIT_TIMER`. While that 45-update countdown is nonzero the pursuit movement is skipped; the
Shadow remains visible and continues accepting SHIV hits, but further hits do not restart the timer.

## Death

The death sequence XOR-erases Shamus, draws three graphic fragments, and sweeps the noise and tone
generators through 256 values. One life is then removed.

If lives remain, Shamus respawns at a room-specific safe position. Losing the final life returns to
the title/new-game sequence. Dying clears the room-rushing timer before the room is rebuilt.

The respawn coordinates fall into three groups:

- Rooms `$06,$0C,$12,$19,$1B,$1E` restart at the right edge (`X=$A2,Y=$42`).
- Rooms `$0B,$10,$11,$14,$18` restart near the top centre (`X=$54,Y=$06`).
- Every other room restarts near the left edge at mid-height (`X=$0A,Y=$42`).

## Lair target

The lair target is a two-part graphic which pursues Shamus. Contact is lethal. ION SHIV hits are
counted rather than awarding the ordinary 50-point enemy score.

After 20 hits, the game returns to Level One and forces the skill setting to Expert. This creates a
faster repeating cycle after the first completion.
