`timescale 1ns/100ps

module FIFO
#(parameter index_bits=3, parameter data_width = 256)
(
	clk, enable, reset,
	push, push_tag,
	pop, 
	
	free_tag, free_tag_valid,
	
	empty, full
);
	
	input clk, enable, reset;
	input push, pop;
	
	input [data_width-1:0] push_tag;
	
	output empty, full;
	
	output free_tag_valid;
	output [data_width-1:0] free_tag;
	

	// Declare the shift register
	reg tag_list_valid [0:2**index_bits-1];
	reg [data_width-1:0] tag_list [0:2**index_bits-1];

	reg [index_bits-1:0] head_ptr;
	reg [index_bits-1:0] tail_ptr;
	
	reg [index_bits:0] size;
	
	integer i; 
	// Shift everything over, load the incoming bit
	always @ (posedge clk or posedge reset)
	begin
		if (reset == 1'b1)
		begin
			// Load N zeros 
			//genvar i; 
			//generate
			for (i=0; i<(2**index_bits); i=i+1) begin
				tag_list[i] <= 0;
				tag_list_valid[i] <= 0;
			end
			head_ptr = 0;
			tail_ptr = 0;
			size = 0;
			//endgenerate
		end
		else if (enable == 1'b1)
		begin
		//first we deal with inserting the values in to the list
			if((size > 0)&&(pop == 1))begin
				tag_list_valid[head_ptr] <= 0;
				head_ptr <= head_ptr + 1;
			end
			if((size < 2**index_bits)&&(push == 1))begin
				tag_list_valid[tail_ptr] <= 1;
				tag_list[tail_ptr] <= push_tag;
				tail_ptr <= tail_ptr + 1;		
			end			
		//Next we got to deal with the size variable
			if(((size > 0)&&(pop == 1))&&((size < 2**index_bits)&&(push == 1)))begin
				size <= size;
			end
			else if ((size < 2**index_bits)&&(push == 1)) begin
				size <= size + 1;
			end
			else if ((size > 0)&&(pop == 1)) begin
				size <= size - 1;
			end
			else begin
				size <= size;
			end		
		end
	end

	assign free_tag_valid = tag_list_valid[head_ptr];
	assign free_tag = tag_list[head_ptr];
	
	assign full = (size==2**index_bits)?1:0;
	assign empty = (size==0)?1:0;

endmodule
