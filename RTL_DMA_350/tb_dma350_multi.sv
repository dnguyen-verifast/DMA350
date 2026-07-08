//-----------------------------------------------------------------------------
// tb_dma350_multi.sv  - two channels copying different regions concurrently.
// Exercises multi-channel instantiation, the AXI5 arbitration node (ID-routed
// multiple-outstanding reads/writes on a shared port) and per-channel CHPRIO.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
`default_nettype none

module tb_dma350_multi;
    localparam int DW = 32, AW = 32, BPB = DW/8, NC = 2;

    logic clk = 0, resetn = 0;
    always #5 clk = ~clk;

    logic psel=0, penable=0, pwrite=0;
    logic [12:0] paddr=0;
    logic [31:0] pwdata=0, prdata;
    logic [3:0]  pstrb=4'hF;
    logic pready, pslverr, irq_ns, irq_s;
    logic [NC-1:0] irq_ch;

    dma350_tb_harness #(.ADDR_WIDTH(AW), .DATA_WIDTH(DW), .NUM_CHANNELS(NC)) h (
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

    // per-channel program: TRANSIZE=2, CHPRIO in CH_CTRL[7:4]
    task automatic program_ch(input int ch, input [31:0] src, input [31:0] dst,
                              input [15:0] units, input [1:0] prio);
        // DONETYPE=001 (bit21), XTYPE=continue (bit9), CHPRIO[7:4], TRANSIZE=2
        apb_write(reg_addr(ch,CH_CTRL), 32'h0020_0200 | ({28'b0,prio}<<4) | 32'h2);
        apb_write(reg_addr(ch,CH_SRCADDR), src);
        apb_write(reg_addr(ch,CH_DESADDR), dst);
        apb_write(reg_addr(ch,CH_XADDRINC), 32'h0001_0001); // increment 1 unit / side
        apb_write(reg_addr(ch,CH_XSIZE),   {units, units}); // DES|SRC XSIZE
    endtask

    localparam [31:0] SRC0=32'h0000_1000, DST0=32'h0000_3000;
    localparam [31:0] SRC1=32'h0000_5000, DST1=32'h0000_7000;
    localparam int U0=32, U1=48;
    int errors = 0;
    logic [31:0] rb0, rb1;

    initial begin
        for (int i=0;i<U0*BPB;i++) h.u_mem.mem[SRC0+i] = (i*7+1)  & 8'hFF;
        for (int i=0;i<U1*BPB;i++) h.u_mem.mem[SRC1+i] = (i*13+9) & 8'hFF;

        resetn=0; repeat(8) @(posedge clk); resetn=1; repeat(4) @(posedge clk);

        program_ch(0, SRC0, DST0, U0[15:0], 2'd1);
        program_ch(1, SRC1, DST1, U1[15:0], 2'd3);   // ch1 higher priority
        // launch both, back to back
        apb_write(reg_addr(0,CH_CMD), 32'h1);
        apb_write(reg_addr(1,CH_CMD), 32'h1);

        // both channels run concurrently in HW; poll them sequentially over the
        // single APB master (one transaction at a time) with a global timeout.
        fork
            begin
                do apb_read(reg_addr(0,CH_STATUS), rb0); while (!rb0[16]);
                $display("[%0t] ch0 DONE", $time);
                do apb_read(reg_addr(1,CH_STATUS), rb1); while (!rb1[16]);
                $display("[%0t] ch1 DONE", $time);
            end
            begin repeat(40000) @(posedge clk); $display("TIMEOUT"); errors++; end
        join_any
        disable fork;
        repeat(20) @(posedge clk);

        for (int i=0;i<U0*BPB;i++)
            if (h.u_mem.mem[SRC0+i] !== h.u_mem.mem[DST0+i]) begin
                if (errors<8) $display("  ch0 byte %0d mismatch", i); errors++; end
        for (int i=0;i<U1*BPB;i++)
            if (h.u_mem.mem[SRC1+i] !== h.u_mem.mem[DST1+i]) begin
                if (errors<8) $display("  ch1 byte %0d mismatch", i); errors++; end

        if (errors==0) $display("\n*** MULTI PASSED: 2 channels, %0d + %0d bytes ***\n", U0*BPB, U1*BPB);
        else           $display("\n*** MULTI FAILED: %0d errors ***\n", errors);
        $finish;
    end

    initial begin #4000000; $display("GLOBAL TIMEOUT"); $finish; end
endmodule
`default_nettype wire
