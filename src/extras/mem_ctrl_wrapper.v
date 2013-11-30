module mem_ctrl_wrapper
#(	parameter BUFF_INDEX_BITS = 2,		// entries in the buffer
	parameter LINE_BITS  = 5,		// LOG(LINE_SIZE)
	parameter LINE_WIDTH = 32,			//
	parameter ADDR_WIDTH = 32,
	parameter CREG_ID_BITS = 4,		// ID BITS of the ld/St Q from core
	parameter MSHR_ID_BITS = 4,		// ID BITS for MSHR going to L2
	parameter AVL_ADDR   = 30,		// AVL address
	parameter AVL_SIZE   = 3,		// AVL size
	parameter AVL_DATA_WIDTH     = LINE_WIDTH,			// AVL data width. cache lie width
	parameter AVL_BE     = 32		// AVL byte enable
)
(
	input clk,
	input reset,
	
	input [ADDR_WIDTH-1:0] addr_in, 	// address in from the core
	input [LINE_WIDTH-1:0] data_in, 	// data from the core
	input rw_in, 				// read / write command
	input valid_in, 			//  valid input on the addr, data buses
	input [CREG_ID_BITS-1:0]  id_in, 	// ld/st Q id for request
	output [LINE_WIDTH-1:0]   data_out,	// data to be given to the core
	output [CREG_ID_BITS-1:0] id_out,	// ld/st Q id for request being satisfied
	output ready_out, 			// the memory request for which data is ready
	output stall_out, 			// the memory system cannot accept anymore requests
													// stall the pipeline when this line is high
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
	//local params
	localparam BUFF_SIZE      = 1 << BUFF_INDEX_BITS;

	//local variables
	reg [BUFF_INDEX_BITS-1:0]    head_pending_counter;
	reg [BUFF_INDEX_BITS-1:0]    tail_req_counter;
	reg [BUFF_INDEX_BITS-1:0]    head_inflight_read;
	reg [BUFF_INDEX_BITS-1:0]    tail_read_req_counter;
	reg [CREG_ID_BITS-1:0]       id_in_store   [0:BUFF_SIZE - 1];
	reg                          r_in_store    [0:BUFF_SIZE - 1];
	reg                          w_in_store    [0:BUFF_SIZE - 1];
	reg [ADDR_WIDTH-1:0]         addr_in_store [0:BUFF_SIZE - 1];
	reg [LINE_WIDTH-1:0]         data_in_store [0:BUFF_SIZE - 1];
	reg req_fifo_full, read_id_fifo_full;

	//Reqs going back to L2
	assign id_out 	          = id_in_store[head_inflight_read];
	assign data_out           = avl_rdata;
	assign ready_out          = avl_rdata_valid;
	assign stall_out          = (req_fifo_full || read_id_fifo_full);

	//Reqs going to DDR2
	assign avl_addr           = addr_in_store[head_pending_counter] >> LINE_BITS;//CHECK!, OK, the address which goes to DDR2 is 25bit cache line address
	assign avl_wdata          = data_in_store[head_pending_counter];
	assign avl_read_req       = r_in_store[head_pending_counter];
	assign avl_write_req      = w_in_store[head_pending_counter];
	assign avl_size           = 1;
	assign avl_be             = {AVL_BE{1'b1}};
	assign avl_burstbegin     = 1'b0;


	
	wire [BUFF_INDEX_BITS-1:0]next_pending_req;
	wire [BUFF_INDEX_BITS-1:0]next_tail_req; 
	wire [BUFF_INDEX_BITS-1:0]next_head_inflight_read;
	wire  [BUFF_INDEX_BITS-1:0]next_tail_read;
	wire  commit_mem_req;
	assign next_pending_req = head_pending_counter + 1;
	assign next_tail_req 	= tail_req_counter + 1;
	assign next_head_inflight_read 	= head_inflight_read + 1;
	assign next_tail_read 	= tail_read_req_counter + 1;
	assign commit_mem_req   = ((avl_ready==1'b1)&&((head_pending_counter!=tail_req_counter)||(req_fifo_full)));//CHECK


	integer i;
	always @ (posedge clk or negedge reset)
	begin
		if (!reset) begin
			head_pending_counter    <= 0;
			tail_req_counter 	<= 0;
			head_inflight_read	<= 0;
			tail_read_req_counter	<= 0;
			req_fifo_full		<= 0;
			read_id_fifo_full 	<= 0;
			//initialize entries
			for (i=0; i<BUFF_SIZE; i=i+1) begin
			 	 id_in_store   [i] <= 0; 
                                 r_in_store    [i] <= 0;
                                 w_in_store    [i] <= 0;
                                 addr_in_store [i] <= 0;
                                 data_in_store [i] <= 0;
			end
		end else begin
			i <= 0;

			if(avl_rdata_valid == 1'b1) begin
				 head_inflight_read <= next_head_inflight_read;
			end
			
			if (commit_mem_req) begin
				head_pending_counter 		   <= next_pending_req;
				r_in_store   [head_pending_counter] <= 1'b0;
                                w_in_store   [head_pending_counter] <= 1'b0;
			end

			if((valid_in == 1'b1 ) && (req_fifo_full != 1'b1) && (read_id_fifo_full != 1'b1)) begin
				tail_req_counter <= next_tail_req;
                                r_in_store    [tail_req_counter] <=  ~rw_in;
                                w_in_store    [tail_req_counter] <=  rw_in;
                                addr_in_store [tail_req_counter] <=  addr_in;
                                data_in_store [tail_req_counter] <=  data_in;

				if (commit_mem_req) begin
					req_fifo_full <= next_tail_req == next_pending_req;
				end else begin
					req_fifo_full <= next_tail_req == head_pending_counter;
				end

				if(rw_in == 1'b0)begin
					tail_read_req_counter			<= next_tail_read;
					id_in_store   [tail_read_req_counter]   <= id_in;
					if (avl_rdata_valid == 1'b1 ) begin
						read_id_fifo_full <= next_tail_read == next_head_inflight_read;
					end else begin
						read_id_fifo_full <= next_tail_read == head_inflight_read;
					end
				end else begin	
					if(avl_rdata_valid == 1'b1)
						read_id_fifo_full <= 1'b0;
				end
			end else begin
				if (commit_mem_req == 1'b1)
					req_fifo_full         <= 1'b0;
				if (avl_rdata_valid == 1'b1)
					read_id_fifo_full <= 1'b0;
			end
		end
        end
endmodule
