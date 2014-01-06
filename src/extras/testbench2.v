`timescale 1ns/100ps
module top();
  reg phi, togclk;// reset_in;
  wire reset_in;  

  wire [6:0] charsel, text, wrcol; 
  wire [0:6] disp1, disp2;
  wire hsync, vsync, valid, led1;
  wire [11:0] dac_vid;
  wire clk1, clkby2;
  wire avl_ready, avl_rdata_valid;

  localparam LINE_BITS    = 5;
  localparam DATA_WIDTH   = 32;
  localparam ADDR_WIDTH   = 32;
  localparam CREG_ID_BITS = 3;
  localparam WORDS        = 8;
  localparam LINE_WIDTH = 256;//DATA_WIDTH*WORDS;
  wire [ADDR_WIDTH-1:0]   avl_addr;
  wire [LINE_WIDTH -1:0]  avl_wdata;
  wire [LINE_WIDTH -1:0]  avl_rdata;
  wire [2:0]        	avl_size;
  wire [31:0] 		avl_be;

  ddr2_ctrl_test_example_sim_e0_d0   mem_driver(.clk(clk1), .clkby2(phi), .reset_n(reset),
    .avl_ready		(avl_ready	),      
    .avl_addr		(avl_addr	),       
    .avl_size		(avl_size	),       
    .avl_wdata		(avl_wdata	),     
    .avl_rdata		(avl_rdata	),     
    .avl_write_req	(avl_write_req	), 
    .avl_read_req	(avl_read_req	),  
    .avl_rdata_valid	(avl_rdata_valid),
    .avl_be		(avl_be		),        
    .avl_burstbegin	(avl_burstbegin	)		
  );	//reset_in for memory, its reset low (0=> reset)

	Mem_dummy #(
		.CACHE_SIZE(8*256*1024),				// in Bytes
		.LINE_BITS(LINE_BITS),				// LOG(LINE_SIZE)
		.INDEX_BITS(16),						// LOG(NO_OF_SETS)
		.LINE_WIDTH(LINE_WIDTH),			//
		.ADDR_WIDTH(ADDR_WIDTH),
		.CREG_ID_BITS(CREG_ID_BITS),		// ID BITS of the ld/St Q from core
		.MSHR_ID_BITS(CREG_ID_BITS)		// ID BITS for MSHR going to L2
	)
	memory ( 
		.clk(clk1),
		.reset(reset),
		.addr_in({avl_addr,{LINE_BITS{1'b0}}}), 	// address to L2
		.data_in(avl_wdata), 		// data to L2
		.rw_in(avl_write_req), 			// read / write command
		.valid_in( (avl_write_req || avl_read_req)&avl_ready), 	//  valid input on the addr, data buses
		.id_in(1), 			// MSHR id for l2 request
		.data_out(avl_rdata),	// data from the l2
		.id_out(),			// MSHR id for request being satisfied
		.ready_out(avl_rdata_valid), 	// the memory request for which data is ready
		//.stall_out(mem_stall_out)  // the memory system cannot accept anymore requests, stall the pipeline
		.stall_out()  // the memory system cannot accept anymore requests, stall the pipeline
	);
   
assign avl_ready = ~mem_stall_out;
nn_reset_source reset_source(clk1, reset);

reg [31:0] stall_counter;
reg [31:0] wait_counter;

assign mem_stall_out = (stall_counter == 5)? 1'b1 : 1'b0;

always@(posedge clk1) begin
   if((avl_write_req || avl_read_req) & avl_ready)begin
      stall_counter<= stall_counter + 1'b1;
      wait_counter<= 0;
   end else begin
      wait_counter <= wait_counter + 1'b1;
     if(wait_counter == 15)
        stall_counter<= 0;
   end
end

  initial
    begin
       $dumpfile("dump.vcd");
       $dumpvars(0, top);
       phi = 0; togclk = 0; stall_counter<= 0; wait_counter<= 0;
       #9 togclk = 1;
       #300091 $finish;
       //#9091 $finish;
    end

   always
     begin
       #5 phi = phi ^ togclk;
     end

   freq_div_nn #(.DIVLOG(1)) freq_div1 (phi, clk1);

endmodule // top
