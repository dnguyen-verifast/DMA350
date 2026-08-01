//==============================================================================
// dma350_vseq_2d_tmplt_des_1d.sv
//   GROUP E - TRM 5.3.3 'Templated transfers' (phia dich)
//   Template dich rai khoi lien tuc ra cac vi tri thua thot.
//   DESTMPLT = 0x0F (bit0 co dinh 1), DESTMPLTSIZE = 3.
//   Ky vong: cac byte bi mask bo qua o dich khong bi cham vao.
//==============================================================================
`ifndef DMA350_VSEQ_2D_TMPLT_DES_1D_SV
`define DMA350_VSEQ_2D_TMPLT_DES_1D_SV

class dma350_vseq_2d_tmplt_des_1d extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_tmplt_des_1d)

  function new(string name = "dma350_vseq_2d_tmplt_des_1d");
    super.new(name);
    src_ysize = 1;
    des_ysize = 1;
    src_xsize = 12;
    des_xsize = 24;
    destmpltsize = 5'd3;
    destmplt = 32'h0000_000F;
    xtype = XT_CONT;
  endfunction

endclass : dma350_vseq_2d_tmplt_des_1d

`endif // DMA350_VSEQ_2D_TMPLT_DES_1D_SV
