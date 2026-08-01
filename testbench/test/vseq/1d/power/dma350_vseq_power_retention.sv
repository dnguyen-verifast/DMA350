//==============================================================================
// dma350_vseq_power_retention.sv
//   "Retention - Low-power state retaining context"
//   Khi IDLE: yeu cau P-Channel -> RET (full retention, giu context) -> chap
//   nhan; sau do ve ON_FULL roi chay mot copy de chung to context van dung.
//==============================================================================
`ifndef DMA350_VSEQ_POWER_RETENTION_SV
`define DMA350_VSEQ_POWER_RETENTION_SV

class dma350_vseq_power_retention extends dma350_vseq_power_base;
  `uvm_object_utils(dma350_vseq_power_retention)

  function new(string name = "dma350_vseq_power_retention");
    super.new(name);
  endfunction

  virtual task body();
    super.body();

    // IDLE -> vao retention (giu context) -> ra lai ON
    pch_request(PSTATE_RET,     "RETENTION");
    pch_request(PSTATE_ON_FULL, "ON_FULL");

    // context con nguyen: chay copy binh thuong
    run_copy();
  endtask

endclass : dma350_vseq_power_retention

`endif // DMA350_VSEQ_POWER_RETENTION_SV
