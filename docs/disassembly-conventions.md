# Disassembly source conventions

The source aims to be readable as a program while remaining byte-identical to the original ROM.

## Completed routines

A fully decoded routine receives:

1. A `;--------------------------------------------------------------------------------------------------` separator.
2. A short overview describing its contract and important state.
3. One semantic global label, such as `configure_display`.
4. Dot-prefixed local labels for internal branches and loops.

The temporary address-derived `Lxxxx` label is removed once every external reference has been
changed to the semantic name. The address remains available in `build/symbols` and the routine map.

## Provisional labels

During decoding, an `Lxxxx` global label meant that an address was still acting as a provisional
entry point or data name. The completed source no longer contains address-derived `Lxxxx` labels.
If future investigation introduces one temporarily, it should remain until its role and callers are
understood, then be replaced with a semantic global label or made local to its owning block.

## Local labels

Internal control flow uses ACME's dot notation:

```asm
configure_display
	lda #$00
.clear_loop
	sta $1000,x
	dex
	bne .clear_loop
	rts
```

Dot labels stay out of the global symbol list, keeping it useful for navigation and debugging.

## Instruction layout

- A label always occupies its own line, including labels attached to data directives.
- Instructions and data directives are indented by one tab.
- A mnemonic or directive and its operand are separated by one space.
- Short, line-specific comments may follow the instruction; routine contracts remain above the
  routine so they do not crowd the implementation.
- A conditional branch used deliberately as an unconditional transfer is marked `;always branch`.
  This is added only when the incoming processor flags prove that the branch must be taken.

```asm
.copy_byte
	lda source,x                       ;read the next source byte
	sta destination,x
	dex
	bpl .copy_byte
```

## Data presentation

- The large binary-row graphic data set lives in `bitmap-graphics.asm`, included from `main.asm` at
  its original position so all following addresses remain unchanged.
- Each distinct data section starts with the separator line. Its overview comment follows the
  separator, followed by the data label on its own line.
- Sprite and graphic rows use binary `%xxxxxxxx` notation.
- Readable VIC text uses ACME's `!scr` or `!pet` encoding as appropriate; isolated non-text values
  remain explicit bytes.
- Lookup, maze, music, and other non-graphic data is grouped into meaningful byte rows.
- Graphic frame boundaries include an address and gameplay name.
- Persistent RAM uses named constants; genuinely reused scratch values are documented as such.
