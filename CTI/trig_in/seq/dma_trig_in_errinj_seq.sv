//============================================================================
// dma_trig_in_errinj_seq.sv
// Error-injection: drive a request that mutates req_type WHILE req is held
// (illegal per TRM 5.4.1 -- req_type must stay stable). Used to prove the
// interface assertion / scoreboard catches the violation.
//============================================================================
`ifndef DMA_TRIG_IN_ERRINJ_SEQ_SV
`define DMA_TRIG_IN_ERRINJ_SEQ_SV

class dma_trig_in_errinj_seq extends dma_trig_in_base_seq;
  `uvm_object_utils(dma_trig_in_errinj_seq)
  function new(string name = "dma_trig_in_errinj_seq");
    super.new(name);
  endfunction
  task body();
    `uvm_do_with(req, { req.reqtype            == DMA_TRIG_BLOCK;
                        req.err_reqtype_change == 1'b1;
                        req.err_reqtype_alt    == DMA_TRIG_SINGLE;
                        req.pre_delay inside {[0:2]}; })
  endtask
endclass : dma_trig_in_errinj_seq

`endif // DMA_TRIG_IN_ERRINJ_SEQ_SV
