//------------------------------------------------------------------------------
// dma_irq_monitor.sv
// Monitor bat tin hieu interrupt output. Vi IRQ la level-based, ta sample
// moi clock va chi phat transaction khi trang thai interrupt thay doi.
//------------------------------------------------------------------------------
class dma_irq_monitor #(
  parameter int NUM_CHANNELS   = 8,
  parameter bit SECEXT_PRESENT = 1
) extends uvm_monitor;

  typedef dma_irq_item#(NUM_CHANNELS)                        item_t;
  typedef dma_irq_config#(NUM_CHANNELS, SECEXT_PRESENT)      cfg_t;
  typedef virtual dma_irq_if#(NUM_CHANNELS, SECEXT_PRESENT)  vif_t;

  vif_t vif;
  cfg_t cfg;

  // Analysis port phat transaction ra scoreboard/coverage
  uvm_analysis_port #(item_t) ap;

  // Luu trang thai truoc do de phat hien thay doi (edge tren level signal)
  bit [NUM_CHANNELS-1:0] prev_irq_channel;
  bit                    prev_comb_nonsec;
  bit                    prev_comb_sec;
  bit                    prev_sec_viol_err;

  `uvm_component_utils(dma_irq_monitor#(NUM_CHANNELS, SECEXT_PRESENT))

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(cfg_t)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "Khong lay duoc dma_irq_config tu config_db")
    vif = cfg.vif;
    if (vif == null)
      `uvm_fatal(get_type_name(), "Virtual interface (cfg.vif) chua duoc set")
  endfunction

  virtual task run_phase(uvm_phase phase);
    // Doi reset xong roi moi quan sat
    wait (vif.resetn === 1'b1);
    sample_reset_state();

    forever begin
      @(vif.mon_cb);

      // Neu bi reset giua chung -> clear baseline
      if (vif.resetn === 1'b0) begin
        wait (vif.resetn === 1'b1);
        sample_reset_state();
        continue;
      end

      collect_if_changed();
    end
  endtask

  // Ghi lai trang thai baseline sau reset (khong phat transaction)
  function void sample_reset_state();
    prev_irq_channel  = '0;
    prev_comb_nonsec  = 1'b0;
    prev_comb_sec     = 1'b0;
    prev_sec_viol_err = 1'b0;
  endfunction

  // So sanh voi trang thai cu; neu co bat ky thay doi thi tao & gui item
  function void collect_if_changed();
    bit [NUM_CHANNELS-1:0] ch;
    bit                    cn, cs, sv;
    item_t                 item;

    ch = vif.mon_cb.irq_channel;
    cn = vif.mon_cb.irq_comb_nonsec;
    // Khi khong co Security Extension thi 2 tin hieu nay khong ton tai -> coi nhu 0
    cs = SECEXT_PRESENT ? vif.mon_cb.irq_comb_sec     : 1'b0;
    sv = SECEXT_PRESENT ? vif.mon_cb.irq_sec_viol_err : 1'b0;

    if ((ch !== prev_irq_channel) ||
        (cn !== prev_comb_nonsec) ||
        (cs !== prev_comb_sec)    ||
        (sv !== prev_sec_viol_err)) begin

      item = item_t::type_id::create("irq_item");
      item.irq_channel      = ch;
      item.irq_comb_nonsec  = cn;
      item.irq_comb_sec     = cs;
      item.irq_sec_viol_err = sv;
      item.sample_time      = $time;
      item.active_ch_id     = first_active_channel(ch);

      `uvm_info(get_type_name(),
                $sformatf("IRQ change: %s", item.convert2string()), UVM_MEDIUM)
      ap.write(item);

      // cap nhat baseline
      prev_irq_channel  = ch;
      prev_comb_nonsec  = cn;
      prev_comb_sec     = cs;
      prev_sec_viol_err = sv;
    end
  endfunction

  // Tra ve index channel thap nhat dang assert, -1 neu khong co
  function int first_active_channel(bit [NUM_CHANNELS-1:0] ch);
    for (int i = 0; i < NUM_CHANNELS; i++)
      if (ch[i]) return i;
    return -1;
  endfunction

endclass : dma_irq_monitor
