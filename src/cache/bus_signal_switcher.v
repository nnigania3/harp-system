`timescale 1ns/100ps

module bus_signal_switcher
#(parameter num_buses = 2, parameter num_buses_log = 1, parameter bus_width = 256)
(
	select,
	data_in,
	bus_out
);

	input [num_buses_log-1:0] select;
	input [bus_width-1:0] data_in;
	
	output [(num_buses*bus_width)-1:0] bus_out;
	
	reg [bus_width-1:0] MSB_half;
	reg [bus_width-1:0] LSB_half;
	
//	integer i;
	always @ (data_in or select)begin
//		for(i=0; i<num_buses; i=i+1)begin
//			if (select == i) begin
//				bus_out[((i+1)*bus_width)-1:(i*bus_width)] <= data_in;
//			end else begin
//				bus_out[((i+1)*bus_width)-1:(i*bus_width)] <= 0;
//			end
//		end

		if (select == 0) begin
			MSB_half <= 0;
			LSB_half <= data_in;
		end else// if (select == 1) 
		begin
			MSB_half <= data_in;
			LSB_half <= 0;
		end
	end
	assign bus_out = {MSB_half, LSB_half};
endmodule