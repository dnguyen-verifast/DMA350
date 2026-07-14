//==============================================================================
// Test 5: dma350_1d_single_wrap_test - XTYPE=wrap (dia chi nguon quay vong)
//==============================================================================
`ifndef dma350_1d_single_wrap_test_SV
`define dma350_1d_single_wrap_test_SV

class dma350_1d_single_wrap_test extends dma350_base_test;
  `uvm_component_utils(dma350_1d_single_wrap_test)

  function new(string name = "dma350_1d_single_wrap_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_1d_single_wrap vseq = dma350_vseq_1d_single_wrap::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask
endclass

`endif // dma350_1d_single_wrap_test_SV
