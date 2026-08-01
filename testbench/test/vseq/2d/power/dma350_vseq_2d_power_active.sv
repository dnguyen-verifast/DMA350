//==============================================================================
// dma350_vseq_2d_power_active.sv
//   GROUP J - TRM 5.9.1, moc so sanh: khung 2D chay o trang thai ON day du
//   Khong co yeu cau P/Q-Channel nao trong luc chay.
//   Ky vong: khung 2D hoan thanh binh thuong (baseline cho cac test power khac).
//==============================================================================
`ifndef DMA350_VSEQ_2D_POWER_ACTIVE_SV
`define DMA350_VSEQ_2D_POWER_ACTIVE_SV

class dma350_vseq_2d_power_active extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_power_active)

  function new(string name = "dma350_vseq_2d_power_active");
    super.new(name);

  endfunction

endclass : dma350_vseq_2d_power_active

`endif // DMA350_VSEQ_2D_POWER_ACTIVE_SV
