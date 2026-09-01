#!/usr/bin/env python3
"""
excel_to_rdl.py

Reads a register-field specification from an Excel sheet and emits a
PeakRDL-compatible SystemRDL file.

Expected Excel columns (row 1 = header, one row per register FIELD):

    Register | Offset | RegDesc | Field | MSB | LSB | SW | HW | Reset | OnWrite

    Register  - register name (repeated on every row that belongs to it)
    Offset    - register byte offset, e.g. "0x004" or "4"
    RegDesc   - free text description of the register (may repeat per row)
    Field     - field name, unique within its register
    MSB       - most significant bit of the field (int)
    LSB       - least significant bit of the field (int)
    SW        - software access: rw | ro | wo
    HW        - hardware access: rw | r | w | na
    Reset     - reset value (decimal or 0x.. hex), or "X" / "0x--" if undefined
    OnWrite   - WR | W1C | W1S | NA
                WR  = normal read/write, no special on-write behaviour
                W1C = write-1-to-clear (software writes 1, hardware bit clears)
                W1S = write-1-to-set   (software writes 1, hardware bit sets)
                NA  = field is not writable by software (typically ro fields)

Usage:
    python3 excel_to_rdl.py <input.xlsx> [-o output.rdl] [--regwidth 32]
"""

import argparse
import sys
from pathlib import Path
from collections import OrderedDict, defaultdict

try:
    import openpyxl
except ImportError:
    print("ERROR: this script requires 'openpyxl'. Install with:\n"
          "    pip install openpyxl --break-system-packages", file=sys.stderr)
    sys.exit(1)

REQUIRED_COLUMNS = ["Register", "Offset", "RegDesc", "Field", "MSB", "LSB",
                    "SW", "HW", "Reset", "OnWrite"]
# Optional: if present, its text is emitted as each field's own `desc` property
# in the generated RDL (separate from RegDesc, which describes the register
# as a whole). Sheets without this column parse exactly as before.
OPTIONAL_COLUMNS = ["FieldDesc"]

VALID_SW = {"rw", "ro", "wo", "r", "w"}
VALID_HW = {"rw", "r", "w", "na"}
VALID_ONWRITE = {"wr", "w1c", "w1s", "na"}
UNDEFINED_RESET_TOKENS = {"x", "0x--", "--", ""}

SW_MAP = {"rw": "rw", "ro": "r", "r": "r", "wo": "w", "w": "w"}
HW_MAP = {"rw": "rw", "r": "r", "w": "w", "na": "na"}
ONWRITE_MAP = {"w1c": "woclr", "w1s": "woset"}  # "wr"/"na" -> no onwrite property

DEFAULT_REG_WIDTH = 32
INDENT = "    "


class SpecError(Exception):
    """Raised for any problem found in the input Excel data."""
    pass


class Field:
    def __init__(self, name, msb, lsb, sw, hw, reset, onwrite, row_num, desc=None):
        self.name = name
        self.msb = msb
        self.lsb = lsb
        self.sw = sw
        self.hw = hw
        self.reset = reset          # int or None (None == undefined / "X")
        self.onwrite = onwrite      # "wr" | "w1c" | "w1s" | "na"
        self.row_num = row_num      # for error messages
        self.desc = desc            # str or None (None == no FieldDesc column / empty cell)

    @property
    def width(self):
        return self.msb - self.lsb + 1


class Register:
    def __init__(self, name, offset, desc):
        self.name = name
        self.offset = offset
        self.desc = desc
        self.fields = []  # list[Field], in the order encountered

    def add_field(self, field):
        self.fields.append(field)


# --------------------------------------------------------------------------
# Parsing helpers
# --------------------------------------------------------------------------

def parse_int_auto(value, row_num, col_name):
    """Parse an int that may be given as decimal or 0x-prefixed hex."""
    if isinstance(value, (int, float)):
        return int(value)
    if value is None:
        raise SpecError(f"Row {row_num}: '{col_name}' is empty but a value is required.")
    s = str(value).strip()
    if s == "":
        raise SpecError(f"Row {row_num}: '{col_name}' is empty but a value is required.")
    try:
        if s.lower().startswith("0x"):
            return int(s, 16)
        return int(s, 10)
    except ValueError:
        raise SpecError(f"Row {row_num}: '{col_name}' value '{value}' is not a valid integer.")


def parse_reset(value, row_num):
    """Return an int reset value, or None if the reset is explicitly undefined."""
    if value is None:
        return None
    s = str(value).strip().lower()
    if s in UNDEFINED_RESET_TOKENS:
        return None
    try:
        if s.startswith("0x"):
            return int(s, 16)
        return int(s, 10)
    except ValueError:
        raise SpecError(
            f"Row {row_num}: 'Reset' value '{value}' is not a valid integer, "
            f"hex literal, or one of the recognised undefined tokens (X, 0x--)."
        )


def parse_offset(value, row_num):
    return parse_int_auto(value, row_num, "Offset")


def validate_identifier(name, row_num, kind):
    if not name:
        raise SpecError(f"Row {row_num}: {kind} name is empty.")
    name = str(name).strip()
    if not (name[0].isalpha() or name[0] == "_"):
        raise SpecError(f"Row {row_num}: {kind} name '{name}' must start with a letter or underscore.")
    if not all(c.isalnum() or c == "_" for c in name):
        raise SpecError(f"Row {row_num}: {kind} name '{name}' contains invalid characters "
                         f"(only letters, digits, underscore allowed).")
    return name


# --------------------------------------------------------------------------
# Excel reading + validation
# --------------------------------------------------------------------------

def read_excel(path):
    try:
        wb = openpyxl.load_workbook(path, data_only=True)
    except FileNotFoundError:
        raise SpecError(f"Input file not found: {path}")
    except Exception as e:
        raise SpecError(f"Could not open '{path}' as an Excel file: {e}")

    ws = wb.active
    rows_iter = ws.iter_rows(values_only=True)
    try:
        header = next(rows_iter)
    except StopIteration:
        raise SpecError("The Excel sheet is empty (no header row found).")

    header = [str(h).strip() if h is not None else "" for h in header]
    missing = [c for c in REQUIRED_COLUMNS if c not in header]
    if missing:
        raise SpecError(
            f"Missing required column(s): {missing}. "
            f"Expected columns: {REQUIRED_COLUMNS}"
        )
    col_idx = {name: header.index(name) for name in REQUIRED_COLUMNS}
    for name in OPTIONAL_COLUMNS:
        if name in header:
            col_idx[name] = header.index(name)

    registers = OrderedDict()  # name -> Register
    seen_offsets = {}          # offset(int) -> register name, to catch conflicts

    for excel_row_num, row in enumerate(rows_iter, start=2):
        if row is None or all(c is None for c in row):
            continue  # skip fully blank rows

        def cell(col):
            idx = col_idx.get(col)
            if idx is None:
                return None
            return row[idx] if idx < len(row) else None

        reg_name_raw = cell("Register")
        if reg_name_raw is None or str(reg_name_raw).strip() == "":
            raise SpecError(f"Row {excel_row_num}: 'Register' column is empty.")
        reg_name = validate_identifier(reg_name_raw, excel_row_num, "Register")

        offset_val = parse_offset(cell("Offset"), excel_row_num)
        desc = cell("RegDesc")
        desc = str(desc).strip() if desc is not None else ""

        field_name_raw = cell("Field")
        field_name = validate_identifier(field_name_raw, excel_row_num, "Field")

        msb = parse_int_auto(cell("MSB"), excel_row_num, "MSB")
        lsb = parse_int_auto(cell("LSB"), excel_row_num, "LSB")
        if msb < lsb:
            raise SpecError(
                f"Row {excel_row_num}: field '{field_name}' has MSB ({msb}) < LSB ({lsb})."
            )
        if lsb < 0:
            raise SpecError(f"Row {excel_row_num}: field '{field_name}' has negative LSB ({lsb}).")

        sw_raw = cell("SW")
        sw_raw = str(sw_raw).strip().lower() if sw_raw is not None else ""
        if sw_raw not in VALID_SW:
            raise SpecError(
                f"Row {excel_row_num}: field '{field_name}' has invalid SW access '{sw_raw}'. "
                f"Expected one of {sorted(VALID_SW)}."
            )

        hw_raw = cell("HW")
        hw_raw = str(hw_raw).strip().lower() if hw_raw is not None else ""
        if hw_raw not in VALID_HW:
            raise SpecError(
                f"Row {excel_row_num}: field '{field_name}' has invalid HW access '{hw_raw}'. "
                f"Expected one of {sorted(VALID_HW)}."
            )

        onwrite_raw = cell("OnWrite")
        onwrite_raw = str(onwrite_raw).strip().lower() if onwrite_raw is not None else "na"
        if onwrite_raw not in VALID_ONWRITE:
            raise SpecError(
                f"Row {excel_row_num}: field '{field_name}' has invalid OnWrite '{onwrite_raw}'. "
                f"Expected one of {sorted(VALID_ONWRITE)}."
            )
        if onwrite_raw in ("w1c", "w1s") and SW_MAP[sw_raw] not in ("rw", "w"):
            raise SpecError(
                f"Row {excel_row_num}: field '{field_name}' has OnWrite='{onwrite_raw}' but "
                f"SW access is '{sw_raw}'. W1C/W1S fields must be software-writable (rw or wo)."
            )

        reset_val = parse_reset(cell("Reset"), excel_row_num)

        field_desc_raw = cell("FieldDesc")
        field_desc = str(field_desc_raw).strip() if field_desc_raw is not None else None
        if field_desc == "":
            field_desc = None

        reg = registers.get(reg_name)
        if reg is None:
            reg = Register(reg_name, offset_val, desc)
            registers[reg_name] = reg
            if offset_val in seen_offsets and seen_offsets[offset_val] != reg_name:
                raise SpecError(
                    f"Row {excel_row_num}: register '{reg_name}' at offset "
                    f"0x{offset_val:X} collides with register "
                    f"'{seen_offsets[offset_val]}' at the same offset."
                )
            seen_offsets[offset_val] = reg_name
        else:
            if reg.offset != offset_val:
                raise SpecError(
                    f"Row {excel_row_num}: register '{reg_name}' previously used offset "
                    f"0x{reg.offset:X} but this row specifies 0x{offset_val:X}. "
                    f"All rows for the same register must use the same offset."
                )
            if desc and not reg.desc:
                reg.desc = desc

        for existing in reg.fields:
            if existing.name == field_name:
                raise SpecError(
                    f"Row {excel_row_num}: duplicate field name '{field_name}' "
                    f"in register '{reg_name}' (first seen at row {existing.row_num})."
                )
            if not (msb < existing.lsb or lsb > existing.msb):
                raise SpecError(
                    f"Row {excel_row_num}: field '{field_name}' [{msb}:{lsb}] overlaps "
                    f"with field '{existing.name}' [{existing.msb}:{existing.lsb}] "
                    f"in register '{reg_name}'."
                )

        reg.add_field(Field(
            name=field_name, msb=msb, lsb=lsb,
            sw=SW_MAP[sw_raw], hw=HW_MAP[hw_raw],
            reset=reset_val,
            onwrite=onwrite_raw,
            row_num=excel_row_num,
            desc=field_desc,
        ))

    if not registers:
        raise SpecError("No register/field rows found in the Excel sheet.")

    return list(registers.values())


# --------------------------------------------------------------------------
# Reserved-field auto-generation
# --------------------------------------------------------------------------

def add_reserved_fields(reg, reg_width):
    """Fill any bit positions in [reg_width-1:0] not covered by a defined
    field with auto-generated reserved fields (sw=r, hw=na, reset=0)."""
    covered = [False] * reg_width
    for f in reg.fields:
        if f.msb >= reg_width:
            raise SpecError(
                f"Register '{reg.name}': field '{f.name}' MSB={f.msb} exceeds "
                f"the register width ({reg_width} bits)."
            )
        for b in range(f.lsb, f.msb + 1):
            covered[b] = True

    gaps = []
    b = 0
    while b < reg_width:
        if not covered[b]:
            start = b
            while b < reg_width and not covered[b]:
                b += 1
            gaps.append((start, b - 1))  # (lsb, msb)
        else:
            b += 1

    for lsb, msb in gaps:
        reg.fields.append(Field(
            name=f"RESERVED_{msb}_{lsb}" if msb != lsb else f"RESERVED_{msb}",
            msb=msb, lsb=lsb,
            sw="r", hw="na",
            reset=0,
            onwrite="na",
            row_num=-1,
        ))

    # keep fields sorted MSB-down for readable output
    reg.fields.sort(key=lambda f: -f.msb)


# --------------------------------------------------------------------------
# SystemRDL emission
# --------------------------------------------------------------------------

def emit_field(f):
    lines = []
    if f.width == 1:
        lines.append(f"{INDENT*2}field {{")
    else:
        lines.append(f"{INDENT*2}field {{")
    if f.desc:
        desc_escaped = f.desc.replace('"', '\\"')
        lines.append(f'{INDENT*3}desc = "{desc_escaped}";')
    lines.append(f"{INDENT*3}sw = {f.sw};")
    lines.append(f"{INDENT*3}hw = {f.hw};")
    if f.onwrite in ONWRITE_MAP:
        lines.append(f"{INDENT*3}onwrite = {ONWRITE_MAP[f.onwrite]};")
    if f.reset is not None:
        lines.append(f"{INDENT*3}reset = {f.reset};")
    lines.append(f"{INDENT*2}}} {f.name}[{f.msb}:{f.lsb}];")
    return "\n".join(lines)


def emit_register(reg, reg_width):
    lines = []
    if reg.desc:
        desc_escaped = reg.desc.replace('"', '\\"')
        lines.append(f'{INDENT}reg {{')
        lines.append(f'{INDENT*2}name = "{reg.name}";')
        lines.append(f'{INDENT*2}desc = "{desc_escaped}";')
        lines.append(f"{INDENT*2}regwidth = {reg_width};")
    else:
        lines.append(f"{INDENT}reg {{")
        lines.append(f"{INDENT*2}regwidth = {reg_width};")
    lines.append("")
    for f in reg.fields:
        lines.append(emit_field(f))
    lines.append(f"{INDENT}}} {reg.name} @ 0x{reg.offset:03X};")
    return "\n".join(lines)


def emit_rdl(registers, reg_width, addrmap_name):
    out = []
    out.append(f"// Auto-generated by excel_to_rdl.py -- DO NOT EDIT BY HAND")
    out.append(f"// Source: {addrmap_name}.xlsx")
    out.append(f"// Target: ARM CMSDK AHB lite  {addrmap_name} Programmer's Model")
    out.append("")
    out.append(f"addrmap {addrmap_name} {{")
    out.append(f'{INDENT}name = "ARM CMSDK AHB lite {addrmap_name}";')
    out.append(f'{INDENT}desc = "Register map for the ARM CMSDK AHB lite {addrmap_name} peripheral.";')
    out.append("")
    for reg in registers:
        out.append(emit_register(reg, reg_width))
        out.append("")
    out.append(f"}};")
    out.append("")
    return "\n".join(out)


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description="Convert a register Excel spec to SystemRDL.")
    ap.add_argument("input_xlsx", help="Path to input .xlsx spec file")
    ap.add_argument("-o", "--output", default=None, help="Path to output .rdl file")
    ap.add_argument("--regwidth", type=int, default=DEFAULT_REG_WIDTH,
                    help=f"Register width in bits (default {DEFAULT_REG_WIDTH})")
    args = ap.parse_args()
    # Peripheral name = Excel filename without extension
    peripheral_name = Path(args.input_xlsx).stem

    # Remove trailing "_RDL" if present
    if peripheral_name.upper().endswith("_RDL"):
        peripheral_name = peripheral_name[:-4]

    if args.output is None:
        args.output = peripheral_name + ".rdl"

    try:
        registers = read_excel(args.input_xlsx)
        for reg in registers:
            add_reserved_fields(reg, args.regwidth)
        rdl_text = emit_rdl(registers, args.regwidth, peripheral_name)
    except SpecError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    with open(args.output, "w") as fh:
        fh.write(rdl_text)

    n_fields = sum(len(r.fields) for r in registers)
    print(f"OK: wrote {args.output}")
    print(f"    {len(registers)} registers, {n_fields} fields "
          f"(including auto-generated reserved fields)")


if __name__ == "__main__":
    main()
