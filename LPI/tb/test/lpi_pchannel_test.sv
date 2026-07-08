//==============================================================================
// lpi_pchannel_test.sv  -  P-Channel only
//==============================================================================
class lpi_pchannel_test extends lpi_smoke_test;
  `uvm_component_utils(lpi_pchannel_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  virtual function void configure(lpi_env_cfg c);
    c.enable_qchannel = 0; c.enable_pchannel = 1;
  endfunction
endclass
