//==============================================================================
// lpi_pchannel_cfg.sv  -  P-Channel agent configuration
// Shared by the master and slave agents (the agent TYPE selects the role).
//==============================================================================
class lpi_pchannel_cfg extends uvm_object;
  virtual lpi_pchannel_if vif;
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  `uvm_object_utils(lpi_pchannel_cfg)
  function new(string name="lpi_pchannel_cfg"); super.new(name); endfunction
endclass
