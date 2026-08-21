# Disassembly source conventions

The source aims to be readable as a program while remaining byte-identical to the original ROM.

## Completed routines

A fully decoded routine receives:

1. A `;--------------------------------------------------------------------------------------------------` separator.
2. A short overview describing its contract and important state.
3. One semantic global label, such as `configure_display`.
4. Dot-prefixed local labels for internal branches and loops.

Routine addresses remain available in `build/symbols` and the routine map.

## Local labels

Internal control flow uses ACME's dot notation:

```asm
configure_display
	lda #0
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

## Number notation

- Immediate values which are ordinary quantities use decimal, for example `lda #66` for a screen
  coordinate or `ldx #6` for a seven-entry loop.
- Immediate bit masks and exact input-bit patterns use eight-digit binary so the selected bits are
  visible, with the equivalent hexadecimal retained in a line comment: `and #%10000000 ;$80` or
  `cmp #%10000100 ;$84`.
- Addresses, address bytes, packed values, character codes and hardware-register layouts remain
  hexadecimal. An uncertain immediate remains hexadecimal until its purpose is established.
- Zero-page locations use their semantic labels rather than raw addresses wherever their role is
  known.
- VIC colour values use `VIC_COLOUR_*` constants, so writes to colour RAM state the intended colour
  directly rather than relying on a numeric code or repeated line comments.
- Enumerated game states use named constants such as `LEVEL_LAIR` and `SKILL_EXPERT` in preference
  to unexplained numeric values.

## Unused absolute loads

An instruction such as:

```asm
	lda reset_level_state
```

loads the byte stored at the address labelled `reset_level_state`; it does not load that address
itself. In this example the byte is `$A9`, the opcode of the routine's first `LDA #0`. The value
is immediately overwritten and has no gameplay effect. Similar loads precede
`initialize_room_runtime_state` and occur in `set_text_row`. They may be original-source remnants or
timing/padding instructions, but are retained because removing them would change the program bytes
and every following address.

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
