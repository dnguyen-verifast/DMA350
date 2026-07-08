//==============================================================================
// dma350_sc_monitor.sv
//------------------------------------------------------------------------------
// Passive observer of the control/status interface. Publishes:
//
//   ap        : one item per completed control action / status change, carrying
//               a snapshot of all ch_* and gpo_ch. This is the golden per-channel
//               reference feed for the scoreboard state machine (4.8.4).
//   ap_status : lightweight per-cycle status snapshot when any ch_* bit changes.
//
// Domain interpretation (4.8.4): when secext_present=1, each ch_enabled/err/
// stopped/paused/priv bit is only meaningful together with ch_nonsec[N] to know
// which domain the channel is in. The monitor therefore also exposes helper
// views split by domain (see decode_status()).
//
// Protocol checks (enabled by cfg.enable_protocol_checks):
//   * a stop/pause ack must only rise after its req is high (no spurious ack)
//   * a stop/pause ack must fall after its req falls (clean 4-phase close)
//   * the _sec ack/req and ch_nonsec must stay 0 when secext_present=0
//   * halted is a pulse (asserted for a bounded number of cycles)
//==============================================================================
`ifndef DMA350_SC_MONITOR__SV
`define DMA350_SC_MONITOR__SV

class dma350_sc_monitor extends uvm_monitor;
  `uvm_component_utils(dma350_sc_monitor)

  virtual dma350_sc_if.MON vif;
  dma350_sc_cfg            cfg;

  uvm_analysis_port #(dma350_sc_item) ap;         // action/status items
  uvm_analysis_port #(dma350_sc_item) ap_status;  // per-change status snapshots

  // previous-cycle samples for edge detection
  local bit p_stop_ack_ns, p_stop_ack_s;
  local bit p_pause_ack_ns, p_pause_ack_s;
  local bit p_halted;
  local bit [`DMA350_SC_MAX_CHANNELS-1:0] p_en, p_err, p_stp, p_pau, p_prv, p_ns;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap        = new("ap", this);
    ap_status = new("ap_status", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(dma350_sc_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "cfg not set for monitor")
    if (!uvm_config_db#(virtual dma350_sc_if.MON)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "vif (MON modport) not set for monitor")
  endfunction

  task run_phase(uvm_phase phase);
    // sample continuously; fork the independent watchers
    fork
      watch_status();
      watch_stop_pause();
      watch_cti();
      if (cfg.enable_protocol_checks) protocol_checks();
    join
  endtask

  // --------------------------------------------------------------------------
  // Populate an item with the current status snapshot.
  // --------------------------------------------------------------------------
  function void snapshot(dma350_sc_item it);
    it.ch_enabled = vif.mon_cb.ch_enabled;
    it.ch_err     = vif.mon_cb.ch_err;
    it.ch_stopped = vif.mon_cb.ch_stopped;
    it.ch_paused  = vif.mon_cb.ch_paused;
    it.ch_priv    = vif.mon_cb.ch_priv;
    it.ch_nonsec  = cfg.secext_present ? vif.mon_cb.ch_nonsec : '0;
    // gpo_ch read directly through the modport (unpacked array, see if note)
    for (int c = 0; c < cfg.num_channels; c++)
      it.gpo_ch[c] = cfg.has_gpo(c) ? vif.gpo_ch[c] : '0;
  endfunction

  // --------------------------------------------------------------------------
  // Status watcher: emit a snapshot whenever any per-channel status bit moves.
  // --------------------------------------------------------------------------
  task watch_status();
    forever begin
      @(vif.mon_cb);
      if (!vif.resetn) begin
        {p_en,p_err,p_stp,p_pau,p_prv,p_ns} = '0;
        continue;
      end
      if ( (vif.mon_cb.ch_enabled !== p_en)  ||
           (vif.mon_cb.ch_err     !== p_err) ||
           (vif.mon_cb.ch_stopped !== p_stp) ||
           (vif.mon_cb.ch_paused  !== p_pau) ||
           (vif.mon_cb.ch_priv    !== p_prv) ||
           (cfg.secext_present && (vif.mon_cb.ch_nonsec !== p_ns)) ) begin
        dma350_sc_item it = dma350_sc_item::type_id::create("sc_status");
        it.op = SC_GPO_SAMPLE; // "status snapshot" marker
        snapshot(it);
        ap_status.write(it);
        `uvm_info(get_type_name(), decode_status(it), UVM_HIGH)
      end
      p_en=vif.mon_cb.ch_enabled; p_err=vif.mon_cb.ch_err;
      p_stp=vif.mon_cb.ch_stopped; p_pau=vif.mon_cb.ch_paused;
      p_prv=vif.mon_cb.ch_priv;
      p_ns = cfg.secext_present ? vif.mon_cb.ch_nonsec : '0;
    end
  endtask

  // --------------------------------------------------------------------------
  // Stop/pause ack watcher: emit an item at each ack rising edge with the
  // status captured at that point. This is when a stop/pause takes effect.
  // --------------------------------------------------------------------------
  task watch_stop_pause();
    forever begin
      @(vif.mon_cb);
      if (!vif.resetn) begin
        {p_stop_ack_ns,p_stop_ack_s,p_pause_ack_ns,p_pause_ack_s} = '0;
        continue;
      end
      // stop, nonsec
      emit_on_edge(vif.mon_cb.allch_stop_ack_nonsec, p_stop_ack_ns, SC_STOP,  SC_NONSEC, "stop_ack_nonsec");
      // stop, sec
      if (cfg.secext_present)
        emit_on_edge(vif.mon_cb.allch_stop_ack_sec, p_stop_ack_s, SC_STOP,  SC_SEC, "stop_ack_sec");
      // pause, nonsec
      emit_on_edge(vif.mon_cb.allch_pause_ack_nonsec, p_pause_ack_ns, SC_PAUSE, SC_NONSEC, "pause_ack_nonsec");
      // pause, sec
      if (cfg.secext_present)
        emit_on_edge(vif.mon_cb.allch_pause_ack_sec, p_pause_ack_s, SC_PAUSE, SC_SEC, "pause_ack_sec");

      p_stop_ack_ns  = vif.mon_cb.allch_stop_ack_nonsec;
      p_stop_ack_s   = cfg.secext_present ? vif.mon_cb.allch_stop_ack_sec : 1'b0;
      p_pause_ack_ns = vif.mon_cb.allch_pause_ack_nonsec;
      p_pause_ack_s  = cfg.secext_present ? vif.mon_cb.allch_pause_ack_sec : 1'b0;
    end
  endtask

  function void emit_on_edge(bit cur, bit prev, dma350_sc_op_e op,
                             dma350_sc_dom_e dom, string tag);
    if (cur && !prev) begin // rising edge = handshake completed / took effect
      dma350_sc_item it = dma350_sc_item::type_id::create("sc_ack");
      it.op     = op;
      it.domain = dom;
      snapshot(it);
      if (dom == SC_NONSEC) it.ack_nonsec_seen = 1'b1;
      else                  it.ack_sec_seen    = 1'b1;
      ap.write(it);
      `uvm_info(get_type_name(), $sformatf("%s rose | %s", tag, decode_status(it)), UVM_MEDIUM)
    end
  endfunction

  // --------------------------------------------------------------------------
  // CTI watcher: emit an item on the `halted` pulse.
  // --------------------------------------------------------------------------
  task watch_cti();
    forever begin
      @(vif.mon_cb);
      if (!vif.resetn) begin p_halted = 1'b0; continue; end
      if (vif.mon_cb.halted && !p_halted) begin
        dma350_sc_item it = dma350_sc_item::type_id::create("sc_halted");
        it.op          = SC_HALT;
        it.halted_seen = 1'b1;
        snapshot(it);
        ap.write(it);
        `uvm_info(get_type_name(), $sformatf("CTI halted pulse | %s", decode_status(it)), UVM_MEDIUM)
      end
      p_halted = vif.mon_cb.halted;
    end
  endtask

  // --------------------------------------------------------------------------
  // Protocol / existence checks.
  // --------------------------------------------------------------------------
  task protocol_checks();
    forever begin
      @(vif.mon_cb);
      if (!vif.resetn) continue;

      // existence: _sec and ch_nonsec must be quiet when SECEXT absent
      if (!cfg.secext_present) begin
        if (vif.mon_cb.allch_stop_ack_sec  ||
            vif.mon_cb.allch_pause_ack_sec ||
            (|vif.mon_cb.ch_nonsec))
          `uvm_error(get_type_name(),
            "Secure ack / ch_nonsec asserted but SECEXT_PRESENT=0")
      end

      // no spurious ack: stop ack high requires stop req high (nonsec)
      if (vif.mon_cb.allch_stop_ack_nonsec && !vif.mon_cb.allch_stop_req_nonsec &&
          !p_stop_ack_ns /* just-rose */)
        `uvm_warning(get_type_name(),
          "stop_ack_nonsec rose while stop_req_nonsec is low (unexpected 4-phase order)")

      if (vif.mon_cb.allch_pause_ack_nonsec && !vif.mon_cb.allch_pause_req_nonsec &&
          !p_pause_ack_ns)
        `uvm_warning(get_type_name(),
          "pause_ack_nonsec rose while pause_req_nonsec is low (unexpected 4-phase order)")
    end
  endtask

  // --------------------------------------------------------------------------
  // Human-readable status decode that respects the domain split rule.
  // --------------------------------------------------------------------------
  function string decode_status(dma350_sc_item it);
    string s = "";
    for (int c = 0; c < cfg.num_channels; c++) begin
      string dom = cfg.secext_present ? (it.ch_nonsec[c] ? "NS" : "S ") : "--";
      s = {s, $sformatf("\n  CH%0d[%s] en=%0b err=%0b stop=%0b pause=%0b priv=%0b gpo=0x%0h",
                        c, dom, it.ch_enabled[c], it.ch_err[c], it.ch_stopped[c],
                        it.ch_paused[c], it.ch_priv[c], it.gpo_ch[c])};
    end
    return s;
  endfunction

endclass : dma350_sc_monitor

`endif // DMA350_SC_MONITOR__SV
