module Arbiter1
#(parameter num_L1s=2, parameter num_L1s_log = 1, parameter addr_width = 32, parameter data_width = 256, parameter cpu_id_width = 2, parameter FIFO_depth_log = 3)
(
	reset, enable,
	
	clk_L1,
	valid_L1_in, rw_L1_in, addr_L1_in, data_L1_in, id_L1_in,

	clk_L2, 
	valid_L2_in, rw_L2_in, addr_L2_in, data_L2_in, id_L2_in, which_L1,
	
	L1_to_L2_full, L1_to_L2_empty, 

	valid_L1_out, rw_L1_out, addr_L1_out, data_L1_out, id_L1_out, accept_L1, which_L1_out,
	
	valid_L2_out, rw_L2_out, addr_L2_out, data_L2_out, id_L2_out, accept_L2,
	
	L2_to_L1_full, L2_to_L1_empty
	
);
	input reset;
	input enable;
	//data coming form L1
	input clk_L1;
	input [num_L1s-1:0] valid_L1_in, rw_L1_in;
	input [(addr_width*num_L1s)-1:0] addr_L1_in;
	input [(data_width*num_L1s)-1:0] data_L1_in;
	input [(cpu_id_width*num_L1s)-1:0] id_L1_in;
	
	//data coming from L2
	input clk_L2;
	input valid_L2_in, rw_L2_in;
	input [addr_width-1:0] addr_L2_in;
	input [data_width-1:0] data_L2_in;
	input [cpu_id_width-1:0] id_L2_in;

	input [num_L1s_log-1:0] which_L1; 
	
	output [num_L1s-1:0] L1_to_L2_full, L1_to_L2_empty;
	
	//Data goign to L1
	output [num_L1s-1:0] valid_L1_out, rw_L1_out;
	output [(addr_width*num_L1s)-1:0] addr_L1_out;
	output [(data_width*num_L1s)-1:0] data_L1_out;
	output [(cpu_id_width*num_L1s)-1:0] id_L1_out;
	
	input [num_L1s-1:0] accept_L1; //signal coming form L1s accepting the data packets form their FIFOS
	
	//data goign to L2
	output valid_L2_out, rw_L2_out;
	output [addr_width-1:0] addr_L2_out;
	output [data_width-1:0] data_L2_out;
	output [cpu_id_width-1:0] id_L2_out;
	
	output [num_L1s_log-1:0] which_L1_out; 
	
	input [num_L1s_log-1:0] accept_L2; //signal coming from L2 accepting the data from its FIFO

	output [num_L1s-1:0] L2_to_L1_full, L2_to_L1_empty;
	
	wire [num_L1s-1:0] accept_L1_formatted_1;
	//These are the outputs of the L1 to L2 FIFOS
	wire [num_L1s-1:0] valid_L1_in_w, rw_L1_in_w;
	wire [(addr_width)-1:0] addr_L1_in_w[0 : num_L1s-1];
	wire [(data_width)-1:0] data_L1_in_w[0 : num_L1s-1];
	wire [(cpu_id_width)-1:0] id_L1_in_w[0 : num_L1s-1];	
	
	reg [num_L1s_log-1:0] L1_to_L2_select;
	
	generate 
		genvar h;
		for(h=0; h < num_L1s; h=h+1)begin : Gen1
			assign accept_L1_formatted_1[h] = (h == L1_to_L2_select)?accept_L2:0; 
			FIFO #(.index_bits(FIFO_depth_log), .data_width(addr_width+data_width+cpu_id_width+1)) L1_to_L2_FIFO_0 (.clk(clk_L1), .enable(enable), .reset(reset), .push(valid_L1_in[h]), 
					.push_tag({addr_L1_in[(h+1)*addr_width -1: h*addr_width], data_L1_in[(h+1)*data_width-1:(h)*data_width], id_L1_in[(h+1)*cpu_id_width-1:(h)*cpu_id_width], rw_L1_in[h]}), .pop(accept_L1_formatted_1[h]), 
					.free_tag({addr_L1_in_w[h], data_L1_in_w[h], id_L1_in_w[h], rw_L1_in_w[h]}), .free_tag_valid(valid_L1_in_w[h]), 
					.empty(L1_to_L2_empty[h]), .full(L1_to_L2_full[h]));
        		assign valid_L1_out[h] = (which_L1 == h) ? valid_L2_in : 1'b0;
		end
	endgenerate              
	
	integer i; //This is where we select whihc FIFO gets forwarded to the L2// Add logic to expand it for higher no of caches, only place in code which needs a change, remove priority
	always @ (*) begin
		if(valid_L1_in_w[0] == 1)begin
			L1_to_L2_select <= 0;
		end else begin
			L1_to_L2_select <= 1;
		end
	end

	//Assign signals L1 ->>> L2	
	assign valid_L2_out = valid_L1_in_w  [L1_to_L2_select];
	assign rw_L2_out    = rw_L1_in_w     [L1_to_L2_select];
	assign addr_L2_out  = addr_L1_in_w   [L1_to_L2_select];
	assign data_L2_out  = data_L1_in_w   [L1_to_L2_select];
	assign id_L2_out    = id_L1_in_w     [L1_to_L2_select];
	assign which_L1_out = L1_to_L2_select;
	//Assign signals L2 ->>> L1
	assign data_L1_out = {num_L1s{data_L2_in}};
	assign id_L1_out   = {num_L1s{id_L2_in}};
//        assign valid_L1_out= (which_L1 == 1'b0) ? {1'b0, valid_L2_in} : {valid_L2_in, 1'b0}; //this is covered in the Gen1 block
endmodule

