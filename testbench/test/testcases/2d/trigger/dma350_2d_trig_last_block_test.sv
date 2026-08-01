//==============================================================================
// dma350_2d_trig_last_block_test.sv
//   GROUP F - TRM Table 5-4, reqtype = LAST BLOCK tren command trigger 2D
//   Peripheral bao ket thuc bang LAST_BLOCK ngay tu request dau tien.
//==============================================================================
`ifndef DMA350_2D_TRIG_LAST_BLOCK_TEST_SV
`define DMA350_2D_TRIG_LAST_BLOCK_TEST_SV

class dma350_2d_trig_last_block_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_trig_last_block_test)

  function new(string name = "dma350_2d_trig_last_block_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_trig_last_block vseq = dma350_vseq_2d_trig_last_block::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_trig_last_block_test

`endif // DMA350_2D_TRIG_LAST_BLOCK_TEST_SV
