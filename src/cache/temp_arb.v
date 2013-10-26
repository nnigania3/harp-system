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
	input [(addr_width)-1:0] addr_L1_in[0 : num_L1s-1];
	input [(data_width)-1:0] data_L1_in[0 : num_L1s-1];
	input [(cpu_id_width)-1:0] id_L1_in[0 : num_L1s-1];
	
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
	output [(addr_width)-1:0] addr_L1_out[0 : num_L1s-1];
	output [(data_width)-1:0] data_L1_out[0 : num_L1s-1];
	output [(cpu_id_width)-1:0] id_L1_out[0 : num_L1s-1];
	
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
		genvar i;
		for(i=0; i < num_L1s; i=i+1)begin : Gen2
			assign accept_L1_formatted_1[i] = (i == L1_to_L2_select)?accept_L2:0; 
		end
	endgenerate              

	generate 
		genvar h;
		for(h=0; h < num_L1s; h=h+1)begin : Gen1
	 	   FIFO #(.index_bits(FIFO_depth_log), .data_width(addr_width+data_width+cpu_id_width+1)) L1_to_L2_FIFO_0 (.clk(clk_L1), .enable(enable), .reset(reset), .push(valid_L1_in[h]), 
			.push_tag({addr_L1_in[h], data_L1_in[h], id_L1_in[h], rw_L1_in[h]}), .pop(accept_L1_formatted_1[h]), 
			.free_tag({addr_L1_in_w[h], data_L1_in_w[h], id_L1_in_w[h], rw_L1_in_w[h]}), .free_tag_valid(valid_L1_in_w[h]), 
			.empty(L1_to_L2_empty[h]), .full(L1_to_L2_full[h]));
		end
	endgenerate              
	
	//generate the FIFOs from L1 to the L2
	//L1_to_L2_O FIFO
/*	assign accept_L1_formatted_1[0] = (0 == L1_to_L2_select)?accept_L2:0; 
	assign accept_L1_formatted_1[1] = (1 == L1_to_L2_select)?accept_L2:0; 
	FIFO #(.index_bits(FIFO_depth_log), .data_width(addr_width+data_width+cpu_id_width+1)) L1_to_L2_FIFO_0 (.clk(clk_L1), .enable(enable), .reset(reset), .push(valid_L1_in[0]), 
			.push_tag({addr_L1_in[addr_width-1:0], data_L1_in[data_width-1:0], id_L1_in[cpu_id_width-1:0], rw_L1_in[0]}), .pop(accept_L1_formatted_1[0]), 
			.free_tag({addr_L1_in_w[addr_width-1:0], data_L1_in_w[data_width-1:0], id_L1_in_w[cpu_id_width-1:0], rw_L1_in_w[0]}), .free_tag_valid(valid_L1_in_w[0]), 
			.empty(L1_to_L2_empty[0]), .full(L1_to_L2_full[0]));
	
	//L1_to_L2_1 FIFO
	FIFO #(.index_bits(FIFO_depth_log), .data_width(addr_width+data_width+cpu_id_width+1)) L1_to_L2_FIFO_1 (.clk(clk_L1), .enable(enable), .reset(reset), .push(valid_L1_in[1]), 
			.push_tag({addr_L1_in[(2*addr_width)-1:addr_width], data_L1_in[(2*data_width)-1:data_width], id_L1_in[(2*cpu_id_width)-1:cpu_id_width], rw_L1_in[1]}), .pop(accept_L1_formatted_1[1]), 
			.free_tag({addr_L1_in_w[(2*addr_width)-1:addr_width], data_L1_in_w[(2*data_width)-1:data_width], id_L1_in_w[(2*cpu_id_width)-1:cpu_id_width], rw_L1_in_w[1]}), .free_tag_valid(valid_L1_in_w[1]), 
			.empty(L1_to_L2_empty[1]), .full(L1_to_L2_full[1]));
*/	
	integer i; //This is where we select whihc FIFO gets forwarded to the L2
	always @ (*) begin
		if(valid_L1_in_w[0] == 1)begin
			L1_to_L2_select <= 0;
		end else begin
			L1_to_L2_select <= 1;
		end
	end
	
	assign valid_L2_out = valid_L1_in_w[L1_to_L2_select];
	assign rw_L2_out    = rw_L1_in_w   [L1_to_L2_select];
	assign addr_L2_out  = addr_L1_in_w [L1_to_L2_select];
	assign data_L2_out  = data_L1_in_w [L1_to_L2_select];
	assign id_L2_out    = id_L1_in_w   [L1_to_L2_select];
	assign which_L1_out = L1_to_L2_select;

/*	assign addr_L2_out  = (L1_to_L2_select == 0)?addr_L1_in_w[addr_width-1:0]:addr_L1_in_w[(2*addr_width)-1:addr_width];
	assign data_L2_out  = (L1_to_L2_select == 0)?data_L1_in_w[data_width-1:0]:data_L1_in_w[(2*data_width)-1:data_width];
	assign id_L2_out    = (L1_to_L2_select == 0)?id_L1_in_w[cpu_id_width-1:0]:id_L1_in_w[(2*cpu_id_width)-1:cpu_id_width];
*/
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Next we need to create the components which go from the L2 to L1
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	assign data_L1_out = {data_L2_in, data_L2_in};
	assign id_L1_out   = {id_L2_in, id_L2_in};
        assign valid_L1_out= (which_L1 == 1'b0) ? {1'b0, valid_L2_in} : {valid_L2_in, 1'b0};
endmodule

/*	
	//We first need to spread out the L2 inputs so that they can be inputted to 2 different FIFOS 
	
	//First we need to shorten the valid signal (push for FIFO) from the L2 to avoid multiple dat being inserted
	wire L2_valid_formatted; 
//	slow_to_fast_clk_signal #(.num_cycles(4)) valid_slow_to_fast_signal_conversion (.signal_in(valid_L2_in), .signal_out(L2_valid_formatted), .clk_fast(clk_L1), .clk_slow(clk_L2), .reset(reset));
	
	
	//these are the expanded wires
	wire [num_L1s-1:0]valid_L2_in_ex, rw_L2_in_ex;
	wire [(num_L1s*addr_width)-1:0] addr_L2_in_ex;
	wire [(num_L1s*data_width)-1:0] data_L2_in_ex;
	wire [(num_L1s*cpu_id_width)-1:0] id_L2_in_ex; 
	
	bus_signal_switcher #(.num_buses(num_L1s), .num_buses_log(num_L1s_log) = 1, .bus_width()) expander (select, data_in, bus_out);
	
	bus_signal_switcher #(.num_buses(num_L1s), .num_buses_log(num_L1s_log), .bus_width(1)) valid_expander (.select(which_L1), .data_in(L2_valid_formatted), .bus_out(valid_L2_in_ex));
	bus_signal_switcher #(.num_buses(num_L1s), .num_buses_log(num_L1s_log), .bus_width(data_width)) data_expander (.select(which_L1), .data_in(data_L2_in), .bus_out(data_L2_in_ex));
	bus_signal_switcher #(.num_buses(num_L1s), .num_buses_log(num_L1s_log), .bus_width(cpu_id_width)) id_expander (.select(which_L1), .data_in(id_L2_in), .bus_out(id_L2_in_ex));
	bus_signal_switcher #(.num_buses(num_L1s), .num_buses_log(num_L1s_log), .bus_width(1)) rw_expander (.select(which_L1), .data_in(rw_L2_in), .bus_out(rw_L2_in_ex));
	bus_signal_switcher #(.num_buses(num_L1s), .num_buses_log(num_L1s_log), .bus_width(addr_width)) addr_expander (.select(which_L1), .data_in(addr_L2_in), .bus_out(addr_L2_in_ex));
	
	//Next we need to create the FIFOs
	//generate the FIFOs from L2 to the L1
	//L1_to_L2_O FIFO
	FIFO #(.index_bits(FIFO_depth_log), .data_width(addr_width+data_width+cpu_id_width+1)) L2_to_L1_FIFO_0 (.clk(clk_L1), .enable(enable), .reset(reset), .push(valid_L2_in_ex[0]), 
			.push_tag({addr_L2_in_ex[addr_width-1:0], data_L2_in_ex[data_width-1:0], id_L2_in_ex[cpu_id_width-1:0], rw_L2_in_ex[0]}), .pop(accept_L1[0]), 
			.free_tag({addr_L1_out[addr_width-1:0], data_L1_out[data_width-1:0], id_L1_out[cpu_id_width-1:0], rw_L1_out[0]}), .free_tag_valid(valid_L1_out[0]), 
			.empty(L2_to_L1_empty[0]), .full(L2_to_L1_full[0]));

	FIFO #(.index_bits(FIFO_depth_log), .data_width(addr_width+data_width+cpu_id_width+1)) L2_to_L1_FIFO_1 (.clk(clk_L1), .enable(enable), .reset(reset), .push(valid_L2_in_ex[1]), 
			.push_tag({addr_L2_in_ex[(2*addr_width)-1:addr_width], data_L2_in_ex[(2*data_width)-1:data_width], id_L2_in_ex[(2*cpu_id_width)-1:cpu_id_width], rw_L2_in_ex[1]}), .pop(accept_L1[1]), 
			.free_tag({addr_L1_out[(2*addr_width)-1:addr_width], data_L1_out[(2*data_width)-1:data_width], id_L1_out[(2*cpu_id_width)-1:cpu_id_width], rw_L1_out[1]}), .free_tag_valid(valid_L1_out[1]), 
			.empty(L2_to_L1_empty[1]), .full(L2_to_L1_full[1]));
*/	
