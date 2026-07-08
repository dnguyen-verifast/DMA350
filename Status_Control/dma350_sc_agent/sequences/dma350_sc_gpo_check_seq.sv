//==============================================================================
// dma350_sc_gpo_check_seq.sv  (Group 1 - General Purpose Outputs, 4.8.1)
//------------------------------------------------------------------------------
// The GPO value itself is SW-controlled through channel registers and is driven
// by the DUT; this agent does not drive gpo_ch. This sequence therefore only
// asks the monitor to snapshot GPO/status at chosen points (SC_GPO_SAMPLE), so
// a scoreboard can check GPO stability across a DMAC operation and the
// "hold last value" behaviour when a channel stops driving it.
//
// Actual GPO *programming* (ENABLE bit, GPOVAL/GPOEN, and the empty command
// that clears all GPOs to 0) is performed via the APB register agent, not here.
//==============================================================================
`ifndef DMA350_SC_GPO_CHECK_SEQ__SV
`define DMA350_SC_GPO_CHECK_SEQ__SV

class dma350_sc_gpo_check_seq extends dma350_sc_base_seq;
  `uvm_object_utils(dma350_sc_gpo_check_seq)

  rand int unsigned samples = 8;
  rand int unsigned gap     = 4;

  function new(string name = "dma350_sc_gpo_check_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info(get_type_name(),
      $sformatf("GPO/status sampling x%0d (gpo_width=%0d)", samples, cfg.gpo_width), UVM_LOW)
    repeat (samples) send(SC_GPO_SAMPLE, SC_NONSEC, 0, gap);
  endtask
endclass : dma350_sc_gpo_check_seq

`endif // DMA350_SC_GPO_CHECK_SEQ__SV
