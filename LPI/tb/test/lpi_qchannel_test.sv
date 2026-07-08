//==============================================================================
// lpi_qchannel_test.sv  -  Q-Channel only
//==============================================================================
class lpi_qchannel_test extends lpi_smoke_test;
  `uvm_component_utils(lpi_qchannel_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  virtual function void configure(lpi_env_cfg c);
    c.enable_qchannel = 1; c.enable_pchannel = 0;
  endfunction
endclass
