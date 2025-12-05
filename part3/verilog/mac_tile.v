// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 

module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset, mac_tile_version, mac_deliver, hold_cq);

parameter bw = 4;
parameter psum_bw = 16;

input hold_cq;
input mac_tile_version;
input mac_deliver;

output [psum_bw-1:0] out_s;
wire [psum_bw-1:0] choice_s;
input  [bw-1:0] in_w; 
output [bw-1:0] out_e; 
input  [1:0] inst_w; // inst[1]:execute, inst[0]: kernel loading
output [1:0] inst_e;
input  [psum_bw-1:0] in_n;
input  clk;
input  reset;

reg [1:0] inst_q;
reg load_ready_q;
reg [bw-1:0] a_q;           
reg [psum_bw-1:0] b_q;// changed to psum_bw from bw         
reg [psum_bw-1:0] c_q;           
//reg [psum_bw-1:0] hold_prev;
assign out_s = (mac_tile_version==1) ? ((mac_deliver == 1) ? c_q : b_q): choice_s;
//assign hold_prev = choice_s;

mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
        .a(a_q), 
        .b(b_q),
        .c(c_q),
	.out(choice_s)
); 

assign out_e = a_q;
assign inst_e = inst_q;

always @ (posedge clk) begin
    // When reset == 1, inst_q and load_ready_q become 1
    // Also initialize a_q, b_q, c_q
    if (reset) begin
        inst_q <= 2'b00;
        load_ready_q <= 1'b1;
        a_q <= 0;
        b_q <= 0;
        c_q <= (mac_tile_version == 1 && hold_cq == 1) ? c_q : 0;

    end else if (mac_tile_version == 0) begin // reset == 0
        inst_q[1] <= inst_w[1];
        c_q <= in_n;
        
        if (inst_w[0] || inst_w[1]) begin
            a_q <=in_w;
        end
            
        if (inst_w[0] && load_ready_q) begin
            b_q <= in_w;
            load_ready_q <= 1'b0;
        end
        
        if (load_ready_q == 1'b0) begin
            inst_q[0] <= inst_w[0];
        end
end else if (mac_tile_version == 1) begin
	inst_q[1] <= inst_w[1];
	inst_q[0] <= inst_w[1];//changed from w[1] to q[1]
	//b_q <= in_n;
	//a_q <= in_w;
	if((inst_w[0] || inst_w[1]) && !mac_deliver)begin// adding inst_[q] conditions even though I don't think this is right
		c_q <= choice_s;
		b_q <= in_n;
		a_q <= in_w;
	end
	else if (mac_deliver == 1) begin
		c_q <= in_n;
		b_q <= 0;
		a_q <= 0;
	end
	else begin
		c_q <= choice_s;//changing from choice_s to just c_q
		b_q <= 0;
		a_q <= 0;
	end
	// not done c_q shinu?	
	
end
    
end       
 
endmodule       
   
    

