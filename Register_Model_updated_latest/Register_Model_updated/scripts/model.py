from dataclasses import dataclass, field


@dataclass
class Field:
    name: str
    lsb: int
    msb: int
    width: int
    sw: str
    hw: str
    reset: int | None
    onwrite: str | None


@dataclass
class Register:
    name: str
    offset: int
    desc: str
    width: int
    fields: list[Field] = field(default_factory=list)


@dataclass
class Peripheral:
    name: str
    desc: str
    registers: list[Register] = field(default_factory=list)
