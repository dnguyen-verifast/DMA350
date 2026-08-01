//==============================================================================
// dma350_2d_life_err_bus_test.sv
//   GROUP I - TRM 5.6.3 'Error handling' - loi bus giua khung 2D
//   Vung nguon co dia chi khong duoc slave AXI phuc vu -> tra loi loi.
//==============================================================================
`ifndef DMA350_2D_LIFE_ERR_BUS_TEST_SV
`define DMA350_2D_LIFE_ERR_BUS_TEST_SV

class dma350_2d_life_err_bus_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_life_err_bus_test)

  function new(string name = "dma350_2d_life_err_bus_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_life_err_bus vseq = dma350_vseq_2d_life_err_bus::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_life_err_bus_test

`endif // DMA350_2D_LIFE_ERR_BUS_TEST_SV
