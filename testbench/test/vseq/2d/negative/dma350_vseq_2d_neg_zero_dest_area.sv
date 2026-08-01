//==============================================================================
// dma350_vseq_2d_neg_zero_dest_area.sv
//   GROUP X - TRM 5.3.2.1 Table 5-3 Case 3 'Read only'
//   Vung dich rong (DESXSIZE = DESYSIZE = 0) nhung nguon hop le, khong dung stream.
//   TRM: nguon van duoc DOC nhung KHONG co ghi nao; wrap/fill bi bo qua.
//   Ky vong: chi co giao dich AR tren bus, tuyet doi khong co AW/W.
//==============================================================================
`ifndef DMA350_VSEQ_2D_NEG_ZERO_DEST_AREA_SV
`define DMA350_VSEQ_2D_NEG_ZERO_DEST_AREA_SV

class dma350_vseq_2d_neg_zero_dest_area extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_neg_zero_dest_area)

  function new(string name = "dma350_vseq_2d_neg_zero_dest_area");
    super.new(name);
    des_xsize = 0;
    des_ysize = 0;
    src_ysize = 4;
  endfunction

endclass : dma350_vseq_2d_neg_zero_dest_area

`endif // DMA350_VSEQ_2D_NEG_ZERO_DEST_AREA_SV
