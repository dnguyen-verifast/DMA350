//==============================================================================
// dma350_vseq_lifecycle_paused.sv
//   "Paused - Execution suspended, resumable"
//   - Enable copy dai -> PAUSECMD -> STAT_PAUSED (+ STAT_RESUMEWAIT: cho resume)
//     -> RESUMECMD -> tiep tuc -> DONE.
//==============================================================================
`ifndef DMA350_VSEQ_LIFECYCLE_PAUSED_SV
`define DMA350_VSEQ_LIFECYCLE_PAUSED_SV

class dma350_vseq_lifecycle_paused extends dma350_vseq_lifecycle_base;
  `uvm_object_utils(dma350_vseq_lifecycle_paused)

  function new(string name = "dma350_vseq_lifecycle_paused");
    super.new(name);
    xsize = 128;
  endfunction

  virtual task body();
    bit [31:0] st;
    super.body();

    cfg_copy();
    enable_ch(ch);

    // PAUSE -> cho toi khi vao trang thai paused
    apb_write(ch_addr(ch,O_CMD), 32'h1 << B_PAUSE);
    wait_ch_bit(ch, S_PAUSED, "PAUSED");

    // van dang enabled (chi tam dung) va cho resume
    check_enabled(1'b1, "Paused (van enabled)");
    apb_read(ch_addr(ch,O_STATUS), st);
    if (!st[S_RESUMEWAIT])
      `uvm_info(get_type_name(), $sformatf(
        "CH%0d PAUSED nhung STAT_RESUMEWAIT chua set (STATUS=0x%08h)", ch, st), UVM_MEDIUM)

    // RESUME -> tiep tuc chay den DONE
    apb_write(ch_addr(ch,O_CMD), 32'h1 << B_RESUME);
    wait_ch_done(ch);
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_lifecycle_paused

`endif // DMA350_VSEQ_LIFECYCLE_PAUSED_SV
