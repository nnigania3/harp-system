`timescale 1ns/100ps

module GenericMux 
#( parameter WIDTH=32, parameter SEL_BITS=3)
(
	input [WIDTH*(2**SEL_BITS)-1:0] in_bus, 
	input [SEL_BITS-1:0] sel,
	output [WIDTH-1:0] out
);

	wire [WIDTH-1:0] array [0:(2**SEL_BITS)-1];

	genvar i;
	
	generate for( i = 0; i < 2**SEL_BITS; i = i+1 ) 
		begin : Gen1
			assign array[i] = in_bus[WIDTH*(i+1)-1:WIDTH*i];
		end
	endgenerate
  
  assign #0.5 out = array[sel];
  
endmodule
