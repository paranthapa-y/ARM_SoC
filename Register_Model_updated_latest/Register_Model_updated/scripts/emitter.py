from model import Register, Peripheral


class CEmitter:

    def __init__(self):
        self.lines = []

    def writeln(self, text=""):
        self.lines.append(text)

    # ---------------------------------------------------------
    # File Header
    # ---------------------------------------------------------

    def emit_header(self):

        self.writeln("#ifndef REGISTERS_H")
        self.writeln("#define REGISTERS_H")
        self.writeln("")
        self.writeln("#include <stdint.h>")
        self.writeln("")

        # CMSIS style qualifiers
        self.writeln("#ifndef __I")
        self.writeln("#define __I  volatile const")
        self.writeln("#endif")
        self.writeln("")

        self.writeln("#ifndef __O")
        self.writeln("#define __O  volatile")
        self.writeln("#endif")
        self.writeln("")

        self.writeln("#ifndef __IO")
        self.writeln("#define __IO volatile")
        self.writeln("#endif")
        self.writeln("")

    # ---------------------------------------------------------
    # Register Union
    # ---------------------------------------------------------

    def emit_register_union(self, peripheral: Peripheral, reg: Register):

        type_name = f"{peripheral.name.upper()}_{reg.name}_Type"

        self.writeln("typedef union")
        self.writeln("{")
        self.writeln("    uint32_t WORD;")
        self.writeln("")
        self.writeln("    struct")
        self.writeln("    {")

        for field in reg.fields:

            self.writeln(
                f"        uint32_t {field.name:<20}:{field.width};"
            )

        self.writeln("    } BIT;")
        self.writeln("")
        self.writeln(f"}} {type_name};")
        self.writeln("")

    # ---------------------------------------------------------
    # Peripheral Structure
    # ---------------------------------------------------------

    def emit_peripheral_struct(self, peripheral: Peripheral):

        typedef_name = f"{peripheral.name.upper()}_TypeDef"

        self.writeln("typedef struct")
        self.writeln("{")

        for reg in peripheral.registers:

            type_name = f"{peripheral.name.upper()}_{reg.name}_Type"

            self.writeln(
                f"    __IO {type_name:<28} {reg.name};"
            )

        self.writeln("")
        self.writeln(f"}} {typedef_name};")
        self.writeln("")

    # ---------------------------------------------------------
    # Footer
    # ---------------------------------------------------------

    def emit_footer(self):

        self.writeln("#endif /* REGISTERS_H */")

    # ---------------------------------------------------------
    # Return Text
    # ---------------------------------------------------------

    def get_text(self):
        return "\n".join(self.lines)
