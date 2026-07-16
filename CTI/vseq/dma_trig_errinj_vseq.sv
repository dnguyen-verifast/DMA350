//============================================================================
// dma_trig_errinj_vseq.sv
// Error-injection: trig-in port 0 mutates req_type while req is held (illegal,
// TRM 5.4.1). Expect the interface assertion to fire. trig-out responders ACK.
//============================================================================
`ifndef DMA_TRIG_ERRINJ_VSEQ_SV
`define DMA_TRIG_ERRINJ_VSEQ_SV

class dma_trig_errinj_vseq extends dma_trig_vseq_base;
  `uvm_object_utils(dma_trig_errinj_vseq)
  function new(string name = "dma_trig_errinj_vseq");
    super.new(name);
  endfunction

  task body();
    dma_trig_in_errinj_seq s;
    start_out_responders(DMA_TRIG_OUT_ACK);
    if (p_sequencer.in_sqr.size() == 0)
      `uvm_fatal(get_type_name(), "no trig-in ports to inject on")
    s = dma_trig_in_errinj_seq::type_id::create("errinj");
    void'(s.randomize());
    s.start(p_sequencer.in_sqr[0]);
    #1us;
  endtask
endclass : dma_trig_errinj_vseq

`endif // DMA_TRIG_ERRINJ_VSEQ_SV
