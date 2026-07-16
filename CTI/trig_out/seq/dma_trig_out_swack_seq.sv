//============================================================================
// dma_trig_out_swack_seq.sv
// Responder: SW-ack mode -- the VIP does NOT drive the hardware trig_out_ack,
// modelling the DMAC being acknowledged via its SWTRIGOUTACK register. Use
// only with a DUT (or SW-ack stub) that completes the request internally;
// otherwise the request stalls forever. Runs forever.
//============================================================================
`ifndef DMA_TRIG_OUT_SWACK_SEQ_SV
`define DMA_TRIG_OUT_SWACK_SEQ_SV

class dma_trig_out_swack_seq extends dma_trig_out_base_seq;
  `uvm_object_utils(dma_trig_out_swack_seq)
  function new(string name = "dma_trig_out_swack_seq");
    super.new(name);
  endfunction
  task body();
    forever
      `uvm_do_with(req, { req.ack_passive == 1; })
  endtask
endclass : dma_trig_out_swack_seq

`endif // DMA_TRIG_OUT_SWACK_SEQ_SV
