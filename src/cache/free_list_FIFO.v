`timescale 1ns/100ps

module free_list_FIFO
#(parameter tag_bits=3)
(
	clk, enable, reset,
	push, push_tag,
	pop, 
	
	free_tag, free_tag_valid
);
	
	input clk, enable, reset;
	input push, pop;
	
	input [tag_bits-1:0] push_tag;
	
	output free_tag_valid;
	output [tag_bits-1:0] free_tag;
	

	// Declare the shift register
	reg tag_list_valid [0:2**tag_bits-1];
	reg [tag_bits-1:0] tag_list [0:2**tag_bits-1];

	reg [tag_bits-1:0] head_ptr;
	reg [tag_bits-1:0] tail_ptr;
	
	reg [tag_bits:0] size;
	
	wire [tag_bits:0] One;
	assign One = {{tag_bits{1'b0}}, 1'b1};
	wire [tag_bits-1:0] OneS;
	assign OneS = {{tag_bits-1{1'b0}}, 1'b1};
	
	integer i; 
	// Shift everything over, load the incoming bit
	always @ (posedge clk or negedge reset)
	begin
		if (!reset)
		begin
			// Load N zeros 
			//genvar i; 
			//generate
			for (i=0; i<(2**tag_bits); i=i+1) begin
				tag_list[i] <= i;
				tag_list_valid[i] <= 1'b1;
			end
			head_ptr <= 0;
			tail_ptr <= 2**tag_bits;
			size <= 2**tag_bits;
			//endgenerate
		end
		else if (enable == 1'b1)
		begin
		//first we deal with inserting the values in to the list
			if((size > 0)&&(pop == 1))begin
				tag_list_valid[head_ptr] <= 1'b0;
				head_ptr <= head_ptr + OneS;
			end
			if((size < 2**tag_bits)&&(push == 1))begin
				tag_list_valid[tail_ptr] <= 1'b1;
				tag_list[tail_ptr] <= push_tag;
				tail_ptr <= tail_ptr + OneS;		
			end			
		//Next we got to deal with the size variable
			if(((size > 0)&&(pop == 1))&&((size < 2**tag_bits)&&(push == 1)))begin
				size <= size;
			end
			else if ((size < 2**tag_bits)&&(push == 1)) begin
				size <= size + One;
			end
			else if ((size > 0)&&(pop == 1)) begin
				size <= size - One;
			end
			else begin
				size <= size;
			end		
		end
	end

	assign free_tag_valid = tag_list_valid[head_ptr];
	assign free_tag = tag_list[head_ptr];

endmodule
