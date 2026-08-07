#!/usr/bin/env python3

import re
import sys
# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------
if len(sys.argv) != 2:
    print("Usage: python3 log_arm.py <TESTNAME>")
    sys.exit(1)

TESTNAME = sys.argv[1]

TRACKER_LOG = "processor_log.txt"
DISASM_FILE = f"{TESTNAME}.dis"
OUTPUT_FILE = f"{TESTNAME}_log_decoded.txt"

# ---------------------------------------------------------
# Build instruction map from objdump
# ---------------------------------------------------------

instruction_map = {}

pattern = re.compile(
    r'^\s*([0-9a-fA-F]+):\s+([0-9a-fA-F ]+)\s+(.+)$'
)

with open(DISASM_FILE) as f:

    for line in f:

        m = pattern.match(line)

        if not m:
            continue

        addr = int(m.group(1), 16)

        opcode = m.group(2).strip()

        asm = m.group(3).strip()

        # Remove comments
        asm = asm.split(";")[0].strip()

        # Remove symbol names
        asm = re.sub(r'<[^>]+>', '', asm)

        # Compress multiple spaces
        asm = re.sub(r'\s+', ' ', asm).strip()

        words = opcode.split()

        # 16-bit Thumb instruction
        if len(words) == 1:
            size = 2

        # 32-bit Thumb-2 instruction
        elif len(words) == 2:
            size = 4

        else:
            continue

        instruction_map[addr] = (size, opcode, asm)

print(f"Loaded {len(instruction_map)} instructions")

# ---------------------------------------------------------
# Open files
# ---------------------------------------------------------

with open(TRACKER_LOG) as fin, \
     open(OUTPUT_FILE, "w") as fout:

    # -----------------------------------------------------
    # Header
    # -----------------------------------------------------

    fout.write("-" * 120 + "\n")

    fout.write(
        f"{'TIME':<15}"
        f"{'BUS':<6}"
        f"{'TYPE':<8}"
        f"{'ADDRESS':<14}"
        f"{'DATA':<14}"
        f"{'OPCODE':<14}"
        f"{'INSTRUCTION'}\n"
    )

    fout.write("-" * 120 + "\n")

    # -----------------------------------------------------
    # Decode tracker
    # -----------------------------------------------------

    for line in fin:

        if line.startswith("-") or \
           line.startswith("TIME") or \
           line.strip() == "":
            continue

        cols = line.split()

        if len(cols) < 7:
            continue

        time = cols[0]
        bus = cols[1]
        rw = cols[2]
        addr = cols[3]
        data = cols[4]

        # -------------------------------------------------
        # D and S bus -> copy only
        # -------------------------------------------------

        if bus != "I":

            fout.write(
                f"{time:<15}"
                f"{bus:<6}"
                f"{rw:<8}"
                f"{addr:<14}"
                f"{data:<14}"
                f"{'-':<14}"
                f"{'-'}\n"
            )

            continue

        fetch_addr = int(addr, 16)

        # -------------------------------------------------
        # Vector table
        # -------------------------------------------------

        if fetch_addr < 0x124:

            fout.write(
                f"{time:<15}"
                f"{bus:<6}"
                f"{rw:<8}"
                f"{addr:<14}"
                f"{data:<14}"
                f"{cols[5]:<14}"
                f".word {cols[5]}\n"
            )

            continue

        # -------------------------------------------------
        # Decode instructions within this fetch window
        # -------------------------------------------------

        pc = fetch_addr

        while pc < fetch_addr + 4:

            if pc not in instruction_map:
                pc += 2
                continue

            size, opcode, asm = instruction_map[pc]

            fout.write(
                f"{time:<15}"
                f"{bus:<6}"
                f"{rw:<8}"
                f"{f'0x{pc:08x}':<14}"
                f"{data:<14}"
                f"{opcode:<14}"
                f"{asm}\n"
            )

            pc += size

print(f"Decoded tracker written to {OUTPUT_FILE}")
