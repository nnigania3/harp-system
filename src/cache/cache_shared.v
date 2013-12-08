`timescale 1ns/100ps

module cache_shared #(
	parameter L1_CACHE_SIZE = 16*1024,		// in Bytes
	parameter L2_CACHE_SIZE = 128*1024,		// in Bytes
	parameter LINE_BITS 	= 5,			// LOG(LINE_SIZE)
	parameter ASSOC_BITS = 2,
	parameter DATA_WIDTH = 32,			//
	parameter ADDR_WIDTH = 32,
	parameter CREG_ID_BITS = 3,			// ID BITS of the ld/St Q from core
        `ifdef SIMD
	parameter SIMD_WIDTH = (2**(LINE_BITS-2)),      // SIMD width = no. of cache line words
        `else
	parameter SIMD_WIDTH = 1,			// SIMD width 
        `endif
	parameter AVL_ADDR       = 30,			// AVL address
	parameter AVL_SIZE       = 3,			// AVL size
	parameter AVL_BE         = 32,			// AVL byte enable
	parameter AVL_DATA_WIDTH = DATA_WIDTH* (2**(LINE_BITS-2)) //L2 width => DATA_WIDTH*WORDS
 )
(
	input clk,
	input clkby2,
	input reset,
	
	input [ADDR_WIDTH-1:0] addr_in1, 		// address in from the core
	input [DATA_WIDTH*SIMD_WIDTH-1:0] data_in1, 		// data from the core
	input rw_in1, 					// read / write command
	input valid_in1, 				//  valid input on the addr, data buses
	input [CREG_ID_BITS-1:0] id_in1, 		// ld/st Q id for request
        `ifdef SIMD
	input  [SIMD_WIDTH - 1:0] valid_word_in1,	// SIMD valid/mask word bits 
        `endif
	output [DATA_WIDTH*SIMD_WIDTH-1:0] data_out1,		// data to be given to the core
	output [CREG_ID_BITS-1:0] id_out1,		// ld/st Q id for request being satisfied
	output ready_out1, 				// the memory request for which data is ready
	output stall_out1, 				// the memory system cannot accept anymore requests
							// stall the pipeline when this line is high
	
	input [ADDR_WIDTH-1:0] addr_in2, 		// address in from the core
	input [DATA_WIDTH*SIMD_WIDTH-1:0] data_in2, 		// data from the core
	input rw_in2, 					// read / write command
	input valid_in2, 				//  valid input on the addr, data buses
	input [CREG_ID_BITS-1:0] id_in2, 		// ld/st Q id for request
        `ifdef SIMD
	input  [SIMD_WIDTH - 1:0] valid_word_in2,	// SIMD valid/mask word bits 
        `endif
	output [DATA_WIDTH*SIMD_WIDTH-1:0] data_out2,		// data to be given to the core
	output [CREG_ID_BITS-1:0] id_out2,		// ld/st Q id for request being satisfied
	output ready_out2, 				// the memory request for which data is ready
	output stall_out2, 				// the memory system cannot accept anymore requests
	//DDR2 controller signals
	input      		     avl_ready,       //          .ready
	output [AVL_ADDR-1:0]        avl_addr,        //          .address
	output [AVL_SIZE-1:0]        avl_size,        //          .burstcount
	output [AVL_DATA_WIDTH-1:0]  avl_wdata,       //          .writedata
	input  [AVL_DATA_WIDTH-1:0]  avl_rdata,       //          .readdata
	output                       avl_write_req,   //          .write
	output                       avl_read_req,    //          .read
	input                        avl_rdata_valid, //          .readdatavalid
	output [AVL_BE-1:0]          avl_be,          //          .byteenable
	output                       avl_burstbegin   //          .beginbursttransfer
													// stall the pipeline when this line is high
);

	localparam L1_INDEX_BITS = 9;				// LOG(L1_CACHE_SIZE) - LINE_BITS
	localparam L2_INDEX_BITS = 10;				// LOG(L2_CACHE_SIZE) - ASSOC_BITS - LINE_BITS
	localparam WORDS = 2**(LINE_BITS-2);
	localparam MSHR_ID_BITS = 3;				// ID BITS for MSHR going to L2
	localparam NUM_L1 = 2;
	localparam NUM_L1_LOG = 1;
	
	
	wire [ADDR_WIDTH-1:0] l2_addr_o;
	wire [DATA_WIDTH*WORDS-1:0] l2_data_o;
	wire l2_rw_o;
	wire l2_valid_o;
	wire [MSHR_ID_BITS-1:0] l2_id_o;
	
	wire [DATA_WIDTH*WORDS-1:0] l2_data_i;
	wire l2_valid_i;
	wire [MSHR_ID_BITS-1:0] l2_id_i;
	wire l2_stall_i;
	
	wire [NUM_L1-1:0] valid_L1;
	wire [NUM_L1-1:0] rw_L1;
	wire [(ADDR_WIDTH*NUM_L1)-1:0] addr_L1;
	wire [DATA_WIDTH*SIMD_WIDTH*NUM_L1-1:0] data_L1;
	wire [MSHR_ID_BITS*NUM_L1-1:0] id_L1;
        `ifdef SIMD
	wire [SIMD_WIDTH*NUM_L1-1:0] valid_word_L1;
        `endif
	
	wire [NUM_L1-1:0] l2_valid_L1;
	wire [NUM_L1-1:0] l2_rw_L1;
	wire [(ADDR_WIDTH*NUM_L1)-1:0] l2_addr_L1;
	wire [DATA_WIDTH*WORDS*NUM_L1-1:0] l2_data_L1;
	wire [MSHR_ID_BITS*NUM_L1-1:0] l2_id_L1;
	
	wire [NUM_L1-1:0] l2_valid_in_L1;
	wire [NUM_L1-1:0] l2_stall_in_L1;
	wire [DATA_WIDTH*WORDS*NUM_L1-1:0] l2_data_in_L1;
	wire [MSHR_ID_BITS*NUM_L1-1:0] l2_id_in_L1;
	
	wire [NUM_L1-1:0] ready_out_L1;
	wire [NUM_L1-1:0] stall_out_L1;
	wire [DATA_WIDTH*SIMD_WIDTH*NUM_L1-1:0] data_out_L1;
	wire [CREG_ID_BITS*NUM_L1-1:0] id_out_L1;
	
	wire [MSHR_ID_BITS:0] l2_id_temp;
	wire [NUM_L1_LOG-1:0] which_L1;
	wire [NUM_L1_LOG-1:0] L1_no;

	assign addr_L1[(0+1)*ADDR_WIDTH-1:0*ADDR_WIDTH] = addr_in1;
	assign data_L1[(0+1)*DATA_WIDTH*SIMD_WIDTH-1:0*DATA_WIDTH*SIMD_WIDTH] = data_in1;
	assign rw_L1[(0+1)-1:0] = rw_in1;
	assign valid_L1[(0+1)-1:0] = valid_in1;
	assign id_L1[(0+1)*CREG_ID_BITS-1:0*CREG_ID_BITS] = id_in1;
        `ifdef SIMD
	assign valid_word_L1[(0+1)*SIMD_WIDTH-1:0*SIMD_WIDTH] = valid_word_in1;
        `endif
	assign data_out1 = data_out_L1[(0+1)*DATA_WIDTH*SIMD_WIDTH-1:0*DATA_WIDTH*SIMD_WIDTH];
	assign id_out1 = id_out_L1[(0+1)*CREG_ID_BITS-1:0*CREG_ID_BITS];
	assign ready_out1 = ready_out_L1[(0+1)-1:0];
	assign stall_out1 = stall_out_L1[(0+1)-1:0] || (~reset);
	
	assign addr_L1[(1+1)*ADDR_WIDTH-1:1*ADDR_WIDTH] = addr_in2;
	assign data_L1[(1+1)*DATA_WIDTH*SIMD_WIDTH-1:1*DATA_WIDTH*SIMD_WIDTH] = data_in2;
	assign rw_L1[(1+1)-1:1] = rw_in2;
	assign valid_L1[(1+1)-1:1] = valid_in2;
	assign id_L1[(1+1)*CREG_ID_BITS-1:1*CREG_ID_BITS] = id_in2;
        `ifdef SIMD
	assign valid_word_L1[(1+1)*SIMD_WIDTH-1:1*SIMD_WIDTH] = valid_word_in2;
        `endif
	assign data_out2 = data_out_L1[(1+1)*DATA_WIDTH*SIMD_WIDTH-1:1*DATA_WIDTH*SIMD_WIDTH];
	assign id_out2 = id_out_L1[(1+1)*CREG_ID_BITS-1:1*CREG_ID_BITS];
	assign ready_out2 = ready_out_L1[(1+1)-1:1];
	assign stall_out2 = stall_out_L1[(1+1)-1:1] || (~reset);
	
	
	genvar j;	
	generate 
		for (j=0; j<NUM_L1; j=j+1) begin: Gen4
			L1_cache #(
				.CACHE_SIZE(L1_CACHE_SIZE),		// in Bytes
				.LINE_BITS(LINE_BITS),				// LOG(LINE_SIZE)
				.INDEX_BITS(L1_INDEX_BITS),			// LOG(NO_OF_SETS)
				.DATA_WIDTH(DATA_WIDTH),			//
				.WORDS(2**(LINE_BITS-2)),
				.ADDR_WIDTH(ADDR_WIDTH),
				.CREG_ID_BITS(CREG_ID_BITS),		// ID BITS of the ld/St Q from core
				.MSHR_ID_BITS(MSHR_ID_BITS),		// ID BITS for MSHR going to L2
				.SIMD_WIDTH(SIMD_WIDTH)		// ID BITS for MSHR going to L2
			)
			L1_instance1 (
				.clk(clk),
				.clkby2(clkby2),
				.reset(reset),
				
				.addr_in(addr_L1[(j+1)*ADDR_WIDTH-1:j*ADDR_WIDTH]), 					// address in from the core
				.data_in(data_L1[(j+1)*DATA_WIDTH*SIMD_WIDTH-1:j*DATA_WIDTH*SIMD_WIDTH]), 					// data from the core
				.rw_in(rw_L1[(j+1)-1:j]), 														// read / write command
				.valid_in(valid_L1[(j+1)-1:j]), 				//  valid input on the addr, data buses
        		`ifdef SIMD
				.valid_word_in(valid_word_L1[(j+1)*SIMD_WIDTH-1:j*SIMD_WIDTH]), 				//  valid/mask data word
        		`endif
				.id_in(id_L1[(j+1)*CREG_ID_BITS-1:j*CREG_ID_BITS]), 					// ld/st Q id for request
				
				.data_out(data_out_L1[(j+1)*DATA_WIDTH*SIMD_WIDTH-1:j*DATA_WIDTH*SIMD_WIDTH]),				// data to be given to the core
				.id_out(id_out_L1[(j+1)*CREG_ID_BITS-1:j*CREG_ID_BITS]),				// ld/st Q id for request being satisfied
				.ready_out(ready_out_L1[(j+1)-1:j]), 										// the memory request for which data is ready
				.stall_out(stall_out_L1[(j+1)-1:j]), 										// the memory system cannot accept anymore requests
																										// stall the pipeline when this line is high

				.l2_addr_o(l2_addr_L1[(j+1)*ADDR_WIDTH-1:j*ADDR_WIDTH]),
				.l2_data_o(l2_data_L1[(j+1)*DATA_WIDTH*WORDS-1:j*DATA_WIDTH*WORDS]),
				.l2_rw_o(l2_rw_L1[(j+1)-1:j]),
				.l2_valid_o(l2_valid_L1[(j+1)-1:j]),
				.l2_id_o(l2_id_L1[(j+1)*MSHR_ID_BITS-1:j*MSHR_ID_BITS]),
				
				.l2_data_i(l2_data_in_L1[(j+1)*DATA_WIDTH*WORDS-1:j*DATA_WIDTH*WORDS]),
				.l2_valid_i(l2_valid_in_L1[(j+1)-1:j]),
				.l2_id_i(l2_id_in_L1[(j+1)*MSHR_ID_BITS-1:j*MSHR_ID_BITS]),
				.l2_stall_i(l2_stall_in_L1[(j+1)-1:j])
			);
		end
	endgenerate
		
		Arbiter1 #(.num_L1s(NUM_L1), .num_L1s_log(NUM_L1_LOG), .addr_width(ADDR_WIDTH), .data_width(DATA_WIDTH*WORDS), .cpu_id_width(CREG_ID_BITS), .FIFO_depth_log(2))
			arb1 (
					.reset(~reset), .enable(1'b1), 
					
					.clk_L1(clk),
					.valid_L1_in(l2_valid_L1), .rw_L1_in(l2_rw_L1), .addr_L1_in(l2_addr_L1), .data_L1_in(l2_data_L1), .id_L1_in(l2_id_L1),

					.clk_L2(), 
					.valid_L2_in(l2_valid_i), .rw_L2_in(), .addr_L2_in(), .data_L2_in(l2_data_i), .id_L2_in(l2_id_i), .which_L1(which_L1),
					
					.L1_to_L2_full(l2_stall_in_L1), .L1_to_L2_empty(), 

					.valid_L1_out(l2_valid_in_L1), .rw_L1_out(), .addr_L1_out(), .data_L1_out(l2_data_in_L1), .id_L1_out(l2_id_in_L1), .accept_L1(1'b1), .which_L1_out(L1_no),
					
					.valid_L2_out(l2_valid_o), .rw_L2_out(l2_rw_o), .addr_L2_out(l2_addr_o), .data_L2_out(l2_data_o), .id_L2_out(l2_id_o), .accept_L2(~l2_stall_i),
					
					.L2_to_L1_full(), .L2_to_L1_empty()
				
			);
			
		L2_cache #(
			.CACHE_SIZE(L2_CACHE_SIZE),		// in Bytes
			.LINE_BITS(LINE_BITS),			// LOG(LINE_SIZE)
			.ASSOC_BITS(ASSOC_BITS),
			.INDEX_BITS(L2_INDEX_BITS),			// LOG(NO_OF_SETS)
			.DATA_WIDTH(DATA_WIDTH*WORDS),			//
			.ADDR_WIDTH(ADDR_WIDTH),
			.CREG_ID_BITS(MSHR_ID_BITS+NUM_L1_LOG),		// ID BITS of the ld/St Q from core
			.MSHR_ID_BITS(MSHR_ID_BITS),			// ID BITS for MSHR going to L2
			.AVL_ADDR(AVL_ADDR),
			.AVL_SIZE(AVL_SIZE),
			.AVL_BE(AVL_BE)
		)
		l2 ( 
			.clk(clk),
			.clkby2(clkby2),
			.reset(reset),
			
			.addr_in(l2_addr_o), 	// address to L2
			.data_in(l2_data_o), 		// data to L2
			.rw_in(l2_rw_o), 			// read / write command
			.valid_in(l2_valid_o), 	//  valid input on the addr, data buses
			.id_in({L1_no,l2_id_o}), 			// MSHR id for l2 request
			
			.data_out(l2_data_i),	// data from the l2
			.id_out(l2_id_temp),			// MSHR id for request being satisfied
			.ready_out(l2_valid_i), 	// the memory request for which data is ready
			.stall_out(l2_stall_i),  // the memory system cannot accept anymore requests, stall the pipeline
                	.avl_ready	(avl_ready	),      
                	.avl_addr	(avl_addr	),       
                	.avl_size	(avl_size	),       
                	.avl_wdata	(avl_wdata	),     
                	.avl_rdata	(avl_rdata	),     
                	.avl_write_req	(avl_write_req	), 
                	.avl_read_req	(avl_read_req	),  
                	.avl_rdata_valid(avl_rdata_valid),
                	.avl_be		(avl_be		),        
                	.avl_burstbegin	(avl_burstbegin	)		
		);
		assign l2_id_i = l2_id_temp[MSHR_ID_BITS-1:0];
		assign which_L1 = l2_id_temp[MSHR_ID_BITS+NUM_L1_LOG-1: MSHR_ID_BITS];	

endmodule
	
