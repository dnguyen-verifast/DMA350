//==============================================================================
// dma350_2d_life_disable_test.sv
//   GROUP I - TRM 5.6.1 'Done state' + DISABLECMD tren 2D
//   DISABLECMD cho lenh 2D dang chay HOAN THANH roi moi dung (khong nap lenh ke).
//==============================================================================
`ifndef DMA350_2D_LIFE_DISABLE_TEST_SV
`define DMA350_2D_LIFE_DISABLE_TEST_SV

class dma350_2d_life_disable_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_life_disable_test)

  function new(string name = "dma350_2d_life_disable_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_life_disable vseq = dma350_vseq_2d_life_disable::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_life_disable_test

`endif // DMA350_2D_LIFE_DISABLE_TEST_SV
