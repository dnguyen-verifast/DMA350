`ifndef DMA350_BASE_TEST_INCLUDED_
`define DMA350_BASE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: dma350_base_test
// Base test cua DMA-350: dung config co ban cho tung agent va set config xuong config_db
// theo DUNG KEY ma dma350_env.build_phase doc. Sequence do test dan xuat tao/chay.
//--------------------------------------------------------------------------------------------
class dma350_base_test extends uvm_test;

  `uvm_component_utils(dma350_base_test)

  // Variable: dma350_env_h
  // Handle for environment
  dma350_env dma350_env_h;

  // Tham so build (khop RTL config params)
  localparam int  NUM_CH = 8;
  localparam bit  SECEXT = 1;

  //-------------------------------------------------------
  // Config handle cho tung agent
  //-------------------------------------------------------
  axi5_slave_agent_config axi5_slave_cfg_h[2];
  axis_master_cfg         axis_master_cfg_h;
  axis_slave_cfg          axis_slave_cfg_h;
  boot_agent_cfg          boot_cfg_h;
  dma_irq_config#()       dma_irq_cfg_h;
  crlp_config             crlp_cfg_h;
  dma350_sc_cfg           dma350_sc_cfg_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "dma350_base_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void setup_dma350_env_cfg();
  extern virtual function void setup_axi5_slave_agent_cfg();
  extern virtual function void setup_axis_master_agent_cfg();
  extern virtual function void setup_axis_slave_agent_cfg();
  extern virtual function void setup_apb_master_agent_cfg();
  extern virtual function void setup_boot_agent_cfg();
  extern virtual function void setup_dma_irq_agent_cfg();
  extern virtual function void setup_crlp_agent_cfg();
  extern virtual function void setup_status_control_agent_cfg();
  extern virtual function void setup_scoreboard_cfg();
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : dma350_base_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function dma350_base_test::new(string name = "dma350_base_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//  Dung tat ca config roi tao env
//--------------------------------------------------------------------------------------------
function void dma350_base_test::build_phase(uvm_phase phase);
  super.build_phase(phase);

  // Setup toan bo config (goi cac setup con)
  setup_dma350_env_cfg();

  dma350_env_h = dma350_env::type_id::create("dma350_env_h", this);
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: setup_dma350_env_cfg
//  Goi setup cho tung agent + scoreboard
//--------------------------------------------------------------------------------------------
function void dma350_base_test::setup_dma350_env_cfg();
  setup_axi5_slave_agent_cfg();
  setup_axis_master_agent_cfg();
  setup_axis_slave_agent_cfg();
  setup_apb_master_agent_cfg();
  setup_boot_agent_cfg();
  setup_dma_irq_agent_cfg();
  setup_crlp_agent_cfg();
  setup_status_control_agent_cfg();
  setup_scoreboard_cfg();
endfunction : setup_dma350_env_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi5_slave_agent_cfg
//  2 AXI5 slave (M0/M1 data-path). Dung BFM o hdl_top (khong giu vif trong cfg).
//--------------------------------------------------------------------------------------------
function void dma350_base_test::setup_axi5_slave_agent_cfg();
  foreach (axi5_slave_cfg_h[i]) begin
    axi5_slave_cfg_h[i] =
      axi5_slave_agent_config::type_id::create($sformatf("axi5_slave_cfg_h[%0d]", i));
    axi5_slave_cfg_h[i].is_active    = uvm_active_passive_enum'(UVM_ACTIVE);
    axi5_slave_cfg_h[i].has_coverage = 1;
  end
  // Key khop dma350_env.build_phase : axi5_slave_agent_config0 / ...config1
  uvm_config_db#(axi5_slave_agent_config)::set(this,"*","axi5_slave_agent_config0", axi5_slave_cfg_h[0]);
  uvm_config_db#(axi5_slave_agent_config)::set(this,"*","axi5_slave_agent_config1", axi5_slave_cfg_h[1]);
  `uvm_info(get_type_name(),"AXI5 slave x2 cfg set (TODO: wire hdl_top BFM)",UVM_LOW);
endfunction : setup_axi5_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axis_master_agent_cfg
//  AXI-Stream IN (peripheral -> DMA)
//--------------------------------------------------------------------------------------------
function void dma350_base_test::setup_axis_master_agent_cfg();
  virtual axi_stream_if vif;
  if (!uvm_config_db#(virtual axi_stream_if)::get(this,"","axis_if_in",vif))
    `uvm_fatal("NOVIF","axis_if_in chua duoc set tu tb_top")
  axis_master_cfg_h = axis_master_cfg::type_id::create("axis_master_cfg_h");
  axis_master_cfg_h.vif       = vif;
  axis_master_cfg_h.is_active = uvm_active_passive_enum'(UVM_ACTIVE);
  uvm_config_db#(axis_master_cfg)::set(this,"*","axis_master_cfg_in", axis_master_cfg_h);
endfunction : setup_axis_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axis_slave_agent_cfg
//  AXI-Stream OUT (DMA -> peripheral)
//--------------------------------------------------------------------------------------------
function void dma350_base_test::setup_axis_slave_agent_cfg();
  virtual axi_stream_if vif;
  if (!uvm_config_db#(virtual axi_stream_if)::get(this,"","axis_if_out",vif))
    `uvm_fatal("NOVIF","axis_if_out chua duoc set tu tb_top")
  axis_slave_cfg_h = axis_slave_cfg::type_id::create("axis_slave_cfg_h");
  axis_slave_cfg_h.vif       = vif;
  axis_slave_cfg_h.is_active = uvm_active_passive_enum'(UVM_ACTIVE);
  uvm_config_db#(axis_slave_cfg)::set(this,"*","axis_slave_cfg_out", axis_slave_cfg_h);
endfunction : setup_axis_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_apb_master_agent_cfg
//  APB register bus. apb_agent_master khong get cfg, chi can virtual apb_interface
//  key "apb_if" (apb_driver_master/apb_monitor_master get truc tiep).
//--------------------------------------------------------------------------------------------
function void dma350_base_test::setup_apb_master_agent_cfg();
  virtual apb_interface vif;
  if (!uvm_config_db#(virtual apb_interface)::get(this,"","apb_vif",vif))
    `uvm_fatal("NOVIF","apb_vif chua duoc set tu tb_top")
  uvm_config_db#(virtual apb_interface)::set(this,"*","apb_if", vif);
endfunction : setup_apb_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_boot_agent_cfg
//--------------------------------------------------------------------------------------------
function void dma350_base_test::setup_boot_agent_cfg();
  virtual boot_if vif;
  if (!uvm_config_db#(virtual boot_if)::get(this,"","boot_vif",vif))
    `uvm_fatal("NOVIF","boot_vif chua duoc set tu tb_top")
  boot_cfg_h = boot_agent_cfg::type_id::create("boot_cfg_h");
  boot_cfg_h.vif            = vif;
  boot_cfg_h.is_active      = uvm_active_passive_enum'(UVM_ACTIVE);
  boot_cfg_h.secext_present = SECEXT;
  uvm_config_db#(boot_agent_cfg)::set(this,"*","boot_agent_cfg", boot_cfg_h);
endfunction : setup_boot_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_dma_irq_agent_cfg
//  IRQ luon passive (chi quan sat).
//--------------------------------------------------------------------------------------------
function void dma350_base_test::setup_dma_irq_agent_cfg();
  virtual dma_irq_if vif;
  if (!uvm_config_db#(virtual dma_irq_if)::get(this,"","irq_vif",vif))
    `uvm_fatal("NOVIF","irq_vif chua duoc set tu tb_top")
  dma_irq_cfg_h = dma_irq_config#()::type_id::create("dma_irq_cfg_h");
  dma_irq_cfg_h.vif       = vif;
  dma_irq_cfg_h.is_active = uvm_active_passive_enum'(UVM_PASSIVE);
  uvm_config_db#(dma_irq_config#())::set(this,"*","dma_irq_config", dma_irq_cfg_h);
endfunction : setup_dma_irq_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_crlp_agent_cfg
//  Clock / Reset / Low-Power
//--------------------------------------------------------------------------------------------
function void dma350_base_test::setup_crlp_agent_cfg();
  virtual crlp_if vif;
  if (!uvm_config_db#(virtual crlp_if)::get(this,"","crlp_vif",vif))
    `uvm_fatal("NOVIF","crlp_vif chua duoc set tu tb_top")
  crlp_cfg_h = crlp_config::type_id::create("crlp_cfg_h");
  crlp_cfg_h.vif       = vif;
  crlp_cfg_h.is_active = uvm_active_passive_enum'(UVM_ACTIVE);
  uvm_config_db#(crlp_config)::set(this,"*","crlp_config", crlp_cfg_h);
endfunction : setup_crlp_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_status_control_agent_cfg
//  Status/Control. cfg khong giu vif; monitor/driver get virtual dma350_sc_if.MON/.DRV
//  key "vif" truc tiep.
//--------------------------------------------------------------------------------------------
function void dma350_base_test::setup_status_control_agent_cfg();
  virtual dma350_sc_if vif;
  if (!uvm_config_db#(virtual dma350_sc_if)::get(this,"","sc_vif",vif))
    `uvm_fatal("NOVIF","sc_vif chua duoc set tu tb_top")
  dma350_sc_cfg_h = dma350_sc_cfg::type_id::create("dma350_sc_cfg_h");
  dma350_sc_cfg_h.is_active      = uvm_active_passive_enum'(UVM_ACTIVE);
  dma350_sc_cfg_h.secext_present = SECEXT;
  dma350_sc_cfg_h.num_channels   = NUM_CH;
  uvm_config_db#(dma350_sc_cfg)::set(this,"*","dma350_sc_cfg", dma350_sc_cfg_h);
  // vif co modport cho monitor va driver
  uvm_config_db#(virtual dma350_sc_if.MON)::set(this,"*","vif", vif);
  uvm_config_db#(virtual dma350_sc_if.DRV)::set(this,"*","vif", vif);
endfunction : setup_status_control_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_scoreboard_cfg
//  Scoreboard can sc_vif (dinh thoi peek) + num_channels.
//--------------------------------------------------------------------------------------------
function void dma350_base_test::setup_scoreboard_cfg();
  virtual dma350_sc_if vif;
  if (uvm_config_db#(virtual dma350_sc_if)::get(this,"","sc_vif",vif))
    uvm_config_db#(virtual dma350_sc_if)::set(this,"*","sc_vif", vif);
  uvm_config_db#(int)::set(this,"*","num_channels", NUM_CH);
endfunction : setup_scoreboard_cfg

//--------------------------------------------------------------------------------------------
// Function: end_of_elaboration_phase
//  In topology testbench
//--------------------------------------------------------------------------------------------
function void dma350_base_test::end_of_elaboration_phase(uvm_phase phase);
  uvm_top.print_topology();
endfunction : end_of_elaboration_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//  Delay co ban; test dan xuat override de chay sequence that.
//--------------------------------------------------------------------------------------------
task dma350_base_test::run_phase(uvm_phase phase);
  phase.raise_objection(this, "dma350_base_test");
  `uvm_info(get_type_name(), "Inside DMA350_BASE_TEST (chua co stimulus)", UVM_NONE);
  super.run_phase(phase);
  #1us;
  `uvm_info(get_type_name(), "Done DMA350_BASE_TEST", UVM_NONE);
  phase.drop_objection(this);
endtask : run_phase

`endif // DMA350_BASE_TEST_INCLUDED_
