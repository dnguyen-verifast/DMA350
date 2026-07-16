//============================================================================
// dma_trig_out_stall_seq.sv
// Responder: HW-ack with a VERY long delay to exercise the channel stalling
// before DONE (TRM 5.4.2: the command halts until the output trigger is
// acknowledged). Runs forever.
//============================================================================
`ifndef DMA_TRIG_OUT_STALL_SEQ_SV
`define DMA_TRIG_OUT_STALL_SEQ_SV

class dma_trig_out_stall_seq extends dma_trig_out_base_seq;
  `uvm_object_utils(dma_trig_out_stall_seq)
  rand int unsigned min_stall = 128;
  function new(string name = "dma_trig_out_stall_seq");
    super.new(name);
  endfunction
  task body();
    forever
      `uvm_do_with(req, { req.ack_passive == 0;
                          req.ack_delay inside {[min_stall : min_stall+64]}; })
  endtask
endclass : dma_trig_out_stall_seq

`endif // DMA_TRIG_OUT_STALL_SEQ_SV
