`timescale 1ns/100ps

module data_array_simd
#(parameter DATA_WIDTH=256, parameter INDEX_WIDTH=9, parameter WORD_BITS = 3)
(
	input [DATA_WIDTH-1:0] data_a, 
	input [DATA_WIDTH-1:0] data_b,
	input [INDEX_WIDTH-1:0] addr_a, 
	input [INDEX_WIDTH-1:0] addr_b,
	input [2**WORD_BITS-1:0] valid_word_a, //word_b,
	input we_a, we_b, mode_a, clk,
	output [DATA_WIDTH-1:0] q_a,
	output [DATA_WIDTH-1:0] q_b
);
	localparam SMALL_DATA_WIDTH = DATA_WIDTH/(2**WORD_BITS);
	
	wire [SMALL_DATA_WIDTH-1:0] final_data_a [0:2**WORD_BITS-1];	
	wire [SMALL_DATA_WIDTH-1:0] final_data_b [0:2**WORD_BITS-1];
	
	wire [SMALL_DATA_WIDTH-1:0] cache_out_a [0:2**WORD_BITS-1];
	wire [SMALL_DATA_WIDTH-1:0] cache_out_b [0:2**WORD_BITS-1];
	
	genvar j;
	generate 
		for (j=0; j<2**WORD_BITS; j=j+1) begin: Gen1
			assign final_data_b[j] = data_b[SMALL_DATA_WIDTH*(j+1)-1:SMALL_DATA_WIDTH*j];
			assign final_data_a[j] = data_a[SMALL_DATA_WIDTH*(j+1)-1:SMALL_DATA_WIDTH*j];
		end
	endgenerate 
	
	generate 
		for (j=0; j<2**WORD_BITS; j=j+1) begin: Gen2
			array #(.DATA_WIDTH(SMALL_DATA_WIDTH), .INDEX_WIDTH(INDEX_WIDTH))	arr
			(
				.data_a(final_data_a[j]), .data_b(final_data_b[j]),
				.addr_a(addr_a), .addr_b(addr_b),
				.we_a(we_a & valid_word_a[j]), .we_b(we_b), .clk(clk),
				.q_a(cache_out_a[j]), .q_b(cache_out_b[j])
			);
		end
	endgenerate
	
	generate 
		for (j=0; j<2**WORD_BITS; j=j+1) begin: Gen3
			assign q_a[SMALL_DATA_WIDTH*(j+1)-1:SMALL_DATA_WIDTH*j] = cache_out_a[j];
			assign q_b[SMALL_DATA_WIDTH*(j+1)-1:SMALL_DATA_WIDTH*j] = cache_out_b[j];
		end
	endgenerate 

endmodule
