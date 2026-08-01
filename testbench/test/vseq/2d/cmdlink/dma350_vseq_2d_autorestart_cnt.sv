//==============================================================================
// dma350_vseq_2d_autorestart_cnt.sv
//   GROUP H - TRM 5.6.2 'Automatic restart of commands' tren lenh 2D
//   CH_AUTOCFG.CMDRESTARTCNT = 2 -> khung 2D duoc lap lai 3 lan.
//   Ky vong: dung so lan lap; dia chi tiep tuc chay toi (khong reload).
//==============================================================================
`ifndef DMA350_VSEQ_2D_AUTORESTART_CNT_SV
`define DMA350_VSEQ_2D_AUTORESTART_CNT_SV

class dma350_vseq_2d_autorestart_cnt extends dma350_vseq_2d_link_base;
  `uvm_object_utils(dma350_vseq_2d_autorestart_cnt)

  function new(string name = "dma350_vseq_2d_autorestart_cnt");
    super.new(name);
    mode = MODE_APB;
  endfunction

  virtual task cfg_apb_cmd0();
    super.cfg_apb_cmd0();
    apb_write(ch_addr(ch,O_AUTOCFG), 32'h0000_0002);   // CMDRESTARTCNT = 2
    apb_write(ch_addr(ch,O_LINKADDR), 32'h0);          // khong link, chi autorestart
  endtask

endclass : dma350_vseq_2d_autorestart_cnt

`endif // DMA350_VSEQ_2D_AUTORESTART_CNT_SV
