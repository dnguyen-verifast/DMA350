//==============================================================================
// dma350_vseq_lifecycle_enabled.sv
//   "Enabled (running) - Channel executing a command"
//   - Enable mot copy dai; kiem tra channel DANG chay (ENABLECMD=1, chua DONE);
//     doi lenh xong -> ve Disabled.
//==============================================================================
`ifndef DMA350_VSEQ_LIFECYCLE_ENABLED_SV
`define DMA350_VSEQ_LIFECYCLE_ENABLED_SV

class dma350_vseq_lifecycle_enabled extends dma350_vseq_lifecycle_base;
  `uvm_object_utils(dma350_vseq_lifecycle_enabled)

  function new(string name = "dma350_vseq_lifecycle_enabled");
    super.new(name);
    xsize = 128;                 // du dai de con dang chay ngay sau enable
  endfunction

  virtual task body();
    bit [31:0] st;
    super.body();

    cfg_copy();
    enable_ch(ch);

    // dang thuc thi: ENABLECMD=1 va chua DONE
    check_enabled(1'b1, "Running");
    apb_read(ch_addr(ch,O_STATUS), st);
    if (st[S_DONE])
      `uvm_info(get_type_name(),
        "lenh da DONE rat som (copy ngan/responder nhanh) - van hop le", UVM_LOW)
    else
      `uvm_info(get_type_name(), $sformatf(
        "CH%0d dang Running (STATUS=0x%08h, chua DONE)", ch, st), UVM_LOW)

    wait_ch_done(ch);
    check_enabled(1'b0, "sau DONE (Disabled)");
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_lifecycle_enabled

`endif // DMA350_VSEQ_LIFECYCLE_ENABLED_SV
