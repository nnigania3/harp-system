module nn_de3_cache_test (clk, ready_out, data_display, clkby2);

	input clk;
	input clkby2;
	output ready_out;
	output [6:0]data_display;
	wire reset;	
	reg [31:0] addr_in; 		// address in from the core
	reg [LINE_WIDTH -1:0] data_in; 		// data from the core
	reg rw_in; 								// read / write command
	wire valid_in; 							//  valid reg on the addr, data buses
	reg [2:0] id_in; 		// ld/st Q id for request
	
	wire [LINE_WIDTH-1:0] data_out;	// data to be given to the core
	wire [2:0] id_out;	// ld/st Q id for request being satisfied
	wire ready_out; 						// the memory request for which data is ready
	wire stall_out;							// the memory system cannot accept anymore requests

	localparam LINE_BITS    = 5;
        localparam DATA_WIDTH   = 32;
        localparam ADDR_WIDTH   = 32;
        localparam CREG_ID_BITS = 3;
        localparam WORDS        = 8;
	localparam LINE_WIDTH = 32;//DATA_WIDTH*WORDS;
	wire [ADDR_WIDTH-1:0]   avl_addr;
	wire [LINE_WIDTH -1:0]  avl_wdata;
	wire [LINE_WIDTH -1:0]  avl_rdata;
	wire [2:0]        	avl_size;
	wire [31:0] 		avl_be;

	
	mem_ctrl_wrapper #(
		.BUFF_INDEX_BITS(2),
		.LINE_BITS(LINE_BITS),				// LOG(LINE_SIZE)
		.INDEX_BITS(13),						// LOG(NO_OF_SETS)
		.LINE_WIDTH(LINE_WIDTH),			//
		.ADDR_WIDTH(ADDR_WIDTH),
		.CREG_ID_BITS(CREG_ID_BITS),		// ID BITS of the ld/St Q from core
		.MSHR_ID_BITS(CREG_ID_BITS),		// ID BITS for MSHR going to L2
		.AVL_ADDR(ADDR_WIDTH)
	) 
	mem_wrapper (
		clk,
		reset,
		addr_in, 		// address in from the core
		data_in, 		// data from the core
		rw_in, 								// read / write command
		valid_in, 							//  valid reg on the addr, data buses
		id_in, 		// ld/st Q id for request
		data_out,	// data to be given to the core
		id_out,	// ld/st Q id for request being satisfied
		ready_out, 				// the memory request for which data is ready
		stall_out, 							// the memory system cannot accept anymore requests
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

	Mem_dummy #(
		.CACHE_SIZE(256*1024),				// in Bytes
		.LINE_BITS(LINE_BITS),				// LOG(LINE_SIZE)
		.INDEX_BITS(13),						// LOG(NO_OF_SETS)
		.LINE_WIDTH(LINE_WIDTH),			//
		.ADDR_WIDTH(ADDR_WIDTH),
		.CREG_ID_BITS(CREG_ID_BITS),		// ID BITS of the ld/St Q from core
		.MSHR_ID_BITS(CREG_ID_BITS)		// ID BITS for MSHR going to L2
	)
	memory ( 
		.clk(clk),
		.reset(reset),
		.addr_in(avl_addr), 	// address to L2
		.data_in(avl_wdata), 		// data to L2
		.rw_in(avl_write_req), 			// read / write command
		.valid_in(avl_write_req || avl_read_req), 	//  valid input on the addr, data buses
		.id_in(1), 			// MSHR id for l2 request
		.data_out(avl_rdata),	// data from the l2
		.id_out(),			// MSHR id for request being satisfied
		.ready_out(avl_rdata_valid), 	// the memory request for which data is ready
		.stall_out(mem_stall_out)  // the memory system cannot accept anymore requests, stall the pipeline
	);

wire mem_stall_out;
assign avl_ready = ~mem_stall_out;

reg [9:0]count;
reg [31:0] reset_time;	//check we will reset again
reg tick;
reg stop;
reg [31:0]data_sum;

wire [31:0]data_display_temp;
assign data_display_temp = data_sum + data_out;
assign data_display = data_display_temp[11:5];

   initial begin
   	reset_time <= 0;
   end

   always @ (posedge clk)
   begin
      reset_time <= reset_time + 1;
      if (reset == 1'b0) begin
       	 addr_in  <= 32'd0;
       	 data_in  <= {LINE_WIDTH{1'b0}};	//initial value
       	 rw_in    <= 1;
       	 id_in    <= 3'b000;
       	 count    <= 1;
	 stop     <= 0;	
	 data_sum <= 0;	
      end else begin
      	 if ( !stall_out && !stop) begin
      	    count    <= count + 1;
	    if ( count == 10'b0010000000)
               stop <= 1'b1;
      	    if(count < 10'b0001000000) begin
      	       rw_in   <= 1'b1;
      	       addr_in <= {28'd0, count[5:0]} * 4;
      	       data_in <= {count[5:0]};
      	       id_in   <= id_in + 3'b001;
      	    end else begin
      	       rw_in   <= 1'b0;
      	       addr_in <= {28'd0, count[5:0]} * 4;
      	     //data_in <= {0, count[3:0]} + 100;
      	       id_in   <= id_in + 3'b001;
      	    end
      	 end
	 if(ready_out == 1'b1)	
		data_sum <= data_sum + data_out;
      end
   end

assign valid_in = (!reset || stop || stall_out) ? 1'b0 : 1'b1;
assign reset    = (reset_time < 32'd30) ? 1'b0 : 1'b1 ;
endmodule
