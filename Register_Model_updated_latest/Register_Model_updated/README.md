# UART Register Model — ARM CMSDK APB UART

A validated, end-to-end register-generation flow for the ARM CMSDK APB UART
peripheral, driven from an Excel spec through SystemRDL to UVM RAL, RTL,
HTML docs, and a C header.

```
ARM UART Programmer's Model (TRM, pages 4-8 to 4-10)
            │
            ▼
specs/UART_RDL_Input_Format.xlsx
            │
            ▼
     scripts/excel_to_rdl.py
            │
            ▼
        rdl/uart.rdl
            │
            ▼
      PeakRDL Compiler (v1.5.0)
            │
 ┌──────────┼──────────┬──────────┬──────────┐
 ▼          ▼          ▼          ▼
uvm/     rtl/        html/      rtl/uart.h
UVM RAL  RTL regblock HTML docs  C header
```

## Source of truth

Table 4-7, "APB UART memory map" (TRM pages 4-8 to 4-10). Registers:
`DATA, STATE, CTRL, INTSTATUS/INTCLEAR, BAUDDIV, PID4, PID5, PID6, PID7,
PID0, PID1, PID2, PID3, CID0, CID1, CID2, CID3`.

## Project structure

```
UART_Register_Model/
├── specs/
│   └── UART_RDL_Input_Format.xlsx   <- register/field spec (input)
├── scripts/
│   └── excel_to_rdl.py              <- Excel -> SystemRDL generator
├── rdl/
│   └── uart.rdl                     <- generated SystemRDL (output of script)
├── uvm/
│   └── uart_uvm_ral.sv              <- UVM RAL model (peakrdl uvm)
├── rtl/
│   ├── uart.sv, uart_pkg.sv          <- RTL register block (peakrdl regblock)
│   └── uart.h                        <- C header (peakrdl c-header)
├── html/
│   └── index.html + assets           <- browsable register documentation
└── README.md
```

## Requirements

```bash
pip install openpyxl peakrdl --break-system-packages
```

Validated against `peakrdl 1.5.0` (`peakrdl --version`).

## How to run

### 1. Excel → SystemRDL

```bash
cd UART_Register_Model
python3 scripts/excel_to_rdl.py specs/UART_RDL_Input_Format.xlsx -o rdl/uart.rdl
```

Optional flags:
- `--regwidth 32` (default) — bus/register width used to auto-fill reserved bits.
- `--addrmap-name uart` (default) — name of the top-level SystemRDL addrmap.

The script validates the sheet (required columns, MSB/LSB sanity, duplicate/
overlapping fields, allowed SW/HW/OnWrite vocab, offset consistency) and
fails with a specific row-number error message if anything is wrong.

### 2. Compile / sanity-check the RDL

```bash
peakrdl dump rdl/uart.rdl
```

Expected output — all 17 registers at their TRM-specified offsets, zero
errors:

```
0x0000-0x0003: uart.DATA
0x0004-0x0007: uart.STATE
0x0008-0x000b: uart.CTRL
0x000c-0x000f: uart.INTSTATUS
0x0010-0x0013: uart.BAUDDIV
0x0fd0-0x0fd3: uart.PID4
...
0x0ffc-0x0fff: uart.CID3
```

### 3. Generate downstream outputs

```bash
peakrdl uvm      rdl/uart.rdl -o uvm/uart_uvm_ral.sv
peakrdl regblock rdl/uart.rdl -o rtl --cpuif apb4
peakrdl html     rdl/uart.rdl -o html
peakrdl c-header rdl/uart.rdl -o rtl/uart.h
```

All four were run during validation of this project and completed with
zero errors (see "Validation performed" below).

## Excel input format

One row per register **field** (not per register). Columns:

| Column   | Meaning                                                             |
|----------|----------------------------------------------------------------------|
| Register | Register name, repeated on every row belonging to it                |
| Offset   | Byte offset, e.g. `0x004`                                            |
| RegDesc  | Free-text register description (may repeat per row)                 |
| Field    | Field name, unique within its register                              |
| MSB      | Field's most significant bit                                        |
| LSB      | Field's least significant bit                                       |
| SW       | Software access: `rw`, `ro`, `wo`                                    |
| HW       | Hardware access: `rw`, `r`, `w`, `na`                                |
| Reset    | Reset value (decimal or `0x..`), or `X` / `0x--` if undefined        |
| OnWrite  | `WR` (normal), `W1C` (write-1-to-clear), `W1S` (write-1-to-set), `NA` |

Reserved/unused bit ranges are **not** entered in the sheet — the script
auto-generates `RESERVED_*` fields to pad every register out to
`--regwidth` bits.

### Design decisions specific to this UART peripheral

- **DATA** (`0x000`): single 8-bit field, reset undefined (`X` in the TRM,
  omitted from the generated RDL entirely — no `reset` property is emitted).
- **STATE** (`0x004`): `RXOR`/`TXOR` are write-1-to-clear (`OnWrite=W1C`,
  hardware sets them on overrun); `RXBF`/`TXBF` are read-only status bits
  driven by hardware (`SW=ro`, `HW=w`).
- **CTRL** (`0x008`): all 7 bits are plain read-write configuration bits
  read by hardware (`HW=r`).
- **INTSTATUS/INTCLEAR** (`0x00C`): the TRM documents this as one address
  with two names (read = status, write = clear). Modeled as a single
  register `INTSTATUS` with 4 write-1-to-clear fields.
- **BAUDDIV** (`0x010`): 20-bit read-write field, bits `[31:20]` reserved.
- **PID4–PID7, PID0–PID3, CID0–CID3**: all read-only constant ID fields
  per the TRM (`SW=ro`, `HW=na`), including the sub-fields called out in
  PID1/PID2/PID4 (e.g. `jep106_id_3_0`, `jedec_used`).
- **No W1S fields exist in this peripheral** — the OnWrite vocabulary
  supports `W1S` for future peripherals, but the UART spec uses only
  `WR` and `W1C`.

## Validation performed

Run in this environment against `peakrdl 1.5.0`:

1. `python3 scripts/excel_to_rdl.py specs/UART_RDL_Input_Format.xlsx -o rdl/uart.rdl`
   → `OK: wrote rdl/uart.rdl` (17 registers, 51 fields including
   auto-generated reserved fields).
2. `peakrdl dump rdl/uart.rdl` → 0 errors, all offsets match Table 4-7 exactly.
3. `peakrdl uvm rdl/uart.rdl -o uvm/uart_uvm_ral.sv` → succeeded.
4. `peakrdl regblock rdl/uart.rdl -o rtl --cpuif apb4` → succeeded
   (`rtl/uart.sv`, `rtl/uart_pkg.sv`).
5. `peakrdl html rdl/uart.rdl -o html` → succeeded (`html/index.html`).
6. `peakrdl c-header rdl/uart.rdl -o rtl/uart.h` → succeeded.

## Extending this flow to other peripherals

This is deliberately a UART-specific, validated flow rather than a generic
one. Once you're happy with the mapping decisions above, the same
`excel_to_rdl.py` script — column format, validation rules, and reserved-bit
logic — should work unchanged for other CMSDK peripherals (timers, dual
timer, watchdog, GPIO) by just producing a new Excel sheet in the same
format and re-running step 1. Let me know when you want to generalize it
(e.g. support for multi-register arrays, interrupt fields, or a `RegWidth`
column instead of a global `--regwidth` flag).
