//==============================================================================
// dma350_vseq_2d_life_err_cfg.sv
//   GROUP I - TRM 5.6.3 'Configuration errors' tren lenh 2D
//   TRANSIZE lon hon do rong bus (RTL: regval_err) tren mot lenh 2D hop le.
//   Ky vong: STAT_ERR + ERRINFO.CFGERR/REGVALERR; KHONG co transfer nao tren bus.
//==============================================================================
`ifndef DMA350_VSEQ_2D_LIFE_ERR_CFG_SV
`define DMA350_VSEQ_2D_LIFE_ERR_CFG_SV

class dma350_vseq_2d_life_err_cfg extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_life_err_cfg)

  function new(string name = "dma350_vseq_2d_life_err_cfg");
    super.new(name);
    transize = 3'd7;
    expect_cfg_err = 1;
  endfunction

endclass : dma350_vseq_2d_life_err_cfg

`endif // DMA350_VSEQ_2D_LIFE_ERR_CFG_SV
