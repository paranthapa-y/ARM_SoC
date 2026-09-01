import struct

outfile = open("trace.bin", "wb")

with open("icode_trace.txt", "r") as f:

    for line in f:

        fields = line.split()

        # Skip header lines
        if len(fields) < 5:
            continue

        try:
            address = int(fields[1], 16)
            word    = int(fields[2], 16)
        except:
            continue

        # Write 32-bit word in little-endian format
        outfile.write(struct.pack("<I", word))

outfile.close()

print("trace.bin generated successfully.")
