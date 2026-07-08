//==============================================================================
// dma350_sc_cti_seq.sv  (Group 3 - Cross Trigger Interface, 4.8.3)
//------------------------------------------------------------------------------
// Exercises the CTI: assert halt_req (level), wait for the `halted` pulse
// (observed by monitor), then restart_req (pulse). halt_req covers BOTH Secure
// and Non-secure channels at once (unlike allch_pause).
//==============================================================================
`ifndef DMA350_SC_CTI_SEQ__SV
`define DMA350_SC_CTI_SEQ__SV

class dma350_sc_cti_seq extends dma350_sc_base_seq;
  `uvm_object_utils(dma350_sc_cti_seq)

  rand int unsigned halt_len    = 20;   // cycles to stay halted
  rand bit          auto_restart = 1'b1;

  function new(string name = "dma350_sc_cti_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info(get_type_name(),
      $sformatf("CTI halt/restart halt_len=%0d auto=%0b", halt_len, auto_restart), UVM_LOW)
    if (auto_restart) begin
      // single self-contained halt then restart pulse
      send(SC_HALT, SC_NONSEC, halt_len, .gap(2), .auto_rst(1'b1));
    end
    else begin
      send(SC_HALT,    SC_NONSEC, halt_len);  // hold halted
      send(SC_RESTART, SC_NONSEC, 0);         // explicit restart pulse
    end
  endtask
endclass : dma350_sc_cti_seq

`endif // DMA350_SC_CTI_SEQ__SV
