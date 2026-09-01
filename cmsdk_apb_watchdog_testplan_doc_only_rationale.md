# cmsdk_apb_watchdog — Documentation-Only Testplan: Rationale, Impact & Check-Method Reference

Companion to `cmsdk_apb_watchdog_testplan_doc_only.xlsx` (56 tests, derived
strictly from `DDI0479D_m_class_processor_system_r1p1_trm (2).pdf` Section 4.5
and its own cross-referenced sections — no RTL). This document adds, for every
test: **why it exists** (what documented claim it verifies), **impact** (the
practical consequence if that claim turns out false in silicon), and **how to
implement the check** — reference-model-plus-scoreboard (RM+SB), assertion
(SVA), both, or neither — **with the reasoning behind that choice**.

---

## Part 1 — How the check-method column was decided

This reuses the RM+SB-vs-assertions framework discussed earlier for this IP,
applied test-by-test:

- **Assertion** fits a test when the expected result is a **constant** or a
  **local, always-true implication** ("if A, then B holds," "these bits
  always read 0," "this mux always follows this select") — no need to compute
  anything from stimulus history, so no reference model is required. Cheap,
  localizes a failure immediately, and — when written independently from the
  register spec rather than derived through the same modeling process as the
  RM — provides a genuine second opinion against common-mode bugs.
- **RM+SB** fits a test when the expected result **depends on accumulated
  stimulus history or continues evolving over time** — a live counter value,
  a multi-register composite effect, a numeric timing computation. These need
  something that tracks state alongside the DUT and a comparator, because
  there's no fixed "always true" statement to write.
- **Both** fits tests with a cheap structural guard (assertion) *and* a data
  question underneath it that only a computed comparison can answer.
- A few tests are **environment-configuration notes** or **out-of-scope**
  markers rather than DUT checks at all — those are labeled accordingly rather
  than forced into one of the above.
- Several tests trace to a **Documentation Gap** (see the source workbook's
  "Documentation Gaps" sheet) — for those, the check-method entry says what
  the check *would* be once the ambiguity is resolved, and flags that writing
  a hard pass/fail assertion today would risk silently picking one
  interpretation over the other rather than surfacing the ambiguity.

---

## Part 2 — Every test

### Reset & Default State

| ID | Rationale (documented claim being verified) | Impact if wrong | Check Method | Reason for Method |
|---|---|---|---|---|
| RST_01 | Table 4-17 states `WDOGLOAD` resets to `0xFFFFFFFF`. | An un-programmed watchdog that resets to a small value instead of all-1s could start counting down toward an unwanted reset before boot software ever touches it — the opposite of the intended fail-safe default. | RM+SB | Single-point data comparison after a specific event (reset) — no ongoing computation needed, just "read equals documented constant." Classic SB job. |
| RST_02 | Table 4-17 states `WDOGVALUE` resets to `0xFFFFFFFF`. | Same fail-safe concern as RST_01, on the live counter register rather than the reload register — a separate flop, a separate chance to get it wrong. | RM+SB | Same reasoning as RST_01. |
| RST_03 | Table 4-17 states `WDOGCONTROL` resets to `0x0` (`INTEN=0`, `RESEN=0`). | If either bit powers up as 1, the watchdog could start counting or asserting reset before software configures it — a silent boot failure that's hard to diagnose because it happens before any code has run. | RM+SB | Data comparison against a documented constant. |
| RST_04 | Table 4-17 states `WDOGRIS` resets to `0x0`. | A latched interrupt out of reset looks like a spurious pending watchdog event to the very first code that reads it. | RM+SB | Data comparison. |
| RST_05 | Table 4-17 states `WDOGMIS` resets to `0x0`. | Same as RST_04, on the masked/output-facing copy. | RM+SB | Data comparison. |
| RST_06 | Table 4-17 states `WDOGLOCK` resets to `0x0` (unlocked). | If it powered up locked, no watchdog register could ever be programmed — an effectively bricked peripheral with no documented recovery. | RM+SB | Data comparison. |
| RST_07 | Table 4-17 states `WDOGITCR` resets to `0x0` (test mode off). | If test mode powered up active, real `WDOGINT`/`WDOGRES` outputs would be masked by whatever garbage is in `WDOGITOP` until software noticed. | RM+SB | Data comparison. |
| RST_08 | Table 4-24 documents `WDOGRESn` as a distinct reset input from `PRESETn`; each should independently return its associated state to defaults. | If the two reset domains are cross-wired, a real SoC (which very plausibly drives these from different reset trees) could see one domain fail to reset when the other reset line is the only one pulsed — an integration-time bug invisible in a testbench that always pulses both together. | Both | Assertion for the continuously-checkable structural claim ("state X changes only in response to reset input Y, never the other") — cheap, always-on, localizes which domain is miswired immediately. RM+SB still needed underneath to know the correct default *values* being compared (reuses RST_01–07's predictions). |

### Register Access

| ID | Rationale | Impact if wrong | Check Method | Reason for Method |
|---|---|---|---|---|
| REG_01 | Basic RW data path integrity on `WDOGLOAD`. | Catches a byte-swapped, truncated, or stuck-bit data path before any subtler test even becomes meaningful to run. | RM+SB | Data-pattern equivalence (walking-1s/0s, random) — a straightforward write/readback comparison. |
| REG_02 | Sweep of the entire Table 4-17 memory map. | A fast way to catch an entire register missing from the read-data path, rather than relying on 20 separate directed tests to each stumble onto the same class of bug. | RM+SB | Generalizes RST_01–07/REG_01's per-register comparison into one sweep — still fundamentally data equivalence. |
| REG_03 | Every register figure states reserved bits "must read as 0s." | Reserved bits silently carrying stray state is a classic forward-compatibility break — a future revision that assigns meaning to those bits would inherit garbage from today's implementation. | Assertion | The expected value (0) is a fixed constant, independent of stimulus history — no reference model needed, just a static implication ("these bit positions are always 0 on read"). Cheapest possible check for this class of claim. |
| REG_04 | Unmapped-address behavior, inferred by analogy from the APB-example-slave convention (Table 4-2), not stated directly for the watchdog. | If wrong, a firmware bug that mis-addresses a register could silently corrupt an unrelated register instead of reading back 0 — a much harder bug to diagnose in the field. | Assertion (provisional) | The claimed behavior ("read 0, write ignored") is a constant/no-op property, assertion-shaped in principle — but flagged provisional because the underlying expectation itself is an analogy, not a direct TRM statement for this component; confirm before treating a violation as a hard failure. |
| REG_05 | `WDOGINTCLR` read value is undocumented (Table 4-17 shows `-`/`-` for width/reset value). | Unknown — this is exactly the risk of leaving it unspecified: a software driver that (incorrectly) relies on reading this address for any purpose has no documented contract to rely on. | Pending GAP-2 | Cannot select a check method without an expected value. Once ruled, it will most likely be Assertion if the answer is "always reads a fixed constant," or RM+SB if the answer is "reflects some other register's value." |
| REG_06 | `WDOGPERIPHID3[7:4]` mirrors the `ECOREVNUM` input (Table 4-17 description, Table 4-24). | Wrong wiring here defeats the entire purpose of the ECO-tracking mechanism — post-silicon fix revisions become unreadable by software/debug tooling. | Assertion | `ECOREVNUM` is documented as a tie-off-style input (or connected to "special tie-off cells"), not stimulus that varies mid-test — so this is a permanently-true combinational equivalence, the textbook continuous-SVA-property case. |
| REG_07 | Peripheral/PrimeCell ID registers match fixed TRM constants. | Wrong values don't break watchdog *function*, but break every debug/discovery tool that identifies the IP by these registers at runtime. | Assertion | Fixed constants, no stimulus dependency — nothing to compute, just compare against literals. |

### WDOGLOAD

| ID | Rationale | Impact if wrong | Check Method | Reason for Method |
|---|---|---|---|---|
| LOAD_01 | "When this register is written to, the count is immediately restarted from the new value." | If the restart doesn't actually happen, software reprogramming the watchdog for a new timeout period would silently keep counting on the old schedule — defeating the reprogram. | RM+SB | "Restarted correctly" is a claim about the counter's value *going forward in time*, not a single-point check — needs a live, time-evolving reference model ticking alongside the DUT to know what "correct" looks like at any later read. |
| LOAD_02 | "The minimum valid value for WDOGLOAD is 1." | Boundary-value risk: an off-by-one at the smallest legal value is one of the most common places for a down-counter's expiry logic to be wrong. | RM+SB | Verifying an exact numeric timing (expiry after precisely one decrement) is a computed prediction, not a static property. |
| LOAD_03 | `WDOGLOAD=0` is one below the documented minimum; consequence undocumented. | Unknown by design — pending GAP-3, this test exists to characterize actual behavior, not to enforce one. | RM+SB (observational) | Even without a documented pass/fail target, RM+SB is the right *instrument* for recording what actually happens (e.g., does the counter ever reach a stable state, does it hang) — an assertion would require asserting a specific behavior as correct, which isn't yet justified. |
| LOAD_04 | Register-specific RW readback (Type=RW per Table 4-17). | Same reasoning as REG_01, scoped specifically to this register's documented type. | RM+SB | Data equivalence. |

### WDOGVALUE

| ID | Rationale | Impact if wrong | Check Method | Reason for Method |
|---|---|---|---|---|
| VAL_01 | "The counter decrements by one on each positive clock edge of WDOGCLK when...WDOGCLKEN is HIGH." | Wrong decrement rate directly changes the real timeout period software configured — a watchdog that fires early or late defeats its entire purpose (nuisance resets or missed-fault detection, respectively). | Both | Assertion for the structural guard ("value only changes on a qualified WDOGCLK edge, otherwise holds") — cheap and continuous. RM+SB for the actual decremented *value* at each qualified edge, which needs a computed, time-evolving prediction. |
| VAL_02 | `WDOGVALUE` is Type=RO. | If writable, software could accidentally (or a bus glitch could) corrupt the live countdown, producing an unpredictable timeout. | Assertion | Static invariant — "this register's value is unaffected by any write to its address," no computed oracle needed. |
| VAL_03 | "Gives the current value of the decrementing counter" — a live, continuously-valid read. | If reads can return stale or transitional garbage, software polling the watchdog for diagnostic purposes gets an unreliable picture of time-to-timeout. | RM+SB | Same live-value reasoning as VAL_01 — needs the time-evolving RM, checked at arbitrary (not just clock-aligned) read points. |

### WDOGCONTROL

| ID | Rationale | Impact if wrong | Check Method | Reason for Method |
|---|---|---|---|---|
| CTRL_01 | `INTEN` "enable[s] the counter and the interrupt" together, per Table 4-18. | If the counter secretly keeps running while `INTEN=0`, it could reach 0 and wrap silently before software ever means to start the watchdog — invisible until the first (unexpected) event fires. | Both | Assertion for "`INTEN=0` implies `WDOGVALUE` is stable" (cheap, continuous). RM+SB for the positive (enabled) case's actual decrementing data. |
| CTRL_02 | `INTEN` `0→1` "reloads the counter from...WDOGLOAD...after previously being disabled." | Without this reload, re-enabling the watchdog after a debug pause would resume from a stale mid-count value instead of a fresh full period — an unpredictable, shortened first timeout. | RM+SB | One-shot, edge-triggered *data* effect (the resulting counter value) — needs a computed comparison, not just a structural implication. |
| CTRL_03 | `RESEN` "acts as a mask for the reset output... to 0 to disable the reset." | The single highest-consequence negative test in this plan: a leak here means software cannot reliably suppress system reset during debug/bring-up, or conversely an unintended reset escapes suppression in the field. | Assertion (primary), RM+SB (supporting) | The masking relationship reads as purely combinational per the "mask" wording — "`RESEN=0` implies `WDOGRES=0`, always" is a clean, cheap, always-on implication. Given the safety stakes, an assertion written independently from the spec (not derived through the same modeling path as the RM) is deliberately chosen as the primary defense here, per the "independent redundant implementation" argument: if the RM/SB author shares a misreading of the spec with a hypothetical buggy implementation, only an independently-authored check catches it. |
| CTRL_04 | Table 4-18 reserved bits `[31:2]` must read 0. | Same forward-compatibility concern as REG_03. | Assertion | Static constant, no reference model needed. |

### Watchdog Operation Flow

| ID | Rationale | Impact if wrong | Check Method | Reason for Method |
|---|---|---|---|---|
| FLOW_01 | Figure 4-15: `WDOGINT` asserts at the first documented zero-crossing when `INTEN=1`. | Late or missing first-interrupt assertion delays fault detection — the entire point of the watchdog is undermined if this doesn't fire on schedule. | RM+SB | Determining *when* "zero" occurs requires tracking the live countdown — an event prediction from a time-evolving model, then matched against the observed `WDOGINT` transition. |
| FLOW_02 | "On the next enabled WDOGCLK clock edge, the counter is reloaded...and the countdown continues" — automatic, not software-triggered. | If reload doesn't happen automatically, the counter could stop dead after the first expiry, silently disabling all future watchdog coverage until software notices and intervenes (which it has no documented reason to expect it needs to). | RM+SB | Same live-counter reasoning as FLOW_01 — this is a claim about behavior continuing correctly over further time, not a single-point check. |
| FLOW_03 | Reset-assertion timing — **GAP-1**: Section 4.5's prose and Figure 4-15 describe apparently different timing (first-timeout-can-reset vs. second-timeout-only-resets). | This is the highest-impact open item in the whole plan: the two readings differ on whether a single missed watchdog service can reset the system, or whether two consecutive misses are required — directly affects how aggressively firmware must service the watchdog, and how a false failure here would be triaged (spec bug vs. RTL bug vs. testbench bug). | RM+SB, run in **observational / dual-hypothesis mode**, not hard pass/fail | Deliberately *not* written as a hard assertion yet: an assertion has to commit to one specific expected behavior to be `assert`-able, and writing it today would silently resolve the ambiguity in one direction rather than surface it. RM+SB used descriptively — track and report which hypothesis actual DUT behavior matches — until GAP-1 is reconciled with the spec owner. |
| FLOW_04 | `WDOGINTCLR`'s documented clear-and-reload effect, and whether it prevents whatever reset-triggering condition Figure 4-15/the prose describe. | Directly determines whether "service the watchdog on time" reliably prevents an unwanted reset — the core promise firmware developers depend on. | RM+SB | Same reasoning as FLOW_03 — its pass/fail criteria are downstream of resolving GAP-1/GAP-10, so it's tracked the same way rather than hard-asserted prematurely. |

### WDOGINTCLR

| ID | Rationale | Impact if wrong | Check Method | Reason for Method |
|---|---|---|---|---|
| CLR_01 | "A write of any value...clears the watchdog interrupt, and reloads the counter." | If the effect depends on the specific data written (contradicting "any value"), a firmware driver written to the letter of the spec (e.g., always writing `0x0`) could work while another (writing `0x1`) silently fails to service the watchdog. | RM+SB | The effect spans multiple registers at once (RIS/MIS/INT clear *and* counter reload) — a cross-register composite data-consistency check, naturally an SB job comparing several signals against RM predictions simultaneously. |
| CLR_02 | Read value undocumented — see REG_05. | See REG_05. | Pending GAP-2 | See REG_05. |
| CLR_03 | WDOGLOCK's description: locking "disables write accesses to all other registers," which includes `WDOGINTCLR`. | If this specific write-enable term is wrong, a locked (tamper-resistant) watchdog could still be silenced by any code able to issue a bus write — defeating the lock's entire purpose. | Assertion | Classic lock-gating implication: "`wdog_lock=1` implies this write has no effect" — cheap, immediate, and independently-authored from the spec text rather than inferred through the same path as the functional RM, which matters given the security/tamper-resistance stakes. |

### WDOGRIS / WDOGMIS

| ID | Rationale | Impact if wrong | Check Method | Reason for Method |
|---|---|---|---|---|
| INT_01 | "Indicates the raw interrupt status from the counter." | Software that reads `WDOGRIS` to distinguish "watchdog fired" from "watchdog fired and is currently masked" (via comparison with `WDOGMIS`) gets an incorrect diagnosis. | RM+SB | Same "when does zero occur" live-tracking requirement as FLOW_01. |
| INT_02 | "The logical AND of the raw interrupt status with the INTEN bit... the same value passed to the interrupt output pin." | If `WDOGMIS` doesn't track `INTEN` live, software could momentarily see a stale masked-interrupt state right after changing `INTEN` — a race condition in interrupt-service-routine logic that depends on this register. | Assertion (primary) | Explicitly described as a logical AND — a permanently-true combinational equivalence between two register bits, with no timing/CDC complexity of its own (unlike the live-counter tests). The textbook case for a continuous SVA property rather than event-based SB matching. |
| INT_03 | Reserved bits `[31:1]` read 0 (Table 4-19, 4-20). | Same forward-compatibility concern as REG_03/CTRL_04. | Assertion | Static constant. |

### WDOGLOCK

| ID | Rationale | Impact if wrong | Check Method | Reason for Method |
|---|---|---|---|---|
| LOCK_01 | Reset value `0x0` = unlocked by default. | If the device powers up locked (see RST_06), it's a bricked peripheral. | RM+SB | Data comparison (reset default) plus confirming a subsequent write succeeds — a functional consequence, not just a static value. |
| LOCK_02 | "Writing a value of 0x1ACCE551 enables write access to all other registers." | If the specific unlock value doesn't work, there is no documented way to ever reprogram a locked watchdog — same brick risk as LOCK_01, but self-inflicted by software rather than a reset bug. | Both | Assertion for the immediate local rule ("this exact write value implies unlocked next"). RM+SB to confirm the downstream consequence — that other-register writes genuinely take effect afterward — which is a behavioral claim beyond the single register's value. |
| LOCK_03 | "Writing any other value disables write accesses." | If some non-magic values accidentally unlock (e.g., an off-by-one against the magic constant), the lock's tamper-resistance is silently weaker than documented. | Both | Same reasoning as LOCK_02 — near-miss values specifically probe the comparator's exactness, which benefits from both the immediate-effect assertion and the downstream-consequence SB check. |
| LOCK_04 | "A read from this register returns only the bottom bit." | Software that (reasonably) expects to read back what it wrote would misinterpret `WDOGLOCK` as a general-purpose register rather than the write-only-effective magic-compare it actually is. | Assertion | Structural read-masking property, independent of what was written — same flavor as reserved-bit checks, a static invariant. |
| LOCK_05 | "All other registers" is a blanket claim covering `WDOGLOAD`, `WDOGCONTROL`, `WDOGINTCLR`, `WDOGITCR`, `WDOGITOP` individually. | The blanket TRM wording is only actually verified if every named register is checked — a single spot-check (e.g., only testing `WDOGLOAD`) could pass while a different register's write-enable term is independently broken. | Assertion | Each register's lock-gating is a separate, cheap, always-on implication — ideal for a set of small independent assertions (one per register) rather than folding into a general-purpose SB flow, precisely because each is an independent piece of logic that needs its own check. |
| LOCK_06 | Inferred (not stated) that the counter keeps running while locked, since the lock's documented scope is "write accesses." | If locking accidentally halts the counter too, a "tamper-proofed" watchdog becomes trivially disable-able by locking it — the opposite of the lock's purpose. | RM+SB | This is a live-counter behavioral question (does counting continue correctly), which — like VAL_01/FLOW family — needs a time-evolving prediction, not a static implication. |

### Integration Test Mode

| ID | Rationale | Impact if wrong | Check Method | Reason for Method |
|---|---|---|---|---|
| ITM_01 | "The test output register directly controls...WDOGINT...and...WDOGRES" when `WDOGITCR=1`. | This is the only documented way to functionally exercise the two output pins from ATE/production test without waiting out a real countdown — if wrong, production test coverage of these pins is compromised, not just simulation coverage. | Assertion | A small, exhaustively enumerable mux truth table (4 combinations of `WDOGITOP[1:0]`) — the definitionally ideal assertion case: cheap, deterministic, no stimulus history involved. |
| ITM_02 | Reversion on exit (`WDOGITCR` `1→0`) — **GAP-4**, not explicitly documented, only the reasonable complementary reading. | If outputs don't revert, a chip that ever entered test mode (e.g., during production test) could remain stuck presenting test-forced values instead of real watchdog behavior for the rest of its operating life. | Assertion (provisional) | Same mux-truth-table reasoning as ITM_01, just the complementary direction — provisional label because the underlying expectation is inferred, not stated, so a failure here should be checked against GAP-4's resolution before being treated as a hard bug. |
| ITM_03 | `WDOGITOP` write is retained (Type=WO, no documented gating on `WDOGITCR`) even with no immediate effect. | If the write doesn't stick, software staging a test pattern before entering test mode (a reasonable documented-implied usage) would find its pattern silently lost. | RM+SB | A stored-data persistence/readback question across a mode change — a data-equivalence check, not a structural implication. |
| ITM_04 | Reserved bits (Table 4-22, 4-23) read 0. | Same forward-compatibility concern as elsewhere. | Assertion | Static constant. |
| ITM_05 | Lock gates `WDOGITCR`/`WDOGITOP` writes — same "all other registers" claim as LOCK_05. | If wrong, a locked device could still have its output pins hijacked into test mode by any code with bus access — a different flavor of the same tamper-resistance defeat as CLR_03. | Assertion | Same lock-gating pattern as LOCK_05/CLR_03. |

### Peripheral / PrimeCell ID

| ID | Rationale | Impact if wrong | Check Method | Reason for Method |
|---|---|---|---|---|
| ID_01 | Fixed ID constants — see REG_07. | See REG_07. | Assertion | Fixed constants, no stimulus dependency. |
| ID_02 | `ECOREVNUM` reflection — see REG_06. | See REG_06. | Assertion | Continuous combinational equivalence against a tie-off-style input. |

### Documented Signal Behavior

| ID | Rationale | Impact if wrong | Check Method | Reason for Method |
|---|---|---|---|---|
| SIG_01 | "The watchdog clock must be synchronous to the APB clock PCLK." | If the verification environment generates a `WDOGCLK` that violates this (e.g., freely asynchronous), any bugs found may not reflect real, spec-compliant SoC integration — wasted debug effort chasing a scenario the DUT was never required to handle, or worse, missing that a *compliant* scenario has a real bug because attention went elsewhere. | Environment configuration check (not a DUT assertion) | This is a constraint on testbench clock generation, not a property of DUT signals to check against each other — the natural place to enforce it is the clock-generation component's own configuration, not an RTL-facing assertion. A self-check assertion on the testbench's own clock-gen logic is a reasonable option if that logic is complex enough to warrant one. |
| SIG_02 | `WDOGCLKEN` gates decrement — see VAL_01. | See VAL_01. | Both | See VAL_01. |
| SIG_03 | `WDOGRESn` distinct reset input — see RST_08. | See RST_08. | Both | See RST_08. |
| SIG_04 | `ECOREVNUM` tie-off input — see REG_06/ID_02. | See REG_06. | Assertion | See REG_06. |

### System / Integration Notes

| ID | Rationale | Impact if wrong | Check Method | Reason for Method |
|---|---|---|---|---|
| SYS_01 | "In the example system, the watchdog interrupt is connected to...NMI...and the watchdog reset signal is connected to the reset generator." | This is the real-world consequence of `WDOGINT`/`WDOGRES` in this repo's actual SoC wiring (per its own `m3ds_user_partition`/`beetle_sysctrl` integration) — a bug at the unit level has an outsized system impact (NMI storm or unwanted full-system reset), which is exactly why unit-level correctness here matters disproportionately to the IP's small size. | N/A at unit level | This is a scope/ownership note, not a checkable property of this IP in isolation — the actual check belongs in a SoC-level testplan where NMI and system-reset behavior are observable. |
| SYS_02 | `INCLUDE_APB_WATCHDOG` build-time parameter, default 1. | If this project's build configuration excludes the watchdog, the entire testplan (both this one and the RTL-informed one) is moot for that configuration — worth confirming once, not assumed. | N/A | Configuration-management fact, not a runtime DUT behavior. |
| SYS_03 | r1p0→r1p1 revision note: "Improved RTL to enable automatic clock gating of read data register," documented as power-only. | If this change is *not* actually functionally transparent (contrary to how it's documented), reads under certain cadences could silently return stale data — a subtle, cadence-dependent data-corruption bug that's easy to miss if only tested with generously-spaced reads. | RM+SB | Confirming "still correct regardless of read cadence" is fundamentally a data-equivalence question across many reads under varied timing, which is what RM+SB is for. An assertion could add a cheap hygiene check ("PRDATA never X/Z"), but the substantive "still correct" claim needs the computed comparison. |

---

## Part 3 — Quick index by check method

- **Assertion-only** (18): REG_03, REG_06, REG_07, CTRL_04, CLR_03, INT_02, INT_03, LOCK_04, LOCK_05, ITM_01, ITM_04, ITM_05, ID_01, ID_02, SIG_04, VAL_02, CTRL_03 (primary), REG_04 (provisional)
- **RM+SB-only** (23): RST_01–07, REG_01, REG_02, LOAD_01, LOAD_02, LOAD_03, LOAD_04, VAL_03, CTRL_02, FLOW_01, FLOW_02, FLOW_03, FLOW_04, CLR_01, INT_01, LOCK_01, LOCK_06, ITM_03, SYS_03
- **Both** (7): RST_08, VAL_01, CTRL_01, LOCK_02, LOCK_03, SIG_02, SIG_03
- **Pending a Documentation Gap ruling** (4): REG_05, CLR_02, ITM_02 (provisional-assertion), LOAD_03 (already counted above, observational)
- **Not a DUT check** (3): SIG_01 (environment config), SYS_01 (out of scope, SoC-level), SYS_02 (build config)

The pattern worth taking away: **almost everything that's a fixed constant,
a masking relationship, or a lock-gating rule ends up an assertion; almost
everything that involves the live counter's actual value over time ends up
RM+SB.** That split isn't a stylistic choice per test — it falls directly out
of whether the TRM's claim for that behavior is expressible as "always true"
or requires computing "what should it be right now."
