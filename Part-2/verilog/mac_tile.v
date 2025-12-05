// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 

module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset, mode);

  parameter bw      = 4;
  parameter psum_bw = 16;

  input                   clk;
  input                   reset;
  input                   mode;          // 0: Vanilla (4-bit Act), 1: SIMD (2-bit Act)
  input  [7:0]            in_w;          // 8-bit input (Weight or Act)
  input  [1:0]            inst_w;        // [1]: execute, [0]: kernel load
  input  [psum_bw-1:0]    in_n;
  output [psum_bw-1:0]    out_s;
  output [7:0]            out_e;         // Modified: 8-bit to carry Weight or Act
  output [1:0]            inst_e;

  reg    [1:0]            inst_q;
  reg    [bw-1:0]         a_q;           // Activation 4-bit
  reg    [bw-1:0]         b_q_0;         // Weight Lane 0
  reg    [bw-1:0]         b_q_1;         // Weight Lane 1
  reg    [psum_bw-1:0]    c_q;
  
  // Shift Register Propagator
  reg    [7:0]            w_prop_q;      

  wire   [bw-1:0]         a_lane0;
  wire   [bw-1:0]         a_lane1;
  wire   [psum_bw-1:0]    mac_out0;
  wire   [psum_bw-1:0]    mac_out1;
  wire   [psum_bw-1:0]    final_out;

  // --- Activation Slicing ---
  assign a_lane0 = { {(bw-2){1'b0}}, a_q[1:0] }; 
  assign a_lane1 = { {(bw-2){1'b0}}, a_q[3:2] }; 

  // --- MAC Instantiations ---
  mac #(.bw(bw), .psum_bw(psum_bw)) mac_inst0 (
    .a   (a_lane0), 
    .b   (b_q_0),    
    .c   (c_q),
    .out (mac_out0)
  );

  mac #(.bw(bw), .psum_bw(psum_bw)) mac_inst1 (
    .a   (a_lane1),
    .b   (b_q_1),    
    .c   (mode ? mac_out0 : {psum_bw{1'b0}}), 
    .out (mac_out1)
  );

  assign final_out = mode ? mac_out1 : (mac_out0 + (mac_out1 << 2));

  assign out_s  = final_out;
  assign inst_e = inst_q;

  // --- Critical: Output Multiplexing ---
  assign out_e = inst_q[0] ? w_prop_q : {4'b0000, a_q};

  // --- Sequential Logic ---
  always @(posedge clk) begin
    if (reset) begin
        inst_q       <= 2'b00;
        a_q          <= {bw{1'b0}};
        b_q_0        <= {bw{1'b0}};
        b_q_1        <= {bw{1'b0}};
        c_q          <= {psum_bw{1'b0}};
        w_prop_q     <= 8'b0;
    end
    else begin
        inst_q <= inst_w;

        // --- Kernel Load Logic (Shift Register) ---
        if (inst_w[0]) begin
            b_q_0 <= in_w[3:0];
            b_q_1 <= in_w[7:4];
            
            w_prop_q <= in_w;
        end

        // --- Execute Logic ---
        if (inst_w[1]) begin
            a_q <= in_w[3:0];
            c_q <= in_n;
        end
    end
  end

endmodule
