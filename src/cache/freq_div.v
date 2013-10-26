module Frequency_Divider #(parameter Divisor = 4, parameter Bits = 2) 
(
	input i_Clock,
	input i_Reset,
	output o_Out
);

reg [Bits-1:0]	r_Count;
wire [Bits-1:0]	plusOne;

assign plusOne = 1; //{{Bits-1{1'b0}}, 1'b1};
always @ (posedge i_Clock or negedge i_Reset)
	if (!i_Reset) begin
		r_Count <= 0;
	//	o_Out <= 0;
	end
	else begin
//		if (r_Count[0] == 1'b1)
//			o_Out <= ~o_Out;
		if (r_Count != Divisor - 1)
			r_Count <= r_Count + plusOne;
		else
			r_Count <= 0;
	end
	assign o_Out = r_Count[Bits-1];
	
endmodule
