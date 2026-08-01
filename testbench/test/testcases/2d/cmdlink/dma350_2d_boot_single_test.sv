//==============================================================================
// dma350_2d_boot_single_test.sv
//   GROUP H - TRM 5.7.3 'Automatic boot feature' voi lenh 2D
//   Autoboot nap MOT lenh 2D vao CH0 ngay sau reset (khong can APB).
//==============================================================================
`ifndef DMA350_2D_BOOT_SINGLE_TEST_SV
`define DMA350_2D_BOOT_SINGLE_TEST_SV

class dma350_2d_boot_single_test extends dma350_base_test;
  `uvm_component_utils(dma350_2d_boot_single_test)

  function new(string name = "dma350_2d_boot_single_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma350_vseq_2d_boot_single vseq = dma350_vseq_2d_boot_single::type_id::create("vseq");
    phase.raise_objection(this, get_type_name());
    vseq.start(dma350_env_h.v_seqr_h);
    #1us;
    phase.drop_objection(this, get_type_name());
  endtask

endclass : dma350_2d_boot_single_test

`endif // DMA350_2D_BOOT_SINGLE_TEST_SV
