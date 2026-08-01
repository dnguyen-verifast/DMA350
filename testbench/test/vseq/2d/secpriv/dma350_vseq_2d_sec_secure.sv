//==============================================================================
// dma350_vseq_2d_sec_secure.sv
//   GROUP K - TRM 5.10 / 6.5.1.11-12, thuoc tinh truy cap tren lenh 2D
//   Secure + Unprivileged.
//   CH_SRCTRANSCFG/CH_DESTRANSCFG dat NONSECATTR=0 PRIVATTR=0.
//   Ky vong: AxPROT[1]=0 (secure), AxPROT[0]=0 cho MOI read/write cua ca khung 2D (khong chi dong dau).
//==============================================================================
`ifndef DMA350_VSEQ_2D_SEC_SECURE_SV
`define DMA350_VSEQ_2D_SEC_SECURE_SV

class dma350_vseq_2d_sec_secure extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_sec_secure)

  function new(string name = "dma350_vseq_2d_sec_secure");
    super.new(name);
    src_transcfg = 32'h000F_0000;
    des_transcfg = 32'h000F_0000;
    src_ysize = 4;
    des_ysize = 4;
    chk_src_drained = 1;
  endfunction

endclass : dma350_vseq_2d_sec_secure

`endif // DMA350_VSEQ_2D_SEC_SECURE_SV
