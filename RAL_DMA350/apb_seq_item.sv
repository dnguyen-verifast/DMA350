class apb_seq_item extends uvm_sequence_item;
  rand logic [31:0]  paddr;
  rand logic         pwrite;
  rand logic [31:0]  pwdata;
  rand logic [3:0]   pstrb;
       logic [31:0]  prdata;
       logic         pslverr;   // dùng để báo lỗi -> status

  `uvm_object_utils(apb_seq_item)
  function new(string name = "apb_seq_item");
    super.new(name);
  endfunction
endclass