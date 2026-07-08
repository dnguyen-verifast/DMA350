# DMA-350 Status & Control UVM Agent

UVM agent for the **Arm® CoreLink™ DMA-350 "Control and status interface"**
(TRM §4.8, signal table **A-10**). One agent covers all four functional groups
because they share a clock/reset domain and are semantically one interface:

| Group | TRM §  | Signals (DUT view)                                              | Dir to TB      |
|-------|--------|----------------------------------------------------------------|----------------|
| **G1**  GPO            | 4.8.1 | `gpo_ch_<N>[GPO_WIDTH-1:0]`                              | monitor        |
| **G2**  Stop control   | 4.8.2 | `allch_stop_req_*` (in) / `allch_stop_ack_*` (out)      | drive / monitor|
| **G2b** Pause control  | 4.8.2 | `allch_pause_req_*` (in) / `allch_pause_ack_*` (out)    | drive / monitor|
| **G3**  CTI            | 4.8.3 | `halt_req` (in, level), `restart_req` (in, pulse), `halted` (out, pulse) | drive / monitor |
| **G4**  Status         | 4.8.4 | `ch_enabled/err/stopped/paused/priv/nonsec[NUM_CHANNELS-1:0]` | monitor    |

The agent is **active** (driver pumps stop/pause/halt/restart) and always has a
**monitor** that tracks `ch_*` + `gpo_ch` as the golden per-channel reference
for a scoreboard.

## Directory layout

```
dma350_sc_agent/
├── interface/   dma350_sc_if.sv            # G1..G4 wires, DRV/MON modports, clocking
├── config/      dma350_sc_cfg.sv           # build-dependent existence knobs
├── seq_item/    dma350_sc_item.sv          # transaction (stimulus + status snapshot)
├── components/  dma350_sc_sequencer.sv
│               dma350_sc_driver.sv         # 4-phase handshakes + CTI level/pulse
│               dma350_sc_monitor.sv        # samples ch_*, gpo, edges + protocol checks
│               dma350_sc_coverage.sv
│               dma350_sc_agent.sv
├── sequences/   dma350_sc_base_seq.sv
│               dma350_sc_stop_seq.sv       # G2
│               dma350_sc_pause_seq.sv      # G2b
│               dma350_sc_cti_seq.sv        # G3
│               dma350_sc_gpo_check_seq.sv  # G1
│               dma350_sc_corner_seqs.sv    # C1..C6 corner cases
├── pkg/         dma350_sc_pkg.sv           # compile-order include hub
├── tb/          dma350_sc_example_env.sv   # example env + smoke test
│               dma350_sc_tb_top.sv         # example top + DUT stub
└── dma350_sc.f                             # filelist
```

## Group → sequence mapping

- **G1 GPO** → `dma350_sc_gpo_check_seq` (snapshots only — see note below).
- **G2 Stop** → `dma350_sc_stop_seq`.
- **G2b Pause** → `dma350_sc_pause_seq` (self-contained or split pause/resume).
- **G3 CTI** → `dma350_sc_cti_seq`.
- **Corner cases** → `dma350_sc_corner_seqs.sv`:
  - `C1 pause_or_halt` — multi-source pause **OR** (allch_pause + CTI overlap, 4.8.3).
  - `C2 stop_inflight` — stop while transfers outstanding (4.8.2).
  - `C3 enable_during_stop` — hold stop/pause across a channel-enable window (4.8.2).
  - `C4 secure_isolation` — `_sec` stops only Secure, `_nonsec` only Non-secure.
  - `C5 both_domain_stop` — interleave both domains in one window.
  - `C6 random` — weighted random mix (build-safe: no Secure on non-TZ builds).

## Build-dependent signal existence (the whole point of `dma350_sc_cfg`)

Several Table A-10 signals only exist in some builds. The config object mirrors
the RTL params so **one vif/agent works across every build**:

| cfg field         | RTL param        | Gates                                             |
|-------------------|------------------|---------------------------------------------------|
| `secext_present`  | `SECEXT_PRESENT` | `allch_*_{req,ack}_sec` pair **and** `ch_nonsec`  |
| `num_channels`    | `NUM_CHANNELS`   | how many `ch_*` / `gpo_ch` ports are real (1..8)  |
| `gpo_width`       | `GPO_WIDTH`      | width of each `gpo_ch` (0..32)                    |
| `ch_gpo_mask[N]`  | `CH_GPO_MASK`    | whether `gpo_ch_<N>` exists                        |

Wires are sized to the spec maxima (`DMA350_SC_MAX_CHANNELS=8`,
`DMA350_SC_MAX_GPO_WIDTH=32`); the driver/monitor only touch the bits/ports the
config says are real. The driver **refuses** to drive a Secure request on a
non-TZ build (downgrades to Non-secure with a warning); the monitor **checks**
that `_sec`/`ch_nonsec` stay quiet when `SECEXT_PRESENT=0`.

## Behavioural notes baked into the driver/monitor

- **4-phase handshake** (stop & pause, both domains): assert req → wait ack →
  deassert req → wait ack low, with a `handshake_timeout` guard.
- **stop = cancel vs pause = freeze** — the driver produces identical
  handshakes; the *distinction is a DUT-behaviour check* your scoreboard makes
  using the monitored `ch_stopped` vs `ch_paused` and the data-path agents
  (stop waits for outstanding responses but issues no new req/trigger; pause
  keeps all state and resumes).
- **CTI signal kinds** — `halt_req` is driven as a **level** (held), `restart_req`
  as a **pulse**; `halted` is monitored as a **pulse**.
- **Domain split (4.8.4)** — the monitor tags every per-channel snapshot with
  `ch_nonsec` so a channel's `enabled/err/stopped/paused/priv` are read in the
  correct domain (`decode_status()`), matching the "must be separated based on
  ch_nonsec" rule.

## What this agent intentionally does **not** do

- It does **not drive** `gpo_ch` — GPO value is SW-controlled via channel
  registers (`ENABLE`, `GPOVAL0/GPOEN0`, and the "empty command clears all GPO
  to 0" flow, §4.8.1). Program those through your **APB register agent**; this
  agent only *observes* GPO for stability / hold-last-value checks.
- It contains no scoreboard. Wire `agent.ap` (action/ack/halted items) and
  `agent.ap_status` (per-change snapshots) into your checker; `ch_*` is the
  golden reference.

## Integration checklist

1. Compile UVM, then add `dma350_sc.f` to your file list (interface → pkg → tb).
2. In your env `build_phase`, create a `dma350_sc_cfg`, set
   `secext_present/num_channels/gpo_width/ch_gpo_mask` to match the DUT build,
   and `uvm_config_db#(dma350_sc_cfg)::set(...,"agent","cfg",cfg)`.
3. Bind the real DMA-350 control/status ports to `dma350_sc_if` (replace the
   `dma350_dut_stub` in `tb/dma350_sc_tb_top.sv`), and hand the `DRV`/`MON`
   modports to the agent via `config_db` (see the example top).
4. Connect `agent.ap` / `agent.ap_status` to your scoreboard and coverage.
5. Run corner-case sequences alongside data-path/register sequences in a
   virtual sequence (e.g. `C2/C3` need in-flight transfers / channel enables to
   be meaningful).

## Files are templates

The `tb/` files (example env, smoke test, DUT **stub**) exist so the package
elaborates and runs standalone. Replace the stub with the real DUT and fold the
example env into your top-level environment.
