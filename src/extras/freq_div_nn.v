module freq_div_nn #(parameter divide_by = 2, DIVLOG = 1) 
(
	input clk,
	output clk_div
);

reg [DIVLOG-1:0]	count;

initial begin
	count <= 0;
end

always @ (posedge clk)
begin
		count <= count + 1;
end

assign clk_div = count[DIVLOG-1];
	
endmodule
