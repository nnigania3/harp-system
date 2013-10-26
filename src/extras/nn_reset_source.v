module nn_reset_source
#(	parameter INITIAL_RESET_CYCLES = 5	// entries in the buffer
)(
	input clk,
	output reg reset
);

reg [31:0] reset_count;

initial begin
	reset_count = 32'd0;
end

always@(posedge clk) begin
 	if(reset_count < INITIAL_RESET_CYCLES) begin
		reset_count <= reset_count + 1;
		reset <= 1'b0;
	end else begin
		reset_count <= INITIAL_RESET_CYCLES;
		reset <= 1'b1;
	end
end

endmodule
