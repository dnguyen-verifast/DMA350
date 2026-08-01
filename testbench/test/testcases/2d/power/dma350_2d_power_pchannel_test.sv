//==============================================================================
// dma350_2d_power_pchannel_test.sv
//   GROUP J - TRM 5.9.1.1, yeu cau P-Channel TRONG LUC khung 2D dang chay
//   TRM: khi DMAC dang active thi yeu cau quiescence bi TU CHOI (pdeny), lenh chay tiep.
//==============================================================================
`ifndef DMA350_2D_POWER_PCHANNEL_TEST_SV
`define DMA350_2D_POWER_PCHANNEL_TEST_SV

class dma350_2d_power_pchannel_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_power_pchannel_test)

  function new(string name = "dma350_2d_power_pchannel_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_power_pchannel vseq = dma350_vseq_2d_power_pchannel::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_power_pchannel_test

`endif // DMA350_2D_POWER_PCHANNEL_TEST_SV
