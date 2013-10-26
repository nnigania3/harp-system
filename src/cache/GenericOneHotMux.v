`timescale 1ns/100ps

module GenericOneHotMux 
#( parameter WIDTH=32, parameter SEL_BITS=4)
(
	input [WIDTH*SEL_BITS-1:0] in_bus, 
	input [SEL_BITS-1:0] sel,
	output [WIDTH-1:0] out
);

	reg [WIDTH-1:0] array; //[0:(2**WIDTH)-1];
	integer i, j;

//	initial begin
//		array = 32'b0;
//	end
	
	always @* begin
		array = {WIDTH{1'b0}};
		for( i = 0; i < SEL_BITS; i = i+1 ) begin
			for( j = 0; j < WIDTH; j = j+1 ) begin
				array[j] = array[j] | (in_bus[WIDTH*i+j] & sel[i]);
			end
		end
	end
	
//	for( j = 0; j < WIDTH; i = i+1 ) begin : Gen1
//			array[i] = in_bus[WIDTH*(i+1)-1:WIDTH*i] & {WIDTH{sel[i]}};
//		end
  
  assign #0.5 out = array;
  
endmodule 
