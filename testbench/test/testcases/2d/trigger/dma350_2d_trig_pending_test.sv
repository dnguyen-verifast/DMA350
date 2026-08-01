//==============================================================================
// dma350_2d_trig_pending_test.sv
//   GROUP F - TRM 5.4.1 'pending req on the trigger input port' tren 2D
//   Ban trigger TRUOC khi enable channel -> request nam cho o cong TI.
//==============================================================================
`ifndef DMA350_2D_TRIG_PENDING_TEST_SV
`define DMA350_2D_TRIG_PENDING_TEST_SV

class dma350_2d_trig_pending_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_trig_pending_test)

  function new(string name = "dma350_2d_trig_pending_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_trig_pending vseq = dma350_vseq_2d_trig_pending::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_trig_pending_test

`endif // DMA350_2D_TRIG_PENDING_TEST_SV
