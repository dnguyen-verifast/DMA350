//------------------------------------------------------------------------------
// dma_irq_item.sv
// Doi tuong transaction mo ta mot su kien/trang thai interrupt duoc sample
//------------------------------------------------------------------------------
class dma_irq_item #(
  parameter int NUM_CHANNELS = 8
) extends uvm_sequence_item;

  // Snapshot cua cac tin hieu tai thoi diem co thay doi
  rand bit [NUM_CHANNELS-1:0] irq_channel;
  rand bit                    irq_comb_nonsec;
  rand bit                    irq_comb_sec;
  rand bit                    irq_sec_viol_err;

  // Thong tin phu tro de debug/coverage
  time                        sample_time;   // thoi diem sample
  int                         active_ch_id;  // channel dau tien dang assert (-1 neu khong co)

  `uvm_object_utils_begin(dma_irq_item#(NUM_CHANNELS))
    `uvm_field_int(irq_channel,      UVM_ALL_ON)
    `uvm_field_int(irq_comb_nonsec,  UVM_ALL_ON)
    `uvm_field_int(irq_comb_sec,     UVM_ALL_ON)
    `uvm_field_int(irq_sec_viol_err, UVM_ALL_ON)
    `uvm_field_int(active_ch_id,     UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end

  function new(string name = "dma_irq_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf(
      "irq_channel=0x%0h comb_nonsec=%0b comb_sec=%0b sec_viol_err=%0b active_ch=%0d @%0t",
      irq_channel, irq_comb_nonsec, irq_comb_sec, irq_sec_viol_err, active_ch_id, sample_time);
  endfunction

endclass : dma_irq_item
