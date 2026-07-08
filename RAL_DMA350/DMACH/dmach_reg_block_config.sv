class dmach_reg_block_config extends uvm_reg_block;
    rand ch_cmd_reg          ch_cmd;
    rand ch_status_reg       ch_status;
    rand ch_intren_reg       ch_intren;
    rand ch_ctrl_reg         ch_ctrl;
    rand ch_srcaddr_reg      ch_srcaddr;
    rand ch_srcaddrhi_reg    ch_srcaddrhi;
    rand ch_desaddr_reg      ch_desaddr;
    rand ch_desaddrhi_reg    ch_desaddrhi;
    rand ch_xsize_reg        ch_xsize;
    rand ch_xsizehi_reg      ch_xsizehi;
    rand ch_srctranscfg_reg  ch_srctranscfg;
    rand ch_destranscfg_reg  ch_destranscfg;
    rand ch_xaddrinc_reg     ch_xaddrinc;
    rand ch_yaddrstride_reg  ch_yaddrstride;
    rand ch_fillval_reg      ch_fillval;
    rand ch_ysize_reg        ch_ysize;
    rand ch_tmpltcfg_reg     ch_tmpltcfg;
    rand ch_srctmplt_reg     ch_srctmplt;
    rand ch_destmplt_reg     ch_destmplt;
    rand ch_srctrigincfg_reg ch_srctrigincfg;
    rand ch_destrigincfg_reg ch_destrigincfg;
    rand ch_trigoutcfg_reg   ch_trigoutcfg;
    rand ch_gpoen0_reg       ch_gpoen0;
    rand ch_gpoval0_reg      ch_gpoval0;
    rand ch_streamintcfg_reg ch_streamintcfg;
    rand ch_linkattr_reg     ch_linkattr;
    rand ch_autocfg_reg      ch_autocfg;
    rand ch_linkaddr_reg     ch_linkaddr;
    rand ch_linkaddrhi_reg   ch_linkaddrhi;
    rand ch_gporead0_reg     ch_gporead0;
    rand ch_wrkregptr_reg    ch_wrkregptr;
    rand ch_wrkregval_reg    ch_wrkregval;
    rand ch_errinfo_reg      ch_errinfo;
    rand ch_iidr_reg         ch_iidr;
    rand ch_aidr_reg         ch_aidr;
    rand ch_issuecap_reg     ch_issuecap;
    rand ch_buildcfg0_reg    ch_buildcfg0;
    rand ch_buildcfg1_reg    ch_buildcfg1;


    `uvm_object_utils(dmach_reg_block_config)
    function new(string name = "dmach_reg_block_config");
        super.new(name,build_coverage(UVM_NO_COVERAGE));
    endfunction
    virtual function void build();
        this.default_map = create_map(.name("DMACH"),
                                        .base_addr(16'h1000),
                                        .n_bytes(256),
                                        .endian(UVM_LITTLE_ENDIAN),
                                        .byte_addressing(0));
        this.ch_cmd = ch_cmd_reg::type_id::create("ch_cmd",, get_full_name());
        this.ch_cmd.configure(.blk_parent(this),
                                .regfile_parent(null),
                                .hdl_path(""));
        this.ch_cmd.build();
        this.default_map.add_reg(.rg(this.ch_cmd),
                                    .offset(`UVM_REG_ADDR_WIDTH'h000),
                                    .rights("RW"),
                                    .unmapped(0),
                                    .frontdoor(null));

        this.ch_intren = ch_intren_reg::type_id::create("ch_intren_reg",, get_full_name());
        this.ch_intren.configure(.blk_parent(this),
                                    .regfile_parent(null),
                                    .hdl_path(""));
        this.ch_intren.build();
        this.default_map.add_reg(.rg(this.ch_intren),
                                    .offset(`UVM_REG_ADDR_WIDTH'h008),
                                    .rights("RW"),
                                    .unmapped(0),
                                    .frontdoor(null));

        this.ch_status = ch_status_reg::type_id::create("ch_status",, get_full_name());
        this.ch_status.configure(this, null, "");
        this.ch_status.build();
        this.default_map.add_reg(this.ch_status, `UVM_REG_ADDR_WIDTH'h004, "RW", 0, null);

        this.ch_ctrl = ch_ctrl_reg::type_id::create("ch_ctrl",, get_full_name());
        this.ch_ctrl.configure(this, null, "");
        this.ch_ctrl.build();
        this.default_map.add_reg(this.ch_ctrl, `UVM_REG_ADDR_WIDTH'h00C, "RW", 0, null);

        this.ch_srcaddr = ch_srcaddr_reg::type_id::create("ch_srcaddr",, get_full_name());
        this.ch_srcaddr.configure(this, null, "");
        this.ch_srcaddr.build();
        this.default_map.add_reg(this.ch_srcaddr, `UVM_REG_ADDR_WIDTH'h010, "RW", 0, null);

        this.ch_srcaddrhi = ch_srcaddrhi_reg::type_id::create("ch_srcaddrhi",, get_full_name());
        this.ch_srcaddrhi.configure(this, null, "");
        this.ch_srcaddrhi.build();
        this.default_map.add_reg(this.ch_srcaddrhi, `UVM_REG_ADDR_WIDTH'h014, "RW", 0, null);

        this.ch_desaddr = ch_desaddr_reg::type_id::create("ch_desaddr",, get_full_name());
        this.ch_desaddr.configure(this, null, "");
        this.ch_desaddr.build();
        this.default_map.add_reg(this.ch_desaddr, `UVM_REG_ADDR_WIDTH'h018, "RW", 0, null);

        this.ch_desaddrhi = ch_desaddrhi_reg::type_id::create("ch_desaddrhi",, get_full_name());
        this.ch_desaddrhi.configure(this, null, "");
        this.ch_desaddrhi.build();
        this.default_map.add_reg(this.ch_desaddrhi, `UVM_REG_ADDR_WIDTH'h01C, "RW", 0, null);

        this.ch_xsize = ch_xsize_reg::type_id::create("ch_xsize",, get_full_name());
        this.ch_xsize.configure(this, null, "");
        this.ch_xsize.build();
        this.default_map.add_reg(this.ch_xsize, `UVM_REG_ADDR_WIDTH'h020, "RW", 0, null);

        this.ch_xsizehi = ch_xsizehi_reg::type_id::create("ch_xsizehi",, get_full_name());
        this.ch_xsizehi.configure(this, null, "");
        this.ch_xsizehi.build();
        this.default_map.add_reg(this.ch_xsizehi, `UVM_REG_ADDR_WIDTH'h024, "RW", 0, null);

        this.ch_srctranscfg = ch_srctranscfg_reg::type_id::create("ch_srctranscfg",, get_full_name());
        this.ch_srctranscfg.configure(this, null, "");
        this.ch_srctranscfg.build();
        this.default_map.add_reg(this.ch_srctranscfg, `UVM_REG_ADDR_WIDTH'h028, "RW", 0, null);

        this.ch_destranscfg = ch_destranscfg_reg::type_id::create("ch_destranscfg",, get_full_name());
        this.ch_destranscfg.configure(this, null, "");
        this.ch_destranscfg.build();
        this.default_map.add_reg(this.ch_destranscfg, `UVM_REG_ADDR_WIDTH'h02C, "RW", 0, null);

        this.ch_xaddrinc = ch_xaddrinc_reg::type_id::create("ch_xaddrinc",, get_full_name());
        this.ch_xaddrinc.configure(this, null, "");
        this.ch_xaddrinc.build();
        this.default_map.add_reg(this.ch_xaddrinc, `UVM_REG_ADDR_WIDTH'h030, "RW", 0, null);

        this.ch_yaddrstride = ch_yaddrstride_reg::type_id::create("ch_yaddrstride",, get_full_name());
        this.ch_yaddrstride.configure(this, null, "");
        this.ch_yaddrstride.build();
        this.default_map.add_reg(this.ch_yaddrstride, `UVM_REG_ADDR_WIDTH'h034, "RW", 0, null);

        this.ch_fillval = ch_fillval_reg::type_id::create("ch_fillval",, get_full_name());
        this.ch_fillval.configure(this, null, "");
        this.ch_fillval.build();
        this.default_map.add_reg(this.ch_fillval, `UVM_REG_ADDR_WIDTH'h038, "RW", 0, null);

        this.ch_ysize = ch_ysize_reg::type_id::create("ch_ysize",, get_full_name());
        this.ch_ysize.configure(this, null, "");
        this.ch_ysize.build();
        this.default_map.add_reg(this.ch_ysize, `UVM_REG_ADDR_WIDTH'h03C, "RW", 0, null);

        this.ch_tmpltcfg = ch_tmpltcfg_reg::type_id::create("ch_tmpltcfg",, get_full_name());
        this.ch_tmpltcfg.configure(this, null, "");
        this.ch_tmpltcfg.build();
        this.default_map.add_reg(this.ch_tmpltcfg, `UVM_REG_ADDR_WIDTH'h040, "RW", 0, null);

        this.ch_srctmplt = ch_srctmplt_reg::type_id::create("ch_srctmplt",, get_full_name());
        this.ch_srctmplt.configure(this, null, "");
        this.ch_srctmplt.build();
        this.default_map.add_reg(this.ch_srctmplt, `UVM_REG_ADDR_WIDTH'h044, "RW", 0, null);

        this.ch_destmplt = ch_destmplt_reg::type_id::create("ch_destmplt",, get_full_name());
        this.ch_destmplt.configure(this, null, "");
        this.ch_destmplt.build();
        this.default_map.add_reg(this.ch_destmplt, `UVM_REG_ADDR_WIDTH'h048, "RW", 0, null);

        this.ch_srctrigincfg = ch_srctrigincfg_reg::type_id::create("ch_srctrigincfg",, get_full_name());
        this.ch_srctrigincfg.configure(this, null, "");
        this.ch_srctrigincfg.build();
        this.default_map.add_reg(this.ch_srctrigincfg, `UVM_REG_ADDR_WIDTH'h04C, "RW", 0, null);

        this.ch_destrigincfg = ch_destrigincfg_reg::type_id::create("ch_destrigincfg",, get_full_name());
        this.ch_destrigincfg.configure(this, null, "");
        this.ch_destrigincfg.build();
        this.default_map.add_reg(this.ch_destrigincfg, `UVM_REG_ADDR_WIDTH'h050, "RW", 0, null);

        this.ch_trigoutcfg = ch_trigoutcfg_reg::type_id::create("ch_trigoutcfg",, get_full_name());
        this.ch_trigoutcfg.configure(this, null, "");
        this.ch_trigoutcfg.build();
        this.default_map.add_reg(this.ch_trigoutcfg, `UVM_REG_ADDR_WIDTH'h054, "RW", 0, null);

        this.ch_gpoen0 = ch_gpoen0_reg::type_id::create("ch_gpoen0",, get_full_name());
        this.ch_gpoen0.configure(this, null, "");
        this.ch_gpoen0.build();
        this.default_map.add_reg(this.ch_gpoen0, `UVM_REG_ADDR_WIDTH'h058, "RW", 0, null);

        this.ch_gpoval0 = ch_gpoval0_reg::type_id::create("ch_gpoval0",, get_full_name());
        this.ch_gpoval0.configure(this, null, "");
        this.ch_gpoval0.build();
        this.default_map.add_reg(this.ch_gpoval0, `UVM_REG_ADDR_WIDTH'h060, "RW", 0, null);

        this.ch_streamintcfg = ch_streamintcfg_reg::type_id::create("ch_streamintcfg",, get_full_name());
        this.ch_streamintcfg.configure(this, null, "");
        this.ch_streamintcfg.build();
        this.default_map.add_reg(this.ch_streamintcfg, `UVM_REG_ADDR_WIDTH'h068, "RW", 0, null);

        this.ch_linkattr = ch_linkattr_reg::type_id::create("ch_linkattr",, get_full_name());
        this.ch_linkattr.configure(this, null, "");
        this.ch_linkattr.build();
        this.default_map.add_reg(this.ch_linkattr, `UVM_REG_ADDR_WIDTH'h070, "RW", 0, null);

        this.ch_autocfg = ch_autocfg_reg::type_id::create("ch_autocfg",, get_full_name());
        this.ch_autocfg.configure(this, null, "");
        this.ch_autocfg.build();
        this.default_map.add_reg(this.ch_autocfg, `UVM_REG_ADDR_WIDTH'h074, "RW", 0, null);

        this.ch_linkaddr = ch_linkaddr_reg::type_id::create("ch_linkaddr",, get_full_name());
        this.ch_linkaddr.configure(this, null, "");
        this.ch_linkaddr.build();
        this.default_map.add_reg(this.ch_linkaddr, `UVM_REG_ADDR_WIDTH'h078, "RW", 0, null);

        this.ch_linkaddrhi = ch_linkaddrhi_reg::type_id::create("ch_linkaddrhi",, get_full_name());
        this.ch_linkaddrhi.configure(this, null, "");
        this.ch_linkaddrhi.build();
        this.default_map.add_reg(this.ch_linkaddrhi, `UVM_REG_ADDR_WIDTH'h07C, "RW", 0, null);

        this.ch_gporead0 = ch_gporead0_reg::type_id::create("ch_gporead0",, get_full_name());
        this.ch_gporead0.configure(this, null, "");
        this.ch_gporead0.build();
        this.default_map.add_reg(this.ch_gporead0, `UVM_REG_ADDR_WIDTH'h080, "RO", 0, null);

        this.ch_wrkregptr = ch_wrkregptr_reg::type_id::create("ch_wrkregptr",, get_full_name());
        this.ch_wrkregptr.configure(this, null, "");
        this.ch_wrkregptr.build();
        this.default_map.add_reg(this.ch_wrkregptr, `UVM_REG_ADDR_WIDTH'h088, "RW", 0, null);

        this.ch_wrkregval = ch_wrkregval_reg::type_id::create("ch_wrkregval",, get_full_name());
        this.ch_wrkregval.configure(this, null, "");
        this.ch_wrkregval.build();
        this.default_map.add_reg(this.ch_wrkregval, `UVM_REG_ADDR_WIDTH'h08C, "RO", 0, null);

        this.ch_errinfo = ch_errinfo_reg::type_id::create("ch_errinfo",, get_full_name());
        this.ch_errinfo.configure(this, null, "");
        this.ch_errinfo.build();
        this.default_map.add_reg(this.ch_errinfo, `UVM_REG_ADDR_WIDTH'h090, "RO", 0, null);

        this.ch_iidr = ch_iidr_reg::type_id::create("ch_iidr",, get_full_name());
        this.ch_iidr.configure(this, null, "");
        this.ch_iidr.build();
        this.default_map.add_reg(this.ch_iidr, `UVM_REG_ADDR_WIDTH'h0C8, "RO", 0, null);

        this.ch_aidr = ch_aidr_reg::type_id::create("ch_aidr",, get_full_name());
        this.ch_aidr.configure(this, null, "");
        this.ch_aidr.build();
        this.default_map.add_reg(this.ch_aidr, `UVM_REG_ADDR_WIDTH'h0CC, "RO", 0, null);

        this.ch_issuecap = ch_issuecap_reg::type_id::create("ch_issuecap",, get_full_name());
        this.ch_issuecap.configure(this, null, "");
        this.ch_issuecap.build();
        this.default_map.add_reg(this.ch_issuecap, `UVM_REG_ADDR_WIDTH'h0E8, "RW", 0, null);

        this.ch_buildcfg0 = ch_buildcfg0_reg::type_id::create("ch_buildcfg0",, get_full_name());
        this.ch_buildcfg0.configure(this, null, "");
        this.ch_buildcfg0.build();
        this.default_map.add_reg(this.ch_buildcfg0, `UVM_REG_ADDR_WIDTH'h0F8, "RO", 0, null);

        this.ch_buildcfg1 = ch_buildcfg1_reg::type_id::create("ch_buildcfg1",, get_full_name());
        this.ch_buildcfg1.configure(this, null, "");
        this.ch_buildcfg1.build();
        this.default_map.add_reg(this.ch_buildcfg1, `UVM_REG_ADDR_WIDTH'h0FC, "RO", 0, null);

        //=====================================================================
        // HDL PATH (BACKDOOR) : map moi thanh ghi vao bien storage that trong
        // RTL dma350_ch_regs.sv (instance: <hdl_root>.g_ch[0].u_regs.<ten>).
        // add_hdl_path_slice(ten_bien_RTL, lsb_trong_thanh_ghi, so_bit).
        //
        // Thanh ghi KHONG co storage (hang so localparam / khong model):
        //   CH_IIDR, CH_AIDR, CH_BUILDCFG0/1, CH_WRKREGVAL -> khong gan path
        //   (peek se fallback frontdoor mirror trong scoreboard).
        //=====================================================================
        // CH_CMD 0x00 : cac bit lenh + SW trigger (pulse/sticky regs)
        this.ch_cmd.add_hdl_path_slice("enablecmd",      0, 1);
        this.ch_cmd.add_hdl_path_slice("clearcmd",       1, 1);
        this.ch_cmd.add_hdl_path_slice("disablecmd",     2, 1);
        this.ch_cmd.add_hdl_path_slice("stopcmd",        3, 1);
        this.ch_cmd.add_hdl_path_slice("pausecmd",       4, 1);
        this.ch_cmd.add_hdl_path_slice("resumecmd",      5, 1);
        this.ch_cmd.add_hdl_path_slice("swtrigin_src",     16, 1);
        this.ch_cmd.add_hdl_path_slice("swtrigin_srctype", 17, 2);
        this.ch_cmd.add_hdl_path_slice("swtrigin_des",     20, 1);
        this.ch_cmd.add_hdl_path_slice("swtrigin_destype", 21, 2);
        this.ch_cmd.add_hdl_path_slice("swtrigout_ack",    24, 1);

        // CH_STATUS 0x04 : sticky status bits (INTR_*/FSM-wait la to hop -> bo)
        this.ch_status.add_hdl_path_slice("stat_done",     16, 1);
        this.ch_status.add_hdl_path_slice("stat_err",      17, 1);
        this.ch_status.add_hdl_path_slice("stat_stopped",  18, 1);
        this.ch_status.add_hdl_path_slice("stat_disabled", 19, 1);
        this.ch_status.add_hdl_path_slice("stat_paused",   20, 1);

        // Cac thanh ghi config 32-bit -> storage *_q 1-1
        this.ch_intren      .add_hdl_path_slice("intren_q",       0, 32);
        this.ch_ctrl        .add_hdl_path_slice("ctrl_q",         0, 32);
        this.ch_srcaddr     .add_hdl_path_slice("srcaddr",        0, 32); // live counter
        this.ch_srcaddrhi   .add_hdl_path_slice("srcaddrhi_q",    0, 32);
        this.ch_desaddr     .add_hdl_path_slice("desaddr",        0, 32); // live counter
        this.ch_desaddrhi   .add_hdl_path_slice("desaddrhi_q",    0, 32);
        // CH_XSIZE 0x20 : {DESXSIZE[15:0], SRCXSIZE[15:0]} = {desxs_lo, srcxs_lo}
        this.ch_xsize       .add_hdl_path_slice("srcxs_lo",       0, 16);
        this.ch_xsize       .add_hdl_path_slice("desxs_lo",      16, 16);
        this.ch_xsizehi     .add_hdl_path_slice("xsizehi_q",      0, 32);
        this.ch_srctranscfg .add_hdl_path_slice("srctranscfg_q",  0, 32);
        this.ch_destranscfg .add_hdl_path_slice("destranscfg_q",  0, 32);
        this.ch_xaddrinc    .add_hdl_path_slice("xaddrinc_q",     0, 32);
        this.ch_yaddrstride .add_hdl_path_slice("yaddrstride_q",  0, 32);
        this.ch_fillval     .add_hdl_path_slice("fillval_q",      0, 32);
        this.ch_ysize       .add_hdl_path_slice("ysize_q",        0, 32);
        this.ch_tmpltcfg    .add_hdl_path_slice("tmpltcfg_q",     0, 32);
        this.ch_srctmplt    .add_hdl_path_slice("srctmplt_q",     0, 32);
        this.ch_destmplt    .add_hdl_path_slice("destmplt_q",     0, 32);
        this.ch_srctrigincfg.add_hdl_path_slice("srctrigincfg_q", 0, 32);
        this.ch_destrigincfg.add_hdl_path_slice("destrigincfg_q", 0, 32);
        this.ch_trigoutcfg  .add_hdl_path_slice("trigoutcfg_q",   0, 32);
        this.ch_gpoen0      .add_hdl_path_slice("gpoen0_q",       0, 32);
        this.ch_gpoval0     .add_hdl_path_slice("gpoval0_q",      0, 32);
        this.ch_streamintcfg.add_hdl_path_slice("streamintcfg_q", 0, 32);
        this.ch_linkattr    .add_hdl_path_slice("linkattr_q",     0, 32);
        // CH_AUTOCFG 0x74 : {15'b0, CMDRESTARTINFEN, CMDRESTARTCNT[15:0]}
        this.ch_autocfg     .add_hdl_path_slice("cmdrestartcnt",   0, 16);
        this.ch_autocfg     .add_hdl_path_slice("cmdrestartinfen", 16, 1);
        this.ch_linkaddr    .add_hdl_path_slice("linkaddr",       0, 32);
        this.ch_linkaddrhi  .add_hdl_path_slice("linkaddrhi_q",   0, 32);
        // CH_GPOREAD0 0x80 : gia tri GPO dang giu (GPO_WIDTH=4 theo build DUT)
        this.ch_gporead0    .add_hdl_path_slice("gpo_out_q",      0, 4);
        this.ch_wrkregptr   .add_hdl_path_slice("wrkregptr_q",    0, 32);
        // CH_ERRINFO 0x90 : wire tu command engine (uvm_hdl doc net duoc)
        this.ch_errinfo     .add_hdl_path_slice("errinfo",        0, 32);
        this.ch_issuecap    .add_hdl_path_slice("issuecap_q",     0, 32);
    endfunction
endclass
