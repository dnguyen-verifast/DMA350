//==============================================================================
// dma350_vseq_trig_sw_src.sv
//   SOFTWARE TRIGGER (TRM 5.4.3) -- source trigger phat bang PHAN MEM qua
//   CH_CMD, khong dung chan ngoai.
//
//   TRIGTYPE = 2'b00 (SW): channel cho trigger nhung KHONG soi chan trig_in_*;
//   SW ghi CH_CMD.SRCSWTRIGINREQ (bit16) + SRCSWTRIGINTYPE ([18:17]) de phat.
//
//   Kich ban: enable channel -> xac nhan dang CHO -> SW ban lan luot cac
//   SINGLE roi LAST_SINGLE -> channel chay xong.
//==============================================================================
`ifndef DMA350_VSEQ_TRIG_SW_SRC_SV
`define DMA350_VSEQ_TRIG_SW_SRC_SV

class dma350_vseq_trig_sw_src extends dma350_vseq_trig_base;
  `uvm_object_utils(dma350_vseq_trig_sw_src)

  int unsigned n_single = 8;   // so SINGLE truoc khi ban LAST_SINGLE

  function new(string name = "dma350_vseq_trig_sw_src");
    super.new(name);
    ch          = 0;
    src_addr    = 32'h0003_0000;
    des_addr    = 32'h0003_4000;
    xsize       = 8;
    use_srctrig = 1;
    trig_type   = TT_SW;        // <-- software trigger
    trig_mode   = TM_CMD;
    trig_sel    = 0;            // khong y nghia voi TYPE=SW
  endfunction

  virtual task body();
    super.body();

    cfg_trig_ch();
    enable_ch(ch);

    // Channel phai dung cho trigger phan mem
    check_waiting_trigger("cho SW src-trigger");

    // Ban chuoi SINGLE roi ket bang LAST_SINGLE
    repeat (n_single) send_sw_srctrig(RQ_SINGLE);
    send_sw_srctrig(RQ_LAST_SINGLE);

    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_trig_sw_src

`endif // DMA350_VSEQ_TRIG_SW_SRC_SV
