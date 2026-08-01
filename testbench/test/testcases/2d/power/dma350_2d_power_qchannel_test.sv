//==============================================================================
// dma350_2d_power_qchannel_test.sv
//   GROUP J - TRM 5.9.1.2 'Clock Q-Channel' quanh lenh 2D
//   Chu ky quiesce/wake clock truoc khi chay va sau khi chay xong khung 2D.
//==============================================================================
`ifndef DMA350_2D_POWER_QCHANNEL_TEST_SV
`define DMA350_2D_POWER_QCHANNEL_TEST_SV

class dma350_2d_power_qchannel_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_power_qchannel_test)

  function new(string name = "dma350_2d_power_qchannel_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_power_qchannel vseq = dma350_vseq_2d_power_qchannel::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_power_qchannel_test

`endif // DMA350_2D_POWER_QCHANNEL_TEST_SV
