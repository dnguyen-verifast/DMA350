//==============================================================================
// dma350_vseq_secpriv_base.sv
//------------------------------------------------------------------------------
// Base cho bo test SECURITY / PRIVILEGE (thuoc tinh truy cap AXI) - CH0.
// Cac loai truy cap (bang anh):
//   Secure        : Secure accesses       (AxPROT[1] = 0)
//   Non-secure    : Non-secure accesses   (AxPROT[1] = 1)
//   Privileged    : Privileged accesses   (AxPROT[0] = 1)
//   Unprivileged  : Unprivileged accesses (AxPROT[0] = 0)
//
// AxPROT[1:0] duoc lay TRUC TIEP tu CH_SRCTRANSCFG/CH_DESTRANSCFG (RTL:
//   src_prot = {1'b0, srctranscfg[10]=NONSECATTR, srctranscfg[11]=PRIVATTR}).
// -> chi can dat 2 bit nay roi chay copy; scoreboard co san se doi chieu
//    arprot/awprot voi du doan -> khong sua scoreboard.
//
// CH_*TRANSCFG (reset 0x000F_0400): [19:16] MAXBURSTLEN=F, [11] PRIVATTR,
//   [10] NONSECATTR, [7:4] MEMATTRHI ...
//==============================================================================
`ifndef DMA350_VSEQ_SECPRIV_BASE_SV
`define DMA350_VSEQ_SECPRIV_BASE_SV

class dma350_vseq_secpriv_base extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_secpriv_base)

  int unsigned ch       = 0;
  bit [31:0]   src_addr = 32'h0005_0000;
  bit [31:0]   des_addr = 32'h0005_4000;
  int unsigned xsize    = 16;

  // ---- knob thuoc tinh truy cap ----
  bit nonsec = 1'b1;             // NONSECATTR (1 = non-secure, 0 = secure)
  bit priv   = 1'b0;             // PRIVATTR   (1 = privileged, 0 = unprivileged)

  function new(string name = "dma350_vseq_secpriv_base");
    super.new(name);
  endfunction

  // Ghep CH_*TRANSCFG: giu MAXBURSTLEN=F, MEMATTR mac dinh, set [11]=priv [10]=nonsec
  function bit [31:0] transcfg();
    bit [31:0] v = 32'h000F_0000;      // MAXBURSTLEN=0xF
    v[11] = priv;                       // PRIVATTR
    v[10] = nonsec;                     // NONSECATTR
    return v;
  endfunction

  virtual task body();
    super.body();

    // cau hinh copy 1D roi ghi de CH_*TRANSCFG voi thuoc tinh mong muon
    cfg_ch(.ch(ch), .src(src_addr), .des(des_addr), .xsize(xsize));
    apb_write(ch_addr(ch,O_SRCTRANSCFG), transcfg());
    apb_write(ch_addr(ch,O_DESTRANSCFG), transcfg());

    `uvm_info(get_type_name(), $sformatf(
      "CH%0d access: %s + %s -> SRC/DESTRANSCFG=0x%08h (AxPROT[1]=%0b NS, [0]=%0b PRIV)",
      ch, nonsec ? "Non-secure" : "Secure", priv ? "Privileged" : "Unprivileged",
      transcfg(), nonsec, priv), UVM_LOW)

    enable_ch(ch);
    wait_ch_done(ch);             // scoreboard doi chieu arprot/awprot trong luc chay
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_secpriv_base

`endif // DMA350_VSEQ_SECPRIV_BASE_SV
