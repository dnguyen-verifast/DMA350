//============================================================================
// dma_trig_vseqr.sv
// Virtual sequencer. Holds arrays of handles to every trig-in and trig-out
// agent sequencer (sized to NUM_TRIGGER_IN / NUM_TRIGGER_OUT) so a virtual
// sequence can drive requests on the in-ports and shape acks on the out-ports.
//============================================================================
`ifndef DMA_TRIG_VSEQR_SV
`define DMA_TRIG_VSEQR_SV

class dma_trig_vseqr extends uvm_sequencer;

  `uvm_component_utils(dma_trig_vseqr)

  dma_trig_in_sequencer   in_sqr[];    // one per trigger-in port  (requester)
  dma_trig_out_sequencer  out_sqr[];   // one per trigger-out port (responder)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : dma_trig_vseqr

`endif // DMA_TRIG_VSEQR_SV
