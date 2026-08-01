//==============================================================================
// dma350_vseq_2d_trig_pending.sv
//   GROUP F - TRM 5.4.1 'pending req on the trigger input port' tren 2D
//   Ban trigger TRUOC khi enable channel -> request nam cho o cong TI.
//   Ky vong: channel nhan ngay request dang treo sau khi enable, khong mat trigger.
//==============================================================================
`ifndef DMA350_VSEQ_2D_TRIG_PENDING_SV
`define DMA350_VSEQ_2D_TRIG_PENDING_SV

class dma350_vseq_2d_trig_pending extends dma350_vseq_2d_trig_base;
  `uvm_object_utils(dma350_vseq_2d_trig_pending)

  function new(string name = "dma350_vseq_2d_trig_pending");
    super.new(name);
    use_srctrig = 1;
    trig_type = TT_HW;
    trig_mode = TM_CMD;
    trig_sel = 8'd2;
  endfunction

  virtual task body();
    super.body();
    cfg_trig_ch();
    // trigger den TRUOC khi enable: phai duoc giu lai va phuc vu sau enable
    fork
      send_src_trig(RQ_BLOCK, 1);
      begin
        #200ns;
        enable_ch(ch);
      end
    join
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_trig_pending

`endif // DMA350_VSEQ_2D_TRIG_PENDING_SV
