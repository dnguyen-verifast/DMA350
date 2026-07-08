//==============================================================================
// dma_trig_item.sv
//------------------------------------------------------------------------------
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!  STUB TOI THIEU  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//
// dma350_scoreboard.process_trigger() tham chieu class `dma_trig_item` nhung
// TRONG CODEBASE HIEN TAI CHUA CO VIP TRIGGER nao dinh nghia no. File nay tao
// mot dinh nghia TOI THIEU chi de scoreboard COMPILE duoc, voi dung cac field
// ma scoreboard doc:
//     observed_acktype  (bit [1:0])   - ack: OKAY/DENY/LASTOKAY
//     observed_reqtype  (enum, .name())
//     comb_ack_seen     (bit)         - vi pham 4-phase (ack cung cycle req)
//     convert2string()
//
// HAY THAY THE bang seq_item that cua VIP trigger khi co, va bo file stub nay.
//==============================================================================
`ifndef DMA_TRIG_ITEM_SV
`define DMA_TRIG_ITEM_SV

// Loai request tren trigger interface (khop cach dung .name() trong scoreboard)
typedef enum bit [1:0] {
  TRIG_REQ_NONE   = 2'b00,
  TRIG_REQ_SRCIN  = 2'b01,   // source trigger-in
  TRIG_REQ_DESIN  = 2'b10,   // destination trigger-in
  TRIG_REQ_OUT    = 2'b11    // trigger-out
} dma_trig_reqtype_e;

class dma_trig_item extends uvm_sequence_item;

  // ack ma DUT phat: 00=OKAY, 01=DENY, 10=LASTOKAY (TRM Table 5-5)
  rand bit [1:0]           observed_acktype;
  // loai request quan sat duoc
  rand dma_trig_reqtype_e  observed_reqtype;
  // co: ack xuat hien COMBINATIONAL cung chu ky voi req (vi pham 4-phase)
  bit                      comb_ack_seen;

  `uvm_object_utils_begin(dma_trig_item)
    `uvm_field_int (observed_acktype, UVM_ALL_ON)
    `uvm_field_enum(dma_trig_reqtype_e, observed_reqtype, UVM_ALL_ON)
    `uvm_field_int (comb_ack_seen,    UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "dma_trig_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("TRIG req=%s ack=0x%0h comb_ack=%0b",
                     observed_reqtype.name(), observed_acktype, comb_ack_seen);
  endfunction

endclass

`endif // DMA_TRIG_ITEM_SV
