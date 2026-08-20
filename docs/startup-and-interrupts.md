# Cartridge startup and interrupt handling

The cartridge header at `$A000` contains two vectors followed by the `A0CBM` signature. The first
vector enters `start_of_program`. The second points to the KERNAL interrupt-exit routine at `$FF56`,
which restores the saved registers and finishes with `RTI`. This gives the KERNAL cartridge-NMI path
a safe way to resume the interrupted game.

`start_of_program` also replaces the ordinary RAM NMI vector at `$0318-$0319` with `$FF5B`. Although
`$FF5B` can look like a nearby undocumented KERNAL routine, the VIC-20 ROM map identifies it as the
start of an RS-232 timing table. It is data, whereas `$FF56` is the actual interrupt-exit code.

Consequently, the two mechanisms have different effects:

- the cartridge header's NMI vector returns safely through `$FF56`;
- any path that follows the normal RAM vector reaches non-code at `$FF5B` instead of returning to
  BASIC or invoking the standard STOP/RESTORE behaviour.

This strongly suggests an anti-escape or defensive cartridge measure. It prevents the RAM-vector
route from providing a convenient way out of the game. Calling it copy protection would be possible
but is not proven by this code alone; there is no checksum or media-validation logic attached to it.

The cartridge does contain a separate plain-text anti-piracy message at `$BA5D`. Tom Griner asks
prospective pirates not to distribute stolen copies and instead to write to him for free software.
This establishes the author's concern about copying, but the text itself is inert data and still
does not turn the NMI-vector patch into a proven media-validation scheme.

## Forced absolute stores

ACME syntax such as:

```asm
	sta+2 SKILL_LEVEL
```

forces the three-byte absolute encoding (`STA $0086`) even though the target lies in zero page and
the normal two-byte `STA $86` instruction has the same effect. The original program performs both
stores consecutively. It repeats the pattern for `SHADOW_APPEARANCE_TIMER` at `$006B`.

The `+2` is therefore unnecessary for game state but necessary to reproduce the original bytes and
addresses. The duplicate stores may be residue from the original source or deliberate padding; they
do not by themselves demonstrate protection.

## References

- [VIC-20 Machine Code, vectored-address table](https://www.vic-20.it/wp-content/uploads/2021/03/VIC-20_Machine_Code.pdf)
  identifies `$0318-$0319` as the NMI RAM vector.
- [VIC-20 ROM memory map](https://retroisle.com/commodore/vic20/Technical/Firmware/MemoryMap.php)
  identifies `$FF56` as Exit Interrupt and `$FF5B` as RS-232 timing data.
