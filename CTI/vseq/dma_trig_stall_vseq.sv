//============================================================================
// dma_trig_stall_vseq.sv
// Channel-stall scenario: trig-out responders ACK with a VERY long delay so
// the DMA channel stalls before DONE (TRM 5.4.2); trig-in ports run traffic.
//============================================================================
`ifndef DMA_TRIG_STALL_VSEQ_SV
`define DMA_TRIG_STALL_VSEQ_SV

class dma_trig_stall_vseq extends dma_trig_vseq_base;
  `uvm_object_utils(dma_trig_stall_vseq)
  rand int unsigned rounds = 3;
  constraint c_r { rounds inside {[1:4]}; }
  function new(string name = "dma_trig_stall_vseq");
    super.new(name);
  endfunction

  task body();
    start_out_responders(DMA_TRIG_OUT_STALL);   // long ack delay
    fork : in_ports
      begin
        foreach (p_sequencer.in_sqr[i]) begin
          automatic int idx = i;
          fork
            begin
              dma_trig_in_traffic_seq s =
                dma_trig_in_traffic_seq::type_id::create($sformatf("traf_%0d", idx));
              if (!s.randomize() with { rounds == local::rounds; })
                `uvm_error(get_type_name(), "traffic randomize failed")
              s.start(p_sequencer.in_sqr[idx]);
            end
          join_none
        end
        wait fork;
      end
    join
    #2us;
  endtask
endclass : dma_trig_stall_vseq

`endif // DMA_TRIG_STALL_VSEQ_SV
