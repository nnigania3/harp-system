module DMem
#(parameter DATA_WIDTH = 256, parameter ADDR_WIDTH=32, parameter SIZE=4096)
(
	input [ADDR_WIDTH-1:0] addr, 
	input [DATA_WIDTH-1:0] data,
	input wr_en, 
	input clk, 
	input reset,
	output [DATA_WIDTH-1:0] mem_data_out	
);

	reg [DATA_WIDTH-1:0] DMem [0:SIZE-1];
	integer i;
	
	initial begin
		for (i=0; i<SIZE/2; i=i+1) begin
			if (i%2 == 0)
				DMem[i] <= 256'h05050505_03030303_09090909_08080808;
			else
				DMem[i] <= 256'h00010002_00030004_00050006_00070008;
		end
		for (i=SIZE/2; i<SIZE; i=i+1) begin
			if (i%2 == 0)
				DMem[i] <= 256'h05050505_03030303_09090909_08080808;
			else
				DMem[i] <= 256'h00010002_00030004_00050006_00070008;
		end
	end
	
	reg [ADDR_WIDTH-1:0] addr_reg;

	always @ (posedge clk)
	begin
		// Write
		if (wr_en)
			DMem[addr] <= data;

		addr_reg <= addr;
	end

	assign mem_data_out = DMem[addr_reg];
   
endmodule 