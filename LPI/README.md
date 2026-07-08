# AMBA Low Power Interface (LPI) — UVM VIP-to-VIP Testbench

A self-checking UVM testbench for the **AMBA Low Power Interface** (ARM IHI 0068D),
covering both the **Q-Channel** (Chapter 2) and **P-Channel** (Chapter 3) low-power
interfaces.

This is a **VIP-to-VIP** environment: there is **no DUT**. A *controller* VIP and a
*device* VIP drive opposite halves of the same interface wires and handshake with
each other. Passive monitors decode the interface state every clock and self-checking
scoreboards verify that every state transition is legal per the spec.

```
            ┌──────────────────────────── lpi_env ────────────────────────────┐
            │                                                                  │
  Q-Channel │  q_slave_agent ─QREQn─►┐         ┌──► q_master_agent            │
            │  (Controller)          │ q_if     │    (Device)                  │
            │            ◄─QACCEPTn/QDENY/QACTIVE─┘                            │
            │                  monitors ─► sb (common checker) + q_cov         │
            │                                                                  │
  P-Channel │  p_master_agent ─PSTATE/PREQ─►┐    ┌──► p_slave_agent            │
            │  (Controller)               │ p_if │    (Device)                 │
            │             ◄─PACCEPT/PDENY/PACTIVE─┘                            │
            │                  monitors ─► sb (common checker) + p_cov         │
            └──────────────────────────────────────────────────────────────────┘
```

## Directory layout

One class per file. Each package only `` `include ``s its classes; the file
lists compile the packages + interfaces + top (the `+incdir` list resolves the
included class files).

```
tb/
  common/lpi_defs.svh                       # PSTATE/PACTIVE widths
  if/
    lpi_qchannel_if.sv                       # Q-Channel interface (Figure 2-1)
    lpi_pchannel_if.sv                       # P-Channel interface (Figure 3-1)
  agents/
    qchannel/
      lpi_qchannel_pkg.sv                    # package (include-only)
      lpi_qchannel_types.svh                 # state enum + decode
      lpi_qchannel_item.sv
      lpi_qchannel_cfg.sv
      lpi_qchannel_coverage.sv
      master/                                # MASTER VIP (Q: Device)
        lpi_qchannel_master_driver.sv
        lpi_qchannel_master_monitor.sv       # master's OWN monitor
        lpi_qchannel_master_agent.sv         # driver + sequencer + monitor
      slave/                                 # SLAVE VIP (Q: Controller)
        lpi_qchannel_slave_driver.sv
        lpi_qchannel_slave_monitor.sv        # slave's OWN monitor
        lpi_qchannel_slave_agent.sv          # driver + sequencer + monitor
    pchannel/                                # same structure as qchannel
      lpi_pchannel_pkg.sv  ...  master/lpi_pchannel_master_*  slave/lpi_pchannel_slave_*
  seq/                                       # ALL child SEQUENCES (separate folder)
    lpi_qchannel_seq_pkg.sv                  # Q sequence-library package
    lpi_qchannel_master_seq.sv  + _accept_seq / _deny_seq   (device responder)
    lpi_qchannel_slave_seq.sv                                (controller initiator)
    lpi_pchannel_seq_pkg.sv                  # P sequence-library package
    lpi_pchannel_master_seq.sv  + _walk_seq                  (controller initiator)
    lpi_pchannel_slave_seq.sv   + _accept_seq / _deny_seq    (device responder)
  env/
    lpi_env_pkg.sv                           # package (include-only)
    lpi_env_cfg.sv
    lpi_virtual_sequencer.sv                 # virtual SEQUENCER lives in env
    lpi_scoreboard.sv                        # ONE common scoreboard (both channels+roles)
    lpi_env.sv
  vseq/                                      # virtual SEQUENCES (separate folder)
    lpi_vseq_pkg.sv                          # package (include-only)
    lpi_base_vseq.sv  lpi_sanity_vseq.sv  lpi_smoke_vseq.sv
    lpi_q_accept_vseq.sv  lpi_q_deny_vseq.sv
    lpi_p_accept_vseq.sv  lpi_p_deny_vseq.sv  lpi_p_walk_vseq.sv
  test/
    lpi_test_pkg.sv                          # package (include-only)
    lpi_base_test.sv
    lpi_smoke_test.sv
    lpi_qchannel_test.sv
    lpi_pchannel_test.sv
  top/tb_top.sv                              # clock/reset, interfaces, run_test
sim/
  Makefile  lpi.f  filelist.f                # build (Questa Makefile + file lists)
  run_questa.do / run_vcs.sh / run_xrun.sh
  lpi_regression.list
```

## What is checked

**Q-Channel** (`lpi_qchannel_scoreboard`, based on Table 2-1 / Figure 2-6):
- Legal state graph only: `Q_RUN→Q_REQUEST→{Q_STOPPED→Q_EXIT→Q_RUN | Q_DENIED→Q_CONTINUE→Q_RUN}`.
- Illegal combination `QACCEPTn=0, QDENY=1` flagged as `Q_ILLEGAL`.
- Reset behavior: device drives `QACCEPTn=QDENY=0`; controller releases with `QREQn=1`
  → interface self-initializes to `Q_RUN`.

**P-Channel** (`lpi_pchannel_scoreboard`, based on Table 3-1 / Figure 3-8):
- Legal state graph only: `P_STABLE→P_REQUEST→{P_ACCEPT→P_COMPLETE→P_STABLE | P_DENIED→P_CONTINUE→P_STABLE}`.
- Illegal combination `PACCEPT=1, PDENY=1` flagged as `P_ILLEGAL`.
- On deny, controller restores `PSTATE` to the current state before dropping `PREQ`
  (section 3.1.2, denied state transition).
- Multiple back-to-back transitions without returning to a common operable state.

Both drivers honour the **handshake signalling rules** (only the controller toggles
the request, only the device toggles the acks, one ack changes per handshake).

Coverage collectors sample every interface state and every legal state-edge.

## Stimulus control (virtual sequencer / virtual sequence)

The env contains a **`lpi_virtual_sequencer`** holding handles to all four
channel sub-sequencers (`q_master_seqr`, `q_slave_seqr`, `p_master_seqr`,
`p_slave_seqr`), wired up in the env `connect_phase`.

The test does **not** start sequences on individual sequencers. Instead it
starts one **virtual sequence** (`lpi_smoke_vseq`) on `env.vseqr`. The virtual
sequence (via `p_sequencer`):

1. launches the device responder sub-sequences (`*_dev_seq`) in the background
   (forever responders, `kill()`-ed when stimulus completes), and
2. runs the controller sub-sequences (`*_ctrl_seq`) for both channels in
   parallel (`fork ... join`).

`do_q` / `do_p` flags on the virtual sequence select which channels are
exercised; the tests set them from the env config so a single `run_phase`
serves the smoke / Q-only / P-only tests.

```
test.run_phase ──start──► lpi_smoke_vseq  (on env.vseqr)
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                      ▼                      ▼
   q_slave_seq (bg)      q_master_seq           p_master_seq    ...p_slave_seq (bg)
   on q_slave_seqr       on q_master_seqr       on p_master_seqr   on p_slave_seqr
```

## Running

UVM 1.2 is required. Point your tool at it as shown.

**Questa**
```
cd sim
vsim -c -do run_questa.do                                   # default: lpi_smoke_test
vsim -c -do "set TEST lpi_qchannel_test; do run_questa.do"  # Q-Channel only
```

**VCS**
```
cd sim
./run_vcs.sh                 # lpi_smoke_test
./run_vcs.sh lpi_pchannel_test
```

**Xcelium**
```
cd sim
./run_xrun.sh lpi_qchannel_test
```

## Tests

| Test                  | Q-Channel | P-Channel | Notes                                       |
|-----------------------|:---------:|:---------:|---------------------------------------------|
| `lpi_sanity_test`     |     ✓     |     ✓     | **run first** — directed bring-up (accept,deny,accept) |
| `lpi_smoke_test`      |     ✓     |     ✓     | randomized, both channels in parallel       |
| `lpi_qchannel_test`   |     ✓     |     —     | Q-Channel only, randomized                  |
| `lpi_pchannel_test`   |     —     |     ✓     | P-Channel only, randomized                  |
| `lpi_q_accept_test`   |     ✓     |     —     | scenario: device always accepts             |
| `lpi_q_deny_test`     |     ✓     |     —     | scenario: device always denies              |
| `lpi_p_accept_test`   |     —     |     ✓     | scenario: device always accepts             |
| `lpi_p_deny_test`     |     —     |     ✓     | scenario: device always denies              |
| `lpi_p_walk_test`     |     —     |     ✓     | scenario: power-state walk ON→Warm→Ret→OFF→ON |

### Scenarios = one virtual sequence + its own child sequences

Each scenario is a **dedicated virtual sequence** (`tb/vseq/lpi_<scn>_vseq.sv`)
that starts **dedicated child sequences**, so scenarios are independently
controllable. The child sequences derive from a configurable base and override
one hook:

```
device responder base : lpi_{q,p}channel_<dev>_seq   (virtual next_deny(idx))
   ├─ ..._accept_seq   override next_deny -> 0   (always accept)
   └─ ..._deny_seq     override next_deny -> 1   (always deny)
controller base       : lpi_{q,p}channel_<ctrl>_seq
   └─ lpi_pchannel_master_walk_seq  override next_pstate(idx) -> ON/Warm/Ret/OFF
```

All child sequences live together in **`tb/seq/`** (packages
`lpi_{q,p}channel_seq_pkg`), separate from the agents and from the virtual
sequences in `tb/vseq/`.

**To add a new scenario:** add a child sequence in `tb/seq/` (override the hook)
and include it in the channel's `*_seq_pkg`, add a `lpi_<scn>_vseq` in
`tb/vseq/` that starts it, and a thin `lpi_<scn>_test` that runs the vseq;
register the test name in `sim/lpi_regression.list`.

### Master / Slave mapping

This is a master-to-slave VIP-to-VIP env (no DUT). The master/slave-to-LPI-role
mapping is **per channel** (note the Q-Channel mapping is intentionally the
opposite of the P-Channel one):

| Channel | `master` agent  | drives                              | `slave` agent  | drives                          |
|---------|-----------------|-------------------------------------|----------------|---------------------------------|
| **Q**   | **Device**      | `QACCEPTn`,`QDENY`,`QACTIVE`        | **Controller** | `QREQn`                         |
| **P**   | **Controller**  | `PSTATE`,`PREQ`                     | **Device**     | `PACCEPT`,`PDENY`,`PACTIVE`     |

In both channels the **Controller** is the initiator (drives the request) and
the **Device** is the state-based responder (accepts/denies). The Device follows
the interface state diagram (Q: Figure 2-6 / P: Figure 3-8); the Controller
drives the request and waits on the device-driven signals to advance.

Every component is its **own class in its own folder**. The master and slave
agents each contain their **own driver + sequencer + monitor**
(`master/lpi_*_master_monitor.sv`, `slave/lpi_*_slave_monitor.sv`). The single
common scoreboard (`env/lpi_scoreboard.sv`) receives all four streams through
role-specific analysis imports and checks legality on each:

```
 q_master_agent(mon) ─► sb.q_master_imp ┐
 q_slave_agent (mon) ─► sb.q_slave_imp  ├─► lpi_scoreboard  (one, common)
 p_master_agent(mon) ─► sb.p_master_imp │
 p_slave_agent (mon) ─► sb.p_slave_imp  ┘
 q_master_agent(mon) ─► q_cov   p_master_agent(mon) ─► p_cov   (coverage)
```

Bring up the environment with the sanity test first:

```
make simulate test=lpi_sanity_test uvm_verbosity=UVM_MEDIUM
```

Expect `UVM_ERROR : 0`; the scoreboards print the observed transition counts.

Select with `+UVM_TESTNAME=<test>`.

## Power states (P-Channel)

The P-Channel device models **4 power states** (`p_power_state_e` in
`lpi_pchannel_pkg.sv`), ordered highest → lowest power:

| State              | PSTATE (M=2) | PACTIVE bit |
|--------------------|:------------:|:-----------:|
| ON                 | `2'b11`      | PACTIVE[3]  |
| Warm reset mode    | `2'b10`      | PACTIVE[2]  |
| Full retention mode| `2'b01`      | PACTIVE[1]  |
| OFF                | `2'b00`      | PACTIVE[0] (implicit minimum, may be omitted) |

The controller sequence only requests these 4 encodings (`c_pstate`), and the
coverage collector has a named bin per state.

## Extending

- Change `n_req` in the test to run more handshakes.
- Tune `c_deny_dist` in the items to stress the denial paths.
- Add the **parity-extended** variants (sections 2.2 / 3.2) by widening the
  interfaces with the `*CHK` signals and the parity-state tables (Table 2-3 / 3-3);
  the agent/scoreboard structure here is designed to be reused for that.
- To verify a **real DUT**, set the relevant agent `is_active=UVM_PASSIVE` (so the
  VIP only monitors that half) and connect the DUT to the corresponding wires.
