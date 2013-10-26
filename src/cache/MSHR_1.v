module MSHR_1
#(parameter addr_tag_bits=20, parameter data_bits = 90, parameter mshr_tag_bits = 3)
(
	clk, enable, reset,
	
	add, add_addr_tag, add_addr_data, add_addr_RW,
	del, del_addr_tag,
	read_next,
	isRW_request,
	isRW_tag,
	
	read_valid, read_addr_tag, read_addr_data, 
	isRW_valid, isRW_RW
);

	input clk, enable, reset;
	
	input add;
	input [addr_tag_bits-1:0] add_addr_tag;
	input [data_bits-1:0] add_addr_data;
	input add_addr_RW;
	
	input del; 
	input [addr_tag_bits-1:0] del_addr_tag;
	input read_next;
	
	input isRW_request;
	input [addr_tag_bits-1:0] isRW_tag;
	
	output read_valid; 
	output [addr_tag_bits-1:0] read_addr_tag;
	output [data_bits-1:0] read_addr_data; 
	output reg isRW_valid, isRW_RW;


	reg [mshr_tag_bits-1:0] del_MSHR_tag, isRW_MSHR_tag;
	
	reg [addr_tag_bits-1:0] tags [0:2**mshr_tag_bits-1];
	reg [data_bits-1:0] data [0:2**mshr_tag_bits-1];
	reg RW [0:2**mshr_tag_bits-1];	
	reg val [0:2**mshr_tag_bits-1];
	reg read [0:2**mshr_tag_bits-1];
	
	reg [mshr_tag_bits-1:0] entries_read;
	reg [mshr_tag_bits:0] occupied_spaces;
	
	wire [mshr_tag_bits-1:0] read_MSHR_tag;
	wire has_free_space;
	
	integer i,j;
	
	wire [mshr_tag_bits-1:0] next_free_reg_tag;
	
	reg add_entry_signal;
	reg del_entry_signal;
	reg read_entry_signal;
	
	fill_list_shift_register A1 (.clk(clk), .enable(enable), .reset(reset), .add(add_entry_signal), .add_tag(next_free_reg_tag), .del(del_entry_signal), .del_tag(del_MSHR_tag), .read(read_entry_signal), .valid_out(read_valid), .tag_out(read_MSHR_tag));
	
	free_list_FIFO B1 (.clk(clk), .enable(enable), .reset(reset), .push(del_entry_signal), .push_tag(del_MSHR_tag), .pop(add_entry_signal), .free_tag(next_free_reg_tag), .free_tag_valid(has_free_space));
	
	assign read_addr_tag = tags[read_MSHR_tag];
	assign read_addr_data = data[read_MSHR_tag];
	
	always @ (negedge clk) begin
		if ((add == 1'b1) && (occupied_spaces < 2**mshr_tag_bits) && (has_free_space))begin
			add_entry_signal = 1;
		end else begin
			add_entry_signal = 0;
		end
		
		if ((del == 1'b1) && (occupied_spaces > 0))begin
			del_entry_signal = 1;
		end else begin
			del_entry_signal = 0;
		end

		if ((read_next == 1'b1) && (occupied_spaces > entries_read))begin
			read_entry_signal = 1;
		end else begin
			read_entry_signal = 0;
		end	
	end
	
	always @ (isRW_request or isRW_tag)
	begin
		for(i=0; i<2**mshr_tag_bits; i=i+1) begin
			if((val[i] == 1'b1)&&(tags[i] == isRW_tag))begin
				isRW_valid <= 1;
				isRW_RW <= RW[i];
			end
			else begin
				isRW_valid <= 0;
				isRW_RW <= 0;			
			end
		end
	end
		
	always @ (del or del_addr_tag)
	begin
		for(j=0; j<2**mshr_tag_bits; j=j+1) begin
			if((val[j] == 1'b1)&&(tags[j] == del_addr_tag))begin
				del_MSHR_tag <= j;
			end
			else begin
				del_MSHR_tag <= 0;			
			end
		end
	end	
	
	integer xx;
	// Shift everything over, load the incoming bit
	always @ (posedge clk or posedge reset)
	begin
		if (reset == 1'b1)
		begin
			entries_read <= 0;
			occupied_spaces <= 0;
			for(xx=0; xx<2**mshr_tag_bits; xx=xx+1) begin
				tags[xx] <= 0;
				data[xx] <= 0;
				RW[xx] <= 0;
				val[xx] <= 0;
				read[xx] <= 0;
			end
		end
		else if (enable == 1'b1)
		begin
			if(add_entry_signal == 1)begin
				val[next_free_reg_tag] <= 1;
				read[next_free_reg_tag] <= 0;
				RW[next_free_reg_tag] <= add_addr_RW;
				tags[next_free_reg_tag] <= add_addr_tag;
				data[next_free_reg_tag] <= add_addr_data;
			end
			if(del_entry_signal == 1'b1)begin
				val[del_MSHR_tag] <= 0;
				read[del_MSHR_tag] <= 0;
				RW[del_MSHR_tag] <= 0;
				tags[del_MSHR_tag] <= 0;
				data[del_MSHR_tag] <= 0;
			end
			if(read_entry_signal)begin
				read[read_MSHR_tag] <= 1;
			end
			
			
			if((add_entry_signal == 1'b1)&&(del_entry_signal == 1'b0))begin
				occupied_spaces = occupied_spaces+1;
			end 
			else if ((add_entry_signal == 1'b0)&&(del_entry_signal == 1'b1)) begin
				occupied_spaces = occupied_spaces-1;
			end
			else begin
				occupied_spaces = occupied_spaces;
			end
			
			if((read_entry_signal == 1'b1)&&(del_entry_signal == 1'b0))begin
				entries_read = entries_read+1;
			end 
			else if ((read_entry_signal == 1'b0)&&(del_entry_signal == 1'b1)) begin
				entries_read = entries_read-1;
			end
			else begin
				entries_read = entries_read;
			end
			
		end
	end

	// Catch the o
endmodule