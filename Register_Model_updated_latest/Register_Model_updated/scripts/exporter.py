#!/usr/bin/env python3

"""
Custom SystemRDL -> C Header Exporter

Stage 2:
    - Parse SystemRDL
    - Build internal register model
    - Emit C unions into a header file
"""

import argparse
import sys

from systemrdl import RDLCompiler

from model import Peripheral, Register, Field
from emitter import CEmitter


class HeaderExporter:

    def __init__(self):
        self.compiler = RDLCompiler()

    def compile(self, filename):
        self.compiler.compile_file(filename)
        return self.compiler.elaborate()

    def build_model(self, root):

        top = root.top

        peripheral = Peripheral(
            name=top.inst_name,
            desc=top.get_property("desc"),
        )

        # Walk all registers
        for reg_node in top.registers():

            reg = Register(
                name=reg_node.inst_name,
                offset=reg_node.absolute_address,
                desc=reg_node.get_property("desc"),
                width=reg_node.get_property("regwidth"),
            )

            # Walk all fields
            for f in reg_node.fields():

                field = Field(
                    name=f.inst_name,
                    lsb=f.low,
                    msb=f.high,
                    width=f.high - f.low + 1,
                    sw=str(f.get_property("sw")),
                    hw=str(f.get_property("hw")),
                    reset=f.get_property("reset"),
                    onwrite=f.get_property("onwrite"),
                )

                reg.fields.append(field)

            peripheral.registers.append(reg)

        return peripheral


def main():

    parser = argparse.ArgumentParser(
        description="Custom SystemRDL C Header Exporter"
    )

    parser.add_argument(
        "input",
        help="Input SystemRDL (.rdl) file",
    )

    parser.add_argument(
        "-o",
        "--output",
        default=None,
        help="Output header file",
    )

    args = parser.parse_args()

    from pathlib import Path

    peripheral_name = Path(args.input).stem

    if args.output is None:
        args.output = peripheral_name + "_REGISTERS.h"

    exporter = HeaderExporter()

    try:

        # Compile RDL
        root = exporter.compile(args.input)

        # Build internal model
        peripheral = exporter.build_model(root)

        # Generate C code
        emitter = CEmitter()

        emitter.emit_header()

        for reg in peripheral.registers:
            emitter.emit_register_union(peripheral, reg)

        emitter.emit_peripheral_struct(peripheral)

        emitter.emit_footer()

        # Write header file
        with open(args.output, "w") as f:
            f.write(emitter.get_text())

        print(f"Header successfully written to '{args.output}'")

    except Exception as e:

        print("ERROR:", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
