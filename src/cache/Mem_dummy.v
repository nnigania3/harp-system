module Mem_dummy
#(	parameter CACHE_SIZE = 16*1024,	// in Bytes
	parameter LINE_BITS 	= 5,			// LOG(LINE_SIZE)
	parameter INDEX_BITS = 9,			// LOG(NO_OF_SETS)
	parameter LINE_WIDTH = 32,			//
	parameter ADDR_WIDTH = 32,
	parameter CREG_ID_BITS = 4,		// ID BITS of the ld/St Q from core
	parameter MSHR_ID_BITS = 4			// ID BITS for MSHR going to L2
)
(
	input clk,
	input reset,
	
	input [ADDR_WIDTH-1:0] addr_in, 		// address in from the core
	input [LINE_WIDTH-1:0] data_in, 		// data from the core
	input rw_in, 								// read / write command
	input valid_in, 							//  valid input on the addr, data buses
	input [CREG_ID_BITS-1:0] id_in, 		// ld/st Q id for request
	output [LINE_WIDTH-1:0] data_out,	// data to be given to the core
	output [CREG_ID_BITS-1:0] id_out,	// ld/st Q id for request being satisfied
	output ready_out, 						// the memory request for which data is ready
	output stall_out 							// the memory system cannot accept anymore requests
													// stall the pipeline when this line is high
); 

	localparam MEM_CYCLE = 8;
	localparam MEM_CYCLE_BITS = 3; 	// LOG(MEM_CYCLE)
	
	reg [LINE_WIDTH-1:0] data_delay [0:MEM_CYCLE-2];
	reg [CREG_ID_BITS-1:0] id_delay [0:MEM_CYCLE-2];
	reg valid_delay [0:MEM_CYCLE-1];
	
	wire [LINE_WIDTH-1:0] mem_data;
	reg [CREG_ID_BITS-1:0] id_temp;
	
//	wire new_clk;
	reg ready_temp;
	reg [MEM_CYCLE_BITS:0] count;
	
//	wire [MEM_CYCLE_BITS:0]	One;
//	wire [MEM_CYCLE_BITS:0]	setMax;

//	assign One = {{MEM_CYCLE_BITS{1'b0}}, 1'b1};
//	assign setMax = {MEM_CYCLE_BITS+1{1'b1}};
	
//	Frequency_Divider #(.Divisor(4), .Bits(2)) f1 (clk,reset,new_clk);
	
	DMem #(.DATA_WIDTH(LINE_WIDTH), .ADDR_WIDTH(INDEX_BITS), .SIZE(CACHE_SIZE/32)) memory
	(
		.addr(addr_in[INDEX_BITS+LINE_BITS-1:LINE_BITS]), 
		.data(data_in), 
		.wr_en(rw_in), 
		.clk(clk), 
		.reset(reset),
		.mem_data_out(mem_data)	
	);
	
//	assign data_out = (addr_in < 100) ? mem_data : data_delay[MEM_CYCLE-2];
//	assign id_out = (addr_in < 100) ? id_temp : id_delay[MEM_CYCLE-2];
	assign data_out = data_delay[MEM_CYCLE-2];
	assign id_out = id_delay[MEM_CYCLE-2];

	integer i;
	always @ (posedge clk or negedge reset)
	begin
		if (!reset) begin
			for (i=0; i<MEM_CYCLE-1; i=i+1) begin
				data_delay[i] <= 0;
				id_delay[i] <= 0;
			end
		end
		else begin
			data_delay[0] <= mem_data;
			id_delay[0] <= id_temp;
			for (i=1; i<MEM_CYCLE-1; i=i+1) begin
				data_delay[i] <= data_delay[i-1];
				id_delay[i] <= id_delay[i-1];
			end
		end
	end
	
//	assign data_out = (addr_in < 32'h100) ? 256'h05050505_03030303_09090909_08080808 : 256'h00010002_00030004_00050006_00070008;
	assign stall_out = 1'b0;
	assign ready_out = valid_delay[MEM_CYCLE-1];
	
	always @ (posedge clk or negedge reset)
	begin
		if (!reset) begin
			for (i=0; i<MEM_CYCLE; i=i+1) begin
				valid_delay[i] <= 1'b0;
			end
		end
		else begin
			valid_delay[0] <= valid_in & ~rw_in;
			for (i=1; i<MEM_CYCLE; i=i+1) begin
				valid_delay[i] <= valid_delay[i-1];
			end
		end
	end
	
	always @ (posedge clk or negedge reset)
	begin
		if (!reset) begin
//			ready_out <= 1'b0;
			id_temp <= 0;
		end
		else begin
//			if (ready_temp & ready_out !=1'b1)
	//			ready_out <= 1'b1;
	//		else	
		//		ready_out <= 1'b0;
			if (valid_in)
				id_temp <= id_in;
		end
	end
	
//	assign ready_out = (posedge clk & ready_temp) ? 1'b0 : ready_temp;
	
/*	always@ (posedge clk or negedge reset)
	begin
		if (!reset) begin
			ready_temp <= 1'b0;
			count <= setMax;
		end
		else begin
			if (rw_in)
				ready_temp <= 1'b0;
			else if (addr_in < 100)
				ready_temp <= valid_in;
			else if (valid_in) begin
				count <= One;
				ready_temp <= 1'b0;
			end	
			else begin	
				if (count < MEM_CYCLE-1) begin
					count <= count + One;
					ready_temp <= 1'b0;
				end	
				else if (count == MEM_CYCLE-1) begin
					count <= setMax;
					ready_temp <= 1'b1;	
				end
				else begin
					count <= setMax;
					ready_temp <= 1'b0;
				end				
			end
		end
	end
*/
	
endmodule