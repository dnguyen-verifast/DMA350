//==============================================================================
// dma350_vseq_power_active.sv
//   "Active / Normal - Full power, running"
//   P-Channel giu o ON_FULL; chay mot copy (DMAC hoat dong full power).
//==============================================================================
`ifndef DMA350_VSEQ_POWER_ACTIVE_SV
`define DMA350_VSEQ_POWER_ACTIVE_SV

class dma350_vseq_power_active extends dma350_vseq_power_base;
  `uvm_object_utils(dma350_vseq_power_active)

  function new(string name = "dma350_vseq_power_active");
    super.new(name);
  endfunction

  virtual task body();
    super.body();
    pch_request(PSTATE_ON_FULL, "ON_FULL");   // full power
    run_copy();                               // running
  endtask

endclass : dma350_vseq_power_active

`endif // DMA350_VSEQ_POWER_ACTIVE_SV
