//==============================================================================
// dma350_vseq_2d_link_base.sv
//------------------------------------------------------------------------------
// Base cho cac test KET HOP 2D + COMMAND LINKING / AUTOBOOT / AUTORESTART
// (TRM 5.7). Ke thua dma350_vseq_cmdlink_base (bo xay descriptor + nap backdoor
// vao cmdlink_mem + wait_chain_done) va them phan hinh hoc 2D.
//
// Descriptor 2D dung them cac bit HEADER (Table 5-12):
//   HDR_YADDRSTRIDE = 13 , HDR_FILLVAL = 14 , HDR_YSIZE = 15
// Cac hang so nay lay tu dma350_cmdlink_mem_pkg (da import trong test pkg).
//
// LUU Y thu tu word trong descriptor: payload xep theo bit HEADER TANG DAN
// (LSB -> MSB). cmd_set() cua base da lo viec do -> goi theo thu tu nao cung duoc.
//==============================================================================
`ifndef DMA350_VSEQ_2D_LINK_BASE_SV
`define DMA350_VSEQ_2D_LINK_BASE_SV

class dma350_vseq_2d_link_base extends dma350_vseq_cmdlink_base;
  `uvm_object_utils(dma350_vseq_2d_link_base)

  localparam bit [2:0] XT_CONT = 3'b001, XT_WRAP = 3'b010, XT_FILL = 3'b011;
  localparam bit [2:0] YT_DIS  = 3'b000, YT_CONT = 3'b001,
                       YT_WRAP = 3'b010, YT_FILL = 3'b011;

  // ---- knob 2D cho LENH #0 (cau hinh qua APB o MODE_APB) ----
  int unsigned src_ysize   = 4;
  int unsigned des_ysize   = 4;
  int          src_ystride = 'h40;
  int          des_ystride = 'h40;
  bit [2:0]    ytype       = YT_CONT;
  bit [2:0]    xtype       = XT_CONT;

  function new(string name = "dma350_vseq_2d_link_base");
    super.new(name);
    xsize = 8;                          // element / dong
  endfunction

  //---------------------------------------------------------------------------
  // CH_CTRL cho lenh 2D (dung trong descriptor lan cfg APB)
  //---------------------------------------------------------------------------
  function bit [31:0] ctrl_2d(bit [2:0] tsize = 3'd2,
                              bit [2:0] xt = XT_CONT,
                              bit [2:0] yt = YT_CONT);
    return (32'h1 << 21) | ({29'b0, yt} << 12) | ({29'b0, xt} << 9) | {29'b0, tsize};
  endfunction

  // Ghep gia tri CH_YSIZE / CH_YADDRSTRIDE cho descriptor
  function bit [31:0] ysize_word(int unsigned sy, int unsigned dy);
    return {dy[15:0], sy[15:0]};
  endfunction
  function bit [31:0] ystride_word(int ss, int ds);
    return {ds[15:0], ss[15:0]};
  endfunction

  //---------------------------------------------------------------------------
  // Lenh #0 qua APB nhung la lenh 2D
  //---------------------------------------------------------------------------
  virtual task cfg_apb_cmd0();
    apb_write(ch_addr(ch,O_SRCADDR),     src_addr);
    apb_write(ch_addr(ch,O_SRCADDRHI),   32'h0);
    apb_write(ch_addr(ch,O_DESADDR),     des_addr);
    apb_write(ch_addr(ch,O_DESADDRHI),   32'h0);
    apb_write(ch_addr(ch,O_XSIZE),       {xsize[15:0], xsize[15:0]});
    apb_write(ch_addr(ch,O_XADDRINC),    32'h0001_0001);
    apb_write(ch_addr(ch,O_YSIZE),       ysize_word(src_ysize, des_ysize));
    apb_write(ch_addr(ch,O_YADDRSTRIDE), ystride_word(src_ystride, des_ystride));
    apb_write(ch_addr(ch,O_SRCTRANSCFG), TRANSCFG_DEFAULT);
    apb_write(ch_addr(ch,O_DESTRANSCFG), TRANSCFG_DEFAULT);
    apb_write(ch_addr(ch,O_CTRL),        ctrl_2d(transize, xtype, ytype));
    apb_write(ch_addr(ch,O_INTREN),      32'h0000_0003);
    apb_write(ch_addr(ch,O_LINKADDR),    cmd_addr(0) | LINKADDREN);

    `uvm_info(get_type_name(), $sformatf(
      "CFG 2D CMD0 (APB) CH%0d: %0d element/dong x %0d dong, stride s=%0d d=%0d -> link 0x%08h",
      ch, xsize, src_ysize, src_ystride, des_ystride, cmd_addr(0)), UVM_LOW)
  endtask

  //---------------------------------------------------------------------------
  // Chuoi mac dinh: 2 lenh 2D noi tiep (doi kich thuoc dong / so dong).
  //---------------------------------------------------------------------------
  virtual function void program_descriptors();
    cmd_slot(0); cmd_begin(0);
      cmd_set(HDR_CTRL,        ctrl_2d(transize, xtype, ytype));
      cmd_set(HDR_SRCADDR,     src_addr + 32'h1000);
      cmd_set(HDR_DESADDR,     des_addr + 32'h1000);
      cmd_set(HDR_XSIZE,       {16'd4, 16'd4});
      cmd_set(HDR_YADDRSTRIDE, ystride_word('h20, 'h20));
      cmd_set(HDR_YSIZE,       ysize_word(2, 2));
      cmd_link(1);
    cmd_emit();

    cmd_slot(1); cmd_begin(0);
      cmd_set(HDR_DESADDR,     des_addr + 32'h2000);
      cmd_set(HDR_YSIZE,       ysize_word(3, 3));
      cmd_end();
    cmd_emit();
  endfunction

endclass : dma350_vseq_2d_link_base

`endif // DMA350_VSEQ_2D_LINK_BASE_SV
