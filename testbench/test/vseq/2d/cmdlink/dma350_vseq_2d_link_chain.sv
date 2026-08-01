//==============================================================================
// dma350_vseq_2d_link_chain.sv
//   GROUP H - TRM 5.7.1 'Command structure', chuoi nhieu lenh 2D
//   Lenh #0 cau hinh qua APB (2D), link toi 2 descriptor 2D nap qua AXI.
//   Ky vong: moi lenh nap dung header bitmap va chay dung hinh hoc 2D moi.
//==============================================================================
`ifndef DMA350_VSEQ_2D_LINK_CHAIN_SV
`define DMA350_VSEQ_2D_LINK_CHAIN_SV

class dma350_vseq_2d_link_chain extends dma350_vseq_2d_link_base;
  `uvm_object_utils(dma350_vseq_2d_link_chain)

  function new(string name = "dma350_vseq_2d_link_chain");
    super.new(name);
    mode = MODE_APB;
  endfunction

endclass : dma350_vseq_2d_link_chain

`endif // DMA350_VSEQ_2D_LINK_CHAIN_SV
