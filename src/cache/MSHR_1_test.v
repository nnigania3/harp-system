`timescale 1ns/100ps

module MSHR_1_test;
	
	parameter addr_tag_bits=20; 
	parameter data_bits = 90; 
	parameter mshr_tag_bits = 3;
	
	reg clk, enable, reset;
	
	reg add;
	reg [addr_tag_bits-1:0] add_addr_tag;
	reg [data_bits-1:0] add_addr_data;
	reg add_addr_RW;
	
	reg del; 
	reg [addr_tag_bits-1:0] del_addr_tag;
	reg read_next;
	
	reg isRW_request;
	reg [addr_tag_bits-1:0] isRW_tag;
	
	wire read_valid; 
	wire [addr_tag_bits-1:0] read_addr_tag;
	wire [data_bits-1:0] read_addr_data; 
	wire isRW_valid, isRW_RW;
	
	MSHR_1 A1
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
	
	always #5 clk = ~clk;
	
	initial begin
		clk = 1;
		enable = 0;
		reset = 0;
		
		add = 0;
		add_addr_tag = 0;
		add_addr_data = 0; 
		add_addr_RW = 0;
		
		del = 0;
		del_addr_tag = 0;
		
		read_next = 0;
		
		isRW_request = 0;
		isRW_tag = 0;
		
		#15

		enable = 0;
		reset = 1;
		
		add = 0;
		add_addr_tag = 0;
		add_addr_data = 0; 
		add_addr_RW = 0;
		
		del = 0;
		del_addr_tag = 0;
		
		read_next = 0;
		
		isRW_request = 0;
		isRW_tag = 0;

		#10
		
		enable = 1;  //1st Write
		reset = 0;
		
		add = 1;
		add_addr_tag = 1;
		add_addr_data = 100; 
		add_addr_RW = 0;
		
		del = 0;
		del_addr_tag = 0;
		
		read_next = 0;
		
		isRW_request = 0;
		isRW_tag = 0;
		
		#10
		
		enable = 1;  //2nd Write
		reset = 0;
		
		add = 1;
		add_addr_tag = 2;
		add_addr_data = 110; 
		add_addr_RW = 0;
		
		del = 0;
		del_addr_tag = 0;
		
		read_next = 0;
		
		isRW_request = 0;
		isRW_tag = 0;
		
		#10
		
		enable = 1;  //3rd Write
		reset = 0;
		
		add = 1;
		add_addr_tag = 3;
		add_addr_data = 120; 
		add_addr_RW = 1;
		
		del = 0;
		del_addr_tag = 0;
		
		read_next = 0;
		
		isRW_request = 0;
		isRW_tag = 0;
		
		#10
		
		enable = 1;  //4th Write
		reset = 0;
		
		add = 1;
		add_addr_tag = 4;
		add_addr_data = 130; 
		add_addr_RW = 0;
		
		del = 0;
		del_addr_tag = 0;
		
		read_next = 0;
		
		isRW_request = 0;
		isRW_tag = 0;
		
		#10
		
		enable = 1;  //5th Write
		reset = 0;
		
		add = 1;
		add_addr_tag = 5;
		add_addr_data = 140; 
		add_addr_RW = 0;
		
		del = 0;
		del_addr_tag = 0;
		
		read_next = 1;
		
		isRW_request = 0;
		isRW_tag = 0;
		
		#10
		
		enable = 1;  //6th Write
		reset = 0;
		
		add = 1;
		add_addr_tag = 6;
		add_addr_data = 150; 
		add_addr_RW = 0;
		
		del = 0;
		del_addr_tag = 0;
		
		read_next = 1;
		
		isRW_request = 0;
		isRW_tag = 0;
		
		#10
		
		enable = 1;  //7th Write
		reset = 0;
		
		add = 1;
		add_addr_tag = 7;
		add_addr_data = 160; 
		add_addr_RW = 0;
		
		del = 0;
		del_addr_tag = 0;
		
		read_next = 1;
		
		isRW_request = 0;
		isRW_tag = 0;
		
		#10
		
		enable = 1;  //8th Write
		reset = 0;
		
		add = 1;
		add_addr_tag = 8;
		add_addr_data = 170; 
		add_addr_RW = 0;
		
		del = 0;
		del_addr_tag = 0;
		
		read_next = 1;
		
		isRW_request = 0;
		isRW_tag = 0;
		
		#10
		
		enable = 1;  //Delete 3rd value
		reset = 0;
		
		add = 0;
		add_addr_tag = 0;
		add_addr_data = 0; 
		add_addr_RW = 0;
		
		del = 1;
		del_addr_tag = 3;
		
		read_next = 1;
		
		isRW_request = 0;
		isRW_tag = 0;
		
		#10
		
		enable = 1;  //Delete 4th value, Add another value to 3
		reset = 0;
		
		add = 1;
		add_addr_tag = 9;
		add_addr_data = 180; 
		add_addr_RW = 1;
		
		del = 1;
		del_addr_tag = 4;
		
		read_next = 1;
		
		isRW_request = 0;
		isRW_tag = 0;
		
		#10
		
		enable = 1;  //Delete 3rd value
		reset = 0;
		
		add = 0;
		add_addr_tag = 0;
		add_addr_data = 0; 
		add_addr_RW = 0;
		
		del = 1;
		del_addr_tag = 1;
		
		read_next = 1;
		
		isRW_request = 0;
		isRW_tag = 0;
		
		#10
		
		enable = 1;  //Delete 3rd value
		reset = 0;
		
		add = 0;
		add_addr_tag = 0;
		add_addr_data = 0; 
		add_addr_RW = 0;
		
		del = 1;
		del_addr_tag = 2;
		
		read_next = 1;
		
		isRW_request = 0;
		isRW_tag = 0;
		
		#10
		
		enable = 1;  //Delete 3rd value
		reset = 0;
		
		add = 0;
		add_addr_tag = 0;
		add_addr_data = 0; 
		add_addr_RW = 0;
		
		del = 1;
		del_addr_tag = 5;
		
		read_next = 1;
		
		isRW_request = 0;
		isRW_tag = 0;
		
		#10
		
		enable = 1;  //Delete 3rd value
		reset = 0;
		
		add = 0;
		add_addr_tag = 0;
		add_addr_data = 0; 
		add_addr_RW = 0;
		
		del = 1;
		del_addr_tag = 6;
		
		read_next = 0;
		
		isRW_request = 0;
		isRW_tag = 0;
	
		#10
		
		enable = 1;  //Delete 3rd value
		reset = 0;
		
		add = 0;
		add_addr_tag = 0;
		add_addr_data = 0; 
		add_addr_RW = 0;
		
		del = 1;
		del_addr_tag = 7;
		
		read_next = 0;
		
		isRW_request = 0;
		isRW_tag = 0;
	
		#10
		
		enable = 1;  //Delete 3rd value
		reset = 0;
		
		add = 0;
		add_addr_tag = 0;
		add_addr_data = 0; 
		add_addr_RW = 0;
		
		del = 1;
		del_addr_tag = 8;
		
		read_next = 0;
		
		isRW_request = 0;
		isRW_tag = 0;
		
		#10
		
		enable = 1;  //Delete 3rd value
		reset = 0;
		
		add = 0;
		add_addr_tag = 0;
		add_addr_data = 0; 
		add_addr_RW = 0;
		
		del = 1;
		del_addr_tag = 9;
		
		read_next = 0;
		
		isRW_request = 0;
		isRW_tag = 0;
		
		#10
		
		$finish;
	end
		
endmodule