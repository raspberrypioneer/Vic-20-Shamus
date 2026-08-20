# Sound, timing, and PAL/NTSC behaviour

Shamus uses all four VIC-I sound generators directly. There is no interrupt-driven music or sound
engine: title music is advanced by the title loop, while gameplay effects are advanced once per
main-loop iteration. This distinction is important when comparing PAL and NTSC machines.

## PAL and NTSC hardware

The VIC-I variants have different raster geometries and clocks:

| System | VIC-I | Cycles per line | Lines per frame | CPU/bus clock | Approx. refresh |
|---|---:|---:|---:|---:|---:|
| NTSC-M | 6560-101 | 65 | 261 | 14.318181 MHz / 14 = 1.022727 MHz | 60.05 Hz |
| PAL-B | 6561-101 | 71 | 312 | 4.433618 MHz / 4 = 1.108405 MHz | 50.05 Hz |

The PAL CPU therefore executes code about 8.4% faster, despite the PAL display refreshing about
16.7% less often. Code tied to the raster and code tied only to CPU execution consequently do not
change speed in the same direction.

## Opening-screen calibration

`configure_display` initially writes 5 to `$9000` (horizontal origin) and 25 to `$9001` (vertical
origin). On the title screen the joystick then changes those VIC registers directly:

- up decrements the vertical origin;
- down increments the vertical origin;
- left decrements the horizontal origin;
- right increments the horizontal origin;
- fire accepts the current position and starts the game.

The routine first waits for all direction contacts to be released, preventing the joystick position
used during loading or startup from immediately shifting the picture. The adjusted register values
are not copied into software variables; they simply remain in the VIC for the ensuing game.

This is manual centring, not PAL/NTSC detection. No test of frame length, raster-line count, VIC
model, or clock standard has been found. It accommodates the substantially different visible areas
of the 6560 and 6561, as well as variation between televisions.

## Raster-paced title screen

The title loop waits until raster register `$9004` reads zero before doing the next animation pass.
It therefore normally advances once per video frame. Consequences include:

- title animation runs at roughly 50 updates/second on PAL and 60 on NTSC;
- title-theme note timing is correspondingly slower on PAL;
- the three longer notes use an eight-update divider, while ordinary notes use four updates;
- the skill-level busy wait occurs before the raster wait and usually consumes otherwise idle time.

The tune data contains a voice byte (copied to soprano and alto) and a bass byte for each step. A
`$ff,$ff` pair terminates and restarts the tune. The melody is Gounod's *Funeral March of a
Marionette*, best known as the theme of *Alfred Hitchcock Presents*.

## CPU-paced gameplay

The main game does not wait for a particular raster line. Its timing is a software loop whose delay
depends on the selected skill:

| Skill | Inner delay seed | Relative delay |
|---|---:|---|
| Beginner | 24 | longest |
| Novice | 16 | medium |
| Advanced | 8 | short |
| Expert | 0 | minimal |

The outer delay loop runs 220 times. Maze depth independently changes enemy update masks, so skill
and room progression are separate speed controls.

Timers for shots, explosions, the Shadow, room-rushing, and enemy movement are counts of main-loop
iterations rather than video frames. Their real duration therefore varies with CPU clock and with
the amount of work performed in an iteration. All else being equal, PAL's faster CPU makes these
iteration-counted events somewhat shorter in wall-clock time. This is an inference from the loop
structure and the documented chip clocks; the game contains no compensating PAL/NTSC branch.

VIC-I tone pitch is also derived from the chip clock. Shamus uses the same register values on both
models, so exact pitch is hardware-standard-dependent rather than explicitly corrected in software.

## Gameplay sound effects

`update_game_sound_effects` multiplexes several small state machines:

- **ION SHIV:** a five-iteration descending two-voice tone in the bass and alto generators.
- **Explosion:** the timer advances from 3 to 9, driving rising noise and a complementary soprano
  sweep before clearing both generators.
- **Shadow warning:** while the appearance timer equals 2, frame-counter values `$e6-$fd` are copied
  to bass, alto, and soprano together, producing the manual's low pulsing warning.
- **Reward pickup:** a five-iteration rising bass tone for extra-life bottles and mystery symbols.
- **Player death:** the death-animation loop continually changes the noise voice.
- **Level completion:** the 256-award bonus loop sweeps bass, alto, and soprano while adding 50
  displayed points each time, for a total bonus of 12,800.

Because these effects are updated cooperatively, starting or ending one may overwrite a generator
also used by another. This is deliberate economy rather than a priority-based sound mixer.

## References

- [MOS 6560/6561 VIC-I technical notes](https://www.vic-20.it/wp-content/uploads/2021/05/6561-6560.pdf)
  for measured clocks, raster geometry, origin ranges, raster-register layout, and sound formulas.
- [Original *Shamus* manual](https://www.mocagh.org/miscgame/shamus-manual.pdf) for the named weapons,
  enemies, skill levels, and the Shadow-warning description. Its instructions are Atari-oriented;
  VIC-specific control behaviour in this document comes from the disassembly itself.
