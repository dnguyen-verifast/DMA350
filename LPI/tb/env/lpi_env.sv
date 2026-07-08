//==============================================================================
// lpi_env.sv
// Top environment. Per channel: MASTER agent + SLAVE agent, each with its OWN
// monitor; plus COVERAGE. One COMMON SCOREBOARD checks BOTH interfaces and both
// roles. Plus one virtual sequencer to coordinate stimulus.
//==============================================================================
class lpi_env extends uvm_env;
  `uvm_component_utils(lpi_env)

  lpi_env_cfg cfg;

  // Virtual sequencer + common scoreboard (shared across both interfaces/roles)
  lpi_virtual_sequencer     vseqr;
  lpi_scoreboard            sb;

  // Q-Channel
  lpi_qchannel_master_agent q_master_agent;
  lpi_qchannel_slave_agent  q_slave_agent;
  lpi_qchannel_coverage     q_cov;

  // P-Channel
  lpi_pchannel_master_agent p_master_agent;
  lpi_pchannel_slave_agent  p_slave_agent;
  lpi_pchannel_coverage     p_cov;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(lpi_env_cfg)::get(this,"","cfg",cfg))
      `uvm_fatal(get_type_name(),"env cfg not set")

    vseqr = lpi_virtual_sequencer::type_id::create("vseqr", this);
    sb    = lpi_scoreboard::type_id::create("sb", this);   // common to Q and P

    // ---------------- Q-Channel ----------------
    if (cfg.enable_qchannel) begin
      lpi_qchannel_cfg qm = lpi_qchannel_cfg::type_id::create("qm");
      lpi_qchannel_cfg qs = lpi_qchannel_cfg::type_id::create("qs");
      qm.vif = cfg.qvif; qm.is_active = UVM_ACTIVE;
      qs.vif = cfg.qvif; qs.is_active = UVM_ACTIVE;
      uvm_config_db#(lpi_qchannel_cfg)::set(this,"q_master_agent","cfg",qm);
      uvm_config_db#(lpi_qchannel_cfg)::set(this,"q_slave_agent", "cfg",qs);
      q_master_agent = lpi_qchannel_master_agent::type_id::create("q_master_agent", this);
      q_slave_agent  = lpi_qchannel_slave_agent ::type_id::create("q_slave_agent",  this);
      q_cov = lpi_qchannel_coverage::type_id::create("q_cov", this);
    end

    // ---------------- P-Channel ----------------
    if (cfg.enable_pchannel) begin
      lpi_pchannel_cfg pm = lpi_pchannel_cfg::type_id::create("pm");
      lpi_pchannel_cfg ps = lpi_pchannel_cfg::type_id::create("ps");
      pm.vif = cfg.pvif; pm.is_active = UVM_ACTIVE;
      ps.vif = cfg.pvif; ps.is_active = UVM_ACTIVE;
      uvm_config_db#(lpi_pchannel_cfg)::set(this,"p_master_agent","cfg",pm);
      uvm_config_db#(lpi_pchannel_cfg)::set(this,"p_slave_agent", "cfg",ps);
      p_master_agent = lpi_pchannel_master_agent::type_id::create("p_master_agent", this);
      p_slave_agent  = lpi_pchannel_slave_agent ::type_id::create("p_slave_agent",  this);
      p_cov = lpi_pchannel_coverage::type_id::create("p_cov", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (cfg.enable_qchannel) begin
      // each role's monitor -> its own scoreboard import
      q_master_agent.ap.connect(sb.q_master_imp);
      q_slave_agent.ap .connect(sb.q_slave_imp);
      // coverage sampled from the master-side observation
      q_master_agent.ap.connect(q_cov.analysis_export);
      vseqr.q_master_seqr = q_master_agent.seqr;
      vseqr.q_slave_seqr  = q_slave_agent.seqr;
    end
    if (cfg.enable_pchannel) begin
      p_master_agent.ap.connect(sb.p_master_imp);
      p_slave_agent.ap .connect(sb.p_slave_imp);
      p_master_agent.ap.connect(p_cov.analysis_export);
      vseqr.p_master_seqr = p_master_agent.seqr;
      vseqr.p_slave_seqr  = p_slave_agent.seqr;
    end
  endfunction
endclass
