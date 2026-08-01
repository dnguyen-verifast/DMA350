//==============================================================================
// dma350_2d_autorestart_cnt_test.sv
//   GROUP H - TRM 5.6.2 'Automatic restart of commands' tren lenh 2D
//   CH_AUTOCFG.CMDRESTARTCNT = 2 -> khung 2D duoc lap lai 3 lan.
//==============================================================================
`ifndef DMA350_2D_AUTORESTART_CNT_TEST_SV
`define DMA350_2D_AUTORESTART_CNT_TEST_SV

class dma350_2d_autorestart_cnt_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_autorestart_cnt_test)

  function new(string name = "dma350_2d_autorestart_cnt_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_autorestart_cnt vseq = dma350_vseq_2d_autorestart_cnt::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_autorestart_cnt_test

`endif // DMA350_2D_AUTORESTART_CNT_TEST_SV
