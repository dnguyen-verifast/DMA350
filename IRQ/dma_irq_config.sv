//------------------------------------------------------------------------------
// dma_irq_config.sv
// Config cho agent: virtual interface + tham so. Agent luon passive.
//------------------------------------------------------------------------------
class dma_irq_config #(
  parameter int NUM_CHANNELS   = 8,
  parameter bit SECEXT_PRESENT = 1
) extends uvm_object;

  virtual dma_irq_if #(NUM_CHANNELS, SECEXT_PRESENT) vif;

  // Agent nay chi de quan sat -> luon passive, khong can driver/sequencer
  uvm_active_passive_enum is_active = UVM_PASSIVE;

  `uvm_object_utils(dma_irq_config#(NUM_CHANNELS, SECEXT_PRESENT))

  function new(string name = "dma_irq_config");
    super.new(name);
  endfunction

endclass : dma_irq_config
