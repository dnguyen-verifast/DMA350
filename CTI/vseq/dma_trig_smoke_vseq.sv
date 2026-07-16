//============================================================================
// dma_trig_smoke_vseq.sv
// Smoke: trig-out responders ACK; each trig-in port issues a few SINGLE reqs.
//============================================================================
`ifndef DMA_TRIG_SMOKE_VSEQ_SV
`define DMA_TRIG_SMOKE_VSEQ_SV

class dma_trig_smoke_vseq extends dma_trig_vseq_base;
  `uvm_object_utils(dma_trig_smoke_vseq)
  function new(string name = "dma_trig_smoke_vseq");
    super.new(name);
  endfunction

  task body();
    start_out_responders(DMA_TRIG_OUT_ACK);
    fork : in_ports
      begin
        foreach (p_sequencer.in_sqr[i]) begin
          automatic int idx = i;
          fork
            begin
              dma_trig_in_smoke_seq s =
                dma_trig_in_smoke_seq::type_id::create($sformatf("smoke_%0d", idx));
              void'(s.randomize());
              s.start(p_sequencer.in_sqr[idx]);
            end
          join_none
        end
        wait fork;
      end
    join
    #1us;
  endtask
endclass : dma_trig_smoke_vseq

`endif // DMA_TRIG_SMOKE_VSEQ_SV
