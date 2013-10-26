`timescale 1ns/100ps

module array
#(parameter DATA_WIDTH=32, parameter INDEX_WIDTH=6)
(
	input [DATA_WIDTH-1:0] data_a, data_b,
	input [INDEX_WIDTH-1:0] addr_a, addr_b,
	input we_a, we_b, clk,
	output reg [DATA_WIDTH-1:0] q_a, q_b
);

	// Declare the array variable
	reg [DATA_WIDTH-1:0] array[2**INDEX_WIDTH-1:0];
	wire [INDEX_WIDTH-1:0] addr_a_t, addr_b_t;

	assign #0.5 addr_a_t = addr_a;
	assign #0.5 addr_b_t = addr_b;
	
	// Port A 
	always @ (posedge clk)
	begin
		if (we_a) 
		begin
			array[addr_a_t] <= data_a;
			q_a <= data_a;
		end
		else 
		begin
			q_a <= array[addr_a_t];
		end 
	end 

	// Port B 
	always @ (posedge clk)
	begin
		if (we_b) 
		begin
			array[addr_b_t] <= data_b;
			q_b <= data_b;
		end
		else 
		begin
			q_b <= array[addr_b_t];
		end 
	end

endmodule
