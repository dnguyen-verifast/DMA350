//------------------------------------------------------------------------------
// boot_coverage.sv
//
// Functional coverage for the boot configuration interface, sampled on each
// monitored item (i.e. once per reset deassertion).
//------------------------------------------------------------------------------
`ifndef BOOT_COVERAGE_SV
`define BOOT_COVERAGE_SV

class boot_coverage extends uvm_subscriber #(boot_seq_item);
  `uvm_component_utils(boot_coverage)

  boot_agent_cfg cfg;
  boot_seq_item  tr;

  covergroup cg_boot;
    option.per_instance = 1;
    option.name         = "boot_cfg_cg";

    cp_en : coverpoint tr.boot_en {
      bins disabled = {0};
      bins enabled  = {1};
    }

    cp_memhi : coverpoint tr.memattr_hi {
      bins device = {BOOT_MEMHI_DEVICE};
      bins normal[] = {[BOOT_MEMHI_NORM_OWA_WT_T : BOOT_MEMHI_NORM_ORWA_WB_NT]};
    }

    cp_share : coverpoint tr.shareattr {
      bins non_share = {BOOT_SHARE_NON};
      bins outer     = {BOOT_SHARE_OUTER};
      bins inner     = {BOOT_SHARE_INNER};
      illegal_bins reserved = {BOOT_SHARE_RESERVED};
    }

    // boot_addr alignment is structural (bits [1:0] absent), but sample the
    // low-order region bits to confirm a spread of addresses is exercised.
    cp_addr_region : coverpoint tr.boot_addr[11:2] {
      bins lo  = {[10'h000 : 10'h0FF]};
      bins mid = {[10'h100 : 10'h2FF]};
      bins hi  = {[10'h300 : 10'h3FF]};
    }

    // Enabled boot crossed with the memory type actually used.
    x_en_memhi : cross cp_en, cp_memhi;
    x_en_share : cross cp_en, cp_share;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_boot = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_config_db#(boot_agent_cfg)::get(this, "", "cfg", cfg));
  endfunction

  function void write(boot_seq_item t);
    tr = t;
    cg_boot.sample();
  endfunction

endclass : boot_coverage

`endif // BOOT_COVERAGE_SV
