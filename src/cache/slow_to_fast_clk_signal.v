module slow_to_fast_clk_signal
#(parameter num_cycles=4)
(
	signal_in, signal_out, 
	clk_fast, clk_slow,
	reset
);

	input signal_in, clk_fast, clk_slow, reset;
	
	output reg signal_out;
	
//	reg [num_cycles:0] counter;
//
//	always @ (posedge clk_fast or posedge reset) begin 
//		if(reset == 1)begin
//			counter <= num_cycles;
//		end else begin 
//			if (counter == num_cycles) begin
//				if (signal_in == 1) begin
//				    counter <= 1;
//				end
//			end else if (counter < num_cycles) begin 
//				counter <= counter + 1;
//			end
//		end	
//	end
//	
//	assign signal_out = (counter == 1)?1:0; 
	
	
	reg prev_state; //Used to measure L2clk
	
	always @ (posedge clk_fast) begin 
			if (clk_slow == 1)begin
				prev_state <= 1;
			end else begin
				prev_state <= 0;
			end 
			
			if ((prev_state == 0) && (clk_slow == 1))begin
				if(signal_in == 1)begin
					signal_out <= 1;
				end else begin 
					signal_out <= 0;
				end
			end else begin
				signal_out <= 0;
			end
	end
	
	
endmodule 
