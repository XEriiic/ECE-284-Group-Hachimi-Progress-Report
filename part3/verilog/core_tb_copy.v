// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`timescale 1ns/1ps
//`default_nettype none
module core_tb;

parameter test_type = 1; // 1 for output stationary and 0 for vanilla version.
parameter bw = 4;
parameter psum_bw = 16;
parameter len_kij = 9;
parameter len_in_ch = 3;
parameter len_onij = 16;
parameter col = 8;
parameter row = 8;
parameter len_nij = 36;

reg clk = 0;
reg reset = 1;

wire [37:0] inst_q; 

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
reg ifn_rd_q = 0;
reg ifn_wr_q = 0;
reg l0_rd_q = 0;
reg l0_wr_q = 0;
reg execute_q = 0;
reg load_q = 0;
reg acc_q = 0;
reg acc = 0;
reg l0_version_q;

reg [1:0]  inst_w; 
reg [bw*row-1:0] D_xmem;
//0: full; 1: ready
reg [psum_bw*col-1:0] answer;


reg ofifo_rd;
reg ififo_wr;
reg ififo_rd;
reg ifn_rd;
reg ifn_wr;
reg l0_rd;
reg l0_wr;
reg [1:0] act = 0;
reg [1:0] act_q = 0;
reg execute;
reg load;
reg [8*30:1] stringvar;
reg [750:0] w_file_name;
reg [750:0] x_file_name;
//reg w_file_name;
wire ofifo_valid;
wire [col*psum_bw-1:0] sfp_out;

reg signed [15:0] hw_val, sw_val;
reg signed [15:0] diff;

integer log_pmem;
//initial log_pmem = $fopen("E:/Things_Of_Graduate/ECE_284/Project_p1.1_software/VGG_data01/debug_pmem_write.txt", "w");



wire [2:0] ofifo_inst; //0: ready; 1: full; 2: valid
wire [1:0] l0_inst;    //0: full; 1: ready
wire [1:0] ifn_inst;   //0: full; 1: ready

//integer lambd_file, lambd_scan_file ;
integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer acc_file, acc_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer captured_data; 
integer t, i, j, k, kij, ch;
integer error;

assign inst_q[37:36] = act_q;
assign inst_q[35] = ifn_rd_q; //ififo north read
assign inst_q[34] = ifn_wr_q; //ififo north write
assign inst_q[33] = acc_q;
assign inst_q[32] = CEN_pmem_q;
assign inst_q[31] = WEN_pmem_q;   // write (WEN == 1)
assign inst_q[30:20] = A_pmem_q;
assign inst_q[19]   = CEN_xmem_q; // CEN == 0 enable
assign inst_q[18]   = WEN_xmem_q; // write (WEN == 1)
assign inst_q[17:7] = A_xmem_q;
assign inst_q[6]   = ofifo_rd_q;
assign inst_q[5]   = ififo_wr_q;
assign inst_q[4]   = ififo_rd_q;
assign inst_q[3]   = l0_rd_q;
assign inst_q[2]   = l0_wr_q;
assign inst_q[1]   = execute_q; 
assign inst_q[0]   = load_q; 

// Additional wire definition //

reg l0_version = 1;
reg mac_tile_version = 1;
reg mac_tile_version_q = 1;
wire ofifo_o_ready;
assign ofifo_o_ready = ofifo_inst[0];
reg mac_deliver_q = 0;
reg mac_deliver = 0;
reg complete_signal = 0;
reg complete_signal_q = 0;
reg compute_signal = 0;
reg compute_signal_q = 0;
reg hold_cq_q = 0;
reg hold_cq = 0;

core  #(.bw(bw), .col(col), .row(row)) core_instance (
	.clk(clk), 
	.inst(inst_q),
	.ofifo_valid(ofifo_valid),
    .D_xmem(D_xmem_q), 
    .sfp_out(sfp_out), 
	.reset(reset),
	.l0_version(l0_version_q), 
	.ofifo_inst(ofifo_inst), 
	.l0_inst(l0_inst),
	.ifn_inst(ifn_inst),
	.mac_tile_version(mac_tile_version_q),
	.mac_deliver(mac_deliver_q),
	.hold_cq(hold_cq_q)

); 

if (test_type == 1) begin
initial begin
  act = 0;
  compute_signal = 0;
  complete_signal = 0;
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
  l0_version = 1;
  ifn_rd = 0;
  ifn_wr = 0;
  mac_deliver = 0;
  mac_tile_version = 1;
  hold_cq = 0;

  
  
  $dumpfile("core_tb.vcd");
  $dumpvars(0,core_tb);
	
  //////// Reset /////////
  #0.5 clk = 1'b0;   reset = 1;
  #0.5 clk = 1'b1; 

  for (i=0; i<10 ; i=i+1) begin
    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;  
  end// Idel Interval

	for (i=0; i<10 ; i=i+1) begin
      		#0.5 clk = 1'b0;
      		#0.5 clk = 1'b1;  
    	end


  #0.5 clk = 1'b0;   reset = 0;
  #0.5 clk = 1'b1; 

  #0.5 clk = 1'b0;   
  #0.5 clk = 1'b1;

 hold_cq = 1;

  for (ch=0; ch<len_in_ch; ch=ch+1) begin  // input channel loop loop /home/linux/ieng6/ECE284_FA25_A00/halajeel/plus_alpha/txt_out/activation_in_ch0.txt"

    case(ch)
	    	0: begin
		x_file_name = "/home/linux/ieng6/students/230/halajeel/Downloads/txt_out1/activation_in_ch0.txt"; 
     		w_file_name = "/home/linux/ieng6/students/230/halajeel/Downloads/txt_out1/weight_in_ch0.txt";
		end
		1: begin
		x_file_name = "/home/linux/ieng6/students/230/halajeel/Downloads/txt_out1/activation_in_ch1.txt"; 
     		w_file_name = "/home/linux/ieng6/students/230/halajeel/Downloads/txt_out1/weight_in_ch1.txt";
		end
		2: begin
		x_file_name = "/home/linux/ieng6/students/230/halajeel/Downloads/txt_out1/activation_in_ch2.txt"; 
     		w_file_name = "/home/linux/ieng6/students/230/halajeel/Downloads/txt_out1/weight_in_ch2.txt";
		end

    endcase
    

    w_file = $fopen(w_file_name, "r");
    x_file = $fopen(x_file_name, "r");

    #0.5 clk = 1'b0;   
    #0.5 clk = 1'b1;   

/////// Kernel data writing to memory ///////
  A_xmem = 0;
  for (t=0;t<len_kij; t=t+1) begin  
    #0.5 clk = 1'b0;  w_scan_file = $fscanf(w_file,"%32b", D_xmem); WEN_xmem = 0; CEN_xmem = 0; if (t>0) A_xmem = A_xmem + 1; 
    #0.5 clk = 1'b1;     
  end

  #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
  #0.5 clk = 1'b1; 

  $fclose(w_file);
  /////////////////////////////////////////////////

    #0.5 clk = 1'b0;   
    #0.5 clk = 1'b1;   

/////////// activation data writing to memory ///////

    A_xmem = 11'b10000000000;

    for (t=0; t<len_kij; t=t+1) begin  
      #0.5 clk = 1'b0;  x_scan_file = $fscanf(x_file,"%32b", D_xmem); WEN_xmem = 0; CEN_xmem = 0; if (t>0) A_xmem = A_xmem + 1; 
      #0.5 clk = 1'b1;  

    end

    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1;
    #0.5 clk = 1'b1; 
    $fclose(x_file);
    /////////////////////////////////////
    
    // Idel Interval
    for (i=0; i<10; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end

/////////// activation data writing to L0 /////// writing to L0 memory
    
    A_xmem = 11'b10000000000;
    WEN_xmem = 1; CEN_xmem = 0; l0_rd = 0; l0_wr = 1;
    
    for (j=0; j<len_kij; j=j+1) begin  
      #0.5 clk = 1'b0; l0_rd = 0; l0_wr = 1; WEN_xmem = 1; CEN_xmem = 0; if (j>0) A_xmem = A_xmem + 1;
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0; l0_wr = 0; A_xmem = 0;CEN_xmem = 1;
    #0.5 clk = 1'b1; 
    
    /////////////////////////////////////
    
    // Idel Interval

	for (i=0; i<10 ; i=i+1) begin
      		#0.5 clk = 1'b0;
      		#0.5 clk = 1'b1;  
    	end

/////////// kernel data writing to ififo north /////// writing to ififo north  memory
    
    A_xmem = 11'b00000000000;
    WEN_xmem = 1; CEN_xmem = 0; ifn_rd = 0; ifn_wr = 1;
    
    for (j=0; j<len_kij; j=j+1) begin  
      #0.5 clk = 1'b0; ifn_rd = 0; ifn_wr = 1; WEN_xmem = 1; CEN_xmem = 0; if (j>0) A_xmem = A_xmem + 1;
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0; ifn_wr = 0; A_xmem = 0;CEN_xmem = 1;
    #0.5 clk = 1'b1; 
    
    /////////////////////////////////////

// Idel Interval

	for (i=0; i<10 ; i=i+1) begin
      		#0.5 clk = 1'b0;
      		#0.5 clk = 1'b1;  
    	end
#0.5 clk = 1'b0;compute_signal = 1;
#0.5 clk = 1'b1;
/////////////Execution///////////////////
#0.5 clk = 1'b0; l0_rd = 1;ifn_rd = 1;
#0.5 clk = 1'b1;

	for (i=0; i<len_kij; i=i+1) begin
      		#0.5 clk = 1'b0;
		execute = 1;
		if (i < len_kij-1) begin	
			l0_rd = 1; 
			ifn_rd = 1; 
		end
		else begin
      			l0_rd = 0;
			ifn_rd = 0;
		end
		#0.5 clk = 1'b1;
    	end

    
    #0.5 clk = 1'b0;   l0_rd = 0; ifn_rd = 0;  execute = 0; compute_signal = 0;
    #0.5 clk = 1'b1;
	// Idel Interval

	for (i=0; i<30 ; i=i+1) begin//changed from 10 to 30
      		#0.5 clk = 1'b0;
      		#0.5 clk = 1'b1;  
    	end

  //////// Reset /////////
  #0.5 clk = 1'b0;   reset = 1;
  #0.5 clk = 1'b1; 
 #0.5 clk = 1'b0;   reset = 0;
  #0.5 clk = 1'b1; 


    end
    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;

///////////Transport c_q's to ofifo///////////////////////
for (i=0; i<row; i=i+1) begin
      #0.5 clk = 1'b0; mac_deliver = 1;
      #0.5 clk = 1'b1;
    end

    
    #0.5 clk = 1'b0; mac_deliver = 0;
    #0.5 clk = 1'b1;   
/////////////////////////////////////////////////////////

	for (i=0; i<10 ; i=i+1) begin
      		#0.5 clk = 1'b0;
      		#0.5 clk = 1'b1;  
    	end

    #0.5 clk = 1'b0; ofifo_rd = 1; //This was here before I commented it out
    //I think it could be important
    #0.5 clk = 1'b1;
    A_pmem = 0;
    for (i=0; i<len_kij; i=i+1) begin // used to be len_kij + 1 changed it to only len_kij
      #0.5 clk = 1'b0; ofifo_rd = 1; WEN_pmem = 0; CEN_pmem = 0; if(i>0) A_pmem = A_pmem + 1; 
      #0.5 clk = 1'b1;
      //$display(log_pmem, "write i=%0d A=%0d\n", i, A_pmem); // For Memory Debug
 
    end 

    #0.5 clk = 1'b0; ofifo_rd = 0; WEN_pmem = 1; CEN_pmem = 1;//  A_pmem = A_pmem + 1; used to be here but I removed it because I thought it was unnecessary
    // also changed 
    #0.5 clk = 1'b1;

  ////////// Accumulation /////////
  //acc_file = $fopen("/home/linux/ieng6/ECE284_FA25_A00/halajeel/plus_alpha/txt_files/acc_address1.txt", "r");
  out_file = $fopen("/home/linux/ieng6/students/230/halajeel/Downloads/txt_out1/out_relu.txt", "r");  
  error = 0;



  $display("############ Verification Start during accumulation #############"); 

  for (i=0; i<8+1; i=i+1) begin //condition should be 8 outputs to check

    #0.5 clk = 1'b0; 
    #0.5 clk = 1'b1; 

    if (i>0) begin
       out_scan_file = $fscanf(out_file,"%128b", answer); // reading from out file to answer
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

    for (j=0; j<1+1; j=j+1) begin 

        #0.5 clk = 1'b0;
        A_pmem = i;
        if (j<1) begin CEN_pmem = 0; WEN_pmem = 1; //acc_scan_file = $fscanf(acc_file,"%11b", A_pmem);
        end else begin CEN_pmem = 1; WEN_pmem = 1; end

        if (j>0)begin  
	acc = 1;
        #0.5 clk = 1'b1;
	end
	else begin
	#0.5 clk = 1'b1;
	end
	end
		  
		    

    #0.5 clk = 1'b0; acc = 0; act = 1;//relu = 0;//ss = 0;
    #0.5 clk = 1'b1;
    #0.5 clk = 1'b0; acc = 0; act = 0;//relu = 0;//ss = 0;
    #0.5 clk = 1'b1;

    
  end


  if (error == 0) begin
  	$display("############ No error detected ##############"); 
  	$display("########### Project Completed !! ############"); 

  end

  //$fclose(acc_file);
  //////////////////////////////////

    for (t=0; t<10; t=t+1) begin  
    #0.5 clk = 1'b0;  
    #0.5 clk = 1'b1;  
  end
  #10 $finish;

end// end of initial of test type 1
end// end of if statement for test type


/*else if (test_type == 0) begin//////////////////////////////////////////// Beginning of second test type for vanilla version
	initial
	$display("Not completed");
	#10 $finish;
end
end*/


always @ (posedge clk) begin
	//relu_q <= relu;
	//lambd_in_q <= lambd_in;
   act_q <= act;
   mac_tile_version_q <= mac_tile_version;
   ifn_rd_q <= ifn_rd;
   ifn_wr_q <= ifn_wr;
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
   mac_deliver_q <= mac_deliver;
   complete_signal_q <= complete_signal;
   compute_signal_q <= compute_signal;
   hold_cq_q <= hold_cq;
//	ss_q <= ss;
end


endmodule




