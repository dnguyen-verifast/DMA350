# DMA-350 Boot Configuration VIP

A UVM Verification IP for the **Arm® CoreLink™ DMA-350** automatic boot
configuration interface, implemented from *Table A-11: Configuration signals*
and the boot-protocol rules in §4.9.1 (*Automatic boot interface*) and §5.7.3
(*Automatic boot feature*) of the TRM (102482_0000_04_en).

## Interface under verification (Table A-11)

| Signal              | Dir (DUT) | Width            | Meaning |
|---------------------|-----------|------------------|---------|
| `boot_en`           | input     | 1                | Enable channel-0 autoboot after reset. |
| `boot_addr`         | input     | `[ADDR_WIDTH-1:2]` | Word-aligned boot-command descriptor address. Must be Secure when `SECEXT_PRESENT=1`. |
| `boot_memattr`      | input     | 8                | Boot fetch memory attributes (same encoding as `LINKMEMATTRHI`/`LINKMEMATTRLO`). |
| `boot_shareattr`    | input     | 2                | Boot fetch shareability (same encoding as `LINKSHAREATTR`). |

All boot signals are **static inputs to the DMAC**. Per §4.9.1 they must be
**stable when `resetn` is deasserted and remain stable until the boot command
fetch starts**. If `boot_en` is LOW, autoboot is disabled and the rest are
ignored.

> `boot_fetch_started` is **not** a Table A-11 pin. It is a VIP observation
> input that the integration TB must drive from a real "boot fetch started"
> indication (e.g. the first channel-0 command-link AXI read:
> `arvalid_m0 & arready_m0 & arcmdlink_m0`). Disable the related checks with
> `boot_agent_cfg.check_stability_window = 0` if unavailable.

## Files

```
vip_boot/
├── boot_vip.f                 # compile file list
├── README.md
├── src/
│   ├── boot_if.sv             # interface + clocking blocks
│   ├── boot_sva.sv            # bindable concurrent assertions
│   ├── boot_types.svh         # memattr/shareattr enums
│   ├── boot_seq_item.sv       # transaction + legality constraints
│   ├── boot_agent_cfg.sv      # agent configuration
│   ├── boot_driver.sv         # drives boot_* (hold-stable-through-reset)
│   ├── boot_monitor.sv        # samples at reset release + protocol checks
│   ├── boot_coverage.sv       # functional coverage
│   ├── boot_agent.sv          # agent + sequencer typedef
│   ├── boot_seq_lib.sv        # enabled / disabled / directed sequences
│   └── boot_pkg.sv            # UVM package
└── tb/
    ├── boot_dut_stub.sv       # behavioral autoboot front-end (demo only)
    ├── boot_test_pkg.sv       # env + tests
    └── boot_tb_top.sv         # top, clk/reset, SVA bind, run_test
```

## What the VIP checks

**Driver** programs the boot configuration *while in reset* and holds it stable
across the reset edge and through the boot-fetch window.

**Monitor** latches the configuration at the deasserting edge of `resetn`
(the point the DMAC samples it), broadcasts it, and flags:
- `boot_shareattr == 2'b01` (Reserved/illegal);
- Device-type `boot_memattr` with an illegal `*LO` nibble (UNPREDICTABLE);
- Normal-memory `boot_memattr` with `LO == 0000` (Reserved);
- with `SECEXT_PRESENT`, an enabled boot whose address is outside the Secure
  region;
- any change of `boot_*` before `boot_fetch_started` (stability-window
  violation).

**SVA** (`boot_sva.sv`) provides the same rules as bindable assertions for
formal/simulation reuse.

**Coverage** samples `boot_en`, memory type, shareability, address region and
their crosses, once per reset.

## Running the example

```sh
# Questa/ModelSim
vlib work
vlog -sv +incdir+vip_boot/src +incdir+vip_boot/tb -f vip_boot/boot_vip.f
vsim -c boot_tb_top -do "run -all; quit"

# Cadence Xcelium
xrun -uvm -sv -f vip_boot/boot_vip.f +UVM_TESTNAME=boot_secure_test

# Synopsys VCS
vcs -sverilog -ntb_opts uvm -f vip_boot/boot_vip.f && ./simv +UVM_TESTNAME=boot_enabled_test
```

Provided tests:
- `boot_enabled_test`  – randomized, legal, autoboot enabled.
- `boot_secure_test`   – `SECEXT_PRESENT=1`, directed Secure boot address.

## Integrating with the real DMAC

1. Replace `tb/boot_dut_stub.sv` with the DMA-350 RTL.
2. Connect the four Table A-11 pins to `boot_if`.
3. Drive `boot_if.boot_fetch_started` from the channel-0 command-link read
   start (or set `check_stability_window = 0`).
4. Set `boot_agent_cfg.addr_width`, `secext_present`, `secure_base/limit` from
   the build configuration (`DMA_BUILDCFG0/2`).
