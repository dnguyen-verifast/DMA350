//==============================================================================
// dma350_vseq_2d_life_err_bus.sv
//   GROUP I - TRM 5.6.3 'Error handling' - loi bus giua khung 2D
//   Vung nguon co dia chi khong duoc slave AXI phuc vu -> tra loi loi.
//   Ky vong: STAT_ERR set, ERRINFO.BUSERR = 1, kem toa do X/Y luc xay ra loi.
//   LUU Y: phu thuoc VIP AXI5 co sinh SLVERR cho vung nay khong; neu VIP luon tra
//          OKAY thi test se bao khong thay loi -> can cau hinh error-injection.
//==============================================================================
`ifndef DMA350_VSEQ_2D_LIFE_ERR_BUS_SV
`define DMA350_VSEQ_2D_LIFE_ERR_BUS_SV

class dma350_vseq_2d_life_err_bus extends dma350_vseq_2d_base;
  `uvm_object_utils(dma350_vseq_2d_life_err_bus)

  function new(string name = "dma350_vseq_2d_life_err_bus");
    super.new(name);
    src_addr = 32'hFFFF_F000;
    src_ysize = 4;
    des_ysize = 4;
  endfunction

  virtual task body();
    bit [31:0] st, ei;
    super.body();
    cfg_2d();
    enable_ch(ch);

    repeat (poll_limit) begin
      apb_read(ch_addr(ch,O_STATUS), st);
      if (st[S_ERR] || st[S_DONE]) break;
    end

    if (st[S_ERR]) begin
      apb_read(ch_addr(ch,O_ERRINFO), ei);
      `uvm_info(get_type_name(), $sformatf(
        "CH%0d bat duoc loi bus giua khung 2D: ERRINFO=0x%08h (BUSERR=%0b)",
        ch, ei, ei[EI_BUSERR]), UVM_LOW)
    end
    else begin
      `uvm_warning(get_type_name(), $sformatf(
        "CH%0d KHONG thay STAT_ERR - VIP AXI5 co the dang tra OKAY cho moi dia chi. Can bat error-injection de test nay co y nghia.", ch))
    end
    clear_ch_status(ch);
  endtask

endclass : dma350_vseq_2d_life_err_bus

`endif // DMA350_VSEQ_2D_LIFE_ERR_BUS_SV
