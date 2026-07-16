//============================================================================
// dma_trig_out_coverage.sv
// Functional coverage for trigger-OUT (checklist group D):
//   ack latency / channel-stall duration (incl. very long), and whether the
//   request completed via hardware ack or the SW-ack path.
//============================================================================
`ifndef DMA_TRIG_OUT_COVERAGE_SV
`define DMA_TRIG_OUT_COVERAGE_SV

class dma_trig_out_coverage extends uvm_subscriber #(dma_trig_item);

  `uvm_component_utils(dma_trig_out_coverage)

  dma_trig_item tr;

  covergroup cg_trig_out;
    option.per_instance = 1;
    cp_stall : coverpoint tr.latency_cycles {
      bins zero    = {0};
      bins one     = {1};
      bins fast    = {[2:4]};
      bins med     = {[5:32]};
      bins long    = {[33:127]};
      bins vlong   = {[128:$]};       // very long stall before DONE
    }
    cp_ackpath : coverpoint tr.ack_passive {  // 1 => completed without hw ack
      bins hw_ack = {0};
      bins sw_ack = {1};
    }
    x_stall_path : cross cp_stall, cp_ackpath;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_trig_out = new();
  endfunction

  function void write(dma_trig_item t);
    tr = t;
    cg_trig_out.sample();
  endfunction

endclass : dma_trig_out_coverage

`endif // DMA_TRIG_OUT_COVERAGE_SV
