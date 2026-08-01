//==============================================================================
// dma350_vseq_lifecycle_error.sv
//   "Error handling - Behaviour on transfer / config errors"
//   - Cau hinh mot lenh CO LOI (TRANSIZE = doubleword 8B > bus 32-bit=4B) ->
//     config error. Enable -> STAT_ERR set, CH_ERRINFO bao CFGERR; channel ve
//     disabled, KHONG phat giao dich AXI. Clear STAT_ERR (xoa luon ERRINFO).
//==============================================================================
`ifndef DMA350_VSEQ_LIFECYCLE_ERROR_SV
`define DMA350_VSEQ_LIFECYCLE_ERROR_SV

class dma350_vseq_lifecycle_error extends dma350_vseq_lifecycle_base;
  `uvm_object_utils(dma350_vseq_lifecycle_error)

  // CH_ERRINFO[1] = CFGERR (config error), [0] = BUSERR
  localparam int EI_CFGERR = 1;

  function new(string name = "dma350_vseq_lifecycle_error");
    super.new(name);
    xsize    = 16;
    transize = 3'd3;             // doubleword (8B) > 32-bit bus -> config error
  endfunction

  virtual task body();
    bit [31:0] st, ei;
    super.body();

    cfg_copy();                  // CTRL.TRANSIZE = 3 -> loi cau hinh
    enable_ch(ch);

    // cho STAT_ERR
    repeat (poll_limit) begin
      apb_read(ch_addr(ch,O_STATUS), st);
      if (st[S_ERR]) break;
      if (st[S_DONE]) begin
        `uvm_error(get_type_name(),
          "lenh loi cau hinh nhung lai bao DONE (khong co STAT_ERR)")
        break;
      end
    end
    if (!st[S_ERR]) begin
      `uvm_error(get_type_name(), $sformatf(
        "CH%0d khong thay STAT_ERR voi lenh loi cau hinh (STATUS=0x%08h)", ch, st))
    end
    else begin
      apb_read(ch_addr(ch,O_ERRINFO), ei);
      `uvm_info(get_type_name(), $sformatf(
        "CH%0d STAT_ERR (STATUS=0x%08h ERRINFO=0x%08h CFGERR=%0b)",
        ch, st, ei, ei[EI_CFGERR]), UVM_LOW)
      if (!ei[EI_CFGERR])
        `uvm_warning(get_type_name(), $sformatf(
          "CH%0d STAT_ERR nhung ERRINFO.CFGERR=0 (ERRINFO=0x%08h)", ch, ei))
    end

    // sau loi: channel ve disabled
    check_enabled(1'b0, "sau ERROR (Disabled)");

    // W1C STAT_ERR -> cung xoa ERRINFO
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_lifecycle_error

`endif // DMA350_VSEQ_LIFECYCLE_ERROR_SV
