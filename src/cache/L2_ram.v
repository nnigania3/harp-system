`timescale 1ns/100ps

module assoc_cache
#(parameter DATA_WIDTH=256, parameter ADDR_WIDTH=32, parameter INDEX_WIDTH=9, parameter LINE_BITS=5, parameter ASSOC_BITS=2)
(
	input clk,
	input clkby2,
	input reset,
	input valid_in,
	input [DATA_WIDTH-1:0] data_a, data_b,
	input [ADDR_WIDTH-1:0] addr_a, addr_b,
	input [2**ASSOC_BITS-1:0] we_a, we_b, 
	input [2**ASSOC_BITS-1:0] dirty_a_i, dirty_b_i,
	input [2**ASSOC_BITS-1:0] valid_a_i, valid_b_i,
	input [2**ASSOC_BITS-1:0] sel_a, sel_b,
	
	output [2**ASSOC_BITS-1:0] dirty_a_out, dirty_b_out,
	output valid_a_out, valid_b_out,
	output [2**ASSOC_BITS-1:0] hit_a, hit_b,
	output [ADDR_WIDTH-LINE_BITS-INDEX_WIDTH-1:0] tag_out_a, tag_out_b,
	output [DATA_WIDTH-1:0] q_a, q_b
);

	localparam ASSOCIATIVITY = 2**ASSOC_BITS;
	localparam TAG_BITS = ADDR_WIDTH-LINE_BITS-INDEX_WIDTH;
	
	wire [DATA_WIDTH-1:0] data_a_dec [0:ASSOCIATIVITY-1];
	wire [DATA_WIDTH-1:0] data_b_dec [0:ASSOCIATIVITY-1];
	wire [DATA_WIDTH-1:0] cache_out_a [0:ASSOCIATIVITY-1];
	wire [DATA_WIDTH-1:0] cache_out_b [0:ASSOCIATIVITY-1];
	
	wire [(DATA_WIDTH*ASSOCIATIVITY)-1:0] cache_bus_a; 
	wire [(DATA_WIDTH*ASSOCIATIVITY)-1:0] cache_bus_b;
	wire [(TAG_BITS*ASSOCIATIVITY)-1:0] tag_bus_a; 
	wire [(TAG_BITS*ASSOCIATIVITY)-1:0] tag_bus_b;
	
	wire [DATA_WIDTH-1:0] cache_a_final;
	wire [DATA_WIDTH-1:0] cache_b_final;
	
	wire [INDEX_WIDTH-1:0] index_a;
	wire [INDEX_WIDTH-1:0] index_b;
	
	wire [TAG_BITS-1:0] tag_a;
	wire [TAG_BITS-1:0] tag_b;
	
	wire [TAG_BITS-1:0] tag_a_dec [0:ASSOCIATIVITY-1];
	wire [TAG_BITS-1:0] tag_b_dec [0:ASSOCIATIVITY-1];
	wire [TAG_BITS-1:0] tag_out_a_dec [0:ASSOCIATIVITY-1];
	wire [TAG_BITS-1:0] tag_out_b_dec [0:ASSOCIATIVITY-1];
	
	wire [ASSOCIATIVITY-1:0] dirty_a_o;
	wire [ASSOCIATIVITY-1:0] dirty_b_o;
	wire [ASSOCIATIVITY-1:0] valid_a_o;
	wire [ASSOCIATIVITY-1:0] valid_b_o;
	
	genvar j;
	
	assign dirty_a_out = (dirty_a_o);// & sel_a);
	assign dirty_b_out = (dirty_b_o);// & sel_b);
	assign valid_a_out = | (valid_a_o);// & sel_a);
	assign valid_b_out = | (valid_b_o);// & sel_b);
	
	assign q_a = cache_a_final;
	assign q_b = cache_b_final;

 	reg [INDEX_WIDTH-1:0]index_a_last;
        always@(posedge clkby2) begin
		index_a_last <= index_a;
	end
	
	assign index_a = addr_a[INDEX_WIDTH+LINE_BITS-1:LINE_BITS];
	assign index_b = addr_b[INDEX_WIDTH+LINE_BITS-1:LINE_BITS];
	
	assign tag_a = addr_a[ADDR_WIDTH-1:INDEX_WIDTH+LINE_BITS];
	assign tag_b = addr_b[ADDR_WIDTH-1:INDEX_WIDTH+LINE_BITS];
	
	generate 
		for (j=0; j<ASSOCIATIVITY; j=j+1) begin: Gen1
			assign #0.5 hit_a[j] = ( valid_in & valid_a_o[j]) ? ((tag_a_dec[j] == tag_out_a_dec[j])&&(index_a_last == index_a)) : 1'b0;
			assign #0.5 hit_b[j] = ( valid_b_i[j] & valid_b_o[j]) ? (tag_b_dec[j] == tag_out_b_dec[j]) : 1'b0;
		end
	endgenerate
	
	generate 
		for (j=0; j<ASSOCIATIVITY; j=j+1) begin: Gen2
			assign data_a_dec[j] = data_a;
			assign data_b_dec[j] = data_b;
			assign tag_a_dec[j] = tag_a;
			assign tag_b_dec[j] = tag_b;
		end
	endgenerate

	generate 
		for (j=0; j<ASSOCIATIVITY; j=j+1) begin: Gen3
			array #(.DATA_WIDTH(DATA_WIDTH), .INDEX_WIDTH(INDEX_WIDTH))	arr (
				.data_a(data_a_dec[j]), .data_b(data_b_dec[j]),
				.addr_a(index_a), .addr_b(index_b),
				.we_a(we_a[j]), .we_b(we_b[j]), .clk(clk),
				.q_a(cache_out_a[j]), .q_b(cache_out_b[j])
			);
		end
	endgenerate
	
	generate 
		for (j=0; j<ASSOCIATIVITY; j=j+1) begin: Gen4
			L2_tag_array #(.TAG_BITS(TAG_BITS), .INDEX_WIDTH(INDEX_WIDTH)) tag_ram (
				.tag_a(tag_a_dec[j]), .tag_b(tag_b_dec[j]),
				.dirty_a_i(dirty_a_i[j]), .dirty_b_i(dirty_b_i[j]),
				.valid_a_i(valid_a_i[j]), .valid_b_i(valid_b_i[j]),
				.addr_a(index_a), .addr_b(index_b),
				.we_a(we_a[j]), .we_b(we_b[j]), .clk(clk), .new_clk(clkby2),
				.q_a(tag_out_a_dec[j]), .q_b(tag_out_b_dec[j]),
				.dirty_a_o(dirty_a_o[j]), .dirty_b_o(dirty_b_o[j]),
				.valid_a_o(valid_a_o[j]), .valid_b_o(valid_b_o[j])
			);
		end
	endgenerate
	
	generate
		for (j=0; j<ASSOCIATIVITY; j=j+1) begin: Gen5
			assign cache_bus_a[DATA_WIDTH*(j+1)-1 : DATA_WIDTH*j] = cache_out_a[j];
			assign cache_bus_b[DATA_WIDTH*(j+1)-1 : DATA_WIDTH*j] = cache_out_b[j];
			assign tag_bus_a[TAG_BITS*(j+1)-1 : TAG_BITS*j] = tag_out_a_dec[j];
			assign tag_bus_b[TAG_BITS*(j+1)-1 : TAG_BITS*j] = tag_out_b_dec[j];
		end
	endgenerate
	
	GenericOneHotMux #(.WIDTH(DATA_WIDTH),.SEL_BITS(ASSOCIATIVITY)) mux1
	(
		.in_bus(cache_bus_a), 
		.sel(sel_a),
		.out(cache_a_final)
	);
	
	GenericOneHotMux #(.WIDTH(DATA_WIDTH),.SEL_BITS(ASSOCIATIVITY)) mux2
	(
		.in_bus(cache_bus_b), 
		.sel(sel_b),
		.out(cache_b_final)
	);
	
	GenericOneHotMux #(.WIDTH(ADDR_WIDTH-LINE_BITS-INDEX_WIDTH),.SEL_BITS(ASSOCIATIVITY)) mux3
	(
		.in_bus(tag_bus_a), 
		.sel(sel_a),
		.out(tag_out_a)
	);
	
	GenericOneHotMux #(.WIDTH(ADDR_WIDTH-LINE_BITS-INDEX_WIDTH),.SEL_BITS(ASSOCIATIVITY)) mux4
	(
		.in_bus(tag_bus_b), 
		.sel(sel_b),
		.out(tag_out_b)
	);
	
endmodule
