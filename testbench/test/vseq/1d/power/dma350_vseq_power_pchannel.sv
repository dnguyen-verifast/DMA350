//==============================================================================
// dma350_vseq_power_pchannel.sv
//   "P-Channel power - Power-domain transitions via LPI P-Channel"
//   Chuoi chuyen power state qua P-Channel: ON_FULL -> RET -> ON_FULL, roi chay
//   copy. Kiem tra handshake P-Channel (accept/deny) khi idle.
//==============================================================================
`ifndef DMA350_VSEQ_POWER_PCHANNEL_SV
`define DMA350_VSEQ_POWER_PCHANNEL_SV

class dma350_vseq_power_pchannel extends dma350_vseq_power_base;
  `uvm_object_utils(dma350_vseq_power_pchannel)

  function new(string name = "dma350_vseq_power_pchannel");
    super.new(name);
  endfunction

  virtual task body();
    super.body();

    // Chuoi chuyen power-domain (idle) qua LPI P-Channel
    pch_request(PSTATE_ON_FULL, "ON_FULL");
    pch_request(PSTATE_RET,     "RETENTION");
    pch_request(PSTATE_ON_FULL, "ON_FULL");

    // sau khi ve full power: chay mot copy
    run_copy();
  endtask

endclass : dma350_vseq_power_pchannel

`endif // DMA350_VSEQ_POWER_PCHANNEL_SV
