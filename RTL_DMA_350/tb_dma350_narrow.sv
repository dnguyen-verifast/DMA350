//-----------------------------------------------------------------------------
// tb_dma350_narrow.sv  - narrow (1-byte unit) transfer with mismatched source
// and destination byte alignment. Exercises AxSIZE from TRANSIZE, per-beat
// byte-accurate WSTRB, and the byte-accumulator realignment (no width-aligned
// address assumption). A non-bus-multiple length is used on purpose; bytes
// outside the transfer must NOT be disturbed.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
`default_nettype none

module tb_dma350_narrow;
    localparam int DW = 32, AW = 32, BPB = DW/8;

    logic clk = 0, resetn = 0;
    always #5 clk = ~clk;

    logic psel=0, penable=0, pwrite=0;
    logic [12:0] paddr=0;
    logic [31:0] pwdata=0, prdata;
    logic [3:0]  pstrb=4'hF;
    logic pready, pslverr, irq_ns, irq_s, irq_ch;

    dma350_tb_harness #(.ADDR_WIDTH(AW), .DATA_WIDTH(DW), .NUM_CHANNELS(1)) h (
        .clk(clk), .resetn(resetn),
        .psel(psel), .penable(penable), .pwrite(pwrite), .paddr(paddr),
        .pwdata(pwdata), .pstrb(pstrb), .prdata(prdata),
        .pready(pready), .pslverr(pslverr),
        .irq_channel(irq_ch), .irq_comb_nonsec(irq_ns), .irq_comb_sec(irq_s)
    );

    localparam [7:0] CH_CMD=8'h00, CH_STATUS=8'h04, CH_CTRL=8'h0C,
                     CH_SRCADDR=8'h10, CH_DESADDR=8'h18, CH_XSIZE=8'h20,
                     CH_XADDRINC=8'h30;
    function automatic [12:0] reg_addr(input int ch, input [7:0] off);
        return {1'b1, 1'b0, ch[2:0], off};   // channel n at 0x1000 + 0x100*n
    endfunction
    task automatic apb_write(input [12:0] a, input [31:0] d);
        @(posedge clk); psel<=1; pwrite<=1; paddr<=a; pwdata<=d; pstrb<=4'hF; penable<=0;
        @(posedge clk); penable<=1;
        do @(posedge clk); while (!pready);
        psel<=0; penable<=0; pwrite<=0;
    endtask
    task automatic apb_read(input [12:0] a, output [31:0] d);
        @(posedge clk); psel<=1; pwrite<=0; paddr<=a; penable<=0;
        @(posedge clk); penable<=1;
        do @(posedge clk); while (!pready);
        d = prdata; psel<=0; penable<=0;
    endtask

    localparam int NBYTES = 30;                  // not a multiple of the bus width
    localparam [31:0] SRC = 32'h0000_1003;       // word-offset 3
    localparam [31:0] DST = 32'h0000_2001;       // word-offset 1 (different lane)
    int errors = 0;
    logic [31:0] rb;
    logic [7:0]  guard_before, guard_after;

    initial begin
        // fill the whole src/dst neighbourhood with a known background, then the
        // payload, so we can detect any stray writes outside [DST, DST+NBYTES).
        for (int i=0;i<256;i++) begin
            h.u_mem.mem[32'h1000+i] = 8'hA5;
            h.u_mem.mem[32'h2000+i] = 8'h5A;
        end
        for (int i=0;i<NBYTES;i++) h.u_mem.mem[SRC+i] = (i*11 + 7) & 8'hFF;
        guard_before = h.u_mem.mem[DST-1];
        guard_after  = h.u_mem.mem[DST+NBYTES];

        resetn=0; repeat(8) @(posedge clk); resetn=1; repeat(4) @(posedge clk);

        // DONETYPE=001 (bit21), XTYPE=continue, TRANSIZE=0
        apb_write(reg_addr(0,CH_CTRL),    32'h0020_0200);
        apb_write(reg_addr(0,CH_SRCADDR), SRC);
        apb_write(reg_addr(0,CH_DESADDR), DST);
        apb_write(reg_addr(0,CH_XADDRINC),32'h0001_0001);   // increment 1 unit / side
        apb_write(reg_addr(0,CH_XSIZE),   (NBYTES<<16)|NBYTES); // DES|SRC XSIZE
        apb_write(reg_addr(0,CH_CMD),     32'h0000_0001);

        fork
            begin do apb_read(reg_addr(0,CH_STATUS), rb); while (!rb[16]); end
            begin repeat(20000) @(posedge clk); $display("TIMEOUT"); errors++; end
        join_any
        disable fork;
        repeat(20) @(posedge clk);

        for (int i=0;i<NBYTES;i++) begin
            logic [7:0] e,g; e=h.u_mem.mem[SRC+i]; g=h.u_mem.mem[DST+i];
            if (e!==g) begin
                if (errors<16) $display("  byte %0d exp %02x got %02x", i, e, g);
                errors++;
            end
        end
        // adjacent bytes must be untouched (byte-accurate WSTRB)
        if (h.u_mem.mem[DST-1]       !== guard_before) begin
            $display("  guard byte BEFORE dst corrupted"); errors++; end
        if (h.u_mem.mem[DST+NBYTES]  !== guard_after)  begin
            $display("  guard byte AFTER dst corrupted");  errors++; end

        if (errors==0) $display("\n*** NARROW PASSED: %0d unaligned bytes, guards intact ***\n", NBYTES);
        else           $display("\n*** NARROW FAILED: %0d errors ***\n", errors);
        $finish;
    end

    initial begin #2000000; $display("GLOBAL TIMEOUT"); $finish; end
endmodule
`default_nettype wire
