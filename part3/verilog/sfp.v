module sfp (clk, reset, acc, in, out, act);

parameter bw = 4;
parameter psum_bw = 16;
parameter shift_val = 3;
parameter thresh_val = 10;

//input relu;
//input ss;
input clk;
input reset;
input [1:0] act;

//input signed [psum_bw-1:0] lambd;
input acc;
//input relu; // Decide the function of sfp.v (either accumulate or ReLU)
input signed [psum_bw-1:0] in;
output signed [psum_bw-1:0] out;
//reg bool;
reg signed [psum_bw-1:0] psum_q;
//reg signed [psum_bw-1:0] lambd_q;
assign out = psum_q;
//assign lambd_q = lambd;


always @(posedge clk) begin
    if (reset == 1)begin
        //lambd_q <= lambd;
		  psum_q <= 0;
		  end
    else begin
        if (acc == 1)
        psum_q <= psum_q + in;
	else begin
	/*if (act == 1 && acc == 0)
	psum_q <= (psum_q[psum_bw-1] == 0)? psum_q : 0;
	else
	psum_q <= psum_q;*/
	case(act)
		2'b00: psum_q <= psum_q;
		2'b01: psum_q <= (psum_q[psum_bw-1] == 0)? psum_q : 0;// relu
		2'b10: psum_q <= (psum_q[psum_bw-1] == 0)? psum_q : psum_q >> shift_val;//leaky relu
	        2'b11: begin // soft shrink
			if (psum_q > thresh_val) psum_q <= psum_q - thresh_val;
			else if (psum_q > -thresh_val) psum_q <= 0;
			else psum_q <= psum_q + thresh_val;
		end	
	endcase
       end

    end
        
end

endmodule
