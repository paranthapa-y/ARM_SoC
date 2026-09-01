# ARM_SoC

ARM Cortex-M3 "DesignStart Eval" SoC (CM3DesignStart-r0p0-02rel0): RTL +
testbench + software for simulating an ARM Cortex-M3 based SoC in ModelSim/
Questa (default), VCS, or Xcelium. Full narrative overview, directory map,
end-to-end boot/run flow, and current known issues: see `PROJECT_OVERVIEW.txt`
at the repo root — read that first for anything beyond a quick command lookup.

## What this is / is not

- The Cortex-M3 CPU core itself is a licensed, obfuscated/encrypted RTL model
  (`cortexm3_model/`) — not readable/editable source. Everything else (bus
  fabric, peripherals, top-level wiring, testbench, software) is normal RTL/C
  you can read and change.
- `boards/` is prebuilt firmware for the physical MPS2+ FPGA board — unrelated
  to the RTL simulation flow below; don't confuse the two.
- `docs/` has ARM's own PDFs (Quick Start, RTL & Testbench User Guide, FPGA
  User Guide, Customization Guide) — authoritative for anything ARM-kit-
  specific that isn't obvious from the code.

## Build & run (the one flow that matters right now: `hello`)

```bash
# 1. Compile the firmware for a test (arm-none-eabi-gcc toolchain, default)
cd m3designstart/logical/testbench/testcodes/hello
make

# 2. Compile the testbench (simulator defaults to mti/Questa; see
#    execution_tb/options.mk for SIMULATOR, TOOL_CHAIN, DSM, TARMAC, etc.)
cd ../../execution_tb
make compile SIMULATOR=mti

# 3. Run
make run TESTNAME=hello SIMULATOR=mti
# log: execution_tb/mti_<test>_run.log (or vcs_/ius_ depending on SIMULATOR)
```

Pass/fail for any test is decided purely by grepping its run log for the
literal string `** TEST PASSED **` (`execution_tb/Makefile`, `runall`
target) — a test's C source must print exactly that string on success. This
is currently broken for `hello` (see Known issues).

**Relocating where code loads (compile-time + run-time, paired):**
```bash
# compile-time: relink hello to run from a different flash address
cd m3designstart/logical/testbench/testcodes/hello
make FLASH_ORIGIN=0x1000        # also: FLASH_LENGTH=, RAM_ORIGIN=, RAM_LENGTH=

# run-time: tell the simulator to place the preloaded bytes at the same address
cd ../../execution_tb
make run TESTNAME=hello SIMULATOR=mti PLUSARGS="+FLASH_LOAD_ADDR=1000"
```
The two values must match — `FLASH_ORIGIN` controls what address the linked
code *believes* it's at; `FLASH_LOAD_ADDR` controls where the simulator
*physically drops the bytes* (in `u_ahb_blockram_128`, byte-address must be
16-byte-aligned and within `0x0`-`0x3FFFF`). Verify it took effect by
grepping the run log for `FLASH:` (prints the accepted offset, silent when
unspecified/default `0x0`), or for hard proof, `examine` the memory directly:
```
vsim -c -64 +FLASH_LOAD_ADDR=1000 tb_fpga_shield \
  -do "run 0; examine -radix hex /tb_fpga_shield/u_fpga_top/u_fpga_system/u_user_partition/u_m3ds_simple_flash/u_ahb_blockram_128/BRAM0[256]; quit -f"
```
(index = byte address >> 4). Note: this does **not** relocate where the CPU
boots from — reset always fetches SP/PC from hardware address `0x0`
regardless, so a non-zero `FLASH_LOAD_ADDR` alone will not produce a booting
program (address `0x0` reads as zero) — confirmed directly in simulation.
Full detail in `PROJECT_OVERVIEW.txt` under "FLASH LOAD ADDRESS".

Other useful targets in `execution_tb/`: `make testcode TESTNAME=<name>`
(build one test), `make tests` (build all), `make runall` (run all + summary),
`make clean` / `make clean_tests` / `make clean_all`.

Per team decision (commit `b748fab`), only `hello`'s `.c` source is tracked
in git; other `testcodes/*/` folders keep their `makefile`/project files but
not their `.c` sources — **`hello` is the test to focus development on**
unless told otherwise.

## Architecture (top to bottom)

```
tb_fpga_shield.v (sim top)
  -> fpga_top.v -> fpga_system.v -> m3ds_user_partition.v (customization layer)
       -> m3ds_iot_top (m3designstart_iot/)     bus fabric + CPU wrapper:
            -> p_beid_interconnect_f0_ahb_mtx    CUSTOM AHB matrix (NOT cmsdk_ahb_busmatrix)
            -> CORTEXM3INTEGRATIONDS             the CPU model (obfuscated RTL)
            -> p_beid_peripheral_f0              2x custom timer (NOT cmsdk_apb_timer)
       -> m3ds_peripherals_wrapper.v -> beetle_peripherals_fpga.v
            UART0/UART1 (cmsdk_apb_uart), dual-timer, watchdog, GPIO (cmsdk_*),
            RTC (rtc_pl031/), TRNG (trng/) — plus fpga_apb_subsystem.v pulling
            in SSP/I2C/I2S/VGA from smm/.
```

Only ~7 of the ~30 `cmsdk/logical/cmsdk_*` IP blocks are actually
instantiated (uart, ahb_gpio/iop_gpio, ahb_slave_mux, ahb_default_slave,
apb_dualtimers, apb_watchdog, + cmsdk_irq_sync). Several similarly-named ones
are NOT used and are silently superseded by custom equivalents —
`cmsdk_apb_timer` and `cmsdk_ahb_busmatrix` in particular look like the
obvious choice but aren't what this SoC uses. `m3designstart_iot/`,
`rtc_pl031/`, `smm/`, `trng/` are all live, wired-in dependencies, not
optional/reference bundles — don't assume they're safe to ignore or delete.
Full traced hierarchy and the complete used/unused list: `PROJECT_OVERVIEW.txt`.

Firmware boot: linker script `m3designstart/software/common/scripts/cm3ds.ld`
places FLASH (code) at `0x00000000` / 64KB and RAM (data) at `0x20000000` /
63KB — standard Cortex-M vector-table-at-0 boot (word 0 = initial SP, word 1
= `Reset_Handler` address). `execution_tb`'s `make run` converts the test's
`.bin` into `flash_main.ini` (a byte-swapped hex dump) which the CPU model
reads to preload code memory before releasing reset.

UART output path: C `printf`/`UartPutc` -> CMSDK APB UART0 DATA register ->
testbench module `cmsdk_uart_capture_ard.v` sniffs the serial TX line bit by
bit and echoes captured lines into the run log with timestamps. Sending byte
`0x04` (EOT) is what ends the simulation.

## Conventions specific to this repo

- Build artifacts for `hello` (`hello.bin`, `.hex`, `.lst`) ARE intentionally
  committed to git — treat them as part of the reference test, not something
  to gitignore. Build artifacts for other tests are not (their `.c` sources
  were removed).
- `.gitignore` should stay reasonably comprehensive (it should cover `*.o`,
  `*.log`, simulator scratch dirs like `work/`, `*.swp`, etc.) — it's been
  thin (just `*.qpg`) since at least 2026-07-17, and that state is now
  **committed** at HEAD, not just an uncommitted accident. Simulation/build
  scratch files will keep showing up as untracked until someone deliberately
  restores it.
- The C sources under `m3designstart/software/common/retarget/` and
  `m3designstart/selftest/apmain/` implement `UartStdOutInit`/`UartPutc`/
  `_write` retargeting that every testcode links against — changes here
  affect every test, not just one.

## Known issues (refreshed 2026-07-26, HEAD `61f10c6`)

The dual-UART work (`printf1()`/`uart_stdout1.c` + a second
`cmsdk_uart_capture_ard.v` instance) is now **committed**, not WIP — it runs
cleanly in simulation (confirmed: baseline `hello` reaches `Test Ended`).
Still true at HEAD:
- `hello.c` still does **not** print `** TEST PASSED **`, so `make runall`/
  any automated pass/fail check reports it as FAILED even on a clean run.
- Leftover commented-out/dead code and stray debug prints remain in
  `hello.c`, `uart_stdout.c`, `cmsdk_uart_capture_ard.v`.
- `.gitignore` is still thin — see above.
- ARM's reference two-stage bootloader (`software/common/bootloader/
  bootloader.c`, uses `SYSCON->REMAP`) is present but **non-functional** in
  this SoC build: `m3ds_user_partition.v`'s `mtx_remap` is hardwired to 0,
  and `beetle_sysctrl`'s `.REMAP()` output is left unconnected. Writing
  `SYSCON->REMAP` from software currently has no effect on the address
  decoder — root cause traced, not fixed.

Currently uncommitted (this session): the `FLASH_LOAD_ADDR` plusarg feature
in `ahb_blockram_128.v` (see above), removal of one line of unrelated stray
debug cruft that was silently blocking `make compile` entirely, and a couple
of minor local tweaks (UART0 `BAUDDIV` 53→32, `uart_driver_tests/makefile`
now also compiling `uart_stdout1.c`).

Full detail, plus lower-priority items, is in `PROJECT_OVERVIEW.txt` under
"KNOWN ISSUES".
