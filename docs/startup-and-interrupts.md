# Cartridge startup and interrupt handling

The cartridge header at `$A000` contains two vectors followed by the `A0CBM` signature. The first
vector enters `start_of_program`. The second points to the KERNAL interrupt-exit routine at `$FF56`,
which restores the saved registers and finishes with `RTI` at `$FF5B`. This gives the KERNAL
cartridge-NMI path a safe way to resume the interrupted game.

`start_of_program` also replaces the ordinary RAM NMI vector at `$0318-$0319` with `$FF5B`, entering
the final `RTI` directly. The RS-232 timing table follows at `$FF5C`; it does not begin at `$FF5B`.

Consequently, the two mechanisms have different effects:

- the cartridge header's NMI vector restores registers and returns through the complete `$FF56`
  exit sequence;
- any path that follows the normal RAM vector enters its final `RTI` directly at `$FF5B`, preventing
  the usual STOP/RESTORE route from returning to BASIC.

This is an anti-escape or defensive cartridge measure: it prevents the RAM-vector route from
providing a convenient way out of the game.

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

The `+2` suffix is useful here because it selects the required instruction width while keeping the
operand symbolic. It reproduces the original bytes and preserves every following address.

## References

- [VIC-20 Machine Code, vectored-address table](https://www.vic-20.it/wp-content/uploads/2021/03/VIC-20_Machine_Code.pdf)
  identifies `$0318-$0319` as the NMI RAM vector.
- The VIC-20 KERNAL disassembly shows the Exit Interrupt routine at `$FF56-$FF5B`, ending with
  `RTI`; its following RS-232 timing table begins at `$FF5C`.
