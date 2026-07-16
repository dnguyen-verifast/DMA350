//============================================================================
// dma_trig_vseq_base.sv
// Base virtual sequence (runs on dma_trig_vseqr). Helpers bring up trig-out
// responders on every out-port and let concrete vseqs drive requester
// stimulus on every in-port.
//============================================================================
`ifndef DMA_TRIG_VSEQ_BASE_SV
`define DMA_TRIG_VSEQ_BASE_SV

typedef enum { DMA_TRIG_OUT_ACK, DMA_TRIG_OUT_STALL, DMA_TRIG_OUT_SWACK }
  dma_trig_out_resp_e;

class dma_trig_vseq_base extends uvm_sequence;

  `uvm_object_utils(dma_trig_vseq_base)
  `uvm_declare_p_sequencer(dma_trig_vseqr)

  function new(string name = "dma_trig_vseq_base");
    super.new(name);
  endfunction

  // Start a forever trig-out responder on every out-port (detached).
  task start_out_responders(input dma_trig_out_resp_e kind = DMA_TRIG_OUT_ACK);
    foreach (p_sequencer.out_sqr[i]) begin
      automatic int idx = i;
      fork
        begin
          case (kind)
            DMA_TRIG_OUT_STALL: begin
              dma_trig_out_stall_seq s = dma_trig_out_stall_seq::type_id::create(
                                           $sformatf("stall_%0d", idx));
              void'(s.randomize());
              s.start(p_sequencer.out_sqr[idx]);
            end
            DMA_TRIG_OUT_SWACK: begin
              dma_trig_out_swack_seq s = dma_trig_out_swack_seq::type_id::create(
                                           $sformatf("swack_%0d", idx));
              s.start(p_sequencer.out_sqr[idx]);
            end
            default: begin
              dma_trig_out_ack_seq s = dma_trig_out_ack_seq::type_id::create(
                                         $sformatf("ack_%0d", idx));
              s.start(p_sequencer.out_sqr[idx]);
            end
          endcase
        end
      join_none
    end
  endtask

endclass : dma_trig_vseq_base

`endif // DMA_TRIG_VSEQ_BASE_SV
