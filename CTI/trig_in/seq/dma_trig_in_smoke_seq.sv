//============================================================================
// dma_trig_in_smoke_seq.sv  -- N SINGLE requests (used by smoke vseq).
//============================================================================
`ifndef DMA_TRIG_IN_SMOKE_SEQ_SV
`define DMA_TRIG_IN_SMOKE_SEQ_SV

class dma_trig_in_smoke_seq extends dma_trig_in_base_seq;
  `uvm_object_utils(dma_trig_in_smoke_seq)
  rand int unsigned n_req = 5;
  constraint c_n { n_req inside {[1:10]}; }
  function new(string name = "dma_trig_in_smoke_seq");
    super.new(name);
  endfunction
  task body();
    repeat (n_req) begin
      dma_trig_in_single_seq s = dma_trig_in_single_seq::type_id::create("single");
      if (!s.randomize() with { pre_delay inside {[0:3]}; })
        `uvm_error(get_type_name(), "single randomize failed")
      s.start(m_sequencer);
    end
  endtask
endclass : dma_trig_in_smoke_seq

`endif // DMA_TRIG_IN_SMOKE_SEQ_SV
