//------------------------------------------------------------------------------
// boot_seq_lib.sv
//
// Reusable sequences for the boot VIP.
//------------------------------------------------------------------------------
`ifndef BOOT_SEQ_LIB_SV
`define BOOT_SEQ_LIB_SV

// Base: carries DMAC parameters so address/security constraints are correct.
class boot_base_seq extends uvm_sequence #(boot_seq_item);
  `uvm_object_utils(boot_base_seq)

  int unsigned addr_width     = 32;
  bit          secext_present = 0;
  bit [63:0]   secure_base    = '0;
  bit [63:0]   secure_limit   = '1;

  function new(string name = "boot_base_seq");
    super.new(name);
  endfunction

  // Helper to create+randomize an item with shared parameters applied.
  protected function boot_seq_item make_item(string name = "boot_item");
    boot_seq_item it = boot_seq_item::type_id::create(name);
    it.addr_width     = addr_width;
    it.secext_present = secext_present;
    it.secure_base    = secure_base;
    it.secure_limit   = secure_limit;
    return it;
  endfunction
endclass : boot_base_seq

// Autoboot enabled with a fully randomized, legal configuration.
class boot_enabled_seq extends boot_base_seq;
  `uvm_object_utils(boot_enabled_seq)

  function new(string name = "boot_enabled_seq");
    super.new(name);
  endfunction

  task body();
    boot_seq_item it = make_item("boot_enabled");
    start_item(it);
    if (!it.randomize() with { boot_en == 1'b1; })
      `uvm_fatal(get_type_name(), "randomize failed")
    finish_item(it);
  endtask
endclass : boot_enabled_seq

// Autoboot disabled (boot_en = 0); other signals are don't-care to the DUT.
class boot_disabled_seq extends boot_base_seq;
  `uvm_object_utils(boot_disabled_seq)

  function new(string name = "boot_disabled_seq");
    super.new(name);
  endfunction

  task body();
    boot_seq_item it = make_item("boot_disabled");
    start_item(it);
    if (!it.randomize() with { boot_en == 1'b0; })
      `uvm_fatal(get_type_name(), "randomize failed")
    finish_item(it);
  endtask
endclass : boot_disabled_seq

// Directed: boot from a specific address with explicit attributes.
class boot_directed_seq extends boot_base_seq;
  `uvm_object_utils(boot_directed_seq)

  bit [63:2]            addr;
  boot_memattr_hi_e     memattr_hi = BOOT_MEMHI_NORM_ORWA_WB_NT;
  bit [3:0]             memattr_lo = 4'b1111;
  boot_shareattr_e      shareattr  = BOOT_SHARE_INNER;

  function new(string name = "boot_directed_seq");
    super.new(name);
  endfunction

  task body();
    boot_seq_item it = make_item("boot_directed");
    start_item(it);
    it.boot_en    = 1'b1;
    it.boot_addr  = addr;
    it.memattr_hi = memattr_hi;
    it.memattr_lo = memattr_lo;
    it.shareattr  = shareattr;
    finish_item(it);
  endtask
endclass : boot_directed_seq

`endif // BOOT_SEQ_LIB_SV
