module mac_array (clk, reset, out_s, in_w, in_n, inst_w, valid, mode);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;
  parameter row = 8;

  input  clk, reset;
  input  mode;                      
  output [psum_bw*col-1:0] out_s;
  input  [row*bw-1:0] in_w;       
  input  [1:0] inst_w;
  input  [psum_bw*col-1:0] in_n;
  output [col-1:0] valid;

  reg    [2*row-1:0] inst_w_temp;
  wire   [psum_bw*col*(row+1)-1:0] temp;
  wire   [row*col-1:0] valid_temp;


  reg    [row*bw-1:0]   w_buffer; 
  reg                   w_buffer_valid; 
  reg    [row*bw*2-1:0] w_combined;

  genvar i;
 
  assign out_s = temp[psum_bw*col*9-1:psum_bw*col*8];
  assign temp[psum_bw*col*1-1:psum_bw*col*0] = 0;
  assign valid = valid_temp[row*col-1:row*col-8];

  generate
  for (i=1; i < row+1; i=i+1) begin : row_num
      mac_row #(.bw(bw), .psum_bw(psum_bw)) mac_row_instance (
         .clk(clk),
         .reset(reset),
         .mode(mode),
         .in_w(w_combined[bw*2*i-1 : bw*2*(i-1)]),  // 8-bit
         .inst_w(inst_w_temp[2*i-1 : 2*(i-1)]),
         .in_n(temp[psum_bw*col*i-1 : psum_bw*col*(i-1)]),
         .valid(valid_temp[col*i-1 : col*(i-1)]),
         .out_s(temp[psum_bw*col*(i+1)-1 : psum_bw*col*i])
      );
  end
  endgenerate


  always @(posedge clk) begin
    if (reset) begin
      w_buffer       <= {row*bw{1'b0}};
      w_buffer_valid <= 1'b0;
      w_combined     <= {row*bw*2{1'b0}};
    end
    else begin
      if (inst_w[0]) begin  // Kernel load mode
        if (!w_buffer_valid) begin
          // Buffering cycle
          w_buffer <= in_w;
          w_buffer_valid <= 1'b1;
        end
        else begin
          // Combination cycle
          w_combined[7:0]     <= {in_w[3:0],   w_buffer[3:0]};    // Row0
          w_combined[15:8]    <= {in_w[7:4],   w_buffer[7:4]};    // Row1
          w_combined[23:16]   <= {in_w[11:8],  w_buffer[11:8]};   // Row2
          w_combined[31:24]   <= {in_w[15:12], w_buffer[15:12]};  // Row3
          w_combined[39:32]   <= {in_w[19:16], w_buffer[19:16]};  // Row4
          w_combined[47:40]   <= {in_w[23:20], w_buffer[23:20]};  // Row5
          w_combined[55:48]   <= {in_w[27:24], w_buffer[27:24]};  // Row6
          w_combined[63:56]   <= {in_w[31:28], w_buffer[31:28]};  // Row7
          
          w_buffer_valid <= 1'b0;  // Clear buffer valid after combination cycle
        end
      end
      else if (inst_w[1]) begin
        // Execute mode
        w_combined[7:0]     <= {4'b0000, in_w[3:0]};
        w_combined[15:8]    <= {4'b0000, in_w[7:4]};
        w_combined[23:16]   <= {4'b0000, in_w[11:8]};
        w_combined[31:24]   <= {4'b0000, in_w[15:12]};
        w_combined[39:32]   <= {4'b0000, in_w[19:16]};
        w_combined[47:40]   <= {4'b0000, in_w[23:20]};
        w_combined[55:48]   <= {4'b0000, in_w[27:24]};
        w_combined[63:56]   <= {4'b0000, in_w[31:28]};
        
        w_buffer_valid <= 1'b0;
      end
    end
  end


  always @ (posedge clk) begin
    if (inst_w[0] && w_buffer_valid) begin
      // Kernel load mode, at second cycle
      inst_w_temp[1:0]   <= inst_w; 
      inst_w_temp[3:2]   <= inst_w_temp[1:0]; 
      inst_w_temp[5:4]   <= inst_w_temp[3:2]; 
      inst_w_temp[7:6]   <= inst_w_temp[5:4]; 
      inst_w_temp[9:8]   <= inst_w_temp[7:6]; 
      inst_w_temp[11:10] <= inst_w_temp[9:8]; 
      inst_w_temp[13:12] <= inst_w_temp[11:10]; 
      inst_w_temp[15:14] <= inst_w_temp[13:12];
    end
    else if (inst_w[1]) begin
      // Execute mode
      inst_w_temp[1:0]   <= inst_w; 
      inst_w_temp[3:2]   <= inst_w_temp[1:0]; 
      inst_w_temp[5:4]   <= inst_w_temp[3:2]; 
      inst_w_temp[7:6]   <= inst_w_temp[5:4]; 
      inst_w_temp[9:8]   <= inst_w_temp[7:6]; 
      inst_w_temp[11:10] <= inst_w_temp[9:8]; 
      inst_w_temp[13:12] <= inst_w_temp[11:10]; 
      inst_w_temp[15:14] <= inst_w_temp[13:12];
    end
    else begin
      inst_w_temp <= inst_w_temp;
    end
  end

endmodule
