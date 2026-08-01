//==============================================================================
// dma350_vseq_2d_sec_priv.sv
//   GROUP K - TRM 5.10 / 6.5.1.11-12, thuoc tinh truy cap tren lenh 2D
//   Non-secure + Privileged.
//   CH_SRCTRANSCFG/CH_DESTRANSCFG dat NONSECATTR=1 PRIVATTR=1.
//   Ky vong: AxPROT[1]=1, AxPROT[0]=1 (privileged) cho MOI read/write cua ca khung 2D (khong chi dong dau).
//==============================================================================
`ifndef DMA350_VSEQ_2D_SEC_PRIV_SV
`define DMA350_VSEQ_2D_SEC_PRIV_SV

class dma350_vseq_2d_sec_priv extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_sec_priv)

  function new(string name = "dma350_vseq_2d_sec_priv");
    super.new(name);
    src_transcfg = 32'h000F_0C00;
    des_transcfg = 32'h000F_0C00;
    src_ysize = 4;
    des_ysize = 4;
    chk_src_drained = 1;
  endfunction

endclass : dma350_vseq_2d_sec_priv

`endif // DMA350_VSEQ_2D_SEC_PRIV_SV
