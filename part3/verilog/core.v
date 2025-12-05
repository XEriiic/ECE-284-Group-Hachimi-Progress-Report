`timescale 1ns / 1ps
module core(clk, reset, inst, ofifo_valid, D_xmem, sfp_out,
            l0_version, ofifo_inst, l0_inst, ifn_inst, mac_tile_version, mac_deliver, hold_cq);
    
    parameter psum_bw = 16;
    parameter bw      = 4;
    parameter row     = 8;
    parameter col     = 8;
    
	 //input signed [psum_bw-1:0] lambd_in;
	 //input relu;
    input hold_cq;
    input mac_deliver;
    input mac_tile_version;
    input clk;
    input reset;
	 //input ss;
    input [37:0] inst;
    input [bw*row-1:0] D_xmem; //[31:0]
    output ofifo_valid;
    output [psum_bw*col-1:0] sfp_out; //[127:0]
    
    wire [psum_bw*col-1:0] sfp_in;
    wire [psum_bw*col-1:0] ofifo2sram; // ofifo_o_out to psum_sram
    wire [bw*row-1:0] sram2l0; //this signal is used for both the l0 fifo and the ififo north.
    input l0_version;// = 1;
    output [2:0] ofifo_inst; //0: ready; 1: full; 2: valid 
    output [1:0] l0_inst;    //0: full; 1: ready
    output [1:0] ifn_inst; //0: full; 1: ready

    corelet #(.psum_bw(psum_bw), .bw(bw), .row(row), .col(col)) corelet_instance(
        .clk(clk),
        .reset(reset),
        .inst(inst),
        .l0_in(sram2l0), .l0_version(l0_version), .l0_o_full(l0_inst[0]), .l0_o_ready(l0_inst[1]),
        .ofifo_o_ready(ofifo_inst[0]), .ofifo_o_full(ofifo_inst[1]), .ofifo_o_valid(ofifo_inst[2]), .ofifo_o_out(ofifo2sram),
        .sram2sfp(sfp_in), .results(sfp_out), .ifn_o_full(ifn_inst[0]), .ifn_o_ready(ifn_inst[1]), .ifn_in(sram2l0), .mac_tile_version(mac_tile_version), .mac_deliver(mac_deliver), .hold_cq(hold_cq)    );
    
    sram_32b_w2048 #(.num(2048), .width(32)) input_sram(
        .CLK(clk), 
        .D(D_xmem), 
        .Q(sram2l0), // input_sram to both l0_in and ifn_in
        .CEN(inst[19]), 
        .WEN(inst[18]), 
        .A(inst[17:7])
    );
    
    sram_128b_w2048 #(.num(2048)) psum_sram(
        .CLK(clk), 
        .D(ofifo2sram), // ofifo_o_out to psum_sram
        .Q(sfp_in), 
        .CEN(inst[32]), 
        .WEN(inst[31]), 
        .A(inst[30:20])
    ); 
    
    
    
    
endmodule
