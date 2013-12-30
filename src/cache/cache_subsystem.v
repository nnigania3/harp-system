`timescale 1ns/100ps

module cache_subsystem #(
	parameter L1_CACHE_SIZE = 16*1024,		// in Bytes
	parameter L2_CACHE_SIZE = 128*1024,		// in Bytes
	parameter LINE_BITS 	= 5,			// LOG(LINE_SIZE)
	parameter ASSOC_BITS = 2,
	parameter DATA_WIDTH = 32,			//
	parameter ADDR_WIDTH = 32,
	parameter CREG_ID_BITS = 3,	 		// ID BITS of the ld/St Q from core
	parameter L1_INDEX_BITS = 9,			// LOG(L1_CACHE_SIZE) - LINE_BITS
	parameter L2_INDEX_BITS = 10,			// LOG(L2_CACHE_SIZE) - ASSOC_BITS - LINE_BITS
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
	
	input [ADDR_WIDTH-1:0] addr_in, 		// address in from the core
	input [DATA_WIDTH*SIMD_WIDTH-1:0] data_in, 	// data from the core
	input rw_in, 					// read / write command
	input valid_in, 				//  valid input on the addr, data buses
	input [CREG_ID_BITS-1:0] id_in, 		// ld/st Q id for request
        `ifdef SIMD
	input  [SIMD_WIDTH - 1:0] valid_word_in,	// SIMD valid/mask word bits 
        `endif
	output [DATA_WIDTH*SIMD_WIDTH-1:0] data_out,	// data to be given to the core
	output [CREG_ID_BITS-1:0] id_out,		// ld/st Q id for request being satisfied
	output ready_out, 				// the memory request for which data is ready
	output stall_out, 				// the memory system cannot accept anymore requests
	//DDR2 controller signals
	input      		     avl_ready,         // ready
	output [AVL_ADDR-1:0]        avl_addr,          // address
	output [AVL_SIZE-1:0]        avl_size,          // burstcount
	output [AVL_DATA_WIDTH-1:0]  avl_wdata,         // writedata
	input  [AVL_DATA_WIDTH-1:0]  avl_rdata,         // readdata
	output                       avl_write_req,     // write
	output                       avl_read_req,      // read
	input                        avl_rdata_valid,   // readdatavalid
	output [AVL_BE-1:0]          avl_be,            // byteenable
	output                       avl_burstbegin     // beginbursttransfer
);
	localparam WORDS = 2**(LINE_BITS-2);
	localparam MSHR_ID_BITS = 3;				// ID BITS for MSHR going to L2
	
	
	wire [DATA_WIDTH*WORDS-1:0] l2_data_i;
	reg l2_valid_i;
	wire [MSHR_ID_BITS-1:0] l2_id_i;
	wire l2_stall_i;
	
	wire l2_valid_big;
	
	wire l2_valid_small;
	wire l2_rw_small;
	wire [ADDR_WIDTH-1:0] l2_addr_small;
	wire [DATA_WIDTH*WORDS-1:0] l2_data_small;
	wire [MSHR_ID_BITS-1:0] l2_id_small;
	
	wire L1_stall_out;
	assign stall_out = L1_stall_out || (~reset) ;

	L1_cache #(
		.CACHE_SIZE(L1_CACHE_SIZE),	// in Bytes
		.LINE_BITS(LINE_BITS),		// LOG(LINE_SIZE)
		.INDEX_BITS(L1_INDEX_BITS),	// LOG(NO_OF_SETS)
		.DATA_WIDTH(DATA_WIDTH),	//
		.WORDS(2**(LINE_BITS-2)),
		.ADDR_WIDTH(ADDR_WIDTH),
		.CREG_ID_BITS(CREG_ID_BITS),	// ID BITS of the ld/St Q from core
		.MSHR_ID_BITS(MSHR_ID_BITS),	// ID BITS for MSHR going to L2
		.SIMD_WIDTH(SIMD_WIDTH)		// ID BITS for MSHR going to L2
	)
	L1_instance (
		.clk(clk),
		.clkby2(clkby2),
		.reset(reset),
		
		.addr_in(addr_in), 				// address in from the core
		.data_in(data_in), 				// data from the core
		.rw_in(rw_in), 					// read / write command
		.valid_in(valid_in), 				//  valid input on the addr, data buses
        `ifdef SIMD
		.valid_word_in(valid_word_in), 			//  valid input on the addr, data buses
        `endif
		.id_in(id_in), 					// ld/st Q id for request
		.data_out(data_out),				// data to be given to the core
		.id_out(id_out),				// ld/st Q id for request being satisfied
		.ready_out(ready_out), 				// the memory request for which data is ready
		.stall_out(L1_stall_out), 			// the memory system cannot accept anymore requests
								// stall the pipeline when this line is high

		.l2_addr_o(l2_addr_small),
		.l2_data_o(l2_data_small),
		.l2_rw_o(l2_rw_small),
		.l2_valid_o(l2_valid_small),
		.l2_id_o(l2_id_small),
		.l2_data_i(l2_data_i),
		//.l2_valid_i(l2_valid_i),
		.l2_valid_i(l2_valid_big),
		.l2_id_i(l2_id_i),
		.l2_stall_i(l2_stall_i)
	);
	
	
	L2_cache #(
		.CACHE_SIZE(L2_CACHE_SIZE),		// in Bytes
		.LINE_BITS(LINE_BITS),			// LOG(LINE_SIZE)
		.ASSOC_BITS(ASSOC_BITS),
		.INDEX_BITS(L2_INDEX_BITS),		// LOG(NO_OF_SETS)
		.DATA_WIDTH(DATA_WIDTH*WORDS),		//
		.ADDR_WIDTH(ADDR_WIDTH),
		.CREG_ID_BITS(CREG_ID_BITS),		// ID BITS of the ld/St Q from core
		.MSHR_ID_BITS(MSHR_ID_BITS),		// ID BITS for MSHR going to L2
		.AVL_ADDR(AVL_ADDR),
		.AVL_SIZE(AVL_SIZE),
		.AVL_BE(AVL_BE)
	)
	l2 ( 
		//.clk(new_clk),
		//.clkby2(new_clkby2),
		.clk(clk),
		.clkby2(clkby2),
		.reset(reset),
		//.addr_in(l2_addr_o), 		// address to L2
		//.data_in(l2_data_o), 		// data to L2
		//.rw_in(l2_rw_o), 		// read / write command
		//.valid_in(l2_valid_o), 	//  valid input on the addr, data buses
		//.id_in(l2_id_o), 		// MSHR id for l2 request
		.addr_in(l2_addr_small), 	// address to L2
		.data_in(l2_data_small), 	// data to L2
		.rw_in(l2_rw_small), 		// read / write command
		.valid_in(l2_valid_small), 	//  valid input on the addr, data buses
		.id_in(l2_id_small), 		// MSHR id for l2 request
		.data_out(l2_data_i),  		// data from the l2
		.id_out(l2_id_i),		// MSHR id for request being satisfied
		.ready_out(l2_valid_big), 	// the memory request for which data is ready
		.stall_out(l2_stall_i),  	// the memory system cannot accept anymore requests, stall the pipeline
		//DDR2 controller signals!
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

endmodule

//Old Code. This was used when we were running L2 at half freq as L1. Now both are run at same speed!
/*	
	reg [ADDR_WIDTH-1:0] l2_addr_o;
	reg [DATA_WIDTH*WORDS-1:0] l2_data_o;
	reg l2_rw_o;
	reg l2_valid_o;
	reg [MSHR_ID_BITS-1:0] l2_id_o;

	reg l2_valid_temp;
	reg l2_rw_temp;
	reg [ADDR_WIDTH-1:0] l2_addr_temp;
	reg [DATA_WIDTH*WORDS-1:0] l2_data_temp;
	reg [MSHR_ID_BITS-1:0] l2_id_temp;

	wire new_clk, new_clkby2;	
	Frequency_Divider #(.Divisor(2), .Bits(1)) f1 (clk,reset,new_clk);
	assign new_clkby2 = clk;

	always @(posedge clk or negedge reset)
	begin
		if (!reset)
			l2_valid_temp <= 1'b0;
		else if (l2_valid_small) begin
			l2_valid_temp <= 1'b1;
			l2_rw_temp <= l2_rw_small;
			l2_id_temp <= l2_id_small;
			l2_data_temp <= l2_data_small;
			l2_addr_temp <= l2_addr_small;
		end
		else if (l2_valid_o) begin 
			l2_valid_temp <= 1'b0;
		end
	end
	
	always @(posedge new_clk or negedge reset)
	begin
		if (!reset) begin
			l2_valid_o <= 1'b0;
			l2_rw_o <= 1'b0;
		end
		else begin
			l2_valid_o <= l2_valid_temp;
			if (l2_valid_temp & ~l2_stall_i) begin
				l2_rw_o <= l2_rw_temp;
				l2_id_o <= l2_id_temp;
				l2_data_o <= l2_data_temp;
				l2_addr_o <= l2_addr_temp;
			end
			else if (l2_valid_o) begin 
				l2_rw_o <= 1'b0;
			end 
		end
	end
	
	reg l2_big_flag;
	always @(posedge clk or negedge reset)
	begin
		if (!reset) begin
			l2_valid_i <= 1'b0;
			l2_big_flag <= 1'b0;
		end
		else if (l2_valid_big & ~l2_valid_i & ~l2_big_flag) begin
			l2_valid_i <= 1'b1;
			l2_big_flag <= 1'b1;
		end
		else if (l2_valid_big & l2_valid_i) begin
			l2_valid_i <= 1'b0;
		end
		else if (~l2_valid_big) begin
			l2_big_flag <= 1'b0;
		end			
	end

*/
