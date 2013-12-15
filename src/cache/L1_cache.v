`timescale 1ns/100ps

module L1_cache #(
	parameter CACHE_SIZE = 16*1024,	// in Bytes
//	parameter LINE_SIZE 	= 32,			// in Bytes
	parameter LINE_BITS 	= 5,			// LOG(LINE_SIZE)
//	parameter NO_OF_SETS = 256,		//	NO_OF_SETS*LINE_SIZE = CACHE_SIZE
	parameter INDEX_BITS = 9,			// LOG(NO_OF_SETS)
//	parameter TAG_BITS	= 19,			//	ADDR_WIDTH-LINE_BITS-INDEX_BITS
	parameter DATA_WIDTH = 32,			//
	parameter WORDS = 8,
	parameter ADDR_WIDTH = 32,
	parameter CREG_ID_BITS = 4,		// ID BITS of the ld/St Q from core
	parameter MSHR_ID_BITS = 4,			// ID BITS for MSHR going to L2
	parameter SIMD_WIDTH = 1			// SIMD width 
 )
(
	input clk,
	input clkby2,
	input reset,
	
	input [ADDR_WIDTH-1:0] addr_in, 		// address in from the core
	input [DATA_WIDTH*SIMD_WIDTH-1:0] data_in, 		// data from the core
	input rw_in, 								// read / write command
	input valid_in, 							//  valid input on the addr, data buses
	input [CREG_ID_BITS-1:0] id_in, 		// ld/st Q id for request
        `ifdef SIMD
	input [WORDS-1:0] valid_word_in, 		// valid word in
        `endif
	output [DATA_WIDTH*SIMD_WIDTH-1:0] data_out,	// data to be given to the core
	output reg [CREG_ID_BITS-1:0] id_out,	// ld/st Q id for request being satisfied
	output reg ready_out, 						// the memory request for which data is ready
	output stall_out, 							// the memory system cannot accept anymore requests
													// stall the pipeline when this line is high

	output [ADDR_WIDTH-1:0] l2_addr_o,
	output [DATA_WIDTH*WORDS-1:0] l2_data_o,
	output l2_rw_o,
	output l2_valid_o,
	output reg [MSHR_ID_BITS-1:0] l2_id_o,
	input [DATA_WIDTH*WORDS-1:0] l2_data_i,
	input l2_valid_i,
	input [MSHR_ID_BITS-1:0] l2_id_i,
	input l2_stall_i

);
	
	localparam ASSOC_BITS=1;
	
	// signals for  proc side data array
	wire data_a_we;
	wire [DATA_WIDTH*WORDS-1:0] cache_out;
	
	// signals for proc side tag array
	wire tag_a_dirty_in;
	wire tag_a_valid_in;
	wire tag_a_we;
	wire dirty_out;
	wire valid_out;
	wire [ADDR_WIDTH-LINE_BITS-INDEX_BITS-1:0] tag_out;
	
	// signals for L2 data array
	wire data_b_we;
	wire [DATA_WIDTH*WORDS-1:0] cache_out2;
	reg [DATA_WIDTH*WORDS-1:0] cache_in2;
	
	// signals for L2 tag array
	wire tag_b_dirty_in;
	wire tag_b_valid_in;
	wire tag_b_we;
	wire dirty_out_b;
	wire valid_out_b;
	wire [ADDR_WIDTH-LINE_BITS-INDEX_BITS-1:0] tag_out_b;

	// signals related to address split	
	wire [INDEX_BITS-1:0] index_in, index_a;
	wire [ADDR_WIDTH-LINE_BITS-INDEX_BITS-1:0] tag_in, tag_a;
	wire [LINE_BITS-2-1:0] word_in, word_a;
	wire [DATA_WIDTH*SIMD_WIDTH-1:0] data_a;
	
	// stored signals for L2
	reg [ADDR_WIDTH-1:0] ram_addr, addr_prev;
	reg [INDEX_BITS-1:0] index_prev;
	reg [ADDR_WIDTH-LINE_BITS-INDEX_BITS-1:0] tag_prev;
	reg [LINE_BITS-2-1:0] word_prev;
	reg [CREG_ID_BITS-1:0] id_prev;
	reg [DATA_WIDTH*SIMD_WIDTH-1:0] data_prev;
        
        `ifdef SIMD
	reg  [SIMD_WIDTH-1:0] word_val_prev;
	wire [SIMD_WIDTH-1:0] mshr_add_word_val;
	wire [SIMD_WIDTH-1:0] mshr_get_word_val;
	reg  [SIMD_WIDTH-1:0] mshr_same_word_val;
	wire [SIMD_WIDTH-1:0] word_val_bef_reg;	// data to be given to the core
	wire [SIMD_WIDTH-1:0] data_a_word_val;
        `endif

	reg rw_prev;
	
	wire mshr_add;
	wire [ADDR_WIDTH-1:0] mshr_add_addr;
	wire [CREG_ID_BITS-1:0] mshr_add_cpu_id;
	wire [DATA_WIDTH*SIMD_WIDTH-1:0] mshr_add_data;
	wire mshr_add_rw, mshr_add_dirty;
	
	wire [ADDR_WIDTH-1:0] mshr_get_addr;
	wire [CREG_ID_BITS-1:0] mshr_get_cpu_id;
	wire [DATA_WIDTH*SIMD_WIDTH-1:0] mshr_get_data;
	wire mshr_get_rw, mshr_get_valid, mshr_get_dirty;
	
	wire mshr_rn_valid;
	reg [ADDR_WIDTH-1:0] addr_b;
	wire [ADDR_WIDTH-1:0] addr_b_cache;
	wire [INDEX_BITS-1:0] index_b;
	wire [ADDR_WIDTH-LINE_BITS-INDEX_BITS-1:0] tag_b;
	wire [2:0] l2_id_temp; 
	wire [ADDR_WIDTH-1:0] addr_b_temp;
	wire mshr_empty, mshr_full;
	wire mshr_rn_dirty;
	wire mshr_read_next, mshr_get, mshr_del;
			
	reg [ADDR_WIDTH-1:0] mshr_same_addr;
	reg [DATA_WIDTH*SIMD_WIDTH-1:0] mshr_same_data;
	reg [CREG_ID_BITS-1:0] mshr_same_id;
	reg [ASSOC_BITS-1:0] mshr_same_victim;
	reg mshr_same_rw, mshr_same_dirty;
	wire [ADDR_WIDTH-1:0] mshr_comp_addr;
	wire mshr_comp_true, mshr_diff_true, mshr_same_true, mshr_comp_read;
	reg mshr_same_true_d;
	
	// random signals
	wire hit; 
	reg [LINE_BITS-2-1:0] word_a_d;
	wire miss_bef_reg;
	wire valid_real;
	
	// blocking fsm control signals	 
        wire rd_valid_b;
        wire l2_addr_en;
	wire stall_out_fsm;
	wire portA_op_en;
	wire block_stall;
	reg  block_signal_same;
	reg  block_signal_diff;
	wire block_signal;

	reg [ASSOC_BITS-1:0] counter, victim_temp;
	wire [ASSOC_BITS-1:0] victim_a, victim_b;
	wire [ASSOC_BITS-1:0] mshr_rn_victim, mshr_get_victim;
	reg [ASSOC_BITS-1:0] mshr_rn_victim_d, victim_prev;
	
	wire [ADDR_WIDTH-1:0] addr_bef_reg;
	wire [CREG_ID_BITS-1:0] id_temp;
	wire rw_bef_reg;
	wire [DATA_WIDTH*SIMD_WIDTH-1:0] data_bef_reg;	// data to be given to the core

	wire [DATA_WIDTH*WORDS-1:0] fullZeros; 
	wire [DATA_WIDTH*(WORDS-1)-1:0] lessZeros;
	
	assign fullZeros = {DATA_WIDTH*WORDS{1'b0}};
	assign lessZeros = fullZeros[DATA_WIDTH*(WORDS-1)-1:0];
	 
        assign #0.5 hit = ( valid_real & valid_out) ? (tag_in == tag_out) : 1'b0;
//	assign miss = ~hit & valid_in;
	
	assign #0.5 index_a = portA_op_en ? index_prev : index_in;
	assign #0.5 tag_a = portA_op_en ? tag_prev : tag_in;
	assign #0.5 word_a = portA_op_en ? word_prev : word_in;
	assign #0.5 data_a = portA_op_en ? data_prev : data_bef_reg;
        `ifdef SIMD
	assign #0.5 data_a_word_val = portA_op_en ? word_val_prev : word_val_bef_reg;
        `endif
	
	assign #0.5 data_a_we = portA_op_en ? rw_prev : rw_in & hit;
	assign #0.5 tag_a_we = portA_op_en ? rw_prev : rw_in & hit;
	assign tag_a_valid_in = tag_a_we;
	assign tag_a_dirty_in = tag_a_we;
	
	//// Outputs for now
	wire rdy_bef_reg; 
	wire [CREG_ID_BITS-1:0] id_bef_reg;
	assign #0.5 rdy_bef_reg = portA_op_en ? ~rw_prev : (hit & ~rw_in);
	assign #0.5 id_bef_reg = (portA_op_en ? id_prev : id_in);
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
			id_out <= id_bef_reg;
		end
	end
	
	///////// TODO This will change with non-blocking ///////////
/*	always @ (posedge clk or negedge reset) begin
		if (!reset)
			stall_out <= 1'b0;
		else if (miss_bef_reg & ~miss)
			stall_out <= 1'b1;
		else if (portA_op_en & ~stall_out_fsm)
			stall_out <= 1'b0;
	end
*/
	assign stall_out = mshr_full | portA_op_en | block_stall | block_signal;
	assign valid_real = valid_in & ~stall_out;
	assign #0.5 miss_bef_reg = ~hit & valid_real;

	always @ (posedge clk or negedge reset) begin
		if (!reset) begin
	//		miss <= 1'b0;
	//		miss_d <= 1'b0;
			word_a_d <= 1'b0;
	//		dirty_out_d <= 1'b0;
		end
		else begin
	//		miss <= miss_bef_reg;
	//		miss_d <= miss;
			word_a_d <= word_a;
	//		dirty_out_d <= dirty_out;
		end
	end
	
	reg [CREG_ID_BITS-1:0] l2_id_d, l2_id_d_d;
	reg mshr_rn_valid_d;
	always @ (posedge clk or negedge reset) begin
		if (!reset) begin
			cache_in2 <= 0;
			l2_id_d <= 1'b0;
			l2_id_d_d <= 1'b0;
		end
		else begin
			if (l2_valid_i) begin
				cache_in2 <= l2_data_i;
				l2_id_d <= l2_id_i;
			end
			l2_id_d_d <= l2_id_d;
		end
	end
	
        `ifdef SIMD
	data_array_simd #(.DATA_WIDTH(DATA_WIDTH*WORDS), .INDEX_WIDTH(INDEX_BITS), .WORD_BITS(LINE_BITS-2))
		data_ram
		(
			.data_a(data_a), .data_b(cache_in2),
			.addr_a(index_a), .addr_b(index_b),
			.valid_word_a(data_a_word_val), //.word_b(0),
			.we_a(data_a_we), .we_b(data_b_we), .mode_a(1'b0), .clk(clk),
			.q_a(cache_out), .q_b(cache_out2)
		);
        `else
	data_array #(.DATA_WIDTH(DATA_WIDTH*WORDS), .INDEX_WIDTH(INDEX_BITS), .WORD_BITS(LINE_BITS-2))
		data_ram
		(
			.data_a({lessZeros,data_a}), .data_b(cache_in2),
			.addr_a(index_a), .addr_b(index_b),
			.word_a(word_a), //.word_b(0),
			.we_a(data_a_we), .we_b(data_b_we), .mode_a(1'b0), .clk(clk),
			.q_a(cache_out), .q_b(cache_out2)
		);
        `endif
	
	
        `ifdef SIMD
         assign data_out = cache_out;
        `else
	GenericMux #(.WIDTH(DATA_WIDTH),.SEL_BITS(LINE_BITS-2)) mux1
	(
		.in_bus(cache_out), 
		.sel(word_a_d),
		.out(data_out)
	);
        `endif

	
	L1_tag_array #(.TAG_BITS(ADDR_WIDTH-LINE_BITS-INDEX_BITS), .INDEX_WIDTH(INDEX_BITS))
		tag_ram
		(
			.tag_a(tag_a), .tag_b(tag_b),
			.dirty_a_i(tag_a_dirty_in), .dirty_b_i(tag_b_dirty_in),
			.valid_a_i(tag_a_valid_in), .valid_b_i(tag_b_valid_in),
			.addr_a(index_a), .addr_b(index_b),
			.we_a(tag_a_we), .we_b(tag_b_we), .clk(clk), .new_clk(clkby2),
			.q_a(tag_out), .q_b(tag_out_b),
			.dirty_a_o(dirty_out), .dirty_b_o(dirty_out_b),
			.valid_a_o(valid_out), .valid_b_o(valid_out_b)
		);
	
	

	/////////////// L2 side of things ///////////	
	assign tag_b_we = data_b_we;
	assign tag_b_valid_in = data_b_we;
	assign tag_b_dirty_in = 1'b0;	
			
	assign #0.5 l2_addr_o = l2_addr_en ? {tag_out_b,index_b,{LINE_BITS{1'b0}}} : addr_b;	//NN Fix this for Line bits instead of 5
	assign #0.5 l2_data_o = rd_valid_b ? cache_out2 : fullZeros;
	assign #0.5 addr_b_cache = mshr_rn_valid ? addr_b_temp: stall_out_fsm ? mshr_get_addr : addr_b;
	assign #0.5 index_b = addr_b_cache[INDEX_BITS+LINE_BITS-1:LINE_BITS];
	assign #0.5 tag_b = addr_b_cache[ADDR_WIDTH-1:INDEX_BITS+LINE_BITS];
	

	assign #0.5 addr_bef_reg = addr_in;
	assign #0.5 id_temp = id_in; 
	assign #0.5 rw_bef_reg = rw_in;
	assign #0.5 index_in = addr_in[INDEX_BITS+LINE_BITS-1:LINE_BITS];
	assign #0.5 tag_in = addr_in[ADDR_WIDTH-1:INDEX_BITS+LINE_BITS];
	assign #0.5 word_in = addr_in[LINE_BITS-1:2];
	assign #0.5 data_bef_reg = data_in;
        `ifdef SIMD
	assign #0.5 word_val_bef_reg = valid_word_in;
        `endif
		
	//////// Values that needs to be saved in MSHR and used on return ///////
	always@ (posedge clk or negedge reset)
	begin
		if (!reset) begin
			addr_prev <= 0;
			rw_prev <= 1'b0;
			id_prev <= 0;
			data_prev <= 0;

                        `ifdef SIMD
			word_val_prev <= 0;
                        `endif
			victim_prev <= 0;
			
			l2_id_o <= 0;
			addr_b <= 0;
			mshr_rn_victim_d <= 0;

			mshr_same_addr <= 0;
			mshr_same_rw <= 1'b0;
			mshr_same_id <= 0;
			mshr_same_data <= 0;
			mshr_same_dirty <= 1'b0;
			block_signal_same <= 1'b0;
			block_signal_diff <= 1'b0;
                        `ifdef SIMD
			mshr_same_word_val <= 0;
                        `endif
		end
		else begin
			if (mshr_get_valid) begin
				addr_prev <= mshr_get_addr;
				rw_prev <= mshr_get_rw;
				id_prev <= mshr_get_cpu_id;
				data_prev <= mshr_get_data;
                                `ifdef SIMD
				word_val_prev <= mshr_get_word_val;
                                `endif
				victim_prev <= mshr_get_victim;
			end else begin
			        if (block_signal == 1'b1 && ~mshr_comp_true) begin
			        	block_signal_same <= 1'b0;
			        	block_signal_diff <= 1'b0;
			        end
			        if (block_signal_same == 1'b1 && ~mshr_comp_true) begin
			        	addr_prev <= mshr_same_addr;
			        	rw_prev <= mshr_same_rw;
			        	id_prev <= mshr_same_id;
			        	data_prev <= mshr_same_data;
                                        `ifdef SIMD
		                        word_val_prev <= mshr_same_word_val;
                                        `endif
			        end
			end
			if (mshr_rn_valid) begin
				l2_id_o <= l2_id_temp;
				addr_b <= addr_b_temp;
				mshr_rn_victim_d <= mshr_rn_victim;
			end
			if (mshr_comp_true & miss_bef_reg) begin
				mshr_same_addr <= addr_bef_reg;
				mshr_same_rw <= rw_bef_reg;
				mshr_same_id <= id_temp;
				mshr_same_data <= data_bef_reg;
				mshr_same_dirty <= dirty_out;
                                `ifdef SIMD
		                mshr_same_word_val <= word_val_bef_reg;
                                `endif
				if (mshr_same_true & miss_bef_reg)
					block_signal_same <= 1'b1;
				else if (mshr_diff_true & miss_bef_reg)
					block_signal_diff <= 1'b1;
						
			end
			/*if (block_signal == 1'b1 && ~mshr_comp_true) begin
				block_signal_same <= 1'b0;
				block_signal_diff <= 1'b0;
			end
			if (block_signal_same == 1'b1 && ~mshr_comp_true) begin
				addr_prev <= mshr_same_addr;
				rw_prev <= mshr_same_rw;
				id_prev <= mshr_same_id;
				data_prev <= mshr_same_data;
                                `ifdef SIMD
		                word_val_prev <= mshr_same_word_val;
                                `endif
			end*/
			mshr_same_true_d <= mshr_same_true;
		end
	end
	assign block_signal = block_signal_same | block_signal_diff;
	
	always @(addr_prev) begin
		index_prev = addr_prev[INDEX_BITS+LINE_BITS-1:LINE_BITS];
		tag_prev = addr_prev[ADDR_WIDTH-1:INDEX_BITS+LINE_BITS];
		word_prev = addr_prev[LINE_BITS-1:2];
	end
	
	assign #0.5 mshr_comp_addr = miss_bef_reg ? addr_in : mshr_same_addr;
	
	assign mshr_add = (block_signal_diff & ~mshr_comp_true) ? 1'b1 : (miss_bef_reg & ~mshr_comp_true);
	assign mshr_add_addr = (block_signal_diff & ~mshr_comp_true) ? mshr_same_addr : addr_bef_reg;
	assign mshr_add_data = (block_signal_diff & ~mshr_comp_true) ? mshr_same_data : data_bef_reg;
	assign mshr_add_rw = (block_signal_diff & ~mshr_comp_true) ? mshr_same_rw : rw_bef_reg;
	assign mshr_add_cpu_id = (block_signal_diff & ~mshr_comp_true) ? mshr_same_id : id_temp;
	assign mshr_add_dirty = (block_signal_diff & ~mshr_comp_true) ? mshr_same_dirty : dirty_out;
        `ifdef SIMD
	assign mshr_add_word_val = (block_signal_diff & ~mshr_comp_true) ? mshr_same_word_val : word_val_bef_reg;
        `endif

	MSHR_2 #(.addr_bits(ADDR_WIDTH), .data_bits(DATA_WIDTH*SIMD_WIDTH), .mshr_tag_bits(MSHR_ID_BITS), .cpu_id_bits(CREG_ID_BITS), .ASSOC_BITS(1)) mshr
	(
		.clk(clk), .enable(1'b1), .reset(reset),
		
		.add(mshr_add), .add_addr(mshr_add_addr), .add_data(mshr_add_data), .add_rw(mshr_add_rw), .add_dirty(mshr_add_dirty), .add_cpu_id(mshr_add_cpu_id), .add_victim(1'b0),
		
		.del(mshr_del), .del_tag(l2_id_d_d),
		
		.read_next(mshr_read_next),
		.rn_valid(mshr_rn_valid), .rn_addr(addr_b_temp), .rn_data(), .rn_rw(), .rn_dirty(mshr_rn_dirty), .rn_cpu_id(), .rn_mshr_id(l2_id_temp), .rn_victim(mshr_rn_victim),
		
		.get(mshr_get), .get_tag(l2_id_d),
		.get_valid(mshr_get_valid), .get_addr(mshr_get_addr), .get_data(mshr_get_data), .get_rw(mshr_get_rw), .get_dirty(mshr_get_dirty), .get_cpu_id(mshr_get_cpu_id), .get_victim(mshr_get_victim),

		.comp_addr(mshr_comp_addr), .comp_victim(1'b0),
		.comp_true(mshr_comp_true), .diff_line_true(mshr_diff_true), .same_line_true(mshr_same_true), .comp_read(mshr_comp_read), 
        `ifdef SIMD
         .add_word_valid(mshr_add_word_val), .rn_word_valid(), .get_word_valid(mshr_get_word_val),
        `endif	
		.empty(mshr_empty), .full(mshr_full)
	);
	
	nonblocking_fsm_L1 ctrl 
	(
		 .reset(reset),
		 .clock(clk),
		 
		 .dirty(mshr_rn_dirty | dirty_out_b),
		 .rw_prev(mshr_get_rw),
		 .stall_l2(l2_stall_i),
		 .done_l2(l2_valid_i),
	//	 .miss(miss),
		 .mshr_empty(mshr_empty),
		 .block(block_signal & mshr_comp_true),
		 .same_line(mshr_same_true_d),
		 .prev_read(mshr_comp_read),
		 
		 .rw_l2(l2_rw_o),
		 .valid_l2(l2_valid_o),
		 .we_b(data_b_we),
		 .rd_valid_b(rd_valid_b),
		 .l2_addr_en(l2_addr_en),
		 .mshr_read_next(mshr_read_next),
		 .mshr_get(mshr_get), 
		 .mshr_del(mshr_del), 
		 .stall_out(stall_out_fsm),
		 .stall_out_d(portA_op_en),
		 .block_stall(block_stall)
	);
		
endmodule
