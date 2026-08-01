//==============================================================================
// dma350_vseq_2d_autorestart_reload.sv
//   GROUP H - TRM 5.6.2 + CH_CTRL.REGRELOADTYPE tren lenh 2D
//   Autorestart co REGRELOADTYPE = 111 -> nap lai ca dia chi va kich thuoc moi vong.
//   Ky vong: moi vong lap ghi vao DUNG vung dich ban dau (khung 2D lap lai tai cho).
//==============================================================================
`ifndef DMA350_VSEQ_2D_AUTORESTART_RELOAD_SV
`define DMA350_VSEQ_2D_AUTORESTART_RELOAD_SV

class dma350_vseq_2d_autorestart_reload extends dma350_vseq_2d_link_base;
  `uvm_object_utils(dma350_vseq_2d_autorestart_reload)

  function new(string name = "dma350_vseq_2d_autorestart_reload");
    super.new(name);
    mode = MODE_APB;
  endfunction

  virtual task cfg_apb_cmd0();
    super.cfg_apb_cmd0();
    // REGRELOADTYPE = 3'b111 (nap lai src+des addr va cac size)
    apb_write(ch_addr(ch,O_CTRL),
              ctrl_2d(transize, xtype, ytype) | (32'h7 << 18));
    apb_write(ch_addr(ch,O_AUTOCFG),  32'h0000_0002);
    apb_write(ch_addr(ch,O_LINKADDR), 32'h0);
  endtask

endclass : dma350_vseq_2d_autorestart_reload

`endif // DMA350_VSEQ_2D_AUTORESTART_RELOAD_SV
