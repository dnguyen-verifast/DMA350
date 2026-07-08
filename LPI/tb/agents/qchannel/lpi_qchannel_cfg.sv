//==============================================================================
// lpi_qchannel_cfg.sv  -  Q-Channel agent configuration
// Shared by the master and slave agents (the agent TYPE selects the role).
//==============================================================================
class lpi_qchannel_cfg extends uvm_object;
  virtual lpi_qchannel_if vif;
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  `uvm_object_utils(lpi_qchannel_cfg)
  function new(string name="lpi_qchannel_cfg"); super.new(name); endfunction
endclass
