//==============================================================================
// dma350_cmdlink_mem.sv - Anh bo nho (memory image) chua COMMAND LINK cho DMA-350
//------------------------------------------------------------------------------
// Tham chieu: Arm CoreLink DMA-350 TRM (102482_0000_04_en) muc 5.7 "Command linking"
//   - 5.7.1 Command structure / Table 5-12 Command link header
//   - Table 5-13/5-14/5-15 vi du 3 descriptor lien tiep (32-bit addressing)
//
// NOI DUNG:
//   Descriptor duoc luu trong system memory duoi dang mang lien tuc cac tu 32-bit.
//   Tu dau tien = HEADER (bitmap cho biet thanh ghi nao can update). Cac tu tiep
//   theo la GIA TRI cac thanh ghi duoc chon, xep theo dung thu tu bit LSB -> MSB
//   cua header.
//
//   Chuoi ket thuc khi mot command KHONG set LINKADDREN (bit[0] cua CH_LINKADDR).
//
// CACH DUNG (vi du trong sequence/test):
//   import dma350_cmdlink_mem_pkg::*;
//   // 1) nap anh bo nho vao AXI slave memory (byte-wise, little endian)
//   for (int i = 0; i < CMDLINK_IMAGE_SIZE; i++) begin
//     for (int b = 0; b < 4; b++)
//       slave_mem.mem_write(CMDLINK_BASE + i*4 + b, cmdlink_byte(i*4 + b));
//   end
//   // 2) cau hinh channel: CH_LINKADDR = CMD0_ADDR | LINKADDREN(=1'b1)
//==============================================================================
`ifndef DMA350_CMDLINK_MEM_SV
`define DMA350_CMDLINK_MEM_SV

package dma350_cmdlink_mem_pkg;

  //--------------------------------------------------------------------------
  // Table 5-12: Command link header - vi tri bit cho tung thanh ghi
  //--------------------------------------------------------------------------
  localparam int HDR_REGCLEAR      = 0;   // xoa toan bo reg truoc khi update
  // bit 1 : Reserved, phai = 0
  localparam int HDR_INTREN        = 2;
  localparam int HDR_CTRL          = 3;
  localparam int HDR_SRCADDR       = 4;
  localparam int HDR_SRCADDRHI     = 5;
  localparam int HDR_DESADDR       = 6;
  localparam int HDR_DESADDRHI     = 7;
  localparam int HDR_XSIZE         = 8;
  localparam int HDR_XSIZEHI       = 9;
  localparam int HDR_SRCTRANSCFG   = 10;
  localparam int HDR_DESTRANSCFG   = 11;
  localparam int HDR_XADDRINC      = 12;
  localparam int HDR_YADDRSTRIDE   = 13;
  localparam int HDR_FILLVAL       = 14;
  localparam int HDR_YSIZE         = 15;
  localparam int HDR_TMPLTCFG      = 16;
  localparam int HDR_SRCTMPLT      = 17;
  localparam int HDR_DESTMPLT      = 18;
  localparam int HDR_SRCTRIGINCFG  = 19;
  localparam int HDR_DESTRIGINCFG  = 20;
  localparam int HDR_TRIGOUTCFG    = 21;
  localparam int HDR_GPOEN0        = 22;
  // bit 23: Reserved, phai = 0
  localparam int HDR_GPOVAL0       = 24;
  // bit 25: Reserved, phai = 0
  localparam int HDR_STREAMINTCFG  = 26;
  // bit 27: Reserved, phai = 0
  localparam int HDR_LINKATTR      = 28;
  localparam int HDR_AUTOCFG       = 29;
  localparam int HDR_LINKADDR      = 30;
  localparam int HDR_LINKADDRHI    = 31;

  // CH_LINKADDR[0] = LINKADDREN
  localparam bit [31:0] LINKADDREN = 32'h0000_0001;

  //--------------------------------------------------------------------------
  // Dia chi goc cua vung command link trong system memory.
  // Doi lai neu memory map cua TB khac.
  //--------------------------------------------------------------------------
  localparam longint unsigned CMDLINK_BASE = 64'h0000_2000;

  // Dia chi vung du lieu dung cho cac lenh copy trong vi du
  localparam bit [31:0] SRC_BUF_0 = 32'h0001_0000;
  localparam bit [31:0] DES_BUF_0 = 32'h0002_0000;
  localparam bit [31:0] SRC_BUF_1 = 32'h0001_1000;
  localparam bit [31:0] DES_BUF_1 = 32'h0002_1000;
  localparam bit [31:0] DES_BUF_2 = 32'h0002_2000;

  //--------------------------------------------------------------------------
  // Offset cua tung descriptor trong anh bo nho (byte offset tinh tu CMDLINK_BASE)
  //   CMD0: header + 8 word  = 9  word = 0x24 byte -> ke tiep 0x024
  //   CMD1: header + 5 word  = 6  word = 0x18 byte -> ke tiep 0x03C
  //   CMD2: header + 3 word  = 4  word = 0x10 byte
  //--------------------------------------------------------------------------
  localparam bit [31:0] CMD0_OFFSET = 32'h0000_0000;
  localparam bit [31:0] CMD1_OFFSET = 32'h0000_0024;
  localparam bit [31:0] CMD2_OFFSET = 32'h0000_003C;

  localparam bit [31:0] CMD0_ADDR = CMDLINK_BASE[31:0] + CMD0_OFFSET;
  localparam bit [31:0] CMD1_ADDR = CMDLINK_BASE[31:0] + CMD1_OFFSET;
  localparam bit [31:0] CMD2_ADDR = CMDLINK_BASE[31:0] + CMD2_OFFSET;

  //--------------------------------------------------------------------------
  // HEADER cua tung command
  //--------------------------------------------------------------------------
  // CMD0 = 0x4000_0D5D
  //   REGCLEAR | INTREN | CTRL | SRCADDR | DESADDR | XSIZE |
  //   SRCTRANSCFG | DESTRANSCFG | LINKADDR
  localparam bit [31:0] CMD0_HEADER = (1 << HDR_REGCLEAR)
                                    | (1 << HDR_INTREN)
                                    | (1 << HDR_CTRL)
                                    | (1 << HDR_SRCADDR)
                                    | (1 << HDR_DESADDR)
                                    | (1 << HDR_XSIZE)
                                    | (1 << HDR_SRCTRANSCFG)
                                    | (1 << HDR_DESTRANSCFG)
                                    | (1 << HDR_LINKADDR);

  // CMD1 = 0x4000_0158 : CTRL | SRCADDR | DESADDR | XSIZE | LINKADDR
  localparam bit [31:0] CMD1_HEADER = (1 << HDR_CTRL)
                                    | (1 << HDR_SRCADDR)
                                    | (1 << HDR_DESADDR)
                                    | (1 << HDR_XSIZE)
                                    | (1 << HDR_LINKADDR);

  // CMD2 = 0x4000_0140 : DESADDR | XSIZE | LINKADDR (LINKADDR = 0 -> ket thuc chuoi)
  localparam bit [31:0] CMD2_HEADER = (1 << HDR_DESADDR)
                                    | (1 << HDR_XSIZE)
                                    | (1 << HDR_LINKADDR);

  //--------------------------------------------------------------------------
  // Gia tri CH_CTRL dung trong vi du
  //   [11:9] XTYPE = 001 (continue), [7:4] CHPRIO = 0, [2:0] TRANSIZE
  //--------------------------------------------------------------------------
  localparam bit [31:0] CTRL_1D_WORD = (3'b001 << 9) | 3'd2; // 1D, TRANSIZE=32-bit
  localparam bit [31:0] CTRL_1D_BYTE = (3'b001 << 9) | 3'd0; // 1D, TRANSIZE=8-bit

  // CH_SRCTRANSCFG / CH_DESTRANSCFG: MAXBURSTLEN=0xF, NONSECATTR=1 (gia tri reset)
  localparam bit [31:0] TRANSCFG_DEFAULT = 32'h000F_0400;

  //--------------------------------------------------------------------------
  // ANH BO NHO: mang 32-bit lien tuc, index i <-> dia chi CMDLINK_BASE + i*4
  //--------------------------------------------------------------------------
  localparam int CMDLINK_IMAGE_SIZE = 19; // 9 + 6 + 4 word

  const bit [31:0] cmdlink_image [CMDLINK_IMAGE_SIZE] = '{
    //---------------- CMD0 @ CMDLINK_BASE + 0x000 -------------------------
    // Set day du 1 lenh copy 1D 32-bit, REGCLEAR xoa het cau hinh cu.
    /* 0x000 */ CMD0_HEADER,          // HEADER   = 0x4000_0D5D
    /* 0x004 */ 32'h0000_0001,        // INTREN   : INTREN_DONE = 1
    /* 0x008 */ CTRL_1D_WORD,         // CTRL     : 1D continue, TRANSIZE = word
    /* 0x00C */ SRC_BUF_0,            // SRCADDR
    /* 0x010 */ DES_BUF_0,            // DESADDR
    /* 0x014 */ 32'h0010_0010,        // XSIZE    : DESXSIZE=16, SRCXSIZE=16
    /* 0x018 */ TRANSCFG_DEFAULT,     // SRCTRANSCFG
    /* 0x01C */ TRANSCFG_DEFAULT,     // DESTRANSCFG
    /* 0x020 */ CMD1_ADDR | LINKADDREN, // LINKADDR -> CMD1, LINKADDREN = 1

    //---------------- CMD1 @ CMDLINK_BASE + 0x024 -------------------------
    // Chi doi CTRL / dia chi / XSIZE, cac thanh ghi khac giu nguyen tu CMD0.
    /* 0x024 */ CMD1_HEADER,          // HEADER   = 0x4000_0158
    /* 0x028 */ CTRL_1D_BYTE,         // CTRL     : 1D continue, TRANSIZE = byte
    /* 0x02C */ SRC_BUF_1,            // SRCADDR
    /* 0x030 */ DES_BUF_1,            // DESADDR
    /* 0x034 */ 32'h0020_0020,        // XSIZE    : DESXSIZE=32, SRCXSIZE=32
    /* 0x038 */ CMD2_ADDR | LINKADDREN, // LINKADDR -> CMD2, LINKADDREN = 1

    //---------------- CMD2 @ CMDLINK_BASE + 0x03C -------------------------
    // Lenh cuoi: chi doi DESADDR + XSIZE, LINKADDR = 0 => LINKADDREN = 0 => ket thuc.
    /* 0x03C */ CMD2_HEADER,          // HEADER   = 0x4000_0140
    /* 0x040 */ DES_BUF_2,            // DESADDR
    /* 0x044 */ 32'h0008_0008,        // XSIZE    : DESXSIZE=8, SRCXSIZE=8
    /* 0x048 */ 32'h0000_0000         // LINKADDR = 0 -> ket thuc command chain
  };

  //--------------------------------------------------------------------------
  // Helper: lay 1 byte cua anh bo nho (little endian) theo byte offset.
  //   byte_offset tinh tu CMDLINK_BASE.
  //--------------------------------------------------------------------------
  function automatic bit [7:0] cmdlink_byte(int unsigned byte_offset);
    int unsigned widx = byte_offset >> 2;
    int unsigned bsel = byte_offset[1:0];
    if (widx >= CMDLINK_IMAGE_SIZE) return 8'h00;
    return cmdlink_image[widx][8*bsel +: 8];
  endfunction

  //--------------------------------------------------------------------------
  // Helper: gia tri ghi vao CH_LINKADDR de khoi dong chuoi tu CMD0.
  //--------------------------------------------------------------------------
  function automatic bit [31:0] cmdlink_start_linkaddr();
    return CMD0_ADDR | LINKADDREN;
  endfunction

  //==========================================================================
  // BO NHO DESCRIPTOR NAP TAY (dong) - dung cho command-link / autoboot
  //--------------------------------------------------------------------------
  // Khac voi anh CONST cmdlink_image (co dinh 3 lenh, dung lam vi du), bo nho
  // nay la associative-array BYTE dia-chi-hoa TUYET DOI, cho phep tung vseq nap
  // descriptor RIENG (header khac nhau) truoc khi chay.
  //
  // Bien package -> static, dung chung toan sim: vseq NAP (cmdlink_mem_write_*),
  // hook trong axi5_slave_driver_proxy DOC (cmdlink_mem_has/cmdlink_mem_get) khi
  // DUT fetch descriptor (arcmdlink=1). Guard theo dia chi da nap -> khong anh
  // huong cac test khong dung command-link.
  //==========================================================================
  bit [7:0] cmdlink_mem [longint unsigned];

  // Xoa toan bo (goi dau moi test de tranh ron descriptor cu).
  function automatic void cmdlink_mem_clear();
    cmdlink_mem.delete();
  endfunction

  // Nap 1 byte / 1 word 32-bit (little endian) vao dia chi TUYET DOI.
  function automatic void cmdlink_mem_write_byte(longint unsigned addr, bit [7:0] data);
    cmdlink_mem[addr] = data;
  endfunction

  function automatic void cmdlink_mem_write_word(longint unsigned addr, bit [31:0] data);
    for (int b = 0; b < 4; b++)
      cmdlink_mem[addr + b] = data[8*b +: 8];
  endfunction

  // Dia chi da nap chua? / lay byte (0x00 neu chua nap).
  function automatic bit cmdlink_mem_has(longint unsigned addr);
    return cmdlink_mem.exists(addr);
  endfunction

  function automatic bit [7:0] cmdlink_mem_get(longint unsigned addr);
    return cmdlink_mem.exists(addr) ? cmdlink_mem[addr] : 8'h00;
  endfunction

  // Nap SAN anh vi du 3-lenh (cmdlink_image) vao bo nho dong tai CMDLINK_BASE.
  // Dung cho test muon xai truc tiep vi du co san + cmdlink_start_linkaddr().
  function automatic void cmdlink_mem_load_example();
    for (int i = 0; i < CMDLINK_IMAGE_SIZE; i++)
      cmdlink_mem_write_word(CMDLINK_BASE[31:0] + i*4, cmdlink_image[i]);
  endfunction

endpackage : dma350_cmdlink_mem_pkg

`endif // DMA350_CMDLINK_MEM_SV
