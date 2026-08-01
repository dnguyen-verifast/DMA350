//==============================================================================
// dma350_2d_trig_out_test.sv
//   GROUP F - TRM 5.4.2 'Trigger outputs' tren lenh 2D
//   Lenh 2D tu chay, khi xong thi phat trigger-out ra cong ngoai va DUNG lai cho ack.
//==============================================================================
`ifndef DMA350_2D_TRIG_OUT_TEST_SV
`define DMA350_2D_TRIG_OUT_TEST_SV

class dma350_2d_trig_out_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_trig_out_test)

  function new(string name = "dma350_2d_trig_out_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_trig_out vseq = dma350_vseq_2d_trig_out::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_trig_out_test

`endif // DMA350_2D_TRIG_OUT_TEST_SV
