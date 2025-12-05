// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
// Modified for Part 2: Added mode reconfigurability test
`timescale 1ns/1ps
`default_nettype none
module core_tb;

parameter bw = 4;
parameter psum_bw = 16;
parameter len_kij = 9;
parameter len_onij = 16;
parameter col = 8;
parameter row = 8;
parameter len_nij = 36;

reg clk = 0;
reg reset = 1;
reg mode = 0;              

wire [33:0] inst_q; 

reg [1:0]  inst_w_q = 0; 
reg [bw*row-1:0] D_xmem_q = 0;
reg CEN_xmem = 1;
reg WEN_xmem = 1;
reg [10:0] A_xmem = 0;
reg CEN_xmem_q = 1;
reg WEN_xmem_q = 1;
reg [10:0] A_xmem_q = 0;
reg CEN_pmem = 1;
reg WEN_pmem = 1;
reg [10:0] A_pmem = 0;
reg CEN_pmem_q = 1;
reg WEN_pmem_q = 1;
reg [10:0] A_pmem_q = 0;
reg ofifo_rd_q = 0;
reg ififo_wr_q = 0;
reg ififo_rd_q = 0;
reg l0_rd_q = 0;
reg l0_wr_q = 0;
reg execute_q = 0;
reg load_q = 0;
reg acc_q = 0;
reg acc = 0;
reg l0_version_q;
reg mode_q = 0;            // delayed mode signal
reg [31:0] weight_buffer [0:7];


reg [1:0]  inst_w; 
reg [bw*row-1:0] D_xmem;
reg [psum_bw*col-1:0] answer;

reg ofifo_rd;
reg ififo_wr;
reg ififo_rd;
reg l0_rd;
reg l0_wr;
reg execute;
reg load;
reg [8*30:1] stringvar;
reg [100*30:1] w_file_name;
reg [100*30:1] x_file_name;    // for different activation files
reg [100*30:1] out_file_name;  // for different output files
reg [100*30:1] acc_file_name;

reg [800:0] path_root_4bit; 
reg [800:0] path_root_2bit;


wire ofifo_valid;
wire [col*psum_bw-1:0] sfp_out;
wire [2:0] ofifo_inst; //0: ready; 1: full; 2: valid
wire [1:0] l0_inst;    //0: full; 1: ready

integer x_file, x_scan_file ; 
integer w_file, w_scan_file ; 
integer acc_file, acc_scan_file ; 
integer out_file, out_scan_file ; 
integer captured_data; 
integer t, i, j, k, kij;
integer error;
integer test_mode;         // to track which mode we're testing

assign inst_q[33] = acc_q;
assign inst_q[32] = CEN_pmem_q;
assign inst_q[31] = WEN_pmem_q;
assign inst_q[30:20] = A_pmem_q;
assign inst_q[19]   = CEN_xmem_q;
assign inst_q[18]   = WEN_xmem_q;
assign inst_q[17:7] = A_xmem_q;
assign inst_q[6]   = ofifo_rd_q;
assign inst_q[5]   = ififo_wr_q;
assign inst_q[4]   = ififo_rd_q;
assign inst_q[3]   = l0_rd_q;
assign inst_q[2]   = l0_wr_q;
assign inst_q[1]   = execute_q; 
assign inst_q[0]   = load_q; 

reg l0_version = 0;

wire ofifo_o_ready;
assign ofifo_o_ready = ofifo_inst[0];

core  #(.bw(bw), .col(col), .row(row)) core_instance (
  .clk(clk), 
  .inst(inst_q),
  .mode(mode_q),           // connect mode signal
  .ofifo_valid(ofifo_valid),
  .D_xmem(D_xmem_q), 
  .sfp_out(sfp_out), 
  .reset(reset),
  .l0_version(l0_version_q), 
  .ofifo_inst(ofifo_inst), 
  .l0_inst(l0_inst)     
); 

// Task to run one complete test
task run_test;
   input integer current_mode; // 0: 4-bit, 1: 2-bit


  begin

    path_root_4bit = "./VGG_data/"; 
    path_root_2bit = "./VGG_data_2bit/"; 
    
    if (current_mode == 1) begin
      $display("==========================================");
      $display("===== Starting 2-bit Mode Test =====");
      $display("==========================================");
      
      x_file_name = {path_root_2bit, "activation.txt"};    // Update with your 2-bit data path
      out_file_name =  {path_root_2bit, "out.txt"};
      acc_file_name = {path_root_2bit, "acc_address.txt"};
    end else begin
      $display("==========================================");
      $display("===== Starting 4-bit Mode Test =====");
      $display("==========================================");
      x_file_name = {path_root_4bit, "activation.txt"};
      out_file_name = {path_root_4bit, "out.txt"};
      acc_file_name = {path_root_4bit, "acc_address.txt"};
    end

    /////// Activation data writing to memory ///////
    x_file = $fopen(x_file_name, "r");
    x_scan_file = $fscanf(x_file,"%s", captured_data);
    x_scan_file = $fscanf(x_file,"%s", captured_data);
    x_scan_file = $fscanf(x_file,"%s", captured_data);

    for (t=0; t<len_nij; t=t+1) begin  
      #0.5 clk = 1'b0;  x_scan_file = $fscanf(x_file,"%32b", D_xmem); WEN_xmem = 0; CEN_xmem = 0; if (t>0) A_xmem = A_xmem + 1;
      #0.5 clk = 1'b1;   
    end

    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
    #0.5 clk = 1'b1; 

    $fclose(x_file);
    /////////////////////////////////////////////////

    for (kij=0; kij<9; kij=kij+1) begin  // kij loop

      if (current_mode == 1) begin
          $sformat(w_file_name, "VGG_data_2bit/weight_2bit_kij%0d.txt", kij);
      end else begin
          $sformat(w_file_name, "VGG_data/weight_itile0_otile0_kij%0d.txt", kij);
      end


      w_file = $fopen(w_file_name, "r");
      w_scan_file = $fscanf(w_file,"%s", captured_data);
      w_scan_file = $fscanf(w_file,"%s", captured_data);
      w_scan_file = $fscanf(w_file,"%s", captured_data);

      #0.5 clk = 1'b0;   reset = 1;
      #0.5 clk = 1'b1; 

      for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end

      #0.5 clk = 1'b0;   reset = 0;
      #0.5 clk = 1'b1; 

      #0.5 clk = 1'b0;   
      #0.5 clk = 1'b1;   

      /////////// Kernel data writing to memory ///////
      A_xmem = 11'b10000000000;

    if (current_mode == 0) begin
      // ==== 4-bit mode: read 8 weights and copy====
      
    
      for (t=0; t<col; t=t+1) begin  
        w_scan_file = $fscanf(w_file,"%32b", weight_buffer[t]); 
      end
    
      // Write first set
      for (t=0; t<col; t=t+1) begin  
          #0.5 clk = 1'b0;  
          D_xmem = weight_buffer[t]; 
          WEN_xmem = 0; CEN_xmem = 0; 
          if (t>0) A_xmem = A_xmem + 1; 
        #0.5 clk = 1'b1;  
      end
    
      // Copy and write second set
      for (t=0; t<col; t=t+1) begin  
        #0.5 clk = 1'b0;  
          D_xmem = weight_buffer[t]; 
          WEN_xmem = 0; CEN_xmem = 0; 
          A_xmem = A_xmem + 1; 
        #0.5 clk = 1'b1;  
      end
     
    end else begin
      // ==== 2-bit mode: read 16 weights ====
      for (t=0; t<col*2; t=t+1) begin  
        #0.5 clk = 1'b0;  
        w_scan_file = $fscanf(w_file,"%32b", D_xmem); 
        WEN_xmem = 0; CEN_xmem = 0; 
        if (t>0) A_xmem = A_xmem + 1; 
        #0.5 clk = 1'b1;  
      end
    end


      #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
      #0.5 clk = 1'b1; 

      // Idle Interval
      for (i=0; i<10; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end

      /////////// Kernel data writing to L0 ///////
      l0_version = 0;

      WEN_xmem = 1; CEN_xmem = 0;
      A_xmem = 11'b10000000000;
      
      // Write first set to L0
      for (j=0; j<col; j=j+1) begin  
        #0.5 clk = 1'b0; l0_rd = 0; l0_wr = 1; WEN_xmem = 1; CEN_xmem = 0; if (j>0) A_xmem = A_xmem + 1; 
        #0.5 clk = 1'b1;  
      end
      
      // Write second set to L0
      for (j=0; j<col; j=j+1) begin  
        #0.5 clk = 1'b0; l0_rd = 0; l0_wr = 1; WEN_xmem = 1; CEN_xmem = 0; A_xmem = A_xmem + 1; 
        #0.5 clk = 1'b1;  
      end

      #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0; l0_wr = 0;
      #0.5 clk = 1'b1; 

      // Idle Interval
      for (k=0; ~l0_inst[0]&&k<10 ; k=k+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end

      /////////// Kernel loading to PEs ///////
      l0_version = 0;
      l0_rd = 1;
      
      // Cycle 1: First read, mac_array buffers
      #0.5 clk = 1'b0; l0_rd = 1; load = 1;
      #0.5 clk = 1'b1;
      
      // Cycle 2: Second read, mac_array combines and sends to PEs
      #0.5 clk = 1'b0; l0_rd = 1; load = 1;
      #0.5 clk = 1'b1;

      #0.5 clk = 1'b0;  load = 0; l0_rd = 0;
      #0.5 clk = 1'b1;  

      // Wait for systolic propagation (8 cycles for 8 PEs)
      for (i=0; i<col+2 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end

      /////////// Activation data writing to L0 ///////
      
      l0_version = 1;
      
      A_xmem = 11'b00000000000;
      
      for (t=0; t<len_nij; t=t+1) begin  
        #0.5 clk = 1'b0; l0_rd = 0; l0_wr = 1;  WEN_xmem = 1; CEN_xmem = 0; if (t>0) A_xmem = A_xmem + 1; 
        #0.5 clk = 1'b1;  
      end

      #0.5 clk = 1'b0; WEN_xmem = 1; CEN_xmem = 1;  A_xmem = 0;
      #0.5 clk = 1'b1;
      #0.5 clk = 1'b0; l0_wr = 0; 
      #0.5 clk = 1'b1; 

      /////////// Execution ///////
      l0_version = 1;
      
      l0_rd = 1;
      
      for (i=0; i<len_nij; i=i+1) begin
        #0.5 clk = 1'b0; l0_rd = 1; execute = 1;
        #0.5 clk = 1'b1;
      end
      
      #0.5 clk = 1'b0; l0_rd = 0; execute = 0;
      #0.5 clk = 1'b1;    

      // Idle Interval 
      for (t=0; t<len_nij; t=t+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end

      //////////// OFIFO READ ////////
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;
      
      for (i=0; i<len_nij+1; i=i+1) begin
        #0.5 clk = 1'b0; ofifo_rd = 1; WEN_pmem = 0; CEN_pmem = 0; if(i>0 | A_pmem>0) A_pmem = A_pmem + 1;
        #0.5 clk = 1'b1;
      end 
      #0.5 clk = 1'b0; WEN_pmem = 1; CEN_pmem = 1; ofifo_rd = 0;
      #0.5 clk = 1'b1;

    end  // end of kij loop

    ////////// Accumulation and Verification /////////
    acc_file = $fopen(acc_file_name, "r"); 
    out_file = $fopen(out_file_name, "r");  

    out_scan_file = $fscanf(out_file,"%s", answer); 
    out_scan_file = $fscanf(out_file,"%s", answer); 
    out_scan_file = $fscanf(out_file,"%s", answer); 

    error = 0;

    if (current_mode == 1)
      $display("############ 2-bit Mode Verification Start #############"); 
    else
      $display("############ 4-bit Mode Verification Start #############"); 

    for (i=0; i<len_onij+1; i=i+1) begin 
      #0.5 clk = 1'b0; 
      #0.5 clk = 1'b1; 

      if (i>0) begin
        out_scan_file = $fscanf(out_file,"%128b", answer);
        if (sfp_out == answer)
          $display("%2d-th output featuremap Data matched! :D", i); 
        else begin
          $display("%2d-th output featuremap Data ERROR!!", i); 
          $display("sfpout: %128b", sfp_out);
          $display("answer: %128b", answer);
          error = 1;
        end
      end
   
      #0.5 clk = 1'b0; reset = 1;
      #0.5 clk = 1'b1;  
      #0.5 clk = 1'b0; reset = 0; 
      #0.5 clk = 1'b1;  

      for (j=0; j<len_kij+1; j=j+1) begin 
        #0.5 clk = 1'b0;   
          if (j<len_kij) begin CEN_pmem = 0; WEN_pmem = 1; acc_scan_file = $fscanf(acc_file,"%11b", A_pmem); end
                         else  begin CEN_pmem = 1; WEN_pmem = 1; end
          if (j>0)  acc = 1;  
        #0.5 clk = 1'b1;   
      end

      #0.5 clk = 1'b0; acc = 0;
      #0.5 clk = 1'b1;
    end

    if (error == 0) begin
      if (current_mode == 1)
        $display("############ 2-bit Mode: No error detected ##############"); 
      else
        $display("############ 4-bit Mode: No error detected ##############"); 
    end else begin
      if (current_mode == 1)
        $display("############ 2-bit Mode: ERRORS DETECTED ##############"); 
      else
        $display("############ 4-bit Mode: ERRORS DETECTED ##############"); 
    end

    $fclose(acc_file);
    $fclose(out_file);
    $fclose(w_file);

  end
endtask

initial begin 
  inst_w   = 0; 
  D_xmem   = 0;
  CEN_xmem = 1;
  WEN_xmem = 1;
  A_xmem   = 0;
  ofifo_rd = 0;
  ififo_wr = 0;
  ififo_rd = 0;
  l0_rd    = 0;
  l0_wr    = 0;
  execute  = 0;
  load     = 0;
  l0_version = 0;

  $dumpfile("core_tb.vcd");
  $dumpvars(0,core_tb);

  //////// Initial Reset /////////
  #0.5 clk = 1'b0;   reset = 1;
  #0.5 clk = 1'b1; 

  for (i=0; i<10 ; i=i+1) begin
    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;  
  end

  #0.5 clk = 1'b0;   reset = 0;
  #0.5 clk = 1'b1; 

  #0.5 clk = 1'b0;   
  #0.5 clk = 1'b1;   
  /////////////////////////

  // ===== Test Sequence as Required by Part 2 =====
  
  // 1. Run in 2-bit mode
  $display("==========================================");
  $display("===== Setting 2-bit Mode =====");
  $display("==========================================");
  mode = 1;
  run_test(1);  // 2-bit mode test
  
  // 2. Reset (as required)
  $display("==========================================");
  $display("===== Resetting System =====");
  $display("==========================================");
  #0.5 clk = 1'b0;   reset = 1;
  #0.5 clk = 1'b1; 
  for (i=0; i<20 ; i=i+1) begin
    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;  
  end
  #0.5 clk = 1'b0;   reset = 0;
  #0.5 clk = 1'b1; 
  
  // 3. Reconfigure to 4-bit mode (as required)
  $display("==========================================");
  $display("===== Reconfiguring to 4-bit Mode =====");
  $display("==========================================");
  mode = 0;
  
  // 4. Run in 4-bit mode
  run_test(0);  // 4-bit mode test
  
  $display("==========================================");
  $display("===== All Tests Completed =====");
  $display("==========================================");

  for (t=0; t<10; t=t+1) begin  
    #0.5 clk = 1'b0;  
    #0.5 clk = 1'b1;  
  end

  #10 $finish;
end

always @ (posedge clk) begin
   inst_w_q   <= inst_w; 
   D_xmem_q   <= D_xmem;
   CEN_xmem_q <= CEN_xmem;
   WEN_xmem_q <= WEN_xmem;
   A_pmem_q   <= A_pmem;
   CEN_pmem_q <= CEN_pmem;
   WEN_pmem_q <= WEN_pmem;
   A_xmem_q   <= A_xmem;
   ofifo_rd_q <= ofifo_rd;
   acc_q      <= acc;
   ififo_wr_q <= ififo_wr;
   ififo_rd_q <= ififo_rd;
   l0_rd_q    <= l0_rd;
   l0_wr_q    <= l0_wr ;
   execute_q  <= execute;
   load_q     <= load;
   l0_version_q  <= l0_version;
   mode_q     <= mode;
end

endmodule
