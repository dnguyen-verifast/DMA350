//==============================================================================
// dma350_sc_example_env.sv
//------------------------------------------------------------------------------
// Minimal example env + test showing how to build the status/control agent for
// a specific DMA-350 build and drive a couple of sequences. Drop into your own
// package or adapt into your top-level env. Requires dma350_sc_pkg.
//==============================================================================
`ifndef DMA350_SC_EXAMPLE_ENV__SV
`define DMA350_SC_EXAMPLE_ENV__SV

class dma350_sc_example_env extends uvm_env;
  `uvm_component_utils(dma350_sc_example_env)

  dma350_sc_agent    agent;
  dma350_sc_coverage cov;
  dma350_sc_cfg      cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // ---- describe THIS build (mirror your RTL config params) -------------
    cfg = dma350_sc_cfg::type_id::create("cfg");
    cfg.is_active      = UVM_ACTIVE;
    cfg.secext_present = 1'b1;   // SECEXT_PRESENT=1  -> _sec pairs + ch_nonsec exist
    cfg.num_channels   = 4;      // NUM_CHANNELS=4
    cfg.gpo_width      = 16;     // GPO_WIDTH=16
    foreach (cfg.ch_gpo_mask[i]) cfg.ch_gpo_mask[i] = (i < 4); // CH_GPO_MASK

    uvm_config_db#(dma350_sc_cfg)::set(this, "agent", "cfg", cfg);

    agent = dma350_sc_agent   ::type_id::create("agent", this);
    cov   = dma350_sc_coverage::type_id::create("cov",   this);
    uvm_config_db#(dma350_sc_cfg)::set(this, "cov", "cfg", cfg);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // feed monitored action items to coverage (and, in a real env, to the SB)
    agent.ap.connect(cov.analysis_export);
  endfunction

endclass : dma350_sc_example_env


// --- example test -----------------------------------------------------------
class dma350_sc_smoke_test extends uvm_test;
  `uvm_component_utils(dma350_sc_smoke_test)
  dma350_sc_example_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = dma350_sc_example_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    dma350_sc_stop_seq            s_stop;
    dma350_sc_pause_seq           s_pause;
    dma350_sc_cti_seq             s_cti;
    dma350_sc_pause_or_halt_seq   s_or;
    dma350_sc_secure_isolation_seq s_sec;

    phase.raise_objection(this);

    s_stop  = dma350_sc_stop_seq::type_id::create("s_stop");
    s_pause = dma350_sc_pause_seq::type_id::create("s_pause");
    s_cti   = dma350_sc_cti_seq::type_id::create("s_cti");
    s_or    = dma350_sc_pause_or_halt_seq::type_id::create("s_or");
    s_sec   = dma350_sc_secure_isolation_seq::type_id::create("s_sec");

    s_stop.start (env.agent.sqr);
    s_pause.start(env.agent.sqr);
    s_cti.start  (env.agent.sqr);
    s_or.start   (env.agent.sqr);
    s_sec.start  (env.agent.sqr);

    phase.drop_objection(this);
  endtask
endclass : dma350_sc_smoke_test

`endif // DMA350_SC_EXAMPLE_ENV__SV
