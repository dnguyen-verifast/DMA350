//==============================================================================
// dma350_vseq_2d_trig_base.sv
//------------------------------------------------------------------------------
// Base cho cac test KET HOP 2D + TRIGGER (TRM 5.4 tren lenh 2D).
// Ke thua toan bo may trigger cua dma350_vseq_trig_base (cau hinh cong, gui
// HW/SW trigger, kiem tra cac bit WAIT) va CHI THEM phan hinh hoc 2D.
//
// CACH THEM 2D: goi super.cfg_trig_ch() (viet CH_YSIZE=0 va CH_CTRL khong co
// YTYPE), sau do ghi de CH_YSIZE / CH_YADDRSTRIDE va read-modify-write CH_CTRL
// de nhet YTYPE. CH_CTRL con ghi duoc vi channel chua ENABLE.
//
// RANG BUOC SPEC (TRM 5.9.2.2 + RTL cfgconfl_err):
//   flow-control trigger (TRIGINMODE bit1 = 1) + YSIZE > 1  = CONFIG ERROR.
//   -> cac test 2D DUONG o day chi dung COMMAND mode trigger. Truong hop
//      flow-control + 2D nam trong nhom test AM (dma350_vseq_2d_neg_flowctrl_*).
//==============================================================================
`ifndef DMA350_VSEQ_2D_TRIG_BASE_SV
`define DMA350_VSEQ_2D_TRIG_BASE_SV

class dma350_vseq_2d_trig_base extends dma350_vseq_trig_base;
  `uvm_object_utils(dma350_vseq_2d_trig_base)

  localparam bit [2:0] YT_DIS = 3'b000, YT_CONT = 3'b001,
                       YT_WRAP = 3'b010, YT_FILL = 3'b011;

  // ---- knob hinh hoc 2D (xsize/transize ke thua tu trig_base) ----
  int unsigned src_ysize   = 4;
  int unsigned des_ysize   = 4;
  int          src_ystride = 'h40;    // BYTE (xem ghi chu trong dma350_vseq_2d_base)
  int          des_ystride = 'h40;
  bit [2:0]    ytype       = YT_CONT;

  function new(string name = "dma350_vseq_2d_trig_base");
    super.new(name);
    xsize    = 8;                     // 8 element / dong
    src_addr = 32'h0007_0000;
    des_addr = 32'h0007_8000;
  endfunction

  //---------------------------------------------------------------------------
  // cfg 1D cua trig_base + phu them 2D
  //---------------------------------------------------------------------------
  virtual task cfg_trig_ch();
    bit [31:0] c;
    super.cfg_trig_ch();

    apb_write(ch_addr(ch,O_YSIZE),       {des_ysize[15:0], src_ysize[15:0]});
    apb_write(ch_addr(ch,O_YADDRSTRIDE), {des_ystride[15:0], src_ystride[15:0]});

    // nhet YTYPE vao CH_CTRL (read-modify-write, channel chua enable)
    apb_read(ch_addr(ch,O_CTRL), c);
    apb_write(ch_addr(ch,O_CTRL), c | ({29'b0, ytype} << 12));

    `uvm_info(get_type_name(), $sformatf(
      "CFG 2D+TRIG CH%0d: %0d element/dong, SRCYSIZE=%0d DESYSIZE=%0d stride s=%0d d=%0d YTYPE=%03b",
      ch, xsize, src_ysize, des_ysize, src_ystride, des_ystride, ytype), UVM_LOW)
  endtask

  virtual task body();
    super.body();
  endtask

endclass : dma350_vseq_2d_trig_base

`endif // DMA350_VSEQ_2D_TRIG_BASE_SV
