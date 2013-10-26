module nn_de3_cache_test (clk, ready_out, data_display, clkby2);

	input clk;
	input clkby2;
	output ready_out;
	output [6:0]data_display;
	wire reset;	
	reg [31:0] addr_in; 		// address in from the core
	reg [31:0] data_in; 		// data from the core
	reg rw_in; 								// read / write command
	wire valid_in; 							//  valid reg on the addr, data buses
	reg [2:0] id_in; 		// ld/st Q id for request
	
	wire [31:0] data_out;	// data to be given to the core
	wire [2:0] id_out;	// ld/st Q id for request being satisfied
	wire ready_out; 						// the memory request for which data is ready
	wire stall_out;							// the memory system cannot accept anymore requests

	cache_subsystem cache
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
	);


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
       	 data_in  <= 32'd0;	//initial value
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
      	       data_in <= {28'd0, count[5:0]};
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
