//==============================================================================
// dma350_sc_base_seq.sv
//------------------------------------------------------------------------------
// Base sequence: pulls cfg from the sequencer so child sequences know the build
// (secext_present etc.) and provides small helpers.
//==============================================================================
`ifndef DMA350_SC_BASE_SEQ__SV
`define DMA350_SC_BASE_SEQ__SV

class dma350_sc_base_seq extends uvm_sequence #(dma350_sc_item);
  `uvm_object_utils(dma350_sc_base_seq)

  dma350_sc_cfg cfg;

  function new(string name = "dma350_sc_base_seq");
    super.new(name);
  endfunction

  virtual task pre_body();
    // Best-effort cfg fetch (sequencer scope).
    if (!uvm_config_db#(dma350_sc_cfg)::get(m_sequencer, "", "cfg", cfg))
      `uvm_warning(get_type_name(), "cfg not found on sequencer; using defaults")
    if (cfg == null) cfg = dma350_sc_cfg::type_id::create("cfg");
  endtask

  // helper: send a single item
  task send(dma350_sc_op_e op, dma350_sc_dom_e dom = SC_NONSEC,
            int unsigned hold = 0, int unsigned gap = 2, bit auto_rst = 0);
    dma350_sc_item it = dma350_sc_item::type_id::create("it");
    start_item(it);
    if (!it.randomize() with {
          op          == local::op;
          domain      == local::dom;
          hold_cycles == local::hold;
          duration    == local::gap;
          auto_restart == local::auto_rst;
        })
      `uvm_error(get_type_name(), "randomize failed")
    finish_item(it);
  endtask

endclass : dma350_sc_base_seq

`endif // DMA350_SC_BASE_SEQ__SV
