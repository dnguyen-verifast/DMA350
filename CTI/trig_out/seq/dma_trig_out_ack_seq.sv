//============================================================================
// dma_trig_out_ack_seq.sv
// Responder: HW-ack every trig_out request with a small, varying delay.
// Runs forever (background responder).
//============================================================================
`ifndef DMA_TRIG_OUT_ACK_SEQ_SV
`define DMA_TRIG_OUT_ACK_SEQ_SV

class dma_trig_out_ack_seq extends dma_trig_out_base_seq;
  `uvm_object_utils(dma_trig_out_ack_seq)
  function new(string name = "dma_trig_out_ack_seq");
    super.new(name);
  endfunction
  task body();
    forever
      `uvm_do_with(req, { req.ack_passive == 0; req.ack_delay inside {[0:4]}; })
  endtask
endclass : dma_trig_out_ack_seq

`endif // DMA_TRIG_OUT_ACK_SEQ_SV
