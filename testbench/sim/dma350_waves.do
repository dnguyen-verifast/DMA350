# =============================================================================
# dma350_waves.do  -  Layout + group cho waveform DMA-350 (Questa)
# -----------------------------------------------------------------------------
# .wlf chi luu DU LIEU tin hieu (do 'log -r /*' trong batch). Cau truc folder/
# group nam o day, chi ap khi VIEW:
#     vsim -view <test>/waveform.wlf -do dma350_waves.do
# hoac:  make waves test=<ten_test>
#
# Ten instance/interface duoi day khop dma350_tb_top HIEN TAI. Neu doi ten trong
# tb_top thi sua tuong ung. Kiem tra nhanh trong console Questa:
#     find instances /dma350_tb_top/*
#
# Luu y Tcl: chi so generate '[0]' phai escape '\[0\]' (khong thi Tcl coi la
# command-substitution). 'add wave' voi path khong ton tai chi WARNING, khong
# lam dung do-file -> an toan neu vai path lech ten.
# =============================================================================

quietly set TB /dma350_tb_top

delete wave *
configure wave -namecolwidth 250
configure wave -valuecolwidth 120
configure wave -timelineunits ns

# --- Clock & Reset : mo san vi luon can nhin (do CRLP agent sinh) ------------
add wave -expand -group {CLK_RST} \
    $TB/tb_clk \
    $TB/tb_resetn

# --- CRLP (clock/reset/low-power : Q-Channel + P-Channel) --------------------
add wave -group {CRLP} -r $TB/crlp_if_i/*

# --- APB4 register interface -------------------------------------------------
add wave -group {APB4} -r $TB/apb_if_i/*

# --- AXI5 M0 (read-path) : tach nhom con AW/W/B/AR/R -------------------------
add wave -group {AXI5_M0} -group {AW} -r $TB/axi5_m0_if/aw*
add wave -group {AXI5_M0} -group {W}  -r $TB/axi5_m0_if/w*
add wave -group {AXI5_M0} -group {B}  -r $TB/axi5_m0_if/b*
add wave -group {AXI5_M0} -group {AR} -r $TB/axi5_m0_if/ar*
add wave -group {AXI5_M0} -group {R}  -r $TB/axi5_m0_if/r*

# --- AXI5 M1 (write-path, M1_PRESENT=1) -------------------------------------
add wave -group {AXI5_M1} -group {AW} -r $TB/axi5_m1_if/aw*
add wave -group {AXI5_M1} -group {W}  -r $TB/axi5_m1_if/w*
add wave -group {AXI5_M1} -group {B}  -r $TB/axi5_m1_if/b*
add wave -group {AXI5_M1} -group {AR} -r $TB/axi5_m1_if/ar*
add wave -group {AXI5_M1} -group {R}  -r $TB/axi5_m1_if/r*

# --- AXI4-Stream : IN (peripheral->DMA) / OUT (DMA->peripheral) --------------
add wave -group {STREAM} -group {IN}  -r $TB/axis_in_if/*
add wave -group {STREAM} -group {OUT} -r $TB/axis_out_if/*

# --- IRQ / Status-Control / Boot --------------------------------------------
add wave -group {IRQ}          -r $TB/irq_if_i/*
add wave -group {STATUS_CTRL}  -r $TB/sc_if_i/*
add wave -group {BOOT}         -r $TB/boot_if_i/*

# --- DUT internals (generate g_ch[<n>] : u_regs = reg frame, u_ch = engine) --
# Chi bay CH0/CH1 (NUM_CHANNELS=8, log het se rat nang). Them CH khac neu can.
add wave -group {DUT} -group {CH0}      -r $TB/u_dut/g_ch\[0\]/*
add wave -group {DUT} -group {CH1}      -r $TB/u_dut/g_ch\[1\]/*
add wave -group {DUT} -group {REGS_CH0} -r $TB/u_dut/g_ch\[0\]/u_regs/*

wave zoom full
