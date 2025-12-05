// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 

module mac_row (clk, out_s, in_w, in_n, valid, inst_w, reset, mode);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;

  input  clk, reset;
  input  mode;                    // mode=0: 4-bit, mode=1: 2-bit

  output [psum_bw*col-1:0] out_s; 
  output [col-1:0] valid;         
  input  [7:0] in_w;           
  input  [1:0] inst_w;            // inst[1]: execute, inst[0]: kernel loading
  input  [psum_bw*col-1:0] in_n;  

  wire   [(col+1)*8-1:0] temp;    
  assign temp[7:0]   = in_w;    
  
  wire   [(col+1)*2-1:0] inst_temp;
  assign inst_temp[1:0] = inst_w;  // Pass instruction through column
  
  genvar i;
  generate
      for (i=1; i < col+1; i=i+1) begin : col_num
          mac_tile #(.bw(bw), .psum_bw(psum_bw)) mac_tile_instance (
             .clk(clk),
             .reset(reset),
             .mode(mode),                                
             .in_w(temp[8*i-1:8*(i-1)]),              
             .out_e(temp[8*(i+1)-1:8*i]),             
             .inst_w(inst_temp[2*i-1:2*(i-1)]),         
             .inst_e(inst_temp[2*(i+1)-1:2*i]),
             .in_n(in_n[psum_bw*i-1:psum_bw*(i-1)]),    
             .out_s(out_s[psum_bw*i-1:psum_bw*(i-1)])   
          );

          assign valid[i-1] = inst_temp[2*(i+1)-1]; 
      end
  endgenerate
  
endmodule
