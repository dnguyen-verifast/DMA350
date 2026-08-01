//==============================================================================
// dma350_vseq_2d_power_pchannel.sv
//   GROUP J - TRM 5.9.1.1, yeu cau P-Channel TRONG LUC khung 2D dang chay
//   TRM: khi DMAC dang active thi yeu cau quiescence bi TU CHOI (pdeny), lenh chay tiep.
//   Ky vong: khung 2D khong mat du lieu, khong dut o ranh gioi dong.
//==============================================================================
`ifndef DMA350_VSEQ_2D_POWER_PCHANNEL_SV
`define DMA350_VSEQ_2D_POWER_PCHANNEL_SV

class dma350_vseq_2d_power_pchannel extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_power_pchannel)

  function new(string name = "dma350_vseq_2d_power_pchannel");
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

    fork
      begin
        crlp_pch_seq p = crlp_pch_seq::type_id::create("pch_mid");
        if (!p.randomize() with { target_state == 4'h4; })  // xin RET giua chung
          `uvm_error(get_type_name(), "randomize pch giua khung 2D that bai")
        p.start(p_sequencer.crlp_seqr_h);
      end
    join_none

    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_power_pchannel

`endif // DMA350_VSEQ_2D_POWER_PCHANNEL_SV
