//==============================================================================
// lpi_env_cfg.sv  -  top environment configuration
//==============================================================================
class lpi_env_cfg extends uvm_object;
  virtual lpi_qchannel_if qvif;
  virtual lpi_pchannel_if pvif;
  bit enable_qchannel = 1;
  bit enable_pchannel = 1;

  `uvm_object_utils(lpi_env_cfg)
  function new(string name="lpi_env_cfg"); super.new(name); endfunction
endclass
