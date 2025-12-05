module sfp (clk, reset, acc, in, out);

parameter bw = 4;
parameter psum_bw = 16;
parameter relu = 1;
input clk;
input reset;

input acc;
//input relu; // Decide the function of sfp.v (either accumulate or ReLU)

input signed [psum_bw-1:0] in;
output signed [psum_bw-1:0] out;

reg signed [psum_bw-1:0] psum_q;
assign out = psum_q;

always @(posedge clk) begin
    if (reset == 1) 
        psum_q <= 0;
    else begin
        // Accumulation
        if (acc == 1) psum_q <= psum_q + in;
        
        // ReLu            
        else if (relu == 1) 
            psum_q <= (psum_q > 16'b0)? psum_q : 0;
        else 
            psum_q <= psum_q;
    end      
end



endmodule
