//==============================================================================
// dma350_vseq_2d_tmplt_src_1d.sv
//   GROUP E - TRM 5.3.3 'Templated transfers' (phia nguon)
//   Template nguon gom cac element thua thot thanh khoi lien tuc o dich.
//   SRCTMPLT = 0x69 (bit0 co dinh 1), SRCTMPLTSIZE = 7 -> chu ky 7 element.
//   TRM 5.9.2.2: templated KHONG duoc dung voi 2D -> chay o che do YSIZE = 1.
//   Ky vong: chi cac dia chi co bit mask = 1 duoc doc; transfer don (khong gop burst).
//==============================================================================
`ifndef DMA350_VSEQ_2D_TMPLT_SRC_1D_SV
`define DMA350_VSEQ_2D_TMPLT_SRC_1D_SV

class dma350_vseq_2d_tmplt_src_1d extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_tmplt_src_1d)

  function new(string name = "dma350_vseq_2d_tmplt_src_1d");
    super.new(name);
    src_ysize = 1;
    des_ysize = 1;
    src_xsize = 24;
    des_xsize = 12;
    srctmpltsize = 5'd7;
    srctmplt = 32'h0000_0069;
    xtype = XT_CONT;
  endfunction

endclass : dma350_vseq_2d_tmplt_src_1d

`endif // DMA350_VSEQ_2D_TMPLT_SRC_1D_SV
