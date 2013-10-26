`timescale 1ns/100ps

module test;

	reg clk;
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
	wire clk1;
	freq_div_nn #(.DIVLOG(1)) freq_div1 (clk, clk1);
	
	cache_subsystem cache
	(
		clk,
		clk1,
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
	
	initial 
	 begin 
			clk = 1; 
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
//			addr_in = 0;
//			valid_in = 1'b0;
//			@ (negedge stall_out);
 //		#2
			rw_in = 1;
			addr_in = 301;
			data_in = 16;
			id_in = 6;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			valid_in = 1'b0;
		#20
			rw_in = 0;
			addr_in = 37;
			data_in = 8;
			valid_in = 1'b0;
		#60
			rw_in = 0;
			addr_in = 201;
			data_in = 9875;
			id_in = 16;
			valid_in = 1'b1;
		#20
			addr_in = 0;
			id_in = 0;
			valid_in = 1'b0;
			@ (negedge stall_out);
		#22
			rw_in = 0;
			addr_in = 97;
			data_in = 0;
			id_in = 7;
			valid_in = 1'b1;
		#20
			rw_in = 1;
			addr_in = 99;
			data_in = 56;
			id_in = 8;
			valid_in = 1'b1;
		#200
			rw_in = 1;
			addr_in = 197;
			data_in = 1234;
			id_in = 17;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			addr_in = 99;
			data_in = 77;
			id_in = 9;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			addr_in = 101;
			data_in = 33;
			id_in = 10;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			addr_in = 65733;
			data_in = 21;
			id_in = 21;
			valid_in = 1'b1;
		#20
			addr_in = 0;
			id_in = 0;
			valid_in = 1'b0;
	//		@ (negedge stall_out);
		#22
			rw_in = 0;
			addr_in = 65633;
			data_in = 11;
			id_in = 11;
			valid_in = 1'b1;
		#20
	//		addr_in = 100;
	//		valid_in = 1'b0;
	//		@ (negedge stall_out);
	//	#2
			rw_in = 1;
			addr_in = 196407;
			data_in = 505;
			id_in = 12;
			valid_in = 1'b1;
		#20
	//		rw_in = 0;
	//		addr_in = 65633;
	//		id_in = 10;
	//		valid_in = 1'b0;
	//		@ (negedge stall_out);
	//	#2
			rw_in = 0;
			addr_in = 196513;
			data_in = 000;
			id_in = 13;
			valid_in = 1'b1;
		#20
			addr_in = 65633;
			id_in = 10;
			valid_in = 1'b0;
	//		@ (negedge stall_out);
		#20
			rw_in = 0;
			addr_in = 97;
			data_in = 0;
			id_in = 37;
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
			@ (negedge ready_out);
		#2
			rw_in = 0;
			addr_in = 99;
			data_in = 56;
			id_in = 38;
			valid_in = 1'b1;
		#20
			rw_in = 1;
			addr_in = 105;
			data_in = 45;
			id_in = 39;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			addr_in = 197;
			data_in = 1234;
			id_in = 40;
			valid_in = 1'b1;
		#20
			addr_in = 65633;
			id_in = 10;
			valid_in = 1'b0;
	//		@ (negedge stall_out);
		#20
			rw_in = 0;
			addr_in = 196707;
			data_in = 77;
			id_in = 41;
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
			@ (negedge stall_out);
	//	#2
			rw_in = 0;
			addr_in = 105;
			data_in = 34;
			id_in = 42;
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
	//		@ (negedge ready_out);
		#2
			rw_in = 1;
			addr_in = 131169;
			data_in = 90;
			id_in = 43;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			id_in = 10;
			valid_in = 1'b0;
	//		@ (negedge stall_out);
		#20
			rw_in = 1;
			addr_in = 196809;
			data_in = 43645;
			id_in = 44;
			valid_in = 1'b1;
		#20
			id_in = 10;
			valid_in = 1'b0;
			@ (negedge stall_out);
		#20
			rw_in = 0;
			addr_in = 65641;
			data_in = 9349;
			id_in = 45;
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
//			@ (negedge ready_out);
		#20
			rw_in = 1;
			addr_in = 99;
			data_in = 76;
			id_in = 46;
			valid_in = 1'b1;
		#20
			id_in = 10;
			valid_in = 1'b0;
			@ (negedge stall_out);
		#2
			rw_in = 0;
			addr_in = 131171;
			data_in = 132;
			id_in = 47;
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
//			@ (negedge ready_out);
		#22
			rw_in = 1;
			addr_in = 196715;
			data_in = 89;
			id_in = 48;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			id_in = 10;
			valid_in = 1'b0;
		#20
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
			@ (negedge stall_out);
		#2
			rw_in = 0;
			addr_in = 65733;
			data_in = 67;
			id_in = 49;
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
			@ (negedge ready_out);
		#2
			rw_in = 1;
			addr_in = 193;
			data_in = 345;
			id_in = 40;
			valid_in = 1'b1;
		#20
		//	rw_in = 0;
			id_in = 10;
			valid_in = 1'b0;
			@ (negedge stall_out);
	//	#20
			rw_in = 0;
			addr_in = 105;
			data_in = 345;
			id_in = 51;
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
			@ (negedge ready_out);
		#20
			rw_in = 0;
			addr_in = 131169;
			data_in = 345;
			id_in = 52;
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
			@ (negedge ready_out);
		#2
			rw_in = 1;
			addr_in = 53;
			data_in = 243;
			id_in = 53;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			id_in = 10;
			valid_in = 1'b0;
			@ (negedge stall_out);
		#20
			rw_in = 1;
			addr_in = 105;
			data_in = 7645;
			id_in = 54;
			valid_in = 1'b1;
		#20
			rw_in = 0;
			addr_in = 65589;
			data_in = 345;
			id_in = 55;
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
		#20
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
			@ (negedge ready_out);
	//	#20
			rw_in = 0;
			addr_in = 53;
			data_in = 345;
			id_in = 56;
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
			@ (negedge ready_out);
		#2
			rw_in = 0;
			addr_in = 196809;
			data_in = 77;
			id_in = 42;
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
			@ (negedge ready_out);
		#2
			rw_in = 0;
			addr_in = 196715;
			data_in = 77;
			id_in = 43;
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
		#20
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
			@ (negedge ready_out);
	//	#20
			rw_in = 0;
			addr_in = 193;
			data_in = 77;
			id_in = 44;
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
			@ (negedge ready_out);
		#2
			rw_in = 0;
			addr_in = 201;
			data_in = 77;
			id_in = 45;
			valid_in = 1'b1;
		#20
			valid_in = 1'b0;
			@ (negedge ready_out);
		#10000
			$finish;
	 end

endmodule