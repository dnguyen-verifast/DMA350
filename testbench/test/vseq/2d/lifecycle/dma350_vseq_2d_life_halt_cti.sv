//==============================================================================
// dma350_vseq_2d_life_halt_cti.sv
//   GROUP I - TRM 5.9.3 'Halting and restarting the DMA with CTI' tren 2D
//   halt_req qua Cross Trigger Interface giua khung 2D roi restart_req.
//   Ky vong: CTI giu nguyen tien do X/Y; sau restart chay tiep den DONE.
//==============================================================================
`ifndef DMA350_VSEQ_2D_LIFE_HALT_CTI_SV
`define DMA350_VSEQ_2D_LIFE_HALT_CTI_SV

class dma350_vseq_2d_life_halt_cti extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_life_halt_cti)

  function new(string name = "dma350_vseq_2d_life_halt_cti");
    super.new(name);
    src_xsize = 32;
    des_xsize = 32;
    src_ysize = 16;
    des_ysize = 16;
    src_ystride = 'h100;
    des_ystride = 'h100;
  endfunction

  virtual task body();
    super.body();
    cfg_2d();
    enable_ch(ch);

    if (p_sequencer.sc_seqr_h == null)
      `uvm_error(get_type_name(), "sc_seqr_h = null (SC agent passive?) - khong CTI duoc")
    else begin
      dma350_sc_cti_seq cti = dma350_sc_cti_seq::type_id::create("cti_halt_2d");
      if (!cti.randomize() with { halt_len == 40; auto_restart == 1'b1; })
        `uvm_error(get_type_name(), "randomize dma350_sc_cti_seq that bai")
      cti.start(p_sequencer.sc_seqr_h);
    end

    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_life_halt_cti

`endif // DMA350_VSEQ_2D_LIFE_HALT_CTI_SV
