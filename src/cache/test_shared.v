`timescale 1ns/100ps

module test_shared;

	reg clk;
	reg reset;	
	reg [31:0] addr_in1; 		// address in from the core
	reg [31:0] data_in1; 		// data from the core
	reg rw_in1; 								// read / write command
	reg valid_in1; 							//  valid reg on the addr, data buses
	reg [2:0] id_in1; 		// ld/st Q id for request
	
	wire [31:0] data_out1;	// data to be given to the core
	wire [2:0] id_out1;	// ld/st Q id for request being satisfied
	wire ready_out1; 						// the memory request for which data is ready
	wire stall_out1;							// the memory system cannot accept anymore requests
	
	reg [31:0] addr_in2; 		// address in from the core
	reg [31:0] data_in2; 		// data from the core
	reg rw_in2; 								// read / write command
	reg valid_in2; 							//  valid reg on the addr, data buses
	reg [2:0] id_in2; 		// ld/st Q id for request
	
	wire [31:0] data_out2;	// data to be given to the core
	wire [2:0] id_out2;	// ld/st Q id for request being satisfied
	wire ready_out2; 						// the memory request for which data is ready
	wire stall_out2;
        reg clkby2;							// the memory system cannot accept anymore requests
//        freq_div_nn #(.DIVLOG(1)) freq_div1 (clk, clk_half);
		
	cache_shared cache
	(
		clk,
		clkby2,
		reset,
		addr_in1, 		// address in from the core
		data_in1, 		// data from the core
		rw_in1, 								// read / write command
		valid_in1, 							//  valid reg on the addr, data buses
		id_in1, 		// ld/st Q id for request
		data_out1,	// data to be given to the core
		id_out1,	// ld/st Q id for request being satisfied
		ready_out1, 				// the memory request for which data is ready
		stall_out1, 							// the memory system cannot accept anymore requests
		
		addr_in2, 		// address in from the core
		data_in2, 		// data from the core
		rw_in2, 								// read / write command
		valid_in2, 							//  valid reg on the addr, data buses
		id_in2, 		// ld/st Q id for request
		data_out2,	// data to be given to the core
		id_out2,	// ld/st Q id for request being satisfied
		ready_out2, 				// the memory request for which data is ready
		stall_out2, 							// the memory system cannot accept anymore requests
                avl_ready,      
                avl_addr,       
                avl_size,       
                avl_wdata,      
                avl_rdata,      
                avl_write_req,  
                avl_read_req,   
                avl_rdata_valid,
                avl_be,         
                avl_burstbegin  		
	);
	
	always #10 clk = ~clk;	//NN code check!
	always #5 clkby2 = ~clkby2;
	
	initial 
	 begin 
       		$dumpfile("dump.vcd");
       		$dumpvars(3, test_shared);
			clk = 1; 
			clkby2 = 0; 
			reset = 0;
			rw_in1 = 0;
			addr_in1 = 0;
			id_in1 = 0;
			data_in1 = 0;
			valid_in1 = 0;
			rw_in2 = 0;
			addr_in2 = 0;
			id_in2 = 0;
			data_in2 = 0;
			valid_in2 = 0;
		#20
			reset = 1;
		#22
			rw_in1 = 1;
			addr_in1 = 97;
			id_in1 = 2;
			data_in1 = 8;
			valid_in1 = 1'b1;
	//	#20
//			addr_in = 0;
//			valid_in1 = 1'b0;
//			@ (negedge stall_out);
 //		#2
			rw_in2 = 1;
			addr_in2 = 301;
			data_in2 = 16;
			id_in2 = 6;
			valid_in2 = 1'b1;
		#20
			valid_in1 = 1'b0;
			rw_in2 = 0;
			valid_in2 = 1'b0;
		#60
			rw_in1 = 0;
			addr_in1 = 201;
			data_in1 = 9875;
			id_in1 = 16;
			valid_in1 = 1'b1;
		#20
			addr_in1 = 0;
			id_in1 = 0;
			valid_in1 = 1'b0;
	//		@ (negedge stall_out);
		#20
			rw_in2 = 0;
			addr_in2 = 497;
			data_in2 = 0;
			id_in2 = 7;
			valid_in2 = 1'b1;
	//	#20
			rw_in1 = 1;
			addr_in1 = 599;
			data_in1 = 56;
			id_in1 = 8;
			valid_in1 = 1'b1;
		#20
			valid_in1 = 1'b0;
			valid_in2 = 1'b0;
		#200
			rw_in1 = 1;
			addr_in1 = 697;
			data_in1 = 1234;
			id_in1 = 17;
			valid_in1 = 1'b1;
		#20
			rw_in2 = 0;
			addr_in2 = 799;
			data_in2 = 77;
			id_in2 = 9;
			valid_in2 = 1'b1;
			valid_in1 = 1'b0;
		#20
			valid_in1 = 1'b0;
			valid_in2 = 1'b0;
		#20
			rw_in1 = 0;
			addr_in1 = 97;
			id_in1 = 3;
			data_in1 = 8;
			valid_in1 = 1'b1;

			rw_in2 = 0;
			addr_in2 = 999;
			data_in2 = 77;
			id_in2 = 4;
			valid_in2 = 1'b1;
		#20
			valid_in1 = 1'b0;
			valid_in2 = 1'b0;

    			@ (negedge stall_out1);//NN remove this crap!

			rw_in1 = 0;
			addr_in1 = 1048673;//2^20+97
			id_in1 = 5;
			data_in1 = 8;
			valid_in1 = 1'b1;
		#20
			valid_in1 = 1'b0;
			valid_in2 = 1'b0;
/*		#20
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
	*/	#10000
			$finish;
	 end

endmodule
