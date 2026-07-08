`timescale 1ns/1ns
module top;
    import uvm_pkg::*;
	import apb_test_package::*;
    bit clk;
    bit rstn;
	initial	clk =0;
        always  #5 clk = ~clk;
    initial begin
        rstn = 0;
        #50 rstn = 1;
    end

    apb_interface #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32),
        .SLAVE_COUNT(1)
    ) apb_if (
        .clk(clk),
        .rstn(rstn)
    );
    initial begin
        uvm_config_db#(virtual apb_interface)::set(null, "*", "apb_if", apb_if);
        run_test();
    end
endmodule
