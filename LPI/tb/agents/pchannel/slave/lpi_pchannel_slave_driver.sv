//==============================================================================
// lpi_pchannel_slave_driver.sv
// P-Channel SLAVE (device) driver : reactive responder for PACCEPT/PDENY/
// PACTIVE. Slave = the side that accepts/denies the master's transitions.
//==============================================================================
class lpi_pchannel_slave_driver extends uvm_driver #(lpi_pchannel_item);
  `uvm_component_utils(lpi_pchannel_slave_driver)
  lpi_pchannel_cfg cfg;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(lpi_pchannel_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal(get_type_name(),"cfg not set")
  endfunction

  task run_phase(uvm_phase phase);
    cfg.vif.paccept = 1'b0;          // reset values (section 3.1.2)
    cfg.vif.pdeny   = 1'b0;
    cfg.vif.pactive = '0;
    @(posedge cfg.vif.resetn);
    @(cfg.vif.dev_cb);
    forever respond();
  endtask

  task respond();
    p_state_e st = p_decode(1'b1, cfg.vif.dev_cb.preq,
                            cfg.vif.dev_cb.paccept, cfg.vif.dev_cb.pdeny);
    case (st)
      P_COMPLETE : begin cfg.vif.dev_cb.paccept <= 1'b0; @(cfg.vif.dev_cb); end // -> STABLE
      P_CONTINUE : begin cfg.vif.dev_cb.pdeny   <= 1'b0; @(cfg.vif.dev_cb); end // -> STABLE
      P_REQUEST  : begin
                     lpi_pchannel_item it;
                     seq_item_port.get_next_item(it);
                     repeat (it.resp_delay) @(cfg.vif.dev_cb);
                     cfg.vif.dev_cb.pactive <= it.pactive;
                     if (it.deny) cfg.vif.dev_cb.pdeny   <= 1'b1; // -> P_DENIED
                     else         cfg.vif.dev_cb.paccept <= 1'b1; // -> P_ACCEPT
                     @(cfg.vif.dev_cb);
                     seq_item_port.item_done();
                   end
      default    : @(cfg.vif.dev_cb);
    endcase
  endtask
endclass
