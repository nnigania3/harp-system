`timescale 1ns/100ps


module fill_list_shift_register
#(parameter tag_bits=3)
(
	clk, enable, reset,
	
	add, add_tag,
	del, del_tag,
	
	read, 
	
	valid_out,
	tag_out
);

	input clk, enable, reset;
	
	input add, del;
	input [tag_bits-1:0]  add_tag, del_tag;

	input read;
	
	output reg valid_out;
	output reg [tag_bits-1:0] tag_out;
	
	// Declare the shift register
	reg [tag_bits-1:0] tags [0:2**tag_bits-1];
	reg val [0:2**tag_bits-1];
	
	wire shift_var [0:2**tag_bits-1];
	
	reg [tag_bits-1:0] index_ptr;
	reg [tag_bits:0] size;
	
	wire [tag_bits:0] One;
	assign One = {{tag_bits{1'b0}}, 1'b1};
	wire [tag_bits-1:0] OneS;
	assign OneS = {{tag_bits-1{1'b0}}, 1'b1};

	//I need to know which registers I need to shift up into
	genvar i;
	assign shift_var[0] = ((val[0]==1'b1)&&(tags[0]==del_tag))?1'b1:1'b0;
	generate
	for(i=1; i<2**tag_bits; i=i+1) begin: Gen1
		assign shift_var[i] = ((val[i]==1'b1)&&(tags[i]==del_tag))?1'b1:shift_var[i-1];
	end
	endgenerate
	
	//genvar j;
	//genvar k;
	//genvar l;

	integer l;
	integer j;
	integer k;
	
	// Shift everything over, load the incoming bit
	always @ (posedge clk or negedge reset)
	begin
		if (!reset)
		begin  //Must initialize everything to zero
			//generate	
		   for(j=0; j<2**tag_bits; j=j+1) begin: Gen2
				tags[j] <= 0;
				val[j] <= 1'b0;
			end
			//endgenerate
			index_ptr <= 0;
			size <= 0;
			valid_out <= 1'b0;
		end
		
		
		
		else if (enable == 1'b1)
		begin
		//First thing to do is to shift the register valuse up by one if there is a delete(we need to also include the adding operation here)
		//Second thing to do is to update the size

		if ((add == 1'b1)&&(del == 1'b0)) begin
			tags[size] <= add_tag;
			val[size] <= 1'b1;
			size <= size+One;
		end
		else if ((add == 1'b0)&&(del == 1'b1)) begin
			//generate
			for (k=0; k<(2**tag_bits-1); k=k+1) begin
				tags[k] <= (shift_var[k])?tags[k+1]:tags[k];
				val[k] <= (shift_var[k])?val[k+1]:val[k];
			end
			tags[2**tag_bits-1] <= (shift_var[2**tag_bits-1])?0:tags[k];
			val[2**tag_bits-1] <= (shift_var[2**tag_bits-1])?1'b0:val[k];
			//endgenerate
			
			size <= size-One;
		end	
		else if ((add == 1'b1)&&(del == 1'b1)) begin
			//generate
			for (l=0; l<(2**tag_bits-1); l=l+1) begin
				if ((size-1) == l) begin
					tags[l] <= add_tag;
					val[l] <= 1'b1;
				end
				else begin	
					tags[l] <= (shift_var[l])?tags[l+1]:tags[l];
					val[l] <= (shift_var[l])?val[l+1]:val[l];
				end
			end
			if ((size-1) == (2**tag_bits-1)) begin
				tags[2**tag_bits-1] <= add_tag;
				val[2**tag_bits-1] <= 1'b1;
			end
			else begin	
				tags[2**tag_bits-1] <= (shift_var[2**tag_bits-1])?0:tags[k];
				val[2**tag_bits-1] <= (shift_var[2**tag_bits-1])?1'b0:val[k];
			end
			//endgenerate
			size <= size;
		end			
			
		
		//Third we send out the outputs and update the index ptr
		
		if ((read == 1'b0)&&(del == 1'b1)) begin
				index_ptr <= index_ptr - OneS;
				valid_out <= 1'b0;
				tag_out <= 0;
		end
		else if ((read == 1'b1)&&(del == 1'b0)) begin
			if (index_ptr < size) begin 
				index_ptr <= index_ptr + OneS;
				valid_out <= 1'b1;
				tag_out <= tags[index_ptr];
			end
			else begin
				valid_out <= 0;
				tag_out <= 0;
			end			
		end
		else if ((read == 1'b1)&&(del == 1'b1)) begin 
			index_ptr <= index_ptr;
			valid_out <= 1'b1;
			tag_out <= tags[index_ptr];
		end
		else begin
			index_ptr <= index_ptr;
			valid_out <= 1'b0;
			tag_out <= 0;
		end
		end
	end
	
endmodule
