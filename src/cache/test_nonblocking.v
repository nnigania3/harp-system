`timescale 1ns/100ps

module test_nonblocking;

	reg clk;
	reg clkby2;
	reg reset;	
	reg [31:0] addr_in; 		// address in from the core
	reg [31:0] data_in; 		// data from the core
	reg rw_in; 								// read / write command
	reg valid_in; 							//  valid reg on the addr, data buses
	reg [2:0] id_in; 		// ld/st Q id for request
	
	wire [31:0] data_out;	// data to be given to the core
	wire [2:0] id_out;	// ld/st Q id for request being satisfied
	wire ready_out; 						// the memory request for which data is ready
	wire stall_out;							// the memory system cannot accept anymore requests
	
/*	wire [31:0] addr_l2_o;
	wire [255:0] data_l2_o;
	wire rw_l2_o;
	wire valid_l2_o;
	wire [3:0] id_l2_o;
	reg [255:0] data_l2_i;
	reg valid_l2_i;
	reg [3:0] id_l2_i;
	reg stall_l2_i;
*/	
	L2_cache cache
	(
		clk,
		clkby2,
		reset,
		addr_in, 		// address in from the core
		data_in, 		// data from the core
		rw_in, 								// read / write command
		valid_in, 							//  valid reg on the addr, data buses
		id_in, 		// ld/st Q id for request
		data_out,	// data to be given to the core
		id_out,	// ld/st Q id for request being satisfied
		ready_out, 				// the memory request for which data is ready
		stall_out 							// the memory system cannot accept anymore requests
		
/*		addr_l2_o,
		data_l2_o,
		rw_l2_o,
		valid_l2_o,
		id_l2_o,
		data_l2_i,
		valid_l2_i,
		id_l2_i,
		stall_l2_i
*/	);
	
	always #10 clk = ~clk;
	always #5 clkby2 = ~clkby2;
	
	initial 
	 begin 
			clk = 1;
			clkby2 = 1;
			reset = 0;
			rw_in = 0;
			addr_in = 0;
			id_in = 0;
			data_in = 0;
			valid_in = 0;
		#20
			reset = 1;
		#22
			rw_in = 1;
			addr_in = 97;
			id_in = 2;
			data_in = 8;
			valid_in = 1'b1;	
		#20
		if (stall_out) begin
			valid_in = 1'b0;
			#200;
		end
			rw_in = 1;
			addr_in = 1101;
			data_in = 16;
			id_in = 6;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			addr_in = 197;
			data_in = 8;
			valid_in = 1'b0;
		#20
			rw_in = 0;
			addr_in = 1201;
			data_in = 9875;
			id_in = 16;
			valid_in = 1'b1;
		#20
			addr_in = 0;
			id_in = 0;
			valid_in = 1'b0;
	//		@ (negedge stall_out);
		#20
			rw_in = 0;
			addr_in = 497;
			data_in = 0;
			id_in = 7;
			valid_in = 1'b1;
		#20
			rw_in = 1;
			addr_in = 999;
			data_in = 56;
			id_in = 8;
			valid_in = 1'b1;
		#20
			rw_in = 1;
			addr_in = 597;
			data_in = 1234;
			id_in = 17;
			valid_in = 1'b1;
		#20
		if (stall_out) begin
			valid_in = 1'b0;
			#200;
		end
			rw_in = 0;
			addr_in = 99;
			data_in = 77;
			id_in = 9;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			addr_in = 1101;
			data_in = 33;
			id_in = 10;
			valid_in = 1'b1;
		#20
		if (stall_out) begin
			valid_in = 1'b0;
			#200;
		end
			rw_in = 0;
			addr_in = 65733;
			data_in = 21;
			id_in = 21;
			valid_in = 1'b1;
		#20
		if (stall_out) begin
			valid_in = 1'b0;
			#200;
		end
			rw_in = 1;
			addr_in = 65633;
			data_in = 11;
			id_in = 11;
			valid_in = 1'b1;
		#20
			addr_in = 100;
			valid_in = 1'b0;
	//		@ (negedge stall_out);
		#20
			rw_in = 1;
			addr_in = 196707;
			data_in = 505;
			id_in = 12;
			valid_in = 1'b1;
		#20
		if (stall_out) begin
			valid_in = 1'b0;
			#200;
		end
			addr_in = 10;
			id_in = 10;
			valid_in = 1'b0;
	//		@ (negedge stall_out);
		#20
			rw_in = 0;
			addr_in = 196713;
			data_in = 000;
			id_in = 13;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			addr_in = 97;
			data_in = 0;
			id_in = 37;
			valid_in = 1'b1;
		#20
			addr_in = 10;
			id_in = 10;
			valid_in = 1'b0;
	//		@ (negedge ready_out);
/*		#20
			addr_in = 65633;
			id_in = 10;
			valid_in = 1'b0;
			@ (negedge stall_out);
*/		#20
			rw_in = 0;
			addr_in = 99;
			data_in = 56;
			id_in = 38;
			valid_in = 1'b1;
		#20
			rw_in = 1;
			addr_in = 99;
			data_in = 56;
			id_in = 39;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			addr_in = 197;
			data_in = 1234;
			id_in = 40;
			valid_in = 1'b1;
	/*	#20
			addr_in = 65633;
			id_in = 10;
			valid_in = 1'b0;
			@ (negedge stall_out);
	*/	#20
			rw_in = 0;
			addr_in = 196707;
			data_in = 77;
			id_in = 41;
			valid_in = 1'b1;
		#20
			rw_in = 1;
			addr_in = 297;
			id_in = 2;
			data_in = 8;
			valid_in = 1'b1;
		#20
			addr_in = 0;
			valid_in = 1'b0;
			@ (negedge stall_out);
 		#22
			rw_in = 1;
			addr_in = 301;
			data_in = 16;
			id_in = 6;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			addr_in = 297;
			data_in = 8;
			valid_in = 1'b0;
		#20
			rw_in = 0;
			addr_in = 201;
			data_in = 9875;
			id_in = 16;
			valid_in = 1'b1;
		#20
	//		addr_in = 0;
	//		id_in = 0;
	//		valid_in = 1'b0;
	//		@ (negedge stall_out);
	//	#22
			rw_in = 0;
			addr_in = 197;
			data_in = 0;
			id_in = 7;
			valid_in = 1'b1;
		#20
			rw_in = 1;
			addr_in = 299;
			data_in = 56;
			id_in = 8;
			valid_in = 1'b1;
		#20
			rw_in = 1;
			addr_in = 397;
			data_in = 1234;
			id_in = 17;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			addr_in = 299;
			data_in = 77;
			id_in = 9;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			addr_in = 301;
			data_in = 33;
			id_in = 10;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			addr_in = 75733;
			data_in = 21;
			id_in = 21;
			valid_in = 1'b1;
		#20
			addr_in = 0;
			id_in = 0;
			valid_in = 1'b0;
			@ (negedge stall_out);
		#22
			rw_in = 1;
			addr_in = 75633;
			data_in = 11;
			id_in = 11;
			valid_in = 1'b1;
		#20
			addr_in = 100;
			valid_in = 1'b0;
			@ (negedge stall_out);
		#2
			rw_in = 1;
			addr_in = 196707;
			data_in = 505;
			id_in = 12;
			valid_in = 1'b1;
		#20
	//		addr_in = 10;
	//		id_in = 10;
	//		valid_in = 1'b0;
	//		@ (negedge stall_out);
	//	#2
			rw_in = 0;
			addr_in = 196713;
			data_in = 000;
			id_in = 13;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			addr_in = 97;
			data_in = 0;
			id_in = 37;
			valid_in = 1'b1;
		#20
	//		addr_in = 10;
	//		id_in = 10;
	//		valid_in = 1'b0;
	//		@ (negedge ready_out);
/*		#20
			addr_in = 65633;
			id_in = 10;
			valid_in = 1'b0;
			@ (negedge stall_out);
*/		#20
			rw_in = 0;
			addr_in = 297;
			data_in = 1234;
			id_in = 40;
			valid_in = 1'b1;
	/*	#20
			addr_in = 65633;
			id_in = 10;
			valid_in = 1'b0;
			@ (negedge stall_out);
	*/	#20
			rw_in = 0;
			addr_in = 196707;
			data_in = 77;
			id_in = 41;
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
			@ (negedge stall_out);
		#1000
			$finish;
	 end

endmodule