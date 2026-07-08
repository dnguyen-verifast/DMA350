#!/usr/bin/env bash
# Build and run the DMA-350 basic self-checking tests with QuestaSim.
# (Package must precede the modules that import it.)
set -e; cd "$(dirname "$0")"

RTL="dma350_pkg.sv dma350_byte_fifo.sv dma350_burst.sv dma350_trigger.sv \
     dma350_lpi.sv dma350_axi_node.sv dma350_ch_regs.sv dma350_channel.sv \
     dma350_top.sv"
TBLIB="axi5_mem_slave.sv dma350_tb_harness.sv"

# Tạo library một lần
vlib work
vmap work work

for t in basic narrow multi; do
  echo "=== $t ==="
  # Compile: -sv bật SystemVerilog, +acc để giữ tín hiệu nếu cần debug
  vlog -sv -quiet $RTL $TBLIB tb_dma350_$t.sv

  # Run ở chế độ console (-c), không GUI
  vsim mkdir dma
     -c -quiet -voptargs=+acc work.tb_dma350_$t \
       -do -do "log -r /*; add wave -r /*; coverage save -onexit -assert -directive -cvg -codeAll dma/dma_coverage.ucdb; run -all; exit" \
	-wlf dma/waveform.wlf \
    | grep -E "PASSED|FAILED|DONE|TIMEOUT|mismatch|corrupted|STAT_DONE"
done