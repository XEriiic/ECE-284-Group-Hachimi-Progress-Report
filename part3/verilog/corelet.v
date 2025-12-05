module corelet(clk, reset, inst,
               l0_in, l0_version, l0_o_full, l0_o_ready,
               ofifo_o_ready, ofifo_o_full, ofifo_o_valid, ofifo_o_out,
               sram2sfp, results, ifn_in, ifn_o_full, ifn_o_ready, mac_tile_version, mac_deliver, hold_cq
                );
                
    parameter psum_bw = 16;
    parameter bw      = 4;
    parameter row     = 8;
    parameter col     = 8;
    
	 //input relu;
	 //input ss;
    input hold_cq;
    input mac_deliver;
    input mac_tile_version;
    input clk;
    input reset;
    input [37:0] inst;
    //integer difference = psum_bw-bw;
    
    input [psum_bw*col-1:0] sram2sfp; // sram to sfp
    output [psum_bw*col-1:0] results; // final output  
    
    //input signed [psum_bw-1:0] lambd_in;
    
////////// l0 //////////   
    input [row*bw-1:0] l0_in;
    input l0_version;
    wire [row*bw-1:0] l0_out;
    output l0_o_full;
    output l0_o_ready;
  
    l0 #(.bw(bw),.row(row)) l0_instance(
        .clk(clk),
        .reset(reset),
        .in(l0_in), 
        .out(l0_out), 
        .rd(inst[3]),
        .wr(inst[2]), 
        .o_full(l0_o_full),     
        .o_ready(l0_o_ready),
        .version(l0_version)    
    );
   
////////// ififo north////////// not done yet too!
    input [col*bw-1:0] ifn_in;//!new
    wire [col*bw-1:0] ifn_out;
    output ifn_o_full;//!new
    output ifn_o_ready;//!new
  
    l0 #(.bw(bw),.row(row)) ifn_instance(
        .clk(clk),
        .reset(reset),
        .in(ifn_in), 
        .out(ifn_out), 
        .rd(inst[35]),// need to add two extra bits for rd and wr in corelet, core, core_tb.
        .wr(inst[34]), 
        .o_full(ifn_o_full),     
        .o_ready(ifn_o_ready),
        .version(l0_version)    
    );

////////// Output FIFO //////////    
    wire [psum_bw*col-1:0] mac_out_s; 
    wire [col-1:0] mac_valid; 
    wire [col-1:0] deliver;
    assign deliver = (mac_deliver == 1) ? 8'b11111111 : 8'b00000000;
    wire [col-1:0] choice_valid;
    assign choice_valid = (mac_tile_version == 1) ?  deliver : mac_valid;  
    output ofifo_o_ready;
    output ofifo_o_full;
    output ofifo_o_valid; // ?Unsure
    output [psum_bw*col-1:0] ofifo_o_out; // Output of ofifo to sram
    
    ofifo #(.psum_bw(psum_bw),.col(col)) ofifo_instance(
        .clk(clk), 
        .reset(reset),
        .in(mac_out_s), 
        .out(ofifo_o_out), 
        .o_rd(inst[6]),
        .wr(choice_valid),
        .o_full(ofifo_o_full),
        .o_ready(ofifo_o_ready),
        .o_valid(ofifo_o_valid)
    );
    
////////// Mac_array //////////    
    //wire [psum_bw*col-1:0] in_n = 0;
    wire [psum_bw*col-1:0] mac_in_n;
    wire [psum_bw*col-1:0] choice;
    assign choice = (mac_tile_version == 1) ? mac_in_n : 0;//done here
    
    mac_array #(.bw(bw), .psum_bw(psum_bw),.row(row),.col(col)) mac_array_instance (
        .clk(clk),
        .reset(reset),
        .in_n(choice),
        .in_w(l0_out),      // The output of l0 is connected to mac_array
        .inst_w(inst[1:0]),       
        .out_s(mac_out_s),  
        .valid(mac_valid),
	.mac_tile_version(mac_tile_version),//!new addition to mac_array
	.mac_deliver(mac_deliver),//!new addition to mac array
	.hold_cq(hold_cq)
    );
    
////////// Special Function Unit //////////    

    genvar g;
    generate
    for (g=1; g<col+1; g=g+1) begin: sfp_col
        sfp #(.bw(bw), .psum_bw(psum_bw)) sfp_instance(
            .clk(clk),
            .reset(reset),
            .in(sram2sfp[psum_bw*g-1 : psum_bw*(g-1)]),
            .out(results[psum_bw*g-1 : psum_bw*(g-1)]),
            .acc(inst[33]),
	    .act(inst[37:36])
        );

	assign mac_in_n[psum_bw*g-1:psum_bw*(g-1)] = $signed(ifn_out[bw*g-1:bw*(g-1)]); //connecting mac_in_n with the ififo north input

    end
endgenerate
    
    
//end                   
endmodule
 
