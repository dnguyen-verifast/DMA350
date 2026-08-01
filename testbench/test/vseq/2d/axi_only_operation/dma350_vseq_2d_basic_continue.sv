//==============================================================================
// dma350_vseq_2d_basic_continue.sv
//   GROUP A - TRM 5.3.1 'Transfer type 2D'
//   Baseline: khoi 2D 8 element x 4 dong, XTYPE=continue YTYPE=continue.
//   Nguon va dich cung hinh dang, stride 0x40 (dong 32B + gap 32B).
//   Ky vong: dung hinh hoc khoi + du lieu; SRCXSIZE/DESXSIZE ve 0; STAT_DONE.
//==============================================================================
`ifndef DMA350_VSEQ_2D_BASIC_CONTINUE_SV
`define DMA350_VSEQ_2D_BASIC_CONTINUE_SV

class dma350_vseq_2d_basic_continue extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_basic_continue)

  function new(string name = "dma350_vseq_2d_basic_continue");
    super.new(name);
    chk_src_drained = 1;
    chk_des_drained = 1;
  endfunction

endclass : dma350_vseq_2d_basic_continue

`endif // DMA350_VSEQ_2D_BASIC_CONTINUE_SV
