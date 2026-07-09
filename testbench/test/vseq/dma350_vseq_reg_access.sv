//==============================================================================
// dma350_vseq_reg_access.sv
//   Ghi cac thanh ghi config roi doc lai so khop (channel disabled).
//==============================================================================
`ifndef DMA350_VSEQ_REG_ACCESS_SV
`define DMA350_VSEQ_REG_ACCESS_SV

class dma350_vseq_reg_access extends dma350_vseq_base;
  `uvm_object_utils(dma350_vseq_reg_access)
  function new(string name="dma350_vseq_reg_access"); super.new(name); endfunction

  virtual task body();
    super.body();
    // cac thanh ghi config RW co the ghi/doc tu do khi channel disabled
    apb_write(ch_addr(0,O_SRCADDR),  32'hA5A5_1000);
    apb_write(ch_addr(0,O_DESADDR),  32'h5A5A_2000);
    apb_write(ch_addr(0,O_XSIZE),    32'h0010_0010);
    apb_write(ch_addr(0,O_XADDRINC), 32'h0001_0001);
    apb_write(ch_addr(0,O_FILLVAL),  32'hDEAD_BEEF);
    apb_write(ch_addr(0,O_YSIZE),    32'h0000_0004);

    apb_check(ch_addr(0,O_SRCADDR),  32'hA5A5_1000);
    apb_check(ch_addr(0,O_DESADDR),  32'h5A5A_2000);
    apb_check(ch_addr(0,O_XSIZE),    32'h0010_0010);
    apb_check(ch_addr(0,O_XADDRINC), 32'h0001_0001);
    apb_check(ch_addr(0,O_FILLVAL),  32'hDEAD_BEEF);
    apb_check(ch_addr(0,O_YSIZE),    32'h0000_0004, 32'h0000_FFFF);
    `uvm_info(get_type_name(), "register access OK", UVM_LOW)
  endtask
endclass

`endif // DMA350_VSEQ_REG_ACCESS_SV
