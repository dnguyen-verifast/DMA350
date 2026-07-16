//============================================================================
// dma_trig_in_traffic_seq.sv
// Alternating BLOCK bursts and SINGLE streams to exercise the full reqtype
// space (used by distribute / flow-control vseqs).
//============================================================================
`ifndef DMA_TRIG_IN_TRAFFIC_SEQ_SV
`define DMA_TRIG_IN_TRAFFIC_SEQ_SV

class dma_trig_in_traffic_seq extends dma_trig_in_base_seq;
  `uvm_object_utils(dma_trig_in_traffic_seq)
  rand int unsigned rounds = 4;
  constraint c_r { rounds inside {[1:8]}; }
  function new(string name = "dma_trig_in_traffic_seq");
    super.new(name);
  endfunction
  task body();
    for (int r = 0; r < rounds; r++) begin
      if (r % 2 == 0) begin
        dma_trig_in_block_burst_seq s =
          dma_trig_in_block_burst_seq::type_id::create($sformatf("blk_%0d", r));
        if (!s.randomize()) `uvm_error(get_type_name(), "block randomize failed")
        s.start(m_sequencer);
      end else begin
        dma_trig_in_single_stream_seq s =
          dma_trig_in_single_stream_seq::type_id::create($sformatf("sgl_%0d", r));
        if (!s.randomize()) `uvm_error(get_type_name(), "stream randomize failed")
        s.start(m_sequencer);
      end
    end
  endtask
endclass : dma_trig_in_traffic_seq

`endif // DMA_TRIG_IN_TRAFFIC_SEQ_SV
