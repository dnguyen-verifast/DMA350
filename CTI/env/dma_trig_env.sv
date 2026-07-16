//============================================================================
// dma_trig_env.sv
// Peripheral-VIP environment. Instantiates NUM_TRIGGER_IN trig-in (requester)
// agents and NUM_TRIGGER_OUT trig-out (responder) agents -- one agent per
// physical port, matching the configurable, separate port counts of the
// DMA-350. A single scoreboard receives every trig-in and trig-out monitor.
//
//   env
//    |- in_agent[0..NUM_TRIGGER_IN-1]   (dma_trig_in_agent : requester)
//    |- out_agent[0..NUM_TRIGGER_OUT-1] (dma_trig_out_agent : responder)
//    |- vseqr (in_sqr[], out_sqr[])
//    \- sb    (in monitors -> in_imp, out monitors -> out_imp)
//
// Counts come from config DB ints "num_trig_in" / "num_trig_out" (default 1).
// Virtual interfaces come from typed keys trig_in_vif_<i> / trig_out_vif_<i>.
// A template cfg (key "cfg") supplies mode / blk_size / coverage enable.
//
// LUU Y kien truc interface (sau khi them dma_trig_if):
//   * cong trig-in  dung interface TONG dma_trig_if (6 signal). Tren cong
//     in-only cua tb standalone, phan trig-out cua interface duoc stub tie 0
//     nen luong auto-ack trong driver khong bao gio kich hoat.
//   * cong trig-out van dung dma_trig_out_if + dma_trig_out_agent rieng, de
//     giu duoc cac test stall / SW-ack cua VIP.
//   (Trong testbench DMA-350 that: 1 dma_trig_if = 1 cap <TI>/<TO>, khong dung
//    agent trig-out - driver trig-in tu auto-ack.)
//============================================================================
`ifndef DMA_TRIG_ENV_SV
`define DMA_TRIG_ENV_SV

class dma_trig_env extends uvm_env;

  `uvm_component_utils(dma_trig_env)

  int unsigned          num_in  = 1;
  int unsigned          num_out = 1;
  dma_trig_cfg          tmpl;

  dma_trig_in_agent     in_agent[];
  dma_trig_out_agent    out_agent[];
  dma_trig_vseqr        vseqr;
  dma_trig_scoreboard   sb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    void'(uvm_config_db#(int unsigned)::get(this, "", "num_trig_in",  num_in));
    void'(uvm_config_db#(int unsigned)::get(this, "", "num_trig_out", num_out));
    if (!uvm_config_db#(dma_trig_cfg)::get(this, "", "cfg", tmpl))
      tmpl = dma_trig_cfg::type_id::create("tmpl");

    // Scoreboard takes its ack-semantics mode from the template cfg.
    uvm_config_db#(dma_trig_cfg)::set(this, "sb", "cfg", tmpl);
    sb    = dma_trig_scoreboard::type_id::create("sb", this);
    vseqr = dma_trig_vseqr::type_id::create("vseqr", this);

    in_agent      = new[num_in];
    out_agent     = new[num_out];
    vseqr.in_sqr  = new[num_in];
    vseqr.out_sqr = new[num_out];

    for (int i = 0; i < num_in; i++) begin
      virtual dma_trig_if vif;
      dma_trig_cfg c = dma_trig_cfg::type_id::create($sformatf("in_cfg_%0d", i));
      c.copy(tmpl); c.port_id = i;
      if (!uvm_config_db#(virtual dma_trig_if)::get(
              this, "", $sformatf("trig_in_vif_%0d", i), vif))
        `uvm_fatal(get_type_name(), $sformatf("trig_in_vif_%0d not set", i))
      uvm_config_db#(dma_trig_cfg)::set(this, $sformatf("in_agent_%0d", i), "cfg", c);
      uvm_config_db#(virtual dma_trig_if)::set(
          this, $sformatf("in_agent_%0d", i), "vif", vif);
      in_agent[i] = dma_trig_in_agent::type_id::create($sformatf("in_agent_%0d", i), this);
    end

    for (int i = 0; i < num_out; i++) begin
      virtual dma_trig_out_if vif;
      dma_trig_cfg c = dma_trig_cfg::type_id::create($sformatf("out_cfg_%0d", i));
      c.copy(tmpl); c.port_id = i;
      if (!uvm_config_db#(virtual dma_trig_out_if)::get(
              this, "", $sformatf("trig_out_vif_%0d", i), vif))
        `uvm_fatal(get_type_name(), $sformatf("trig_out_vif_%0d not set", i))
      uvm_config_db#(dma_trig_cfg)::set(this, $sformatf("out_agent_%0d", i), "cfg", c);
      uvm_config_db#(virtual dma_trig_out_if)::set(
          this, $sformatf("out_agent_%0d", i), "vif", vif);
      out_agent[i] = dma_trig_out_agent::type_id::create($sformatf("out_agent_%0d", i), this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    foreach (in_agent[i])  begin
      in_agent[i].ap.connect(sb.in_imp);
      vseqr.in_sqr[i] = in_agent[i].sqr;
    end
    foreach (out_agent[i]) begin
      out_agent[i].ap.connect(sb.out_imp);
      vseqr.out_sqr[i] = out_agent[i].sqr;
    end
  endfunction

endclass : dma_trig_env

`endif // DMA_TRIG_ENV_SV
