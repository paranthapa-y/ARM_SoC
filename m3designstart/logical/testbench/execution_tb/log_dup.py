import re
import subprocess
from bisect import bisect_right
import sys


INPUT_LOG  = "processor_log.txt"


if len(sys.argv) < 2:
    print("Usage: python3 tracker.py TESTNAME")
    sys.exit(1)

TESTNAME = sys.argv[1]

OBJ_FILE = f"../testcodes/{TESTNAME}/{TESTNAME}.o"

OUTPUT_LOG = f"{TESTNAME}_tracker.txt"

result = subprocess.run(
    ["arm-none-eabi-objdump", "-d", OBJ_FILE],
    capture_output=True,
    text=True,
    check=True
)

instruction_map = {}

pattern = re.compile(
    r'^\s*([0-9a-fA-F]+):\s+'
    r'((?:[0-9a-fA-F]{4}\s*)+)\s+'
    r'(.+)$'
)

for line in result.stdout.splitlines():

    m = pattern.match(line)

    if not m:
        continue

    addr = int(m.group(1), 16)
    asm  = m.group(3).strip()

    # Remove symbol names like <Uart1Putc> or <printf1+0x52>
    asm = re.sub(r'\s*<.*?>', '', asm).strip()

    instruction_map[addr] = asm

# Sorted list of instruction start addresses
instruction_addresses = sorted(instruction_map.keys())


# ----------------------------------------------------------
# Find instruction corresponding to a PC
# ----------------------------------------------------------
def lookup_instruction(pc):

    idx = bisect_right(instruction_addresses, pc)

    if idx == 0:
        return "<NOT FOUND>"

    return instruction_map[instruction_addresses[idx - 1]]


# ----------------------------------------------------------
# Process tracker log
# ----------------------------------------------------------
with open(INPUT_LOG, "r") as fin, \
     open(OUTPUT_LOG, "w") as fout:

    for line in fin:

        # Preserve headers
        if (
            line.startswith("-")
            or line.startswith("TIME")
            or line.strip() == ""
        ):
            fout.write(line)
            continue

        cols = line.split()

        if len(cols) < 7:
            fout.write(line)
            continue

        bus = cols[1]

        # Decode only I-Bus
        if bus == "I":

            addr = int(cols[3], 16)

            asm = lookup_instruction(addr)

            fout.write(line.rstrip() + "\t" + asm + "\n")

        else:
            fout.write(line)

print(f"Decoded log written to {OUTPUT_LOG}")
