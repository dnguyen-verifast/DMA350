//==============================================================================
// dma350_2d_trig_sw_cmd_test.sv
//   GROUP F - TRM 5.4.5 'Software triggers' tren lenh 2D
//   Command-mode trigger bang phan mem (CH_CMD.SRCSWTRIGINREQ) khoi dong ca khoi 2D.
//==============================================================================
`ifndef DMA350_2D_TRIG_SW_CMD_TEST_SV
`define DMA350_2D_TRIG_SW_CMD_TEST_SV

class dma350_2d_trig_sw_cmd_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_trig_sw_cmd_test)

  function new(string name = "dma350_2d_trig_sw_cmd_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_trig_sw_cmd vseq = dma350_vseq_2d_trig_sw_cmd::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_trig_sw_cmd_test

`endif // DMA350_2D_TRIG_SW_CMD_TEST_SV
