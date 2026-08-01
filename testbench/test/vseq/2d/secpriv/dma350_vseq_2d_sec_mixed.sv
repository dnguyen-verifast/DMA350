//==============================================================================
// dma350_vseq_2d_sec_mixed.sv
//   GROUP K - TRM 6.5.1.11-12, thuoc tinh KHAC NHAU giua nguon va dich tren 2D
//   Nguon: secure + privileged. Dich: non-secure + unprivileged.
//   Ky vong: arprot va awprot mang gia tri KHAC nhau va dung cho tung phia.
//==============================================================================
`ifndef DMA350_VSEQ_2D_SEC_MIXED_SV
`define DMA350_VSEQ_2D_SEC_MIXED_SV

class dma350_vseq_2d_sec_mixed extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_sec_mixed)

  function new(string name = "dma350_vseq_2d_sec_mixed");
    super.new(name);
    src_transcfg = 32'h000F_0800;
    des_transcfg = 32'h000F_0400;
    src_ysize = 4;
    des_ysize = 4;
    chk_src_drained = 1;
  endfunction

endclass : dma350_vseq_2d_sec_mixed

`endif // DMA350_VSEQ_2D_SEC_MIXED_SV
