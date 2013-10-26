module fast_to_slow_clk_signal
#(parameter num_cycles=4)
(
	signal_in, signal_out, 
	clk_fast, clk_slow,
	reset
);

	input signal_in, clk_fast, clk_slow, reset;
	output signal_out;
	reg [num_cycles-1:0] counter;

	always @ (posedge signal_in or posedge clk_fast or posedge reset) begin 
		if(reset == 1)begin
			counter <= num_cycles;
		end else if ((signal_in == 1) && (counter == num_cycles)) begin
			counter <= 0;
		end else if (counter < num_cycles) begin 
			counter <= counter + 1;
		end	
	end
	
	assign signal_out = (counter < num_cycles)?1:0; 
	
endmodule 