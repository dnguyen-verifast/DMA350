//------------------------------------------------------------------------------
// boot_monitor.sv
//
// Samples the boot configuration at the deasserting edge of resetn (the point
// at which the DMAC latches it, per TRM 4.9.1 / 5.7.3 autoboot process) and
// broadcasts a boot_seq_item. Also performs protocol checks:
//   * boot_* stable from reset deassertion until boot_fetch_started
//   * boot_shareattr never the reserved encoding 2'b01
//   * Device-type memattr uses only legal *LO encodings
//   * with SECEXT, an enabled boot points into the Secure region
//------------------------------------------------------------------------------
`ifndef BOOT_MONITOR_SV
`define BOOT_MONITOR_SV

class boot_monitor extends uvm_monitor;
  `uvm_component_utils(boot_monitor)

  boot_agent_cfg  cfg;
  virtual boot_if vif;

  uvm_analysis_port #(boot_seq_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(boot_agent_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "boot_agent_cfg not set for monitor")
    vif = cfg.vif;
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      // Detect the rising (deasserting) edge of the active-LOW reset.
      @(posedge vif.resetn);
      sample_and_check();
    end
  endtask

  protected task sample_and_check();
    boot_seq_item tr;
    bit [63:2]    captured_addr;
    bit [7:0]     captured_memattr;
    bit [1:0]     captured_share;
    bit           captured_en;

    // Capture the latched configuration at reset deassertion.
    // vif.boot_addr is [ADDR_WIDTH-1:2]; assigning into the wider [63:2] vector
    // zero-extends the high bits (both are LSB-aligned at bit 2). Avoids a
    // variable part-select on captured_addr.
    captured_en      = vif.boot_en;
    captured_addr    = '0;
    captured_addr    = vif.boot_addr;
    captured_memattr = vif.boot_memattr;
    captured_share   = vif.boot_shareattr;

    tr = boot_seq_item::type_id::create("boot_observed");
    tr.addr_width     = cfg.addr_width;
    tr.secext_present = cfg.secext_present;
    tr.secure_base    = cfg.secure_base;
    tr.secure_limit   = cfg.secure_limit;
    tr.boot_en        = captured_en;
    tr.boot_addr      = captured_addr;
    tr.memattr_hi     = boot_memattr_hi_e'(captured_memattr[7:4]);
    tr.memattr_lo     = captured_memattr[3:0];
    tr.shareattr      = boot_shareattr_e'(captured_share);

    `uvm_info(get_type_name(),
      $sformatf("Boot config latched at reset release: %s",
                tr.convert2string()), UVM_LOW)

    check_legal(tr);
    ap.write(tr);

    // Launch the stability watcher in the background so the monitor can re-arm
    // on the next reset without blocking here.
    if (captured_en && cfg.check_stability_window) begin
      fork
        check_stability(captured_en, captured_addr, captured_memattr,
                        captured_share);
      join_none
    end
  endtask

  // Static legality checks on the latched configuration.
  protected function void check_legal(boot_seq_item tr);
    if (tr.shareattr == BOOT_SHARE_RESERVED)
      `uvm_error(get_type_name(),
        "boot_shareattr == 2'b01 is Reserved/illegal")

    if (tr.memattr_hi == BOOT_MEMHI_DEVICE &&
        !(tr.memattr_lo inside {4'b0000, 4'b0100, 4'b1000, 4'b1100}))
      `uvm_error(get_type_name(),
        $sformatf("Device boot_memattr LO=0x%01h is UNPREDICTABLE",
                  tr.memattr_lo))

    if (tr.memattr_hi != BOOT_MEMHI_DEVICE && tr.memattr_lo == 4'b0000)
      `uvm_error(get_type_name(),
        "Normal-memory boot_memattr LO=0000 is Reserved")

    if (cfg.secext_present && tr.boot_en) begin
      bit [63:0] a = {tr.boot_addr, 2'b00};
      if (!(a >= cfg.secure_base && a < cfg.secure_limit))
        `uvm_error(get_type_name(),
          $sformatf({"With SECEXT_PRESENT, an enabled boot must point into ",
                     "Secure memory: addr=0x%0h not in [0x%0h, 0x%0h)"},
                    a, cfg.secure_base, cfg.secure_limit))
    end
  endfunction

  // Verify boot_* are held stable from reset deassertion until the boot fetch
  // starts (boot_fetch_started pulses/asserts HIGH).
  protected task automatic check_stability(bit en, bit [63:2] addr,
                                           bit [7:0] memattr, bit [1:0] share);
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.boot_fetch_started) break;
      if (vif.resetn !== 1'b1) break; // reset re-asserted, window aborted
      // Direct compares: narrower vif buses zero-extend to match the captured
      // values (high bits of addr are zero), all LSB-aligned.
      if (vif.mon_cb.boot_en        !== en      ||
          vif.mon_cb.boot_addr      !== addr     ||
          vif.mon_cb.boot_memattr   !== memattr ||
          vif.mon_cb.boot_shareattr !== share) begin
        `uvm_error(get_type_name(),
          "boot_* changed before boot command fetch started (TRM 4.9.1)")
        break;
      end
    end
  endtask

endclass : boot_monitor

`endif // BOOT_MONITOR_SV
