`timescale 1ns/100ps

module Arbiter1_test();
	parameter num_L1s=2; 
	parameter num_L1s_log = 1; 
	parameter addr_width = 32;
	parameter data_width = 256; 
	parameter cpu_id_width = 2; 
	parameter FIFO_depth_log = 3;
	
	
	reg reset;
	reg enable;
	//data coming form L1
	reg clk_L1;
	reg clk_L2;
	
	reg [num_L1s-1:0] valid_L1_in, rw_L1_in;
	reg [(addr_width*num_L1s)-1:0] addr_L1_in;
	reg [(data_width*num_L1s)-1:0] data_L1_in;
	reg [(cpu_id_width*num_L1s)-1:0] id_L1_in;
	
	//data coming from L2
	reg valid_L2_in, rw_L2_in;
	reg [addr_width-1:0] addr_L2_in;
	reg [data_width-1:0] data_L2_in;
	reg [cpu_id_width-1:0] id_L2_in;

	reg [num_L1s_log-1:0] which_L1; 
	
	wire [num_L1s-1:0] L1_to_L2_full, L1_to_L2_empty;
	
	//Data goign to L1
	wire [num_L1s-1:0] valid_L1_out, rw_L1_out;
	wire [(addr_width*num_L1s)-1:0] addr_L1_out;
	wire [(data_width*num_L1s)-1:0] data_L1_out;
	wire [(cpu_id_width*num_L1s)-1:0] id_L1_out;
	
	reg [num_L1s-1:0] accept_L1; //signal coming form L1s accepting the data packets form their FIFOS
	
	//data goign to L2
	wire valid_L2_out, rw_L2_out;
	wire [addr_width-1:0] addr_L2_out;
	wire [data_width-1:0] data_L2_out;
	wire [cpu_id_width-1:0] id_L2_out;
	
	wire [num_L1s_log-1:0] which_L1_out; 
	
	reg [num_L1s_log-1:0] accept_L2; //signal coming from L2 accepting the data from its FIFO

	wire [num_L1s-1:0] L2_to_L1_full, L2_to_L1_empty;
	
	
	Arbiter1
	#(.num_L1s(num_L1s), .num_L1s_log(num_L1s_log), .addr_width(addr_width), .data_width(data_width), .cpu_id_width(cpu_id_width), .FIFO_depth_log(FIFO_depth_log))
	arby
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
	
	
	
	//We need to set the clks
	always #5 clk_L1 = ~clk_L1;
	always #20 clk_L2 = ~clk_L2;

	initial begin 
       		$dumpfile("dump.vcd");
       		$dumpvars(2, Arbiter1_test);
		clk_L1 = 1;
		clk_L2 = 1;
		
		reset = 0;
		enable = 0;
		
		//Data coming from L1's
		valid_L1_in = 2'b00;
		rw_L1_in = 2'b00;
		addr_L1_in = {32'd0, 32'd0};
		data_L1_in = {256'd0, 256'd0};
		id_L1_in = {2'd0, 2'd0};
	
		//Data coming from L2
		valid_L2_in = 1'b0;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd0};
		data_L2_in = {256'd0};
		id_L2_in = {2'd0};
		which_L1 = 1'b0;
		
		//Next we want the accept signals 
		accept_L2 = 1'b0;
		accept_L1 = 2'b00;
		
		#15

		reset = 1;
		enable = 0;
		
		//Data coming from L1's
		valid_L1_in = 2'b00;
		rw_L1_in = 2'b00;
		addr_L1_in = {32'd0, 32'd0};
		data_L1_in = {256'd0, 256'd0};
		id_L1_in = {2'd0, 2'd0};
	
		//Data coming from L2
		valid_L2_in = 1'b0;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd0};
		data_L2_in = {256'd0};
		id_L2_in = {2'd0};
		which_L1 = 1'b0;
		
		//Next we want the accept signals 
		accept_L2 = 1'b0;
		accept_L1 = 2'b00;

		#10
		
		reset = 0;
		enable = 1;
		
		//Data coming from L1's
		valid_L1_in = 2'b00;
		rw_L1_in = 2'b00;
		addr_L1_in = {32'd0, 32'd0};
		data_L1_in = {256'd0, 256'd0};
		id_L1_in = {2'd0, 2'd0};
	
		//Data coming from L2
		valid_L2_in = 1'b0;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd0};
		data_L2_in = {256'd0};
		id_L2_in = {2'd0};
		which_L1 = 1'b0;
		
		//Next we want the accept signals 
		accept_L2 = 1'b0;
		accept_L1 = 2'b00;
		
		#10
		
		reset = 0;
		enable = 1;
		
		//Data coming from L1's
		valid_L1_in = 2'b01;
		rw_L1_in = 2'b01;
		addr_L1_in = {32'd0, 32'd70};
		data_L1_in = {256'd0, 256'd80};
		id_L1_in = {2'd0, 2'd2};
	
		//Data coming from L2
		valid_L2_in = 1'b1;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd20};
		data_L2_in = {256'd21};
		id_L2_in = {2'd1};
		which_L1 = 1'b0;
		
		//Next we want the accept signals 
		accept_L2 = 1'b1;
		accept_L1 = 2'b00;

		#10
		
		reset = 0;
		enable = 1;
		
		//Data coming from L1's
		valid_L1_in = 2'b11;
		rw_L1_in = 2'b11;
		addr_L1_in = {32'd90, 32'd140};
		data_L1_in = {256'd100, 256'd160};
		id_L1_in = {2'd1, 2'd2};
	
		//Data coming from L2
		valid_L2_in = 1'b1;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd30};
		data_L2_in = {256'd31};
		id_L2_in = {2'd3};
		which_L1 = 1'b1;
		
		//Next we want the accept signals 
		accept_L2 = 1'b1;
		accept_L1 = 2'b00;
		
		#10
		
		reset = 0;
		enable = 1;
		
		//Data coming from L1's
		valid_L1_in = 2'b00;
		rw_L1_in = 2'b00;
		addr_L1_in = {32'd0, 32'd0};
		data_L1_in = {256'd0, 256'd0};
		id_L1_in = {2'd0, 2'd0};
	
		//Data coming from L2
		valid_L2_in = 1'b0;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd0};
		data_L2_in = {256'd0};
		id_L2_in = {2'd0};
		which_L1 = 1'b0;
		
		//Next we want the accept signals 
		accept_L2 = 1'b1;
		accept_L1 = 2'b00;
		
		#10
		
		reset = 0;
		enable = 1;
		
		//Data coming from L1's
		valid_L1_in = 2'b00;
		rw_L1_in = 2'b00;
		addr_L1_in = {32'd0, 32'd0};
		data_L1_in = {256'd0, 256'd0};
		id_L1_in = {2'd0, 2'd0};
	
		//Data coming from L2
		valid_L2_in = 1'b0;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd0};
		data_L2_in = {256'd0};
		id_L2_in = {2'd0};
		which_L1 = 1'b0;
		
		//Next we want the accept signals 
		accept_L2 = 1'b1;
		accept_L1 = 2'b00;
		
		#10
		
		reset = 0;
		enable = 1;
		
		//Data coming from L1's
		valid_L1_in = 2'b00;
		rw_L1_in = 2'b00;
		addr_L1_in = {32'd0, 32'd0};
		data_L1_in = {256'd0, 256'd0};
		id_L1_in = {2'd0, 2'd0};
	
		//Data coming from L2
		valid_L2_in = 1'b0;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd0};
		data_L2_in = {256'd0};
		id_L2_in = {2'd0};
		which_L1 = 1'b0;
		
		//Next we want the accept signals 
		accept_L2 = 1'b1;
		accept_L1 = 2'b00;

		#10
		
		reset = 0;
		enable = 1;
		
		//Data coming from L1's
		valid_L1_in = 2'b00;
		rw_L1_in = 2'b00;
		addr_L1_in = {32'd0, 32'd0};
		data_L1_in = {256'd0, 256'd0};
		id_L1_in = {2'd0, 2'd0};
	
		//Data coming from L2
		valid_L2_in = 1'b0;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd0};
		data_L2_in = {256'd0};
		id_L2_in = {2'd0};
		which_L1 = 1'b0;
		
		//Next we want the accept signals 
		accept_L2 = 1'b1;
		accept_L1 = 2'b00;
		
		#10
		
		reset = 0;
		enable = 1;
		
		//Data coming from L1's
		valid_L1_in = 2'b00;
		rw_L1_in = 2'b00;
		addr_L1_in = {32'd0, 32'd0};
		data_L1_in = {256'd0, 256'd0};
		id_L1_in = {2'd0, 2'd0};
	
		//Data coming from L2
		valid_L2_in = 1'b0;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd0};
		data_L2_in = {256'd0};
		id_L2_in = {2'd0};
		which_L1 = 1'b0;
		
		//Next we want the accept signals 
		accept_L2 = 1'b1;
		accept_L1 = 2'b00;
		
		
		#10
		
		reset = 0;
		enable = 1;
		
		//Data coming from L1's
		valid_L1_in = 2'b00;
		rw_L1_in = 2'b00;
		addr_L1_in = {32'd0, 32'd0};
		data_L1_in = {256'd0, 256'd0};
		id_L1_in = {2'd0, 2'd0};
	
		//Data coming from L2
		valid_L2_in = 1'b0;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd0};
		data_L2_in = {256'd0};
		id_L2_in = {2'd0};
		which_L1 = 1'b0;
		
		//Next we want the accept signals 
		accept_L2 = 1'b1;
		accept_L1 = 2'b00;
		
		
		
		#10
		
		reset = 0;
		enable = 1;
		
		//Data coming from L1's
		valid_L1_in = 2'b00;
		rw_L1_in = 2'b00;
		addr_L1_in = {32'd0, 32'd0};
		data_L1_in = {256'd0, 256'd0};
		id_L1_in = {2'd0, 2'd0};
	
		//Data coming from L2
		valid_L2_in = 1'b0;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd0};
		data_L2_in = {256'd0};
		id_L2_in = {2'd0};
		which_L1 = 1'b0;
		
		//Next we want the accept signals 
		accept_L2 = 1'b1;
		accept_L1 = 2'b00;

		#10
		
		reset = 0;
		enable = 1;
		
		//Data coming from L1's
		valid_L1_in = 2'b00;
		rw_L1_in = 2'b00;
		addr_L1_in = {32'd0, 32'd0};
		data_L1_in = {256'd0, 256'd0};
		id_L1_in = {2'd0, 2'd0};
	
		//Data coming from L2
		valid_L2_in = 1'b0;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd0};
		data_L2_in = {256'd0};
		id_L2_in = {2'd0};
		which_L1 = 1'b0;
		
		//Next we want the accept signals 
		accept_L2 = 1'b1;
		accept_L1 = 2'b00;

		#10
		
		reset = 0;
		enable = 1;
		
		//Data coming from L1's
		valid_L1_in = 2'b00;
		rw_L1_in = 2'b00;
		addr_L1_in = {32'd0, 32'd0};
		data_L1_in = {256'd0, 256'd0};
		id_L1_in = {2'd0, 2'd0};
	
		//Data coming from L2
		valid_L2_in = 1'b0;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd0};
		data_L2_in = {256'd0};
		id_L2_in = {2'd0};
		which_L1 = 1'b0;
		
		//Next we want the accept signals 
		accept_L2 = 1'b1;
		accept_L1 = 2'b00;

		#10
		
		reset = 0;
		enable = 1;
		
		//Data coming from L1's
		valid_L1_in = 2'b00;
		rw_L1_in = 2'b00;
		addr_L1_in = {32'd0, 32'd0};
		data_L1_in = {256'd0, 256'd0};
		id_L1_in = {2'd0, 2'd0};
	
		//Data coming from L2
		valid_L2_in = 1'b0;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd0};
		data_L2_in = {256'd0};
		id_L2_in = {2'd0};
		which_L1 = 1'b0;
		
		//Next we want the accept signals 
		accept_L2 = 1'b1;
		accept_L1 = 2'b10;

		#10
		
		reset = 0;
		enable = 1;
		
		//Data coming from L1's
		valid_L1_in = 2'b00;
		rw_L1_in = 2'b00;
		addr_L1_in = {32'd0, 32'd0};
		data_L1_in = {256'd0, 256'd0};
		id_L1_in = {2'd0, 2'd0};
	
		//Data coming from L2
		valid_L2_in = 1'b0;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd0};
		data_L2_in = {256'd0};
		id_L2_in = {2'd0};
		which_L1 = 1'b0;
		
		//Next we want the accept signals 
		accept_L2 = 1'b1;
		accept_L1 = 2'b01;

		#10
		
		reset = 0;
		enable = 1;
		
		//Data coming from L1's
		valid_L1_in = 2'b00;
		rw_L1_in = 2'b00;
		addr_L1_in = {32'd0, 32'd0};
		data_L1_in = {256'd0, 256'd0};
		id_L1_in = {2'd0, 2'd0};
	
		//Data coming from L2
		valid_L2_in = 1'b0;
		rw_L2_in = 1'b0;
		addr_L2_in = {32'd0};
		data_L2_in = {256'd0};
		id_L2_in = {2'd0};
		which_L1 = 1'b0;
		
		//Next we want the accept signals 
		accept_L2 = 1'b1;
		accept_L1 = 2'b00;


		
		#10
		
		$finish;
		
	end
		
		
endmodule
