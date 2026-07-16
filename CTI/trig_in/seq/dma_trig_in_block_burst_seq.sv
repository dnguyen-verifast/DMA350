//============================================================================
// dma_trig_in_block_burst_seq.sv
// BLOCK burst terminated by LAST BLOCK (peripheral is flow-controller and
// knows the size). TRM Table 5-4.
//============================================================================
`ifndef DMA_TRIG_IN_BLOCK_BURST_SEQ_SV
`define DMA_TRIG_IN_BLOCK_BURST_SEQ_SV

class dma_trig_in_block_burst_seq extends dma_trig_in_base_seq;
  `uvm_object_utils(dma_trig_in_block_burst_seq)
  rand int unsigned n_blocks;
  constraint c_n { n_blocks inside {[1:8]}; }
  function new(string name = "dma_trig_in_block_burst_seq");
    super.new(name);
  endfunction
  task body();
    for (int i = 0; i < n_blocks; i++) begin
      bit last = (i == n_blocks-1);
      `uvm_do_with(req, { req.reqtype == (last ? DMA_TRIG_LAST_BLOCK
                                               : DMA_TRIG_BLOCK);
                          req.pre_delay inside {[0:3]}; })
    end
  endtask
endclass : dma_trig_in_block_burst_seq

`endif // DMA_TRIG_IN_BLOCK_BURST_SEQ_SV
