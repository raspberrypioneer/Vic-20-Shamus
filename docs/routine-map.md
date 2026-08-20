# Shamus VIC-20 routine map

This is a functional index to the semantic labels in `main.asm`. The address column preserves the
link to raw disassemblies and debugger locations without retaining decoded `Lxxxx` source labels.

Cartridge entry and NMI behaviour are described in
[startup-and-interrupts.md](startup-and-interrupts.md).

## Program and state flow

```text
start_of_program ($A009)
    -> configure_display ($B55C)
    -> start_new_game ($B951)
       -> title/calibration screen ($A8A1)
       -> initialize_current_room ($B985)
          -> build framebuffer and walls
          -> place persistent objects and keys
          -> initialize enemies and transient objects
          -> main_game_loop ($B9F5)
             -> update entities, effects, input, sound, and timers
             -> handle_player_collision_and_room_exit ($A3D6)
                -> next room / death / next main-loop iteration
```

## Display and drawing

| Address | Semantic label | Purpose |
|---:|---|---|
| `$B55C` | `configure_display` | Configure the 22 by 11 double-height VIC display. |
| `$B57F` | `clear_and_build_framebuffer` | Build the screen-code map, colour RAM, and clear bitmap RAM. |
| `$B5CB` | `xor_draw_shifted_bitmap` | Draw an arbitrary-X bitmap across character-byte boundaries. |
| `$B691` | `get_character_bitmap_address` | Convert a character code to its bitmap address. |
| `$B6AB` | `draw_character` | Draw one ROM character through the bitmap renderer. |
| `$B6B3` | `calculate_framebuffer_address` | Convert pixel X/Y to bitmap pointer and bit shift. |
| `$A870` | `draw_text_character_and_advance` | Draw one character and advance/wrap text X. |
| `$A885` | `set_text_row` | Select a text row and reset its X position. |
| `$A891` | `advance_draw_x_by_8` | Add eight to the current drawing X coordinate. |
| `$A899` | `advance_draw_y_by_8` | Add eight to the current drawing Y coordinate. |

## Room construction and transitions

| Address | Semantic label | Purpose |
|---:|---|---|
| `$A07E` | `draw_room_layout` | Expand a four-byte room record into fixed wall segments. |
| `$A02D` | `animate_electric_walls` | Rotate all lethal wall character graphics. |
| `$A528` | `handle_keys_and_keyholes` | Collect keys and open their colour-matched keyholes. |
| `$A5C8` | `update_room_27_moving_barrier` | Move room `$1B`'s electric-wall gap and detect a SHIV in its X band. |
| `$A3D6` | `handle_player_collision_and_room_exit` | Test death and apply room changes of +/-1 or +/-6. |
| `$B945` | `rebuild_current_room_after_object_change` | Redraw keys/keyholes without respawning enemies. |
| `$B985` | `initialize_current_room` | Rebuild all room graphics, objects, state, and enemy arrays. |
| `$AFA3` | `initialize_room_enemies` | Populate all three enemy species from the room spawn mask. |
| `$B03D` | `clear_transient_entities` | Clear shots/explosions and redraw initial entities. |
| `$B079` | `initialize_open_room_27_enemies` | Fill room `$1B` after its barrier has been removed. |
| `$B93D` | `advance_to_next_level` | Award completion bonus and advance Level One/Two/Lair. |

## Player and weapons

| Address | Semantic label | Purpose |
|---:|---|---|
| `$B196` | `draw_player` | Select Shamus's direction/animation graphic and XOR draw it. |
| `$B209` | `update_player` | Erase, read joystick, move, fire, and redraw Shamus. |
| `$B1FA` | `handle_fire_button` | Apply fire/direction latch behaviour. |
| `$B25D` | `try_fire_player_shot` | Allocate one of three ION SHIV slots. |
| `$B27F` | `draw_player_shot` | Draw an ION SHIV using its direction graphic. |
| `$B2AB` | `decode_joystick_direction` | Convert active-low joystick bits to direction 0-7. |
| `$B2F8` | `update_player_shots` | Move SHIVs four pixels and remove blocked/out-of-range shots. |

## Enemies and effects

| Address | Semantic label | Purpose |
|---:|---|---|
| `$B385` | `update_spiral_drones` | Update all seven Spiral Drone slots. |
| `$B39F` | `update_one_spiral_drone` | Irregular one-pixel pursuit, fire, and hit handling. |
| `$AB55` | `update_robo_droids` | Update all seven Robo Droid slots. |
| `$AB62` | `update_one_robo_droid` | Directed cardinal/diagonal movement, clockwise turns, fire, and hits. |
| `$ACA4` | `update_snap_jumpers` | Update all seven Snap Jumper slots. |
| `$ACB1` | `update_one_snap_jumper` | Direct pursuit with occasional eight-step jump. |
| `$AD1E` | `update_shadow` | Release, pursue, and process Shadow stun state. |
| `$ADAF` | `try_enemy_fire` | Select firing direction and allocate an enemy shot. |
| `$AE40` | `update_enemy_shots` | Move and remove all seven enemy-shot slots. |
| `$AC1A` | `create_explosion` | Allocate a four-frame explosion. |
| `$AC33` | `update_explosions` | Draw and advance all explosion slots. |
| `$AC6D` | `draw_explosion` | Select and XOR-draw the current explosion frame. |

## Collision and score

| Address | Semantic label | Purpose |
|---:|---|---|
| `$B408` | `test_background_at_position` | Test the maze character under a pixel coordinate. |
| `$B434` | `test_2x2_background_collision` | Test four neighbouring character cells. |
| `$B540` | `test_player_object_overlap` | Test a roughly 16 by 16-pixel player/object overlap. |
| `$A62D` | `test_player_enemy_collisions` | Test shots, enemy species, Shadow, and lair target. |
| `$ABDF` | `test_ion_shiv_or_explosion_hit` | Resolve SHIV hits and explosion chain reactions. |
| `$ABE1` | `test_ion_shiv_hit` | SHIV-only entry used by the Shadow and lair target. |
| `$AEE0` | `test_explosion_hit` | Test one entity against active explosion slots. |
| `$B134` | `award_50_points` | Add 50 displayed points and update the high score. |
| `$B10E` | `draw_score_and_high_score` | Render both three-byte BCD values. |
| `$B0BF` | `draw_packed_bcd_score` | Suppress leading zeroes and append the fixed units zero. |

## Objects and special sequences

| Address | Semantic label | Purpose |
|---:|---|---|
| `$B46A` | `update_extra_life_object` | Animate/collect bottles and persist their room flags. |
| `$B4C0` | `update_bonus_object` | Animate/collect question marks and choose a mystery result. |
| `$AF3A` | `update_lair_target` | Pursue Shamus, count hits, and complete the lair. |
| `$AF15` | `draw_lair_target` | Draw the lair target's adjacent bitmap halves. |
| `$A466` | `handle_player_death` | Play death animation/sound and respawn or end the game. |
| `$A760` | `award_level_completion_bonus` | Award 12,800 points with a sound sweep. |

## Input, timing, and sound

| Address | Semantic label | Purpose |
|---:|---|---|
| `$B662` | `read_joystick` | Combine VIA joystick bits into one active-low byte. |
| `$B678` | `update_random_number` | Mix raster, joystick, counters, and scratch values. |
| `$B183` | `apply_skill_level_delay` | Busy-wait according to Beginner through Expert. |
| `$A7AD` | `handle_pause_key` | Debounce and wait for the pause key sequence. |
| `$A6AA` | `silence_sound_generators` | Clear all four VIC sound voices. |
| `$A6B9` | `update_game_sound_effects` | Update SHIV, explosion, warning, and reward sounds. |
| `$AAA5` | `update_title_theme` | Play and decay title-theme register pairs. |
| `$A778` | `update_secondary_sound_effects` | Continue with Shadow-warning and reward tones. |

## Title and new game

| Address | Semantic label | Purpose |
|---:|---|---|
| `$A8A1` | `show_title_and_calibration_screen` | Draw legend, play music, select skill, and adjust display. |
| `$AA60` | `draw_selected_skill_level` | Draw the current eight-character skill name. |
| `$AA7E` | `poll_skill_level_key` | Debounce and cycle the four skill settings. |
| `$B951` | `start_new_game` | Reset lives, scores, progression, objects, and first room. |
| `$B96A` | `reset_level_state` | Reset keys, room objects, barrier state, and starting position. |
| `$B99A` | `initialize_room_runtime_state` | Restore wall glyphs, HUD, timers, and per-room runtime state. |
| `$B9F5` | `main_game_loop` | Central update dispatcher. |

Detailed timing and sound analysis is in [sound-and-timing.md](sound-and-timing.md).
