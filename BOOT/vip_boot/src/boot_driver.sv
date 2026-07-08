//------------------------------------------------------------------------------
// boot_driver.sv
//
// Drives the static boot_* configuration inputs.
//
// Protocol (TRM 4.9.1): all boot signals must be valid and stable when resetn
// is deasserted, and must remain stable until the boot command fetch starts.
// The driver therefore programs the values *while in reset* and then holds them
// constant. A new item only takes effect on the next reset, so the driver waits
// for resetn LOW before applying a fresh configuration.
//------------------------------------------------------------------------------
`ifndef BOOT_DRIVER_SV
`define BOOT_DRIVER_SV

class boot_driver extends uvm_driver #(boot_seq_item);
  `uvm_component_utils(boot_driver)

  boot_agent_cfg     cfg;
  virtual boot_if    vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boot_agent_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "boot_agent_cfg not set for driver")
    vif = cfg.vif;
  endfunction

  task run_phase(uvm_phase phase);
    drive_reset_values();
    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  // Park the interface in a benign state (boot disabled) at time zero.
  protected task drive_reset_values();
    vif.boot_en        <= 1'b0;
    vif.boot_addr      <= '0;
    vif.boot_memattr   <= '0;
    vif.boot_shareattr <= 2'b00;
  endtask

  // Apply one configuration and hold it stable across the reset edge and the
  // boot-fetch window.
  protected task drive_item(boot_seq_item item);
    // Ensure the values are presented during reset so they are stable at the
    // deasserting edge. If we are not currently in reset, wait for the next
    // reset assertion (a fresh boot config only matters at reset).
    if (vif.resetn === 1'b1) begin
      `uvm_info(get_type_name(),
        "Waiting for resetn LOW before applying new boot configuration",
        UVM_MEDIUM)
      wait (vif.resetn === 1'b0);
    end

    @(vif.drv_cb);
    vif.drv_cb.boot_en        <= item.boot_en;
    // item.boot_addr is [63:2]; the interface bus is [ADDR_WIDTH-1:2]. Both are
    // LSB-aligned at bit 2, so a direct assignment lines up correctly and
    // truncates the high (constrained-zero) bits. Avoids a variable part-select.
    vif.drv_cb.boot_addr      <= item.boot_addr;
    vif.drv_cb.boot_memattr   <= item.memattr();
    vif.drv_cb.boot_shareattr <= item.shareattr;

    `uvm_info(get_type_name(),
      $sformatf("Applied boot config: %s", item.convert2string()), UVM_LOW)

    // Hold until reset is released; values then remain driven (the driver does
    // not change them again until the next item arrives during a later reset).
    wait (vif.resetn === 1'b1);
  endtask

endclass : boot_driver

`endif // BOOT_DRIVER_SV
