# CRLP — Clock / Reset / Low-Power UVM Agent

A UVM agent that plays the role of the **external clock controller + power
controller + reset generator** for the DMAC described in doc `102482_0000_04`.

It drives the DMAC clock/reset inputs and negotiates:

- **Q-Channel** (Table A-2) — clock quiescence entry/exit (clock gating).
- **P-Channel** (Table A-3) — power-state changes.

> Signal directions follow the **DMAC (DUT) point of view** from the spec, so
> this agent *drives* the DUT inputs and *samples* the DUT outputs.

## Signals handled

| Group | Agent drives | Agent samples |
|-------|--------------|---------------|
| Clock/Reset (A-1) | `clk`, `resetn`, `aclken_m0`, `aclken_m1`, `pclken` | — |
| Q-Channel  (A-2)  | `clk_qreqn` | `clk_qacceptn`, `clk_qdeny`, `clk_qactive` |
| P-Channel  (A-3)  | `preq`, `pstate[3:0]` | `paccept`, `pdeny` |

## File layout

```
tb/
  crlp_if.sv          interface + driver/monitor clocking blocks
  crlp_types.svh      enums: op, Q-Channel state, response, pstate
  crlp_config.svh     agent config (period, timeouts, active/passive, coverage)
  crlp_seq_item.svh   transaction (request + response fields)
  crlp_sequencer.svh  sequencer
  crlp_driver.svh     clock engine + reset + Q/P-Channel handshakes
  crlp_monitor.svh    passive reconstruction of reset / Q / P transactions
  crlp_coverage.svh   functional coverage subscriber
  crlp_agent.svh      agent (build/connect)
  crlp_seq_lib.svh    reusable sequences
  crlp_pkg.sv         package including all of the above
sim/
  crlp_dut_stub.sv    trivial DMAC responder (replace with real DMAC)
  crlp_test.svh       example env + test
  crlp_tb_top.sv      testbench top
  filelist.f          compile file list
```

## How the clock is "managed"

The driver runs a background **clock engine** that toggles `clk`. It can be
gated two ways:

1. **Bench control** — `OP_CLK_STOP` / `OP_CLK_START`.
2. **Q-Channel (realistic)** — when a `OP_QCH_QUIESCE` request is *accepted*
   (`qacceptn` LOW), the driver gates `clk`. `OP_QCH_WAKE` restarts the clock
   and completes the exit handshake back to `Q_RUN`.

`resetn` follows the A-1 rule: asserted LOW **asynchronously**, deasserted HIGH
**synchronously** (driven on `negedge` so it is clean at the next `posedge`).

## Operations (`crlp_op_e`)

| Op | Meaning |
|----|---------|
| `OP_CLK_START` / `OP_CLK_STOP` | bench clock control (optional new period) |
| `OP_RESET`      | apply active-LOW reset pulse |
| `OP_SET_CLKEN`  | set `aclken_m0/m1`, `pclken` |
| `OP_QCH_QUIESCE`| Q-Channel: request clock stop (accept→gate / deny→resume) |
| `OP_QCH_WAKE`   | Q-Channel: exit quiescence, restart clock |
| `OP_PCH_REQ`    | P-Channel: request `pstate` change (accept/deny) |

Handshake outcome is returned in the item's `rsp` (`RSP_ACCEPT` / `RSP_DENY` /
`RSP_TIMEOUT`) and `latency_cy`.

## Using it in your environment

```systemverilog
// 1. Instance the interface in the top and pass it via config_db:
crlp_if bus();
crlp_dut_stub dut(.bus(bus));   // <- replace with the real DMAC
initial begin
  uvm_config_db#(virtual crlp_if)::set(null, "uvm_test_top", "vif", bus);
  run_test("crlp_base_test");
end

// 2. In the test, build a config and the agent (see sim/crlp_test.svh):
cfg = crlp_config::type_id::create("cfg");
cfg.vif = <interface>;
cfg.is_active     = UVM_ACTIVE;
cfg.clk_period_ps = 10_000;     // 100 MHz
uvm_config_db#(crlp_config)::set(this, "env", "cfg", cfg);

// 3. Run sequences on the agent's sequencer:
crlp_qch_cycle_seq q = crlp_qch_cycle_seq::type_id::create("q");
q.start(env.agent.sqr);
```

### Ready-made sequences

- `crlp_por_seq` — start clock + reset pulse.
- `crlp_qch_cycle_seq` — Q-Channel quiesce then wake.
- `crlp_pch_seq` — one P-Channel state change (`target_state`).
- `crlp_lowpower_flow_seq` — POR → Q-Channel cycle → P-Channel RET → ON.

## Compile / run (example)

```sh
cd sim
# Questa
vlog -sv +incdir+../tb +incdir+../sim -f filelist.f
vsim -c crlp_tb_top -do "run -all; quit" +UVM_TESTNAME=crlp_base_test
# add +DUMP for a VCD waveform
```

The included `crlp_dut_stub` always accepts (never denies), letting the full
flow run end-to-end. Swap it for the real DMAC and connect the scoreboard to
`agent.ap` for checking.

## Adapting to the real DMAC

- Update `crlp_pstate_e` in `crlp_types.svh` to the DMAC's IMPLEMENTATION
  DEFINED power-state encodings.
- Tune `qch_timeout_cycles` / `pch_timeout_cycles` in `crlp_config`.
- Add protocol assertions (Q/P legal transitions, `qactive` wake behaviour) —
  hooks are already isolated in the monitor.
