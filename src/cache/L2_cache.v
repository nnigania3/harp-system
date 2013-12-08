
`timescale 1ns/100ps

module L2_cache
#(	parameter CACHE_SIZE = 16*1024,	// in Bytes
	parameter LINE_BITS 	= 5,			// LOG(LINE_SIZE)
	parameter ASSOC_BITS = 2,
	parameter INDEX_BITS = 9,			// LOG(NO_OF_SETS)
	parameter DATA_WIDTH = 32,			//
	parameter ADDR_WIDTH = 32,
	
	parameter CREG_ID_BITS   = 3,		// ID BITS of the ld/St Q from core
	parameter MSHR_ID_BITS   = 3,			// ID BITS for MSHR going to L2
	parameter AVL_DATA_WIDTH = DATA_WIDTH,			// AVL data width. cache lie width
	parameter AVL_ADDR       = 30,			// AVL address
	parameter AVL_SIZE       = 3,			// AVL size
	parameter AVL_BE         = 32			// AVL byte enable
)
(
	input clk,
	input clkby2,
	input reset,
	
	input [ADDR_WIDTH-1:0] addr_in, 		// address in from the core
	input [DATA_WIDTH-1:0] data_in, 		// data from the core
	input rw_in, 								// read / write command
	input valid_in, 							//  valid input on the addr, data buses
	input [CREG_ID_BITS-1:0] id_in, 		// ld/st Q id for request
	output [DATA_WIDTH-1:0] data_out,	// data to be given to the core
	output reg [CREG_ID_BITS-1:0] id_out,	// ld/st Q id for request being satisfied
	output reg ready_out, 						// the memory request for which data is ready
	output stall_out, 							// the memory system cannot accept anymore requests
													// stall the pipeline when this line is high
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
);
	
	localparam ASSOCIATIVITY=2**ASSOC_BITS;
	localparam TAG_BITS=ADDR_WIDTH-LINE_BITS-INDEX_BITS;
	
	wire [ADDR_WIDTH-1:0] mem_addr_o;
	wire [DATA_WIDTH-1:0] mem_data_o;
	wire mem_rw_o;
	wire mem_valid_o;
	reg [MSHR_ID_BITS-1:0] mem_id_o;
	wire [DATA_WIDTH-1:0] mem_data_i;
	wire mem_valid_i;
	wire [MSHR_ID_BITS-1:0] mem_id_i;
	wire mem_stall_i;
	
	// Array signals for L1 side (port a)
//	wire [INDEX_BITS-1:0] index_a;
	wire [DATA_WIDTH-1:0] cache_out_a;
	wire [ASSOCIATIVITY-1:0] dirty_a_i;
	wire [ASSOCIATIVITY-1:0] valid_a_i;
	reg [ASSOCIATIVITY-1:0] we_a; 
	wire [ASSOCIATIVITY-1:0] sel_a;
	reg [ASSOCIATIVITY-1:0] sel_a_temp; 
//	reg [ASSOCIATIVITY-1:0] sel_a_temp2;
	wire we_a_temp;
	wire [ASSOCIATIVITY-1:0] dirty_a_o;
	wire valid_a_o;
	wire [TAG_BITS-1:0] tag_out_a;
	wire [ADDR_WIDTH-1:0] addr_a;
	wire [DATA_WIDTH-1:0] data_a;
	
	// Array signals for Mem side data array (port b)
//	wire [INDEX_BITS-1:0] index_b;
	reg [DATA_WIDTH-1:0] cache_in2;
	wire [DATA_WIDTH-1:0] cache_out_b;
	wire [ASSOCIATIVITY-1:0] dirty_b_i;
	wire [ASSOCIATIVITY-1:0] valid_b_i;
	reg [ASSOCIATIVITY-1:0] we_b;
	reg [ASSOCIATIVITY-1:0] sel_b_temp;
	reg [ASSOCIATIVITY-1:0] sel_b;
	wire we_b_temp;
	wire [ASSOCIATIVITY-1:0] dirty_b_o;
	wire valid_b_o;
	wire [TAG_BITS-1:0] tag_out_b;
	wire [ADDR_WIDTH-1:0] addr_b_cache;
	reg [ADDR_WIDTH-1:0] addr_b;
	
	// stored signals for L2
	reg [ADDR_WIDTH-1:0] addr_prev;
	reg [CREG_ID_BITS-1:0] id_prev;
	reg [DATA_WIDTH-1:0] data_prev;
	reg rw_prev;
	
	wire mshr_add;
	wire [ADDR_WIDTH-1:0] mshr_add_addr;
	wire [CREG_ID_BITS-1:0] mshr_add_cpu_id;
	wire [DATA_WIDTH-1:0] mshr_add_data;
	wire mshr_add_rw;
	wire [ASSOCIATIVITY-1:0] mshr_add_dirty;
	wire [ASSOC_BITS-1:0] mshr_add_victim;
	
	wire [ADDR_WIDTH-1:0] mshr_get_addr;
	wire [CREG_ID_BITS-1:0] mshr_get_cpu_id;
	wire [DATA_WIDTH-1:0] mshr_get_data;
	wire mshr_get_rw, mshr_get_valid, mshr_get_dirty;
	
	wire mshr_rn_valid;
//	reg [ADDR_WIDTH-1:0] addr_b;
	wire [MSHR_ID_BITS-1:0] mem_id_temp; 
	wire [ADDR_WIDTH-1:0] addr_b_temp;
	wire mshr_empty, mshr_full;
	wire mshr_rn_dirty;
	wire mshr_read_next, mshr_get, mshr_del;
			
	reg [ADDR_WIDTH-1:0] mshr_same_addr;
	reg [DATA_WIDTH-1:0] mshr_same_data;
	reg [CREG_ID_BITS-1:0] mshr_same_id;
	reg [ASSOC_BITS-1:0] mshr_same_victim;
	reg mshr_same_rw, mshr_same_dirty;
	wire [ADDR_WIDTH-1:0] mshr_comp_addr;
	wire mshr_comp_true, mshr_diff_true, mshr_same_true, mshr_comp_read;
	reg mshr_same_true_d;
	
	// random signals
	wire [ASSOCIATIVITY-1:0] hit_temp_a, hit_temp_b; 
	wire hit;
	wire miss_bef_reg;
	wire valid_real;
	
	wire [ADDR_WIDTH-1:0] addr_bef_reg;
	wire [CREG_ID_BITS-1:0] id_temp;
	wire rw_bef_reg;
	wire [DATA_WIDTH-1:0] data_bef_reg;
	
	// blocking fsm control signals	 
	wire rd_valid_b;
	wire mem_addr_en;
	wire stall_out_fsm;
	wire portA_op_en;
	wire block_stall;
	reg block_signal_same;
	reg block_signal_diff;
	wire block_signal;
//	reg portA_op_en_d;

   integer i;
	reg [ASSOC_BITS-1:0] counter, victim_temp;
	wire [ASSOC_BITS-1:0] victim_a, victim_b;
	wire [ASSOC_BITS-1:0] mshr_rn_victim, mshr_get_victim;
	reg [ASSOC_BITS-1:0] mshr_rn_victim_d, victim_prev;
	 
   assign #0.25 hit = | hit_temp_a;
	assign data_out = cache_out_a;
	
	//// Outputs for now
	wire rdy_bef_reg; 
	wire [CREG_ID_BITS-1:0] id_out_bef_reg;
	assign #0.25 rdy_bef_reg = portA_op_en ? ~rw_prev : (hit & ~rw_in);
	assign #0.25 id_out_bef_reg = (portA_op_en ? id_prev : id_in);
	always @ (posedge clk or negedge reset)
	begin
		if (!reset)
		begin
			ready_out <= 0;
			id_out <= 0;
		end
		else
		begin
			ready_out <= rdy_bef_reg;
			id_out <= id_out_bef_reg;
		end
	end
	
	assign stall_out = mshr_full | portA_op_en | block_stall | block_signal;
	assign valid_real = valid_in & ~stall_out;
		
	always @(negedge clk or negedge reset) begin
		if (!reset) begin
			counter <= 0;
			victim_temp <= 0;
		end
		else begin
			counter <= counter+1;
			if (valid_real)
				victim_temp <= counter;
		end
	end
			
	assign #0.25 miss_bef_reg = ~hit & valid_real;

	always @ (posedge clk or negedge reset) begin
		if (!reset) begin
			sel_a_temp = 0;
			sel_b_temp = 0;
		end
		else begin
			sel_a_temp = 0;
			sel_b_temp = 0;
			if (stall_out_fsm)
				sel_b_temp[victim_b] = 1'b1;
			if (portA_op_en)
				sel_a_temp[victim_a] = 1'b1;
			else begin
				sel_a_temp = hit_temp_a;
				sel_b_temp = hit_temp_b;
			end
		end
	end
	assign sel_a = sel_a_temp;	

	reg [MSHR_ID_BITS-1:0] mem_id_d, mem_id_d_d;
	always @ (posedge clk or negedge reset) begin
		if (!reset) begin
			cache_in2 <= 0;
			mem_id_d <= 1'b0;
			mem_id_d_d <= 1'b0;
		end
		else begin
			if (mem_valid_i) begin
				cache_in2 <= mem_data_i;
				mem_id_d <= mem_id_i;
			end
			mem_id_d_d <= mem_id_d;
		end
	end
	
	assoc_cache #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .INDEX_WIDTH(INDEX_BITS), .LINE_BITS(LINE_BITS), .ASSOC_BITS(ASSOC_BITS))
		cache	(
			.clk(clk),
			.clkby2(clkby2),
			.reset(reset),
			.valid_in(valid_real),
			.data_a(data_a), .data_b(cache_in2),
			.addr_a(addr_a), .addr_b(addr_b_cache),
			.we_a(we_a), .we_b(we_b), 
			.dirty_a_i(dirty_a_i), .dirty_b_i(dirty_b_i),
			.valid_a_i(valid_a_i), .valid_b_i(valid_b_i),
			.sel_a(sel_a), .sel_b(sel_b),
			
			.dirty_a_out(dirty_a_o), .dirty_b_out(dirty_b_o),
			.valid_a_out(valid_a_o), .valid_b_out(valid_b_o),
			.hit_a(hit_temp_a), .hit_b(hit_temp_b),
			.tag_out_a(tag_out_a), .tag_out_b(tag_out_b),
			.q_a(cache_out_a), .q_b(cache_out_b)
		);
	
	assign #0.25 addr_a = portA_op_en ? addr_prev : addr_bef_reg;
	assign #0.25 data_a = portA_op_en ? data_prev : data_bef_reg;	
	assign #0.25 victim_a = portA_op_en ? victim_prev : victim_temp;
	assign valid_a_i = we_a;
	assign dirty_a_i = we_a;
		
	assign valid_b_i = we_b;
	assign dirty_b_i = 1'b0;
//	assign addr_b = addr_prev; 
	
	always @* begin
		for (i=0; i<ASSOCIATIVITY; i=i+1) begin
			we_a[i] = 0;
			we_b[i] = 0;
		end	
		if (portA_op_en) begin
			we_a[victim_a] = rw_prev;
		end
		else begin
			we_a = {ASSOCIATIVITY{rw_in}} & hit_temp_a;
		end
		we_b[victim_b] = we_b_temp;
		sel_b = sel_b_temp;
		sel_b[victim_b] = sel_b_temp[victim_b] | rd_valid_b;
	end	
/*	
	blocking_fsm_L2 ctrl (
		 .reset(reset),
		 .clock(clk),
		 .dirty(dirty_out_d),
		 .rw_prev(rw_prev),
		 .stall_l2(mem_stall_i),
		 .done_l2(mem_valid_i),
		 .miss(miss),
		 .rw_l2(mem_rw_o),
		 .valid_l2(mem_valid_o),
		 .we_b(we_b_temp),
		 .rd_valid_b(rd_valid_b),
		 .l2_addr_en(mem_addr_en),
		 .stall_out(stall_out_fsm),
		 .stall_out_d(portA_op_en)
	);
*/	
	nonblocking_fsm_L1 ctrl 
	(
		 .reset(reset),
		 .clock(clk),
		 
		 .dirty(mshr_rn_dirty | dirty_b_o[mshr_rn_victim]),
		 .rw_prev(mshr_get_rw),
		 .stall_l2(mem_stall_i),
		 .done_l2(mem_valid_i),
	//	 .miss(miss),
		 .mshr_empty(mshr_empty),
	//	 .block(),
		 .block(block_signal & mshr_comp_true),
		 .same_line(mshr_same_true_d),
		 .prev_read(mshr_comp_read),
		 
		 .rw_l2(mem_rw_o),
		 .valid_l2(mem_valid_o),
		 .we_b(we_b_temp),
		 .rd_valid_b(rd_valid_b),
		 .l2_addr_en(mem_addr_en),
		 .mshr_read_next(mshr_read_next),
		 .mshr_get(mshr_get), 
		 .mshr_del(mshr_del), 
		 .stall_out(stall_out_fsm),
		 .stall_out_d(portA_op_en),
		 .block_stall(block_stall)
	);

   `ifdef DUMMY_MEM

	Mem_dummy #(
		.CACHE_SIZE(256*1024),				// in Bytes
		.LINE_BITS(LINE_BITS),				// LOG(LINE_SIZE)
		.INDEX_BITS(13),						// LOG(NO_OF_SETS)
		.LINE_WIDTH(DATA_WIDTH),			//
		.ADDR_WIDTH(ADDR_WIDTH),
		.CREG_ID_BITS(CREG_ID_BITS),		// ID BITS of the ld/St Q from core
		.MSHR_ID_BITS(MSHR_ID_BITS)		// ID BITS for MSHR going to L2
	)
	memory ( 
		.clk(clk),
		.reset(reset),
		.addr_in(mem_addr_o), 	// address to L2
		.data_in(mem_data_o), 		// data to L2
		.rw_in(mem_rw_o), 			// read / write command
		.valid_in(mem_valid_o), 	//  valid input on the addr, data buses
		.id_in(mem_id_o), 			// MSHR id for l2 request
		.data_out(mem_data_i),	// data from the l2
		.id_out(mem_id_i),			// MSHR id for request being satisfied
		.ready_out(mem_valid_i), 	// the memory request for which data is ready
		.stall_out(mem_stall_i)  // the memory system cannot accept anymore requests, stall the pipeline
	);

   `else

	mem_ctrl_wrapper #(
		.BUFF_INDEX_BITS(2),			// LOG(Size of Buffer)
		.LINE_BITS(LINE_BITS),			// LOG(LINE_SIZE)
		.LINE_WIDTH(DATA_WIDTH),			//
		.ADDR_WIDTH(ADDR_WIDTH),
		.CREG_ID_BITS(MSHR_ID_BITS),		// ID BITS of the ld/St Q from core
		.MSHR_ID_BITS(MSHR_ID_BITS),		// ID BITS for MSHR going to L2
		.AVL_ADDR(AVL_ADDR),
		.AVL_SIZE(AVL_SIZE),
		.AVL_BE(AVL_BE)
	) 

	mem_wrapper (
		.clk(clk),
		.reset(reset),
		.addr_in(mem_addr_o), 		// address in from the core
		.data_in(mem_data_o), 		// data from the core
		.rw_in(mem_rw_o), 								// read / write command
		.valid_in(mem_valid_o), 							//  valid reg on the addr, data buses
		.id_in(mem_id_o), 		// ld/st Q id for request
		.data_out(mem_data_i),	// data to be given to the core
		.id_out(mem_id_i),	// ld/st Q id for request being satisfied
		.ready_out(mem_valid_i), 				// the memory request for which data is ready
		.stall_out(mem_stall_i), 							// the memory system cannot accept anymore requests
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
   `endif
	
	assign #0.25 mem_addr_o = mem_addr_en ? {tag_out_b,addr_b_cache[ADDR_WIDTH-TAG_BITS-1:0]} : addr_b;
	assign #0.25 mem_data_o = rd_valid_b ? cache_out_b : {DATA_WIDTH{1'b0}};
	assign #0.25 addr_b_cache = mshr_rn_valid ? addr_b_temp: stall_out_fsm ? mshr_get_addr : addr_b;  /// Not correct ///
	assign #0.25 victim_b = mshr_rn_valid ? mshr_rn_victim: stall_out_fsm ? mshr_get_victim : mshr_rn_victim_d;
	
	
	//////// Values that needs to be saved in MSHR and used on return ///////
	assign #0.25 addr_bef_reg = addr_in;
	assign #0.25 id_temp = id_in; 
	assign #0.25 rw_bef_reg = rw_in;	
	assign #0.25 data_bef_reg = data_in;	
	always@ (posedge clk or negedge reset)
	begin
		if (!reset) begin
			addr_prev <= 0;
			rw_prev <= 1'b0;
			id_prev <= 0;
			data_prev <= 0;
			victim_prev <= 0;
			
			mem_id_o <= 0;
			addr_b <= 0;
			mshr_rn_victim_d <= 0;
			
			mshr_same_addr <= 0;
			mshr_same_rw <= 1'b0;
			mshr_same_id <= 0;
			mshr_same_data <= 0;
			mshr_same_dirty <= 1'b0;
			block_signal_same <= 1'b0;
			block_signal_diff <= 1'b0;
		end
		else begin
			if (mshr_get_valid) begin
				addr_prev <= mshr_get_addr;
				rw_prev <= mshr_get_rw;
				id_prev <= mshr_get_cpu_id;
				data_prev <= mshr_get_data;
				victim_prev <= mshr_get_victim;
			end
			if (mshr_rn_valid) begin
				mem_id_o <= mem_id_temp;
				addr_b <= addr_b_temp;
				mshr_rn_victim_d <= mshr_rn_victim;
			end
			if (mshr_comp_true & miss_bef_reg) begin
				mshr_same_addr <= addr_bef_reg;
				mshr_same_rw <= rw_bef_reg;
				mshr_same_id <= id_temp;
				mshr_same_data <= data_bef_reg;
				mshr_same_dirty <= dirty_a_o[victim_temp];
				mshr_same_victim <= victim_temp;
				if (mshr_same_true & miss_bef_reg)
					block_signal_same <= 1'b1;
				else if (mshr_diff_true & miss_bef_reg)
					block_signal_diff <= 1'b1;
						
			end
			if (block_signal == 1'b1 && ~mshr_comp_true) begin
				block_signal_same <= 1'b0;
				block_signal_diff <= 1'b0;
			end
			if (block_signal_same == 1'b1 && ~mshr_comp_true) begin
				addr_prev <= mshr_same_addr;
				rw_prev <= mshr_same_rw;
				id_prev <= mshr_same_id;
				data_prev <= mshr_same_data;
		//		victim_prev <= mshr_same_victim;
			end
			mshr_same_true_d <= mshr_same_true;
		end
	end
	assign block_signal = block_signal_same | block_signal_diff;
	
	assign #0.25 mshr_comp_addr = miss_bef_reg ? addr_bef_reg : mshr_same_addr;
	
	assign mshr_add = (block_signal_diff & ~mshr_comp_true) ? 1'b1 : (miss_bef_reg & ~mshr_comp_true);
	assign mshr_add_addr = (block_signal_diff & ~mshr_comp_true) ? mshr_same_addr : addr_bef_reg;
	assign mshr_add_data = (block_signal_diff & ~mshr_comp_true) ? mshr_same_data : data_bef_reg;
	assign mshr_add_rw = (block_signal_diff & ~mshr_comp_true) ? mshr_same_rw : rw_bef_reg;
	assign mshr_add_cpu_id = (block_signal_diff & ~mshr_comp_true) ? mshr_same_id : id_temp;
	assign mshr_add_dirty = (block_signal_diff & ~mshr_comp_true) ? mshr_same_dirty : dirty_a_o;
	assign mshr_add_victim = (block_signal_diff & ~mshr_comp_true) ? mshr_same_victim : victim_temp;
	
	MSHR_2 #(.addr_bits(ADDR_WIDTH), .data_bits(DATA_WIDTH), .mshr_tag_bits(MSHR_ID_BITS), .cpu_id_bits(CREG_ID_BITS), .ASSOC_BITS(ASSOC_BITS)) mshr
	(
		.clk(clk), .enable(1'b1), .reset(reset),
		
		.add(mshr_add), .add_addr(mshr_add_addr), .add_data(mshr_add_data), .add_rw(mshr_add_rw), .add_dirty(mshr_add_dirty[mshr_add_victim]), .add_cpu_id(mshr_add_cpu_id), .add_victim(mshr_add_victim),
		
		.del(mshr_del), .del_tag(mem_id_d_d),
		
		.read_next(mshr_read_next),
		.rn_valid(mshr_rn_valid), .rn_addr(addr_b_temp), .rn_data(), .rn_rw(), .rn_dirty(mshr_rn_dirty), .rn_cpu_id(), .rn_mshr_id(mem_id_temp), .rn_victim(mshr_rn_victim),
		
		.get(mshr_get), .get_tag(mem_id_d),
		.get_valid(mshr_get_valid), .get_addr(mshr_get_addr), .get_data(mshr_get_data), .get_rw(mshr_get_rw), .get_dirty(mshr_get_dirty), .get_cpu_id(mshr_get_cpu_id), .get_victim(mshr_get_victim),
		
		.comp_addr(mshr_comp_addr), .comp_victim(victim_temp), 
		.comp_true(mshr_comp_true), .diff_line_true(mshr_diff_true), .same_line_true(mshr_same_true), .comp_read(mshr_comp_read), 
		
		.empty(mshr_empty), .full(mshr_full)
	);

endmodule 
