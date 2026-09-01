# cmsdk_apb_watchdog — Test Rationale & Methodology Reference

Companion document to `cmsdk_apb_watchdog_testplan.xlsx`. That spreadsheet is the
tracking artifact (IDs, priority, status); this document is the *why* — for
every test, what it's actually probing, how it's exercised, and why it earns
a place in the plan. Sources: `cmsdk_apb_watchdog.v` / `cmsdk_apb_watchdog_frc.v`
(RTL) and Section 4.5 of the Arm CMSDK TRM (`DDI0479D_m_class_processor_system_r1p1_trm (2).pdf`
— see the note on that file's actual contents in `cmsdk_apb_watchdog_testplan.xlsx`,
sheet "Scope & Sources").

---

## Part 1 — Recurring test patterns

86 tests sounds like 86 different ideas, but it isn't. Most of them are one of
about ten *techniques* applied repeatedly to different registers or signals.
Recognizing the pattern matters for two reasons: it tells you the checking
*mechanism* to reuse (don't reinvent a lock-gating check five times), and it
tells you where a bug in one instance likely means the same bug exists in the
others. Each pattern below lists every test ID that uses it — cross-reference
these tags against the per-category tables in Part 2.

| # | Pattern | The technique | Why it's a pattern, not one test |
|---|---|---|---|
| **P1** | Reset-default readback | Assert/deassert `PRESETn`, read a register or sample a pin, compare against the TRM Table 4-17 reset value. | Same mechanism, applied register-by-register. A single reset-checking helper in the RM covers all of them — the interesting bug isn't "does reset work," it's "did we forget one register." |
| **P2** | Lock-gating | Lock the device (write a non-magic value to `WDOGLOCK`), attempt a write to some other register, confirm it's silently dropped. | The RTL wires `~wdog_lock` into five independent write-enable terms (`CONTROL`, `LOAD`, `INTCLR`, `ITCR`, `ITOP`). Each is a separate line of RTL that could independently be wired wrong — testing "lock works" once and assuming it covers all five is exactly the kind of gap this plan exists to close. |
| **P3** | CDC toggle-sync robustness | Fire the same request (LOAD write, or INTCLR write) twice in immediate succession, faster than the toggle handshake into the `WDOGCLK` domain can resolve. | `wdog_load` and `int_clr` both cross clock domains via a toggle flag (`load_req_tog_p/w`, `int_clr_tog_p/w`) that's explicitly designed to suppress a second request while one is pending (`load_tog_en = load_en_reg & ~load_req_w`). That suppression logic is exactly the kind of thing that's easy to get subtly wrong, and a bug there manifests only under back-to-back stimulus — never under leisurely single-shot testing. |
| **P4** | Sticky/latched state | Set a state bit, then let time/other-events pass, and confirm it *doesn't* clear itself — only an explicit qualifying write clears it. | `WDOGRIS` (cleared only by `WDOGINTCLR`) and `WDOGRES`/`i_wdog_res` (cleared only by `RESEN` deassertion, per the RTL) are both intentionally "sticky." The risk isn't that they fail to set — it's that they clear themselves prematurely (e.g. on the next counter reload) because of a combinational term that was meant to be gated but isn't. |
| **P5** | Same-cycle race resolution | Deliberately land two independent events (a natural counter expiry, a software LOAD, an INTCLR, a RESEN toggle) on the exact same `WDOGCLK` edge. | The counter's next-state mux (`count_mux1`) ORs four trigger conditions together (`load_req_w \| carry_msb \| wdog_int_en_rise \| int_clr_w`) and always selects the *same* source value (`wdog_load`) — so the mux itself can't misbehave, but the *other* logic gated on "which condition actually fired this cycle" (interrupt latch, reset latch) can. These races are the single highest-value corner-case category in this plan because they're the ones directed testing tends to miss and random testing tends to eventually hit — in the field, months after tapeout. |
| **P6** | Reserved-bit hygiene | Write all-1s to a register's undefined/reserved bit positions, read back, confirm those bits are 0. | Cheap, mechanical, and required by the TRM's "must read as 0s" language on every reserved field. Low intellectual content but real risk if skipped: reserved bits silently carrying stray flip-flop state is a classic source of forward-compatibility breakage. |
| **P7** | RO/WO register semantics | Write to a read-only register, or read a write-only one, and confirm the "wrong-direction" access is inert — no state change, no side effect, no protocol error. | `cmsdk_apb_watchdog` has no `PSLVERR`, so there's no protocol-level signal that a software bug (e.g. firmware accidentally writing `WDOGVALUE`) was even attempted — the only way to know the RTL correctly ignored it is to check that nothing changed. |
| **P8** | Integration-test output-mux override | Set `WDOGITCR=1`, drive `WDOGITOP`, confirm `WDOGINT`/`WDOGRES` follow the test register directly, independent of whatever the real counter is doing underneath. | This is a single 2-line RTL mux (`WDOGINT = itcr ? itop[1] : i_wdogint`), but it's also the *only* way to functionally test the watchdog's output pins from an ATE/scan environment without waiting out a real countdown — so its correctness matters beyond this testbench, to production test as well. |
| **P9** | Live/time-evolving correctness | Sample a value that changes continuously in hardware, independent of when it's read, and confirm the read reflects genuinely current state rather than a stale or precomputed snapshot. | `WDOGVALUE` is a free-running down-counter — there's no "transaction" to wait for, the DUT is just always in motion. This is the pattern discussed earlier in this session as needing a *time-evolving reference model* (one that ticks on the same `WDOGCLK`/`WDOGCLKEN` stimulus as the DUT) rather than a reactive one that only computes on write. |
| **P10** | Composite / soak / random regression | Layer many of the above (random LOAD values, random enable gating, random lock/unlock, random reset injection) into one long constrained-random run. | Individual directed tests prove each mechanism works in isolation; this pattern proves they still work when combined in combinations nobody thought to direct — which is exactly where P5-style races tend to surface in practice. |

---

## Part 2 — Every test: what / how / why

Tables below mirror the Excel's categories and test IDs. **Pattern** references
the table above.

### Reset & Default State

| ID | What it tests | How it's tested | Why it matters | Pattern |
|---|---|---|---|---|
| RST_01 | `WDOGLOAD` returns to `0xFFFFFFFF` after reset. | Reset with no prior writes, read `WDOGLOAD`. | Baseline correctness — if the reload register doesn't start at all-1s, a watchdog left un-programmed would time out almost immediately instead of never, which is the opposite of the intended fail-safe default. | P1 |
| RST_02 | `WDOGVALUE` returns to `0xFFFFFFFF` after reset. | Read `WDOGVALUE` before any `WDOGCLK` edge. | Same fail-safe reasoning as RST_01, but on the live counter register (`reg_count`) rather than the reload register — two separate flops, two separate chances to get the reset value wrong. | P1 |
| RST_03 | `WDOGCONTROL` (`INTEN`, `RESEN`) both reset to 0. | Read `WDOGCONTROL` after reset. | If either bit powered up as 1, the watchdog could start counting or resetting the system before software ever configures it — a silent, hard-to-diagnose boot failure. | P1 |
| RST_04 | `WDOGRIS`/`WDOGMIS` both reset to 0. | Read both after reset. | Confirms no interrupt is latched out of reset — otherwise the very first `WDOGMIS`/`WDOGINT` read by boot code would look like a spurious pending watchdog event. | P1 |
| RST_05 | `WDOGLOCK` reads 0 (unlocked) after reset. | Read `WDOGLOCK` after reset. | If it powered up locked, no other watchdog register could ever be programmed — a bricked peripheral. | P1 |
| RST_06 | `WDOGITCR` reads 0 (test mode off) after reset. | Read `WDOGITCR` after reset. | If test mode powered up active, the real interrupt/reset outputs would be permanently masked by whatever garbage is in `WDOGITOP` until software explicitly noticed and cleared it. | P1 |
| RST_07 | `WDOGINT`/`WDOGRES` output pins are LOW immediately at reset, before any `WDOGCLK` activity. | Sample both pins the cycle after `PRESETn` deasserts. | These are the two signals that can assert an NMI or a system reset (per the TRM's example system wiring) — an X or garbage value on them at power-up is the highest-consequence possible bug in this IP. | P1 |
| RST_08 | `PRESETn` and `WDOGRESn` are genuinely independent reset domains — PCLK-domain registers only reset on `PRESETn`, WDOGCLK-domain state only on `WDOGRESn`. | Assert each independently, together, and staggered; check that only the correct domain's state actually resets in each case. | This design deliberately has *two* async resets. A verification environment that only ever pulses them together will never notice if, say, `wdog_lock` were miswired to also depend on `WDOGRESn` — a bug that would only show up in a real SoC where the two reset trees are driven by different sources. | — |
| RST_09 | Clean recovery when reset hits mid-operation — counter running, interrupt latched, or a LOAD/INTCLR toggle-sync request in flight. | Assert reset at each of those points, then check post-reset state is exactly the documented default with no stuck toggle-sync state that "replays" once reset lifts. | The toggle synchronizers (`load_req_tog_p/w`, `int_clr_tog_p/w`) are two independent flops that must land back in the *matched* state after reset — if only one half resets, the mismatch reads as "a request is pending" and the DUT spuriously reloads or clears something the instant it comes out of reset. | P4-adjacent |

### Register Access

| ID | What it tests | How it's tested | Why it matters | Pattern |
|---|---|---|---|---|
| REG_01 | Basic write/readback data integrity on `WDOGLOAD`. | Walking-1s, walking-0s, all-0, all-1, random patterns; write then read back. | The most basic possible check, but it's the one that catches a byte-swapped or truncated data path before any of the more subtle tests even become meaningful to run. | — |
| REG_02 | Every register in the TRM's Table 4-17 map, read after reset and after programming. | Sweep all documented addresses. | This is P1 generalized into a single sweep — a fast way to catch an entire register being missing from the read-data mux (`prdata_next`) rather than testing each one as a separate directed case. | P1 |
| REG_03 | Unmapped addresses inside the 4KB APB region return 0 on read and are inert on write. | Access addresses not in Table 4-17. | The read-data mux's default terms and the write-enable decode both need to agree that "no register matches" is a safe, silent no-op — not an X, not an accidental hit on a neighboring register due to incomplete address decode. | — |
| REG_04 | Reserved bit positions in `WDOGCONTROL`, `WDOGRIS`, `WDOGMIS`, `WDOGITCR`, `WDOGITOP` always read 0. | Write all-1s, read back, check only the documented bits stuck. | See P6. | P6 |
| REG_05 | `WDOGINTCLR` (write-only) returns 0 on read, with no side effect. | Read the `WDOGINTCLR` address. | It isn't even in the RTL's read-data case statement — this test exists to lock in that a *read* can never accidentally trigger the clear-and-reload behavior that a *write* to the same address does. | P7 |
| REG_06 | `WDOGPERIPHID3[7:4]` mirrors the `ECOREVNUM` input. | Sweep all 16 values of `ECOREVNUM`, read `WDOGPERIPHID3`. | `ECOREVNUM` is the SoC-integrator's hook for silicon ECO tracking — if it doesn't reach the register, a post-silicon fix's revision number becomes unreadable by software, undermining the entire mechanism's purpose. | — |
| REG_07 | Peripheral/PrimeCell ID registers match fixed TRM constants. | Read all 11 ID registers. | These are what generic driver/discovery software (and debug tooling) uses to identify the IP at runtime — wrong values here don't break watchdog *function*, but they break every tool that auto-detects the peripheral. | — |

### Lock Mechanism

| ID | What it tests | How it's tested | Why it matters | Pattern |
|---|---|---|---|---|
| LOCK_01 | Device is unlocked by default (writes succeed with no `WDOGLOCK` write at all). | Reset, then write `LOAD`/`CONTROL`/`INTCLR` directly. | Establishes the unlocked baseline the rest of the LOCK tests differ from. | — |
| LOCK_02 | Writing the magic value `0x1ACCE551` unlocks. | Write it, read `WDOGLOCK` back, confirm 0. | Confirms the *specific* unlock value the TRM documents — not "any write unlocks," which would defeat the whole purpose of the mechanism. | — |
| LOCK_03 | Writing *any other* value locks. | Try several non-magic values including an off-by-one (`0x1ACCE550`, `0x1ACCE552`). | The off-by-one cases specifically guard against a fencepost bug in the magic-value comparator — the RTL uses a single equality check (`PWDATA == 32'h1ACCE551`), so this is a direct check of that one comparator being exactly right, not approximately right. | — |
| LOCK_04 | Locked `WDOGINTCLR` write is ignored — interrupt stays latched, counter is not reloaded. | Latch an interrupt, lock, then write `WDOGINTCLR`. | This is P2 applied to the one register whose write-enable term is easy to get wrong, because `int_clr_en` is a more complex expression (`~int_clr_w & PWRITE & frc_sel & ~PENABLE & ~wdog_lock & ...`) than the other lock-gated registers — more terms, more chances for `~wdog_lock` to get dropped or mis-ANDed. | P2 |
| LOCK_05 | `WDOGLOCK` itself can always be written, even while currently locked. | Lock the device, then write the magic value again. | If this were wrong, a locked watchdog could never be unlocked — permanently disabling the ability to reprogram it. This is the one register that must be the *exception* to the P2 pattern, and testing it as an explicit exception (not just assuming symmetry) is the point. | — |
| LOCK_06 | Reading `WDOGLOCK` returns only bit[0], regardless of what was written. | Write `0xDEADBEEF`, then the magic value; read back after each. | The upper 31 bits of the write data are meaningful (they're compared against the magic value) but not meant to be *stored and read back* — this confirms the register isn't accidentally implemented as a plain read/write 32-bit register. | — |
| LOCK_07 | Locking doesn't affect the free-running counter itself. | Start counting, then lock, then let it continue. | Confirms the lock is scoped to *register writes* only, not wired (even accidentally) into the counter's enable/count-stop logic — a watchdog that stops counting the moment it's locked would defeat its own tamper-resistance purpose. | — |
| LOCK_08 | Locked `WDOGITCR`/`WDOGITOP` writes are ignored. | Lock, then attempt both writes. | P2 applied to the integration-test registers — worth testing separately because entering test mode while locked, if it worked, would let software mask the real `WDOGINT`/`WDOGRES` outputs even on a "tamper-proofed" watchdog, defeating the lock's purpose in a different way than LOCK_04 does. | P2 |

### Control Register

| ID | What it tests | How it's tested | Why it matters | Pattern |
|---|---|---|---|---|
| CTRL_01 | Counter is frozen while `INTEN=0`. | Leave `INTEN` at its reset value, pulse `WDOGCLK`/`WDOGCLKEN` for many cycles, confirm `WDOGVALUE` never moves. | `INTEN` isn't just an interrupt mask — per the TRM it also gates the counter itself. A design that only checks "no interrupt when disabled" without checking "no counting when disabled" would miss a bug where the counter free-runs invisibly and wraps before software ever enables it. | — |
| CTRL_02 | Counter runs when `INTEN=1`. | Program `WDOGLOAD`, set `INTEN=1`, apply clocking. | The positive-case complement of CTRL_01. | — |
| CTRL_03 | The `0→1` transition on `INTEN` reloads the counter from `WDOGLOAD`, even without a fresh `WDOGLOAD` write. | Let the counter sit partway through a count, clear `INTEN`, set it again, check the counter snapped back to `WDOGLOAD` rather than resuming from where it left off. | This is a one-shot edge-detector in the RTL (`wdog_int_en_rise = wdog_int_en & ~wdog_int_en_reg`) that only fires for a single `WDOGCLK` cycle — exactly the kind of narrow-window behavior that's invisible unless you specifically probe the transition, not just the steady states on either side of it. | — |
| CTRL_04 | Counter freezes (holds value) when `INTEN` is cleared mid-count. | Disable mid-count, wait many cycles, confirm the value hasn't drifted. | Distinguishes "disabled" from "still decrementing but interrupt just masked" — a subtle but important difference in what software can assume about `WDOGVALUE` while the watchdog is off. | — |
| CTRL_05 | `RESEN=0` fully masks `WDOGRES`, even across repeated unserviced timeouts. | Let the counter expire twice with `RESEN=0`; confirm `WDOGINT` still behaves normally but `WDOGRES` never asserts. | The most safety-critical negative test in the whole plan — this is what lets software disable the *reset* behavior for debug while keeping the *interrupt* behavior for monitoring, and a leak here means an accidental system reset during bring-up/debug. | — |
| CTRL_06 | `RESEN=1` alone (with `INTEN=0`) can never produce a reset. | Set `RESEN=1`, leave `INTEN=0`, wait. | Confirms the two enables are properly independent-but-coupled: reset generation needs `carry_msb`, which only happens if the counter is actually running, which needs `INTEN`. Worth stating explicitly rather than assuming, since it's a two-hop logical dependency a reader of the register spec alone might not infer. | — |
| CTRL_07 | The race where `RESEN` is set to 1 on the *exact* `WDOGCLK` cycle the counter expires with an interrupt already latched from a prior timeout. | Directed alignment of the `RESEN` write's CDC-resolved effect with `carry_msb`'s assertion, plus randomized variants. | This is the P5 pattern's sharpest instance in the whole IP: `nxt_wdog_res` is purely combinational on `wdog_res_en`, `wdog_ris`, and `carry_msb` — so the *exact* cycle `RESEN` takes effect relative to the expiry decides whether a reset fires. Flagged as Open Question OQ-7 in the testplan because it's unclear whether real firmware would ever produce this sequence. | P5 |
| CTRL_08 | `WDOGCONTROL` reserved bits `[31:2]` always read 0. | Write `0xFFFFFFFF`, read back. | See P6. | P6 |

### Load / Counter Reload

| ID | What it tests | How it's tested | Why it matters | Pattern |
|---|---|---|---|---|
| LOAD_01 | A `WDOGLOAD` write is visible on `WDOGVALUE` on the *very next* APB read, even before the value has physically propagated into the `WDOGCLK`-domain counter. | Write `WDOGLOAD` while running, immediately read `WDOGVALUE` on the next APB cycle. | This tests the RTL's explicit read-bypass (`count_read = load_req_w ? wdog_load : reg_count`) — a deliberate design feature to avoid a confusing "I just wrote X but read back the old value" experience for software. It's also the clearest example in this IP of why the reference model has to be *time-evolving* rather than reactive-on-write (see P9): the expected value for this read depends on internal pending-state, not just "what was last written." | P9 |
| LOAD_02 | The counter's *actual* internal value is loaded on the `WDOGCLK` edge following toggle-sync completion, then decrements normally from there. | Write `WDOGLOAD`, poll `WDOGVALUE` across subsequent `WDOGCLK` edges until it settles. | The other half of LOAD_01 — confirms the bypass-read value and the eventually-settled real value agree, i.e. the bypass isn't just cosmetic/wrong. | — |
| LOAD_03 | The documented minimum valid value, `WDOGLOAD=1`, produces exactly one decrement to expiry. | Load 1, enable, check timing to `WDOGINT`. | Boundary-value testing at the one edge the TRM explicitly calls out as the legal minimum. | — |
| LOAD_04 | Behavior at `WDOGLOAD=0`, one below the documented minimum. | Load 0, enable, observe. | Genuinely undocumented territory (see Open Question OQ-2) — the test exists to characterize actual behavior and confirm it's at least not a hang/lockup, pending a ruling on whether more is required. | — |
| LOAD_05 | Two `WDOGLOAD` writes issued faster than the toggle-sync handshake can resolve the first. | Back-to-back APB writes to `WDOGLOAD`. | This is P3 — the RTL's `load_tog_en = load_en_reg & ~load_req_w` term is specifically there to prevent a second toggle before the first is acknowledged in the `WDOGCLK` domain; if that suppression logic has an off-by-one, the failure mode is either a dropped write or a corrupted mid-flight value, and it will *never* show up under single, well-spaced writes. | P3 |
| LOAD_06 | `WDOGLOAD` write is ignored while locked. | Lock, then write. | P2 applied to `WDOGLOAD` specifically. | P2 |
| LOAD_07 | Writing `WDOGLOAD` after a `WDOGRES` timeout restarts the stopped counter. | Drive to a reset condition (`count_stop=1`), then write `WDOGLOAD`. | `count_stop` is explicitly cleared by `load_req_w` in the RTL — this is the documented software recovery path from a stopped counter, so it needs to actually work, not just be assumed from reading the logic equation. | — |

### Free-running Counter

| ID | What it tests | How it's tested | Why it matters | Pattern |
|---|---|---|---|---|
| CNT_01 | Counter decrements by exactly 1 per qualified `WDOGCLK` edge, at multiple `WDOGCLK:PCLK` ratios. | Sweep clock ratios (1:1, 1:2, 1:4, 1:8) via `WDOGCLKEN` gating patterns. | The counter is meant to work at *any* legal ratio the SoC integrator chooses — testing only 1:1 would miss a bug that only appears when `WDOGCLKEN` gates the clock down. | P9 |
| CNT_02 | Counter does not move at all while `WDOGCLKEN=0`, regardless of `WDOGCLK` toggling. | Hold `WDOGCLKEN` low for many `WDOGCLK` periods. | `WDOGCLKEN` is the qualifier on every WDOGCLK-domain sequential update in the RTL — if any one of those updates were accidentally left unqualified, this is the test that would catch it. | — |
| CNT_03 | Counter tracks an *irregular*, randomized `WDOGCLKEN` gating pattern exactly. | Randomize enable gaps, cross-check `WDOGVALUE` at random points against the live RM's tick count. | Real SoC clock-gating for power management doesn't produce neat ratios — it produces exactly this kind of irregular pattern, so this is closer to real silicon operating conditions than CNT_01's clean ratios. | P9 |
| CNT_04 | The internal 16+16-bit split counter's carry chain behaves correctly across the half-word boundary. | Directed loads at `0x00010000`, `0x00000001`, `0x00008000`, `0x0000FFFF`, `0xFFFF0001`. | The RTL comment itself flags that the 32-bit counter is implemented as two 16-bit halves "to improve FPGA implementation" — split-counter carry logic is one of the single most common places for an off-by-one borrow bug to hide, and it's invisible unless you specifically cross the boundary. | — |
| CNT_05 | Deterministic resolution when the counter's natural expiry coincides with a software LOAD or INTCLR on the same `WDOGCLK` edge. | Directed alignment + randomized variants. | P5 again, at the counter level rather than the control-register level — same underlying risk (combinational logic reacting to "which of several simultaneous triggers fired"), different signals. | P5 |
| CNT_06 | `WDOGVALUE` reads are always self-consistent (monotonically decrementing, no glitches) no matter when they're sampled relative to `WDOGCLK`. | Read at many random un-synchronized points during active counting. | This is the practical stress-test of the P9 live-RM requirement — if the RM's own tick-tracking has a bug, this is the test that exposes it as spurious mismatches, so it also doubles as a self-check on the testbench's own correctness. | P9 |

### Interrupt Generation

| ID | What it tests | How it's tested | Why it matters | Pattern |
|---|---|---|---|---|
| INT_01 | First expiry with `INTEN=1` sets `WDOGRIS`, and `WDOGMIS`/`WDOGINT` follow (`RIS & INTEN`). | Let the counter reach 0. | Establishes the basic interrupt path end-to-end, register through pin. | — |
| INT_02 | Interrupt cannot occur while `INTEN=0` (counter frozen). | Wait many cycles with `INTEN=0`. | Follows directly from CTRL_01 — listed separately because it's checking the *interrupt* consequence specifically, not just the counter value. | — |
| INT_03 | `WDOGRIS` stays latched indefinitely — it does not self-clear on subsequent reload/recount cycles. | Let many further `WDOGCLK` edges and reload cycles pass without writing `WDOGINTCLR`. | This is P4 — the RTL's `nxt_wdog_ris = (carry_msb \| wdog_ris) & ~int_clr_w` deliberately ORs in the *current* latched value so it survives until explicitly cleared. A missing `wdog_ris` term in that OR would silently clear the interrupt on the counter's next reload, which is a real, plausible RTL bug and hard to spot by inspection alone. | P4 |
| INT_04 | `WDOGMIS` tracks `INTEN` live, independent of `WDOGRIS`'s latched state. | With `WDOGRIS=1` already latched, toggle `INTEN` `1→0→1` and check `WDOGMIS` follows immediately each time, with no new timeout needed. | Confirms `WDOGMIS` is a *combinational* mask (`read_wdog_ris & wdog_int_en`), not something that only updates when a new interrupt event happens — a distinction software polling `WDOGMIS` right after changing `INTEN` depends on. | — |
| INT_05 | Steady-state periodic interrupt behavior over many serviced timeout cycles. | Run N expiry-then-`WDOGINTCLR` cycles back to back; confirm consistent period and no drift/missed/spurious events. | This is where a subtle CDC or reload bug that's invisible on a single cycle (P3/P5 territory) accumulates into visible drift over many cycles — a soak-style complement to the single-shot directed tests above it. | P10-adjacent |

### Interrupt Clear

| ID | What it tests | How it's tested | Why it matters | Pattern |
|---|---|---|---|---|
| CLR_01 | Writing `WDOGINTCLR` (any data value) clears `WDOGRIS`/`WDOGMIS`/`WDOGINT` and reloads the counter. | Write with data `0x0` and `0xFFFFFFFF`, confirm identical effect either way. | The TRM explicitly says "a write of *any* value" — testing two very different data patterns with the same expected outcome directly checks that the RTL doesn't accidentally decode specific bits of `PWDATA` on this address. | — |
| CLR_02 | The counter reload on `WDOGINTCLR` is *unconditional* — it happens even if no interrupt was pending. | Write `WDOGINTCLR` while `WDOGRIS=0`. | Easy to misread the spec as "clear clears the interrupt, and incidentally reloads" (i.e., reload gated on RIS being set); the RTL's `int_clr_w` term feeds the counter mux regardless of `wdog_ris`. This test exists specifically to pin down that reading. | — |
| CLR_03 | Locked `WDOGINTCLR` write is ignored. | Same as LOCK_04 — listed here too because it's equally a CLR-category regression check, not just a LOCK-category one. | P2 | P2 |
| CLR_04 | Rapid, repeated `WDOGINTCLR` writes faster than the toggle-sync can resolve the first. | Back-to-back writes to the `WDOGINTCLR` address. | P3, mirroring LOAD_05 but on the *other* toggle-synchronized channel (`int_clr_tog_p/w` instead of `load_req_tog_p/w`) — the two channels are separate RTL instances of the same pattern and each needs its own test. | P3 |
| CLR_05 | `WDOGINTCLR` written on the exact cycle the counter is naturally expiring (`carry_msb` asserting). | Directed alignment + randomized variants. | P5 — the RTL explicitly deasserts `int_clr_w` on `~carry_msb`, meaning the clear signal's own duration depends on the counter's state, creating a two-way coupling that's worth probing directly rather than trusting by inspection. | P5 |

### Reset Generation

| ID | What it tests | How it's tested | Why it matters | Pattern |
|---|---|---|---|---|
| RES_01 | A *first* timeout never asserts `WDOGRES`, even with `RESEN=1` — only `WDOGINT`/`WDOGRIS` assert. | First-ever expiry since enable. | This is the core "two strikes" behavior the whole IP exists to implement (per the TRM's flow diagram) — asserting reset on the *first* miss would be far too aggressive for real firmware watchdog-kick timing. | — |
| RES_02 | A *second* unserviced timeout does assert `WDOGRES`. | Let the interrupt from the first expiry go unserviced through to a second expiry. | The positive-case complement of RES_01 — together they pin down the exact "two consecutive misses" semantics. | — |
| RES_03 | Servicing the interrupt (`WDOGINTCLR`) between the first and second expiry prevents the reset entirely. | Clear after the first timeout, before the second. | This is the behavior real firmware depends on for normal operation — "kick the watchdog on time and it never resets you" — so it's arguably the single most consequential positive test in the plan. | — |
| RES_04 | The counter stops (and stays stopped) once `WDOGRES` asserts. | Observe `WDOGVALUE`/`count_stop` over many further edges with no `WDOGLOAD` write. | P4 — same "does it hold until explicitly cleared" concern as the interrupt latch, applied to `count_stop`. Without this, the counter could keep expiring and re-triggering resets in a loop even after the system has (notionally) already reset. | P4 |
| RES_05 | Whether a `WDOGLOAD` write alone deasserts an already-asserted `WDOGRES`. | Assert `WDOGRES`, then write `WDOGLOAD` (which does restart counting, per LOAD_07), and watch the `WDOGRES` pin itself. | The RTL's `nxt_wdog_res` is a level held by `i_wdog_res` unless `wdog_res_en` (RESEN) goes to 0 — meaning, as written, a LOAD write does **not** clear it. That's not documented anywhere in the TRM. This test exists to nail down actual behavior pending Open Question OQ-1, because it directly contradicts the more intuitive assumption that "reprogramming the watchdog clears its reset request." | P4 |
| RES_06 | Clearing then re-setting `RESEN` clears the sticky `WDOGRES` latch, without spuriously reasserting it. | With `WDOGRES` asserted, clear `RESEN`, confirm deassert, then set `RESEN=1` again with no new qualifying timeout, confirm it stays low. | Confirms the *documented* recovery path (per RTL logic) actually works, and — just as important — that re-enabling `RESEN` doesn't immediately re-trigger a reset from stale latched state. | P4 |
| RES_07 | `WDOGRES` pulse-width / duration requirements for the downstream reset generator. | N/A at this unit level — flagged for SoC integration testing. | The TRM doesn't specify a minimum pulse width at the IP level; whatever consumes `WDOGRES` (per this repo's `m3ds_user_partition`/`beetle_sysctrl` wiring) has its own requirements that belong in a system-level testplan, not here. Listed to make the scope boundary explicit rather than silently dropped. | — |
| RES_08 | Integration test mode correctly masks `WDOGRES` while a real countdown continues evolving underneath, and the real state becomes visible again once test mode exits. | Start a real countdown toward reset, enter `WDOGITCR=1` mid-sequence, exit later. | Combines P8 with a "does the masked-out logic keep running correctly while hidden" check — a mux can correctly select its test input while *also* accidentally freezing or corrupting the real state behind it, and only exiting test mode and checking reveals that. | P8 |

### Integration Test Mode

| ID | What it tests | How it's tested | Why it matters | Pattern |
|---|---|---|---|---|
| ITM_01 | `WDOGITCR=1` makes `WDOGINT`/`WDOGRES` follow `WDOGITOP[1:0]` directly, for all 4 combinations. | Sweep `WDOGITOP` through all values with `WDOGITCR=1`. | The core P8 check — this is what lets production test/ATE flows exercise the two output pins deterministically without running a real, slow countdown. | P8 |
| ITM_02 | Exiting test mode (`WDOGITCR=0`) immediately reverts outputs to the real counter-driven values. | Clear `WDOGITCR` after forcing known values via `WDOGITOP`. | Confirms the mux switches cleanly both directions, not just into test mode. | P8 |
| ITM_03 | `WDOGITOP` can be written (and is retained) while `WDOGITCR=0`, with no effect until test mode is later entered. | Write `WDOGITOP` with `WDOGITCR=0`. | Confirms the register-write path and the output-mux-select path are properly independent — software can stage a test pattern before entering test mode. | — |
| ITM_04 | `WDOGITCR`/`WDOGITOP` writes are ignored while locked. | Same as LOCK_08. | P2 | P2 |
| ITM_05 | Full truth-table coverage of `WDOGITOP[1:0]` → `WDOGINT`/`WDOGRES` mapping, as an explicit coverage bin. | Cross-check all 4 combinations are hit and correctly mapped. | Turns ITM_01's spot-check into a closed coverage goal rather than a "we tried a couple of values" check. | P8 |

### APB Protocol

| ID | What it tests | How it's tested | Why it matters | Pattern |
|---|---|---|---|---|
| APB_01 | Standard SETUP/ACCESS handshake access to every register. | Drive standard single-cycle APB reads/writes across the whole map. | Baseline protocol compliance — largely the domain of assertions/VIP rather than this IP's own logic, but still needs to be exercised against every address to confirm decode alignment. | — |
| APB_02 | Back-to-back transactions, no idle cycle between ACCESS and the next SETUP. | Consecutive transactions with zero gap. | Confirms write-capture timing (qualified on `~PENABLE`) doesn't require an idle cycle to settle correctly — a real firmware register-init sequence is often exactly this kind of back-to-back burst. | — |
| APB_03 | The *exact* APB cycle a write is captured on, relative to the `PENABLE` transition. | Directed timing check against the RTL's `~PENABLE`-qualified write-enable terms. | This is really a precision version of APB_02 — pins down *which* cycle, not just "it eventually works," which matters for the CDC-adjacent timing tests elsewhere in the plan that assume a specific capture point. | — |
| APB_04 | No stale `PRDATA` leakage when interleaving reads/writes to different registers. | Interleave accesses to different addresses back-to-back. | The read-data path is a single registered mux (`i_prdata`) shared by every register — this confirms it's fully re-decoded each access, not accidentally holding over a previous value under some address sequence. | — |
| APB_05 | This slave has no `PREADY`/`PSLVERR` — it's a fixed single-cycle, zero-wait-state responder. | Environment configuration note, not a DUT behavior test. | Documented so the APB agent/VIP is configured correctly (no wait-state injection attempted against this DUT) rather than discovered as a "failure" during bring-up. | — |
| APB_06 | This module exposes no `PSTRB` — byte-lane partial writes aren't supported at this interface. | Scope note; see Open Question OQ-4. | Flags that byte-write handling, if it exists at all in this SoC, must be verified at the bus-fabric/wrapper level upstream of this slave — not a gap in this plan, but a boundary that needs to be explicitly owned by someone. | — |

### Clock Domain Crossing

| ID | What it tests | How it's tested | Why it matters | Pattern |
|---|---|---|---|---|
| CDC_01 | Full functional correctness across multiple `WDOGCLK:PCLK` ratios. | Same sweep as CNT_01, run against the *whole* functional suite, not just the raw counter. | Generalizes CNT_01 from "does the counter tick right" to "does everything (load, clear, interrupt, reset) work right" at each ratio — some CDC bugs only manifest in the interaction between subsystems, not in either alone. | P9 |
| CDC_02 | `WDOGCLK` stalled entirely (`WDOGCLKEN` permanently low) while APB writes continue. | Write `WDOGLOAD`/`CONTROL`/`WDOGINTCLR` with the watchdog clock stopped, then resume it and confirm nothing was lost. | PCLK-domain register writes must always succeed regardless of the other clock domain's state — but the pending load/clear request must also *not* be lost, just deferred. This is the most direct test of the CDC design's whole reason for existing: tolerating an independently-gateable clock. | P3-adjacent |
| CDC_03 | Independent reset-domain behavior. | Cross-reference RST_08 — same test, listed here for CDC-category traceability. | — | — |
| CDC_04 | Whether `WDOGCLK` generation in the environment should stay within the TRM's "must be synchronous to PCLK" constraint, or also stress genuinely async/random-phase clocking. | Scope pending Open Question OQ-3. | Determines whether this needs a dedicated CDC-formal workstream (metastability-class bugs) in addition to functional simulation, or whether functional sim alone covers the intended use case. | — |

### Error / Illegal / Corner

| ID | What it tests | How it's tested | Why it matters | Pattern |
|---|---|---|---|---|
| ERR_01 | Writes to every read-only register are no-ops. | Attempt writes to `WDOGVALUE`, `WDOGRIS`, `WDOGMIS`, all ID registers. | P7, generalized to *every* RO register in one sweep rather than one-off checks. | P7 |
| ERR_02 | Read from `WDOGINTCLR` has no side effect. | Cross-reference REG_05. | — | P7 |
| ERR_03 | Fully unmapped address space is inert. | Cross-reference REG_03. | — | — |
| ERR_04 | `WDOGLOAD=0` boundary behavior. | Cross-reference LOAD_04. | — | — |
| ERR_05 | The LOAD and INTCLR toggle-sync channels don't corrupt each other when both are in flight at once. | Issue a `WDOGLOAD` write and a `WDOGINTCLR` write on consecutive APB cycles. | Both channels ultimately feed the *same* counter-value mux (`count_mux1`) in the `WDOGCLK` domain — this is the one test that specifically checks the two independently-designed CDC paths don't interfere with each other when both are active simultaneously, which neither LOAD_05 nor CLR_04 alone would catch. | P3-adjacent |

### Low Power

| ID | What it tests | How it's tested | Why it matters | Pattern |
|---|---|---|---|---|
| PWR_01 | Functional transparency of the r1p0→r1p1 automatic read-data-register clock gating. | Exercise reads at sparse vs. back-to-back cadence. | This TRM-documented change is supposed to be power-only and functionally invisible; the test exists to confirm that's actually true rather than assumed, and to flag (Open Question OQ-5) whether UPF/power-aware simulation is even in scope for this plan. | — |

### Random / Stress

| ID | What it tests | How it's tested | Why it matters | Pattern |
|---|---|---|---|---|
| RAND_01 | Everything above, combined, under long-duration constrained-random stimulus. | Randomize `WDOGLOAD`, `INTEN`/`RESEN` toggling, `WDOGCLKEN` gating, `WDOGINTCLR` timing, lock/unlock sequencing, across thousands of transactions. | This is where P5-class races and P3-class CDC-suppression bugs — the two hardest categories in this plan to hit by direction alone — actually get found in practice. Directed tests prove a mechanism *can* work; this proves it keeps working under combinations nobody thought to write down. | P10 |
| RAND_02 | Random reset injection layered on top of RAND_01's traffic. | Randomly assert `PRESETn`/`WDOGRESn` (independently and jointly) mid-sequence. | Combines RST_08/RST_09's reset-domain-independence concern with RAND_01's stress load — the highest-value single test in the plan for finding an X-propagation or stuck-toggle-sync bug that only a specific timing of reset relative to in-flight CDC activity would expose. | P10 |

---

## Part 3 — Quick index by pattern

If you're reviewing coverage by *mechanism* rather than by register, this is
the fast lookup:

- **P1** (reset defaults): RST_01–07, REG_02
- **P2** (lock-gating): LOCK_03/04/08, LOAD_06, CLR_03, ITM_04
- **P3** (CDC toggle-sync robustness): LOAD_05, CLR_04, CDC_02, ERR_05
- **P4** (sticky/latched state): INT_03, RES_04/05/06, RST_09
- **P5** (same-cycle races): CTRL_07, CNT_05, CLR_05
- **P6** (reserved bits): REG_04, CTRL_08
- **P7** (RO/WO semantics): REG_05, ERR_01/02
- **P8** (integration-test mux): ITM_01–05, RES_08
- **P9** (live/time-evolving values): LOAD_01, CNT_01/03/06, CDC_01
- **P10** (composite/soak/random): INT_05, RAND_01/02

A gap in one pattern's row above is a gap you should assume exists across
*every* test in this document tagged with that pattern — that's the point of
grouping them this way.
