//============================================================================
// dma_trig_in_single_stream_seq.sv
// SINGLE stream closed by LAST SINGLE (peripheral ends a stream of unknown
// size with a final single beat). TRM Table 5-4.
//============================================================================
`ifndef DMA_TRIG_IN_SINGLE_STREAM_SEQ_SV
`define DMA_TRIG_IN_SINGLE_STREAM_SEQ_SV

class dma_trig_in_single_stream_seq extends dma_trig_in_base_seq;
  `uvm_object_utils(dma_trig_in_single_stream_seq)
  rand int unsigned n_singles;
  constraint c_n { n_singles inside {[1:10]}; }
  function new(string name = "dma_trig_in_single_stream_seq");
    super.new(name);
  endfunction
  task body();
    for (int i = 0; i < n_singles; i++) begin
      bit last = (i == n_singles-1);
      `uvm_do_with(req, { req.reqtype == (last ? DMA_TRIG_LAST_SINGLE
                                               : DMA_TRIG_SINGLE);
                          req.pre_delay inside {[0:2]}; })
    end
  endtask
endclass : dma_trig_in_single_stream_seq

`endif // DMA_TRIG_IN_SINGLE_STREAM_SEQ_SV
