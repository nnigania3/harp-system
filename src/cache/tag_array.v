`timescale 1ns/100ps

module L2_tag_array
#(parameter TAG_BITS=18, parameter INDEX_WIDTH=9)
(
	input [TAG_BITS-1:0] tag_a, tag_b,
	input dirty_a_i, dirty_b_i,
	input valid_a_i, valid_b_i,
	input [INDEX_WIDTH-1:0] addr_a, addr_b,
	input we_a, we_b, clk, new_clk,
	output reg [TAG_BITS-1:0] q_a, q_b,
	output reg dirty_a_o, dirty_b_o,
	output reg valid_a_o, valid_b_o
);

	// Declare the RAM variable
	reg [TAG_BITS-1:0] tag_ram[0:2**INDEX_WIDTH-1];
	reg valid_ram[0:2**INDEX_WIDTH-1];
	reg dirty_ram[0:2**INDEX_WIDTH-1];
	wire [INDEX_WIDTH-1:0] addr_a_t, addr_b_t;

	assign addr_a_t = addr_a;
	assign addr_b_t = addr_b;

	integer i;
	initial 
	begin
		for (i=0; i<2**INDEX_WIDTH; i=i+1) begin
			valid_ram[i] = 1'b0;
			dirty_ram[i] = 1'b0;
		end
	end
	
//	wire delayed_clk /* synthesis keep */, inv_clk /* synthesis keep */, new_clk;
/*	assign #0.5 inv_clk = ~clk;
	assign #0.5 delayed_clk = ~inv_clk;
	assign new_clk = clk ^ delayed_clk;
*/
	
	// Port A 
	always @ (posedge new_clk)// or negedge clk)
	begin
		if (we_a & clk == 0) 
		begin
			tag_ram[addr_a_t] <= tag_a;
			valid_ram[addr_a_t] <= valid_a_i;
			dirty_ram[addr_a_t] <= dirty_a_i;
			q_a <= tag_a;
			valid_a_o <= valid_a_i;
			dirty_a_o <= dirty_a_i;
		end
		else //if (clk == 0)
		begin
			q_a <= tag_ram[addr_a_t];
			valid_a_o <= valid_ram[addr_a_t];
			dirty_a_o <= dirty_ram[addr_a_t];
		end 
	end 

	// Port B 
	always @ (posedge new_clk)
	begin
		if (we_b & clk==0) 
		begin
			tag_ram[addr_b_t] <= tag_b;
			valid_ram[addr_b_t] <= valid_b_i;
			dirty_ram[addr_b_t] <= dirty_b_i;
			q_b <= tag_b;
			valid_b_o <= valid_b_i;
			dirty_b_o <= dirty_b_i;
		end
		else 
		begin
			q_b <= tag_ram[addr_b_t];
			valid_b_o <= valid_ram[addr_b_t];
			dirty_b_o <= dirty_ram[addr_b_t];
		end 
	end

endmodule
