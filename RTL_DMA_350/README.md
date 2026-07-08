# Arm CoreLink DMA-350 — RTL (SystemVerilog)

A synthesizable RTL implementation of the **Arm® CoreLink™ DMA-350 Controller**
(TRM 102482_0000_04). This revision rewrites the top level so that the module
port list **covers the full TRM Appendix A "Signal descriptions"** signal set
(Tables A-1 … A-11), with a configurable multi-channel architecture and
behavioral implementations of every interface group.

> Scope: the **interfaces and control plane are complete** per Appendix A
> (every signal is present, correctly directioned and parametrized). The
> **datapath models the 1D transfer path** plus stream/restart/link/pause/
> trigger; deep datapath features (2D/wrap/template, poison, ID reordering,
> clock-gating) are framed via registers/ports but simplified — see *Simplifications*.
> Not silicon-proven: lint/CDC/formal-AXI/coverage still required before tape-out.

## Files

RTL:
```
dma350_pkg.sv        Build options, register offsets, command/status/link-header
                     bit positions, shared enums.
dma350_top.sv        Top level. FULL Appendix A port list. APB decode, NUM_CHANNELS
                     instances, AXI5 M0/M1 arbitration, Q/P-Channel, trigger matrix,
                     IRQ aggregation, all-channel stop/pause, CTI halt/restart, boot.
dma350_ch_regs.sv    DMACH<n> register frame (full register set; 2D/template fields
                     stored/read-back). Commands, status, attributes, triggers, GPO,
                     security/priv, interrupt.
dma350_channel.sv    Command engine: CFG→[TRIG]→XFER↔PAUSED→{NEXTLINE}→DRAIN→
                     TRIGOUT→DONE→{restart|link|donepause|finish}. AXI5 read/write
                     managers, deep per-channel data FIFO, stream, linking, boot,
                     AXI-clean abort drain.
dma350_byte_fifo.sv  Per-channel data FIFO (byte gearbox): FIFO_DEPTH-word deep
                     read/write decoupling buffer that also realigns bytes.
dma350_axi_node.sv   AXI5 manager arbitration with issuing capability: ID-routed
                     multiple-outstanding reads/writes, AW-order FIFO, CHPRIO
                     priority + round-robin, grant lock for AXI-legal VALID hold.
dma350_trigger.sv    Four-phase trigger-in receiver and trigger-out driver.
dma350_lpi.sv        Q-Channel (clock quiescence) and P-Channel (power) controllers.
dma350_burst.sv      DMA-350 burst splitter: AxSIZE-based beats, ≤1024 bytes,
                     4KB-safe, AxLEN≤255, INCR/FIXED.
```
Testbench (basic self-checking):
```
axi5_mem_slave.sv      AXI5 memory subordinate (ID-echoing, AxSIZE-aware, WSTRB).
dma350_tb_harness.sv   Wraps dma350_top + memory on M0, ties off all sideband.
tb_dma350_basic.sv     1D full-width memory-to-memory copy.
tb_dma350_narrow.sv    Narrow (1-byte) unaligned copy; checks WSTRB byte-accuracy.
tb_dma350_multi.sv     Two channels copying concurrently (arbitration + CHPRIO).
run.sh                 Builds and runs the three tests with Icarus Verilog.
```

## Appendix A coverage map

| TRM table | Interface          | Where |
|-----------|--------------------|-------|
| A-1 | Clock & reset (`clk`,`resetn`,`aclken_m0/m1`,`pclken`) | top ports |
| A-2 | Q-Channel clock LPI | `dma350_qchannel` |
| A-3 | P-Channel power LPI | `dma350_pchannel` |
| A-4 | APB4 (`psel`…`prdata`,`pwakeup`,`pdebug`,`pprot`,`pstrb`) | top APB decode + `dma350_ch_regs` |
| A-5 | AXI5 M0 (AW/AR/W/R/B + `qos`/`prot`/`cache`/`domain`/`inner`/`chid`/`chidvalid`/`arcmdlink`/`poison`) | `dma350_axi_node` + top unpack |
| A-6 | AXI5 M1 (active when `AXI5_M1_PRESENT`) | second `dma350_axi_node` |
| A-7 | Trigger (`trig_in_*`,`trig_out_*`) | `dma350_trigger` + matrix |
| A-8 | IRQ (`irq_channel`,`irq_comb_nonsec/sec`,`irq_sec_viol_err`) | top aggregation |
| A-9 | Stream (`str_out_*`,`str_in_*`,`str_in_flush`) | `dma350_channel` |
| A-10| Status/Control (`gpo_ch`, allch stop/pause, `halt_req`/`restart_req`/`halted`, `ch_enabled/err/stopped/paused/priv/nonsec`) | top |
| A-11| Config (`boot_en`,`boot_addr`,`boot_memattr`,`boot_shareattr`) | top boot loader |

Per-port / per-channel buses that the TRM names individually (e.g.
`trig_in_<TI>_req`, `str_out_<N>_tdata`) are exposed as **flattened packed
vectors**: scalar `<i>` → bit `i`, bus `<i>` → lanes `[i*W +: W]`.

## Parameters (configurable options)

`ADDR_WIDTH`, `DATA_WIDTH`, `ID_WIDTH`, `CHID_WIDTH`, `POIS_WIDTH`,
`NUM_CHANNELS`, `AXI5_M1_PRESENT`, `SECEXT_PRESENT`, `NUM_TRIGGER_IN`,
`NUM_TRIGGER_OUT`, `GPO_WIDTH`, `FIFO_DEPTH`, `BURST_SIZE`,
`ISSUING_CAP` (outstanding AXI transactions per port),
`AWQ_DEPTH` (per-channel write-burst issuing depth).

`ID_WIDTH` must be ≥ ⌈log2(NUM_CHANNELS)⌉ so the channel index fits the AXI ID.

When `CHID_WIDTH`/`POIS_WIDTH` are 0 the corresponding pins collapse to width 1
and are held inactive (matching "not present when … set to 0").

## Features implemented

- **Multi-channel** (`NUM_CHANNELS`) command engines with independent register
  frames, arbitrated onto the AXI5 manager port(s). With `AXI5_M1_PRESENT`,
  reads use M0 and writes use M1 (bandwidth split); otherwise both use M0.
- **APB4 subordinate** with channel decode (`paddr[11:8]`), DMA-level block
  (`paddr[12]`), 1-wait-state `pready`, `pstrb` all-or-nothing check → `pslverr`.
- **Byte-accurate datapath** (data-integrity correct):
  - `AxSIZE` is driven from **TRANSIZE** (per side, clamped to the bus width):
    narrow transfers appear correctly on the bus.
  - `WSTRB` marks **exactly** the valid byte lanes per beat — non-bus-multiple
    and unaligned destinations no longer over-write trailing bytes.
  - A **deep per-channel byte FIFO** (`FIFO_DEPTH` bus-words) decouples the read
    and write sides AND realigns: it stores the **compacted** valid source bytes
    and the write side **re-places** them on the destination lanes, so arbitrary
    source-vs-destination byte alignment is handled (no width-aligned-address
    assumption) with proper read/write buffering.
  - `AxBURST` is **INCR or FIXED** per side. Per TRM 5.2.3 a side with
    `SRC/DESXADDRINC == 0` keeps a fixed address (peripheral FIFO); increment 1
    is contiguous; any other signed increment uses single-element addressing.
  - **2D transfers**: `YSIZE` lines, advancing source/destination line base by
    `XADDRINC` / `YADDRSTRIDE` between lines. **Fill** mode (`CH_CTRL.XTYPE`,
    `FILLVAL`) writes without reading. **Empty commands** (`XTYPE=disable` or
    zero sizes) are legal and still honour triggers/GPO/trigger-out/done.
  - Bursts are split to the DMA-350 **max 1024 bytes**, never cross a **1KB
    address boundary** (TRM 4.3.6 burst breakpoint), respect
    **`SRC/DESMAXBURSTLEN`+1** (TRANSCFG[19:16], default 16 beats), `AxLEN≤255`.
  - **>16-bit transfer sizes** via `XSIZE`+`XSIZEHI` (32-bit byte counters).
- **AXI5 attributes / arbitration**: per-channel `AxID` (or the SW **CHID** from
  `NSEC/SEC_CHCFG` when `CHIDVLD` is set), **CHPRIO drives channel arbitration**
  (priority + round-robin tie-break, not decorative), `AxQOS` from `CHPRIO`,
  TRM 6.5.1.11/12 TRANSCFG layout (MEMATTR[7:0]→cache/inner, SHAREATTR[9:8]→
  domain, NONSECATTR[10]/PRIVATTR[11]→AxPROT combined with the channel context),
  `arprot[2]=1` + `arcmdlink` on descriptor fetches, `awakeup`. **R-channel
  poison** (and SLVERR/DECERR) flags a channel error.
- **Issuing capability (multiple outstanding)**:
  - Per channel, reads pipeline multiple AR ahead of returning data, and writes
    issue several AW ahead of W via a per-channel beat-count FIFO (`AWQ_DEPTH`).
  - The arbitration node accepts up to `ISSUING_CAP` outstanding transactions on
    the shared port, routes R/B back by `AxID`, and serialises W in AW-acceptance
    order via an order FIFO. AR/AW grants are locked while VALID awaits READY
    (address stable, AXI-legal). Reads/writes from several channels are in flight
    concurrently.
  - **Stop/abort is AXI-clean**: a stopped or errored channel still drains its
    outstanding reads and completes the W beats of already-accepted AW bursts
    (with `WSTRB=0`) and collects every B before reporting — no protocol
    violation and no deadlock.
- **Command engine**: config-check, data transfer, drain, done; **automatic
  restart** (`AUTOCFG`, `REGRELOADTYPE`), **command linking** (header bitmap,
  TRM Table 5-12), **pause/resume** (`PAUSECMD`/`RESUMECMD`, `DONEPAUSEEN`,
  `STAT_PAUSED`/`RESUMEWAIT`), **stop/clear**, and **graceful `DISABLECMD`**
  (TRM 5.6.1: the current command completes, then the channel disables without
  linking/restarting; only this path sets `STAT_DISABLED`). **`DONETYPE`**
  selects when `STAT_DONE` asserts (never / end of command / end of each
  autorestart cycle). Pause stops issuing new bursts and lets in-flight beats
  drain (AXI VALID never dropped mid-handshake).
- **Triggers (TRM 5.4)**: `TRIGINTYPE` SW-only / external HW / internal
  channel-to-channel, `TRIGINMODE` command vs flow-control. Flow control uses
  the TRM request types (`SINGLE`/`BLOCK`/`LAST SINGLE`/`LAST BLOCK`,
  block = `TRIGINBLKSIZE`+1) on **both source (reads) and destination (writes)**
  with per-burst credit gating; a `LAST` request truncates and closes the
  command. Acknowledge types `OKAY` / `LAST OKAY` (final grant) / `DENY`
  (SW clear of an unselected pending request via `*_SIGNALVAL`). SW triggers:
  `SRC/DESSWTRIGINREQ`+`TYPE` and `SWTRIGOUTACK` in `CH_CMD` (TRM bit positions).
- **Stream expansion** (external DPU) per channel via `str_out_*`/`str_in_*`.
- **Low power**: Q-Channel accepts clock quiescence only when idle; P-Channel
  accepts ON always, low-power/retention only when idle, **OFF blocked by
  `DISMINPWR`** (NSEC/SEC_CTRL[31:30]); an accepted **WARM_RST pauses all
  channels** and exiting to ON resumes them; `pactive` ON/FULL_RET.
- **System control**: all-channel stop/pause with Secure/Non-secure split and
  four-phase acks; CTI `halt_req`/`restart_req` with a **pulsed `halted`**;
  per-channel status and `gpo_ch` (**holds its last driven value**, TRM 4.8.1);
  **boot** loads channel-0's first command from `boot_addr`.
- **Security**: per-channel `ch_nonsec`/`ch_priv`; **RAZ/WI enforcement** on APB
  (NS access to a Secure channel/frame, unprivileged access to a privileged
  channel or the unit control frames), optional **SLVERR** response per
  `SCFG_CTRL.RSPTYPE_SECACCVIO`, `pdebug` suppresses the violation error/IRQ
  while keeping RAZ/WI (TRM 4.2.3); Secure/Non-secure interrupt combination
  gated by `INTREN_ANYCHINTR`, `irq_sec_viol_err` from sticky `STAT_SECACCVIO`.
- **Register map (TRM 6.3/6.4)**: APB decode matches the TRM memory map — channel
  `<n>` frame at `0x1000 + 0x100*n` (full 38-register DMACH set); DMA-unit frames
  at the TRM bases `DMASECCFG`=0x000, `DMASECCTRL`=0x100, `DMANSECCTRL`=0x200,
  `DMAINFO`=0xF00. All §6.4 unit registers are decoded:
  - `DMASECCFG`: `SCFG_CHSEC0`, `SCFG_TRIGINSEC0`, `SCFG_TRIGOUTSEC0`, `SCFG_CTRL`
    (`SEC_CFG_LCK`[31]/`RSPTYPE`[1]/`INTREN_SECACCVIO`[0]), `SCFG_INTRSTATUS`
    (`STAT_SECACCVIO` sticky, gates `irq_sec_viol_err`), plus impl `SCFG_CHPRIV0`.
  - `DMASECCTRL`/`DMANSECCTRL`: `*_CHINTRSTATUS0`, `*_STATUS` (all-channel
    idle/stopped/paused + combined intr), `*_CTRL`, `*_CHPTR`/`*_CHCFG`
    (per-channel CHPRIV/CHID), `*_STATUSPTR`/`*_STATUSVAL`, `*_SIGNALPTR`/`*_SIGNALVAL`.
  - `DMAINFO`: `DMA_BUILDCFG0-2`, `IIDR`, `AIDR`, `PIDR4`@0xD0 + `PIDR0-3`@0xE0-0xEC,
    `CIDR0-3`. Per-channel read-only IDs (`CH_IIDR`/`CH_AIDR`/`CH_BUILDCFG0/1`),
  `CH_ISSUECAP`, `CH_GPOREAD0`, `CH_ERRINFO`. (Corrected `CH_GPOVAL0`=0x60,
  `CH_STREAMINTCFG`=0x68; `IIDR`/`PIDR` values and offsets aligned to TRM 6.5.5.)
- **Error model (TRM 5.6.3 / Table 5-9)**: `CH_ERRINFO` reports the cause —
  bus errors (`AXIRDRESPERR`/`AXIWRRESPERR`/`AXIRDPOISERR` + `BUSERR`) and
  configuration errors (`REGVALERR` illegal size, `CFGCONFLERR` fill+stream,
  `LINKHDRERR` all-zero command-link header + `CFGERR`). Config is validated in
  the CFG state before any bus transfer.
- **Command linking (Table 5-12)**: the header is parsed across all 32 bits with
  correct word indexing (bits 12-28 no longer misalign the descriptor words); an
  all-zero header raises `LINKHDRERR`. Registers beyond the modelled datapath are
  consumed in order but their effect is deferred (see below).

## Remaining simplifications

- **Per-unit start alignment**: each side's start/line address is assumed
  aligned to its transfer unit `2^TRANSIZE` (a DMA-350 size-alignment rule);
  arbitrary sub-unit start offsets are not modelled. Differing source/destination
  *byte* alignment **is** handled by the per-channel byte FIFO.
- **1D WRAP / FILL / CONTINUE (`XTYPE`)** are implemented: `wrap` re-reads the
  source block into successive destination blocks (modelled as a 2D-style loop,
  final pass truncated to write exactly `DESXSIZE`); `fill` writes the source
  then pads the remainder with `FILLVAL`; `continue` stops at `min(SRC,DES)`.
- **Internal trigger** (channel-to-channel, TRM 5.4.4) is implemented: a
  channel's trigger-out (`*_internal` config) drives another channel's
  trigger-in via an on-chip handshake crossbar.
- **CH_CTRL decode corrected** to TRM 6.5.1: `XTYPE[11:9]`, `YTYPE[14:12]`,
  `CHPRIO[7:4]` (4-bit → AxQOS), `DONETYPE[23:21]`, trigger enables
  `USE*[27:25]`. Register field layouts now follow the TRM throughout:
  `CH_CMD` SW-trigger bits [16]/[18:17]/[20]/[22:21]/[24], `CH_INTREN`
  (DONE=0/ERR=1/DISABLED=2/STOPPED=3, trig-waits [10:8]), `CH_STATUS` `INTR_*`
  [10:0] + `STAT_*` trig-waits [26:24], `CH_SRC/DESTRIGINCFG`
  (SEL[7:0]/TYPE[9:8]/MODE[11:10]/BLKSIZE[23:16]), `CH_TRIGOUTCFG`
  (SEL[5:0]/TYPE[9:8]), `SRC/DESTRANSCFG` (MEMATTR/SHAREATTR/NONSEC/PRIV/
  MAXBURSTLEN), strict `CH_XSIZE` (SRC[15:0]/DES[31:16]).
  2D line stride comes from `CH_YADDRSTRIDE`.
- **Templated transfers** (`TMPLTCFG`/`SRC/DESTMPLT`) and **general per-element
  `SRC/DESXADDRINC`** (signed / non-unit / zero=fixed stride) run in the
  single-element "gen" addressing mode (one 1-beat access per element, template
  gaps skipped), per TRM 5.3.3.
- Still pending: full `YTYPE` 2D wrap/fill and `SRC/DES`-independent 2D geometry
  (`DESYSIZE` is stored, not used), 64-bit datapath (HI registers stored), the
  *optimized* bandwidth mode of TRM 4.3.6 (narrow transfers grouped bus-wide;
  the implemented unoptimized mode is TRM-legal), true least-recently-granted
  history (priority + round-robin approximation), P-Channel OFF register-clear
  side effects, sticky unit-level `STAT_ALLCH*` flags and their interrupts
  (read back live, combined IRQ gated by `INTREN_ANYCHINTR` only),
  `CH_WRKREGVAL` internal views, and `CH_ISSUECAP` limiting (build-time
  `ISSUING_CAP` applies).
- **In-order per ID**: each channel uses a single `AxID`, so its own data returns
  in order (AXI guarantee). The model does not reorder within a channel or split
  one channel's traffic across both ports; cross-channel concurrency uses
  distinct IDs and the order FIFO. A single shared W channel means write data is
  head-of-line ordered by AW acceptance (inherent to one AXI port).
- **Not propagated** (on the interface for completeness):
  `aclken_*`/`pclken` clock-gating, `boot_memattr`/`boot_shareattr`.
  (`pdebug` **is** now honoured: it suppresses the security-violation error
  response and interrupt while keeping RAZ/WI protection.)
- Register **offsets, DMA-unit frame bases and field encodings** now match TRM
  6.3/6.4/6.5 for the modelled features; the MEMATTR→AxCACHE mapping is a
  behavioral simplification (outer attr drives `AxCACHE`, inner drives
  `axinner`).

## Provenance note

The burst splitter is a clean DMA-350 implementation (1024-byte cap, AxSIZE-based
beats, FIXED/INCR); the earlier Xilinx-derived `axi_dma_burst` (MM2S/S2MM, DRE,
"Simple mode", `C_*_BURST_SIZE`) has been removed.

## Tests

Three basic self-checking testbenches drive the channel(s) over APB4 against an
AXI5 memory model on M0 and check the destination byte-for-byte:

| Test     | What it covers                                                        |
|----------|-----------------------------------------------------------------------|
| `basic`  | 1D full bus-width memory-to-memory copy (256 B).                       |
| `narrow` | 1-byte unit, mismatched src/dst alignment, non-bus-multiple length;   |
|          | verifies AxSIZE=TRANSIZE, byte-accurate WSTRB, and that adjacent      |
|          | destination bytes are untouched (guard bytes).                        |
| `multi`  | Two channels copying concurrently — exercises the arbitration node    |
|          | (ID-routed multiple-outstanding) and CHPRIO.                          |

```bash
./run.sh                                  # build + run all three (Icarus Verilog)
# or one test:
iverilog -g2012 -o sim.vvp dma350_pkg.sv dma350_burst.sv dma350_trigger.sv \
  dma350_lpi.sv dma350_axi_node.sv dma350_ch_regs.sv dma350_channel.sv \
  dma350_top.sv axi5_mem_slave.sv dma350_tb_harness.sv tb_dma350_basic.sv
vvp sim.vvp
```

These are bring-up smoke tests, not a coverage suite; they have not been run in
this environment (no simulator available here) — run them in your own flow.
