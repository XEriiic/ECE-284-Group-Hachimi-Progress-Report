module corelet(clk, reset, inst, mode, 
               l0_in, l0_version, l0_o_full, l0_o_ready,
               ofifo_o_ready, ofifo_o_full, ofifo_o_valid, ofifo_o_out,
               sram2sfp, results
                );
                
    parameter psum_bw = 16;
    parameter bw      = 4;
    parameter row     = 8;
    parameter col     = 8;
    
    input clk;
    input reset;
    input [33:0] inst;
    input mode;
    
    input [psum_bw*col-1:0] sram2sfp; // sram to sfp
    output [psum_bw*col-1:0] results; // final output  
    
    
    
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
    
////////// Output FIFO //////////    
    wire [psum_bw*col-1:0] mac_out_s; 
    wire [col-1:0] mac_valid; 
    
    output ofifo_o_ready;
    output ofifo_o_full;
    output ofifo_o_valid; // ?Unsure
    output [psum_bw*col-1:0] ofifo_o_out; // Output of ofifo to sram
    
    ofifo #(.psum_bw(psum_bw),.col(col)) ofifo_instance(
        .clk(clk), 
        .reset(reset),
        .in(mac_out_s), 
        .out(ofifo_o_out), 
        .rd(inst[6]),
        .wr(mac_valid),
        .o_full(ofifo_o_full),
        .o_ready(ofifo_o_ready),
        .o_valid(ofifo_o_valid)
    );
    
////////// Mac_array //////////    
    wire [psum_bw*col-1:0] in_n = 0;
    wire [psum_bw*col-1:0] mac_in_n;
    assign mac_in_n = 0;
    
    mac_array #(.bw(bw), .psum_bw(psum_bw),.row(row),.col(col)) mac_array_instance (
        .clk(clk),
        .reset(reset),
        .mode(mode),
        .in_n(mac_in_n),
        .in_w(l0_out),      // The output of l0 is connected to mac_array
        .inst_w(inst[1:0]),       
        .out_s(mac_out_s),  
        .valid(mac_valid)
        //.version(mac_version)
    );
    
////////// Special Function Unit //////////    

    //wire sfp_relu = 0;
    //wire [psum_bw-1:0] debug_in = sram2sfp[15:0];
      
    genvar g;
    for (g=0; g<col; g=g+1) begin: sfp_col
        sfp #(.bw(bw), .psum_bw(psum_bw)) sfp_instance(
            .clk(clk),
            .reset(reset),
            //.in(debug_in),
            .in(sram2sfp[psum_bw*(g+1)-1 : psum_bw*g]),
            .out(results[psum_bw*(g+1)-1 : psum_bw*g]),
            .acc(inst[33])
            //.relu(sfp_relu)
        );
    end
    
    
    
                    
endmodule
 
